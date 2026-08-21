/// 火山引擎流式语音识别服务
/// 完整实现 v3 二进制帧协议
///
/// 【模型切换标注】识别资源和模型在 VolcAsrConfig 中配置（控制台获取）
/// 【接口切换标注】WebSocket 地址在 VolcAsrConfig 中配置
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

import 'volc_asr_config.dart';

// ========== 状态定义 ==========
enum AsrServiceState {
  idle,
  initializing,
  recording,
  connecting,
  recognizing,
  error,
}

// ========== 二进制帧常量 ==========
const int _PROTOCOL_VERSION = 0x01;
const int _HEADER_SIZE = 0x01; // 4 字节头

/// 消息类型
const int _MSG_FULL_CLIENT_REQUEST = 0x01; // 首包（JSON 配置）
const int _MSG_AUDIO_ONLY = 0x02; // 纯音频
const int _MSG_FULL_SERVER_RESPONSE = 0x09; // 服务端结果
const int _MSG_ERROR = 0x0F; // 服务端错误

/// 序列化方式
const int _SERIAL_JSON = 0x01;
const int _SERIAL_BYTES = 0x00;

/// 压缩方式
const int _COMPRESS_NONE = 0x00;
const int _COMPRESS_GZIP = 0x01;

/// 帧标记
const int _FLAG_NO_SEQUENCE = 0x00; // 不带序列号
const int _FLAG_LAST = 0x02; // 最后一包，不带序列号

// ========== 火山引擎流式 ASR 服务 ==========
class VolcAsrService extends ChangeNotifier {
  final VolcAsrConfig _config = VolcAsrConfig();
  AudioRecorder? _recorder;
  IOWebSocketChannel? _channel;
  StreamSubscription? _resultSubscription;
  Timer? _timeoutTimer;

  // ========== 流式录音（静音检测用） ==========
  StreamSubscription<Uint8List>? _audioStreamSub;
  // 采样率：与 RecordConfig 保持一致
  static const int _sampleRate = 16000;
  // 人声振幅阈值（RMS），低于此值视为静音（16bit PCM 可调）
  static const double _voiceRmsThreshold = 800;
  // 发送阈值（RMS）：低于此值的近静音分块不发送到服务端，过滤无效静音
  static const double _minSendRms = 200;
  // 静音停止时长：检测到人声后，连续静音达到该时长自动停止录音（可调）
  static const Duration _silenceStopTimeout = Duration(milliseconds: 800);
  // 最长录音时长：防止无静音场景下无限录音（可调）
  static const Duration _maxRecordTimeout = Duration(seconds: 20);
  bool _speechDetected = false;
  bool _stopRequested = false;
  final Stopwatch _silenceTimer = Stopwatch();

  AsrServiceState _state = AsrServiceState.idle;
  String _lastError = '';
  String _partialText = '';
  String _reqId = '';

  // ========== 回调 ==========
  VoidCallback? onResult;
  Function(String)? onPartial;
  VoidCallback? onListeningStarted;
  VoidCallback? onListeningStopped;
  Function(String)? onError;

  // ========== Getters ==========
  AsrServiceState get state => _state;
  String get lastError => _lastError;
  String get partialText => _partialText;
  bool get isListening =>
      _state == AsrServiceState.recording ||
      _state == AsrServiceState.recognizing;
  bool get isIdle => _state == AsrServiceState.idle;
  bool get hasAllConfig => _config.isFullyConfigured;
  VolcAsrConfig get config => _config;

  // ========== 二进制帧构建 ==========

  /// 生成随机 UUID（v4）
  static String _genUuid() {
    final r = Random();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// 构建火山引擎 ASR v3 二进制帧（不带序列号）
  /// [header]: 4 字节帧头
  /// Byte 0: protocol_version(高4bit) | header_size(低4bit)
  /// Byte 1: message_type(高4bit) | specific_flags(低4bit)
  /// Byte 2: serialization(高4bit) | compression(低4bit)
  /// Byte 3: 保留 (0x00)
  /// [payloadSize]: 4 字节大端 payload 长度
  /// [payload]: payload 数据
  /// 注意：客户端帧不携带 sequence 字段，结构为
  /// [4B header][4B payload size][payload]
  static Uint8List _buildFrame(
      int messageType, int flags, int serialization, int compression,
      Uint8List payload) {
    final frame = Uint8List(8 + payload.length);
    final data = ByteData.view(frame.buffer, 0, 8);

    // Byte 0: protocol_version | header_size
    data.setUint8(0, (_PROTOCOL_VERSION << 4) | _HEADER_SIZE);
    // Byte 1: message_type | flags
    data.setUint8(1, (messageType << 4) | flags);
    // Byte 2: serialization | compression
    data.setUint8(2, (serialization << 4) | compression);
    // Byte 3: reserved
    data.setUint8(3, 0x00);

    // Byte 4-7: payload size (uint32, big-endian)
    data.setUint32(4, payload.length, Endian.big);

    // Payload
    frame.setRange(8, 8 + payload.length, payload);
    return frame;
  }

  /// 解析服务端返回的二进制帧（v3）
  /// 返回 (messageType, flags, serialization, payload) 或 null
  /// 服务端响应帧可能有两种结构：
  /// 带 seq: [4B header][4B seq][4B payload size][payload]
  /// 不带 seq: [4B header][4B payload size][payload]
  /// 错误帧: [4B header][4B error code][4B error msg size][error msg]
  static (int, int, int, Uint8List)? _parseResponse(Uint8List frame) {
    if (frame.length < 4) return null;
    final header = ByteData.sublistView(frame, 0, 4);
    final messageType = header.getUint8(1) >> 4;
    final flags = header.getUint8(1) & 0x0F;
    final serialization = header.getUint8(2) >> 4;

    // 错误帧 (0x0F)：后跟错误码、错误信息长度、错误信息
    if (messageType == _MSG_ERROR) {
      if (frame.length < 12) return null;
      final errSize =
          ByteData.sublistView(frame, 8, 12).getUint32(0, Endian.big);
      if (frame.length < 12 + errSize) return null;
      final payload = Uint8List.sublistView(frame, 12, 12 + errSize);
      return (messageType, flags, serialization, payload);
    }

    if (frame.length < 8) return null;

    // 尝试两种结构解析，选择与 payload 长度匹配的那个
    // 带 seq: 从 offset 8 读 payload size
    // 不带 seq: 从 offset 4 读 payload size
    Uint8List? payload;

    for (final offset in [8, 4]) {
      if (frame.length < offset + 4) continue;
      final len =
          ByteData.sublistView(frame, offset, offset + 4).getUint32(0, Endian.big);
      // payload 长度必须小于帧剩余长度，且不能是异常大值
      if (len > 0 && len <= frame.length - offset - 4 && len < 20 * 1024 * 1024) {
        payload = Uint8List.sublistView(frame, offset + 4, offset + 4 + len);
        break;
      }
    }

    if (payload == null) return null;
    return (messageType, flags, serialization, payload);
  }

  // ========== 生命周期 ==========

  Future<void> initialize() async {
    await _config.load();
  }

  // ========== 麦克风权限 ==========
  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _lastError = '麦克风权限已被永久拒绝，请在系统设置中手动开启';
      return false;
    }
    _lastError = '麦克风权限被拒绝，无法开启语音识别';
    return false;
  }

  // ========== 开始录音 ==========

  Future<bool> startListening() async {
    // === 前置校验 ===
    if (!_config.hasAccessToken) {
      _lastError = '请先在设置页面配置火山引擎 Access Token';
      onError?.call(_lastError);
      return false;
    }
    if (!_config.hasAppId) {
      _lastError = '请先在设置页面配置 App ID（控制台获取）';
      onError?.call(_lastError);
      return false;
    }
    if (!_config.hasResourceId) {
      _lastError = '请先在设置页面配置 Resource ID（控制台获取）';
      onError?.call(_lastError);
      return false;
    }

    // === 麦克风权限 ===
    if (!await _requestMicPermission()) {
      onError?.call(_lastError);
      return false;
    }

    _state = AsrServiceState.initializing;
    _partialText = '';
    _lastError = '';
    _reqId = '${DateTime.now().millisecondsSinceEpoch}${_config.appId}';
    // 重置流式录音状态
    _speechDetected = false;
    _stopRequested = false;
    _silenceTimer.stop();
    _silenceTimer.reset();
    notifyListeners();

    try {
      // 边录边发：先建立 WebSocket 连接并发送首包，缩短识别启动等待
      final connected = await _connectAndInit();
      if (!connected) {
        _state = AsrServiceState.error;
        onError?.call(_lastError);
        notifyListeners();
        return false;
      }

      // 流式录音：直接采集原始 PCM 字节流，实时转发到服务端并做静音检测
      _recorder = AudioRecorder();
      final stream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );

      _audioStreamSub = stream.listen(
        _handleAudioChunk,
        onError: (error) {
          debugPrint('ASR: 录音流错误: $error');
        },
      );

      _state = AsrServiceState.recording;
      onListeningStarted?.call();
      notifyListeners();

      // 最长录音时长兜底：即使无静音也会自动停止（防卡死）
      _timeoutTimer = Timer(_maxRecordTimeout, () {
        if (_state == AsrServiceState.recording) {
          debugPrint('ASR: 超过最长录音时长(${_maxRecordTimeout.inSeconds}s)，自动停止');
          _stopRequested = true;
          stopListening();
        }
      });

      return true;
    } catch (e) {
      _lastError = '启动录音失败: $e';
      _state = AsrServiceState.error;
      onError?.call(_lastError);
      notifyListeners();
      return false;
    }
  }

  // ========== WebSocket 连接与首包 ==========

  /// 建立 WebSocket 连接、发送首包，并开始监听服务端流式响应
  /// 返回是否连接成功（失败原因写入 _lastError）
  Future<bool> _connectAndInit() async {
    try {
      final wsUrl = _config.url.trim();
      if (!wsUrl.startsWith('wss://')) {
        _lastError = '接口地址必须以 wss:// 开头';
        return false;
      }

      _reqId = _genUuid();
      final connectId = _genUuid();
      debugPrint('ASR: 连接 $wsUrl');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'X-Api-App-Key': _config.appId,
          'X-Api-Access-Key': _config.accessToken ?? '',
          'X-Api-Resource-Id': _config.resourceId,
          'X-Api-Connect-Id': connectId,
        },
      );
      await _channel!.ready;
      debugPrint('ASR: WebSocket 连接成功');

      // 发送首包（full client request, message_type=0x01）
      final firstJson = jsonEncode({
        'user': {
          'uid': 'flutter_user_001',
        },
        'audio': {
          'format': 'pcm',
          'codec': 'pcm',
          'rate': 16000,
          'bits': 16,
          'channel': 1,
          'language': 'zh-CN',
        },
        'request': {
          'model_name': 'bigmodel',
          'enable_punc': true,
          'enable_itn': true,
        },
      });
      final firstPayload = Uint8List.fromList(gzip.encode(utf8.encode(firstJson)));
      final firstFrame = _buildFrame(
        _MSG_FULL_CLIENT_REQUEST, _FLAG_NO_SEQUENCE,
        _SERIAL_JSON, _COMPRESS_GZIP,
        firstPayload,
      );
      _channel!.sink.add(firstFrame);
      debugPrint('ASR: 首包已发送 (${firstPayload.length} bytes gzip)');

      // 开始监听响应（服务端会流式返回识别结果）
      _resultSubscription = _channel!.stream.listen(
        (message) {
          if (message is Uint8List) {
            _handleResponse(message);
          } else if (message is String) {
            debugPrint('ASR: 收到文本消息（非预期）: $message');
          }
        },
        onError: (error) {
          debugPrint('ASR: WebSocket 错误: $error');
          _lastError = '网络连接异常，请检查网络后重试';
          _state = AsrServiceState.error;
          onError?.call(_lastError);
          onListeningStopped?.call();
          _cleanupWs();
          notifyListeners();
        },
        onDone: () {
          _state = AsrServiceState.idle;
          onListeningStopped?.call();
          _cleanupWs();
          notifyListeners();
        },
      );

      return true;
    } catch (e) {
      debugPrint('ASR: 连接失败: $e');
      _lastError = '连接火山引擎 ASR 失败，请检查配置和网络';
      _cleanupWs();
      return false;
    }
  }

  // ========== 音频分块处理（静音检测 + 实时转发） ==========

  /// 计算 16bit PCM 分块的 RMS 振幅
  static double _calcRms(Uint8List chunk) {
    if (chunk.length < 2) return 0;
    final data = ByteData.sublistView(chunk);
    double sum = 0;
    int count = 0;
    for (int i = 0; i + 1 < chunk.length; i += 2) {
      final sample = data.getInt16(i, Endian.little);
      sum += sample * sample;
      count++;
    }
    if (count == 0) return 0;
    return sqrt(sum / count);
  }

  /// 处理实时音频分块：
  /// - 过滤无效静音后将 PCM 实时转发到 ASR 服务端（边录边发）
  /// - 检测人声与静音，静音达到阈值自动停止录音
  void _handleAudioChunk(Uint8List chunk) {
    if (_state != AsrServiceState.recording || _stopRequested) return;

    // 计算振幅用于静音检测，并过滤近静音分块（不发送到服务端）
    final rms = _calcRms(chunk);
    if (rms >= _minSendRms) {
      _sendAudioChunk(chunk);
    }

    if (rms >= _voiceRmsThreshold) {
      // 检测到人声，重置静音计时
      _speechDetected = true;
      _silenceTimer.stop();
      _silenceTimer.reset();
    } else if (_speechDetected) {
      // 已有人声且当前为静音，累计静音时长
      if (!_silenceTimer.isRunning) _silenceTimer.start();
      if (_silenceTimer.elapsedMilliseconds >= _silenceStopTimeout.inMilliseconds) {
        debugPrint('ASR: 检测到静音 ${_silenceStopTimeout.inMilliseconds}ms，自动停止');
        _stopRequested = true;
        stopListening();
      }
    }
  }

  /// 将单块 PCM 音频实时发送到 ASR 服务端（不带序列号，gzip 压缩）
  void _sendAudioChunk(Uint8List chunk) {
    if (_channel == null) return;
    try {
      final audioFrame = _buildFrame(
        _MSG_AUDIO_ONLY,
        _FLAG_NO_SEQUENCE,
        _SERIAL_BYTES, _COMPRESS_GZIP,
        Uint8List.fromList(gzip.encode(chunk)),
      );
      _channel!.sink.add(audioFrame);
    } catch (e) {
      debugPrint('ASR: 发送音频分块失败: $e');
    }
  }

  // ========== 停止录音 ==========

  Future<void> stopListening() async {
    if (_state != AsrServiceState.recording) return;
    _timeoutTimer?.cancel();

    try {
      // 停止流式录音
      await _audioStreamSub?.cancel();
      _audioStreamSub = null;
      await _recorder?.stop();
      _recorder?.dispose();
      _recorder = null;

      // 发送最后一包（空音频，flags=LAST），标识音频流结束
      if (_channel != null) {
        try {
          final lastFrame = _buildFrame(
            _MSG_AUDIO_ONLY, _FLAG_LAST,
            _SERIAL_BYTES, _COMPRESS_NONE, Uint8List(0),
          );
          _channel!.sink.add(lastFrame);
        } catch (_) {}
      }

      // 进入识别等待状态，等待服务端最终识别结果
      _state = AsrServiceState.recognizing;
      notifyListeners();

      // 响应超时兜底（防卡死）
      _timeoutTimer = Timer(const Duration(seconds: 5), () {
        if (_state == AsrServiceState.recognizing) {
          debugPrint('ASR: 响应超时，关闭连接');
          _cleanupWs();
          _state = AsrServiceState.idle;
          onListeningStopped?.call();
          notifyListeners();
        }
      });
    } catch (e) {
      _lastError = '停止录音失败: $e';
      _state = AsrServiceState.error;
      onError?.call(_lastError);
      onListeningStopped?.call();
      notifyListeners();
    }
  }

  // ========== 处理服务端响应 ==========

  void _handleResponse(Uint8List frame) {
    final parsed = _parseResponse(frame);
    if (parsed == null) {
      debugPrint('ASR: 无法解析响应帧');
      return;
    }

    final (messageType, flags, serialization, payload) = parsed;
    _timeoutTimer?.cancel();

    if (messageType == _MSG_ERROR) {
      // 错误帧 (0x0F)
      String errorMsg = 'ASR 服务返回错误';
      String? codeStr;
      if (serialization == _SERIAL_JSON) {
        try {
          final text = utf8.decode(payload);
          final data = jsonDecode(text) as Map<String, dynamic>;
          errorMsg = data['message'] as String? ?? '服务端错误';
          final code = data['code'];
          final backendCode = data['backend_code'];
          codeStr = backendCode ?? code;
        } catch (_) {}
      }
      _lastError = codeStr != null
          ? '火山引擎 ASR 错误($codeStr): $errorMsg'
          : '火山引擎 ASR 错误: $errorMsg';
      debugPrint('ASR: 服务端错误帧: $_lastError');
      onError?.call(_lastError);
      _cleanupWs();
      _state = AsrServiceState.idle;
      onListeningStopped?.call();
      notifyListeners();
      return;
    }

    if (messageType == _MSG_FULL_SERVER_RESPONSE && serialization == _SERIAL_JSON) {
      try {
        // v3 响应 payload 可能为 gzip 压缩
        Uint8List raw = payload;
        final compression = ByteData.sublistView(frame, 2, 3).getUint8(0) & 0x0F;
        if (compression == _COMPRESS_GZIP) {
          raw = Uint8List.fromList(gzip.decode(payload));
        }
        final text = utf8.decode(raw);
        final data = jsonDecode(text) as Map<String, dynamic>;

        // 提取识别结果（v3: result 为 map，含 text 字段；async 也可能直接在顶层）
        final result = data['result'];
        String recognizedText = '';
        if (result is Map<String, dynamic>) {
          recognizedText = result['text'] as String? ?? '';
        } else if (result is List<dynamic>) {
          if (result.isNotEmpty && result[0] is Map<String, dynamic>) {
            recognizedText = (result[0] as Map<String, dynamic>)['text'] as String? ?? '';
          }
        }
        if (recognizedText.isEmpty) {
          recognizedText = data['text'] as String? ?? '';
        }

        final isFinal = data['type'] == 'final' ||
            flags == _FLAG_LAST ||   // 0x02
            flags == 0x03;           // 服务端末帧负序号

        if (recognizedText.isNotEmpty) {
          _partialText = recognizedText;
          if (isFinal || data['type'] == 'final') {
            onResult?.call();
          } else {
            onPartial?.call(recognizedText);
          }
          notifyListeners();
        }

        // 识别结束
        if (isFinal || data['type'] == 'final') {
          // 会话销毁时清空临时识别文本（语音识别记忆），避免残留
          _partialText = '';
          _cleanupWs();
          _state = AsrServiceState.idle;
          onListeningStopped?.call();
          notifyListeners();
        }

      } catch (e) {
        debugPrint('ASR: 结果解析失败: $e');
      }
    }
  }

  // ========== 清理 ==========

  void _cleanupWs() {
    _resultSubscription?.cancel();
    _resultSubscription = null;
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void cancelListening() {
    _timeoutTimer?.cancel();
    if (_audioStreamSub != null) {
      _audioStreamSub!.cancel();
      _audioStreamSub = null;
    }
    if (_recorder != null) {
      _recorder!.stop().then((_) {
        _recorder?.dispose();
        _recorder = null;
      }).catchError((_) {});
    }
    _cleanupWs();
    _state = AsrServiceState.idle;
    _partialText = '';
    onListeningStopped?.call();
    notifyListeners();
  }

  @override
  void dispose() {
    cancelListening();
    super.dispose();
  }
}