/// 火山引擎流式语音识别服务
/// 完整实现 v2 二进制帧协议
///
/// 【模型切换标注】识别集群和模型在 VolcAsrConfig 中配置（控制台获取）
/// 【接口切换标注】WebSocket 地址在 VolcAsrConfig 中配置
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'volc_asr_config.dart';
import '../utils/chinese_number_converter.dart';

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

/// 音频帧标记
const int _FLAG_NORMAL = 0x00;
const int _FLAG_LAST = 0x02; // 最后一帧

// ========== 火山引擎流式 ASR 服务 ==========
class VolcAsrService extends ChangeNotifier {
  final VolcAsrConfig _config = VolcAsrConfig();
  AudioRecorder? _recorder;
  IOWebSocketChannel? _channel;
  StreamSubscription? _resultSubscription;
  Timer? _timeoutTimer;
  String _tempFilePath = '';

  AsrServiceState _state = AsrServiceState.idle;
  String _lastError = '';
  String _partialText = '';
  int _sequence = 0;
  String _reqId = '';

  // ========== 回调 ==========
  VoidCallback? onResult;
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

  /// 构建火山引擎 ASR v2 二进制帧
  /// [header]: 4 字节帧头
  /// Byte 0: protocol_version(高4bit) | header_size(低4bit)
  /// Byte 1: message_type(高4bit) | specific_flags(低4bit)
  /// Byte 2: serialization(高4bit) | compression(低4bit)
  /// Byte 3: 保留 (0x00)
  /// [payloadSize]: 4 字节大端 payload 长度
  /// [payload]: payload 数据
  static Uint8List _buildFrame(
      int messageType, int flags, int serialization, int compression,
      Uint8List payload) {
    final frame = Uint8List(8 + payload.length);
    final header = ByteData.view(frame.buffer, 0, 4);

    // Byte 0: protocol_version | header_size
    header.setUint8(0, (_PROTOCOL_VERSION << 4) | _HEADER_SIZE);
    // Byte 1: message_type | flags
    header.setUint8(1, (messageType << 4) | flags);
    // Byte 2: serialization | compression
    header.setUint8(2, (serialization << 4) | compression);
    // Byte 3: reserved
    header.setUint8(3, 0x00);

    // Byte 4-7: payload size (uint32, big-endian)
    header.setUint32(4, payload.length, Endian.big);

    // Payload
    frame.setRange(8, 8 + payload.length, payload);
    return frame;
  }

  /// 解析服务端返回的二进制帧
  /// 返回 (messageType, flags, serialization, payload) 或 null
  static (int, int, int, Uint8List)? _parseResponse(Uint8List frame) {
    if (frame.length < 8) return null;
    final header = ByteData.view(frame.buffer, frame.offsetInBytes, 8);
    final messageType = header.getUint8(1) >> 4;
    final flags = header.getUint8(1) & 0x0F;
    final serialization = header.getUint8(2) >> 4;
    final payloadLen = header.getUint32(4, Endian.big);
    if (frame.length < 8 + payloadLen) return null;
    final payload = Uint8List.sublistView(frame, 8, 8 + payloadLen);
    return (messageType, flags, serialization, payload);
  }

  // ========== 生命周期 ==========

  Future<void> initialize() async {
    await _config.load();
    // 临时硬编码测试凭据
    if (!_config.hasAccessToken) {
      await _config.setAccessToken('jA6AnlD0kDzKXO0t-gpFMZ2lz9x566TJ');
      await _config.setAppId('4261051259');
      await _config.setClusterId('volcengine_asr_common');
      debugPrint('ASR: 已设置开发测试凭据（AppID: 4261051259）');
    }
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
    if (!_config.hasClusterId) {
      _lastError = '请先在设置页面配置 Cluster ID（控制台获取）';
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
    _sequence = 0;
    notifyListeners();

    try {
      final tempDir = await getTemporaryDirectory();
      _tempFilePath =
          '${tempDir.path}/volc_asr_${DateTime.now().millisecondsSinceEpoch}.wav';

      _recorder = AudioRecorder();
      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _tempFilePath,
      );

      _state = AsrServiceState.recording;
      onListeningStarted?.call();
      notifyListeners();

      // 10 秒超时自动停止
      _timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (_state == AsrServiceState.recording) {
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

  // ========== 停止录音 + 发送 ASR 请求 ==========

  Future<void> stopListening() async {
    if (_state != AsrServiceState.recording) return;
    _timeoutTimer?.cancel();

    try {
      final path = await _recorder?.stop();
      _recorder?.dispose();
      _recorder = null;

      if (path == null || !File(path).existsSync()) {
        _lastError = '录音文件不存在';
        _state = AsrServiceState.idle;
        onError?.call(_lastError);
        onListeningStopped?.call();
        notifyListeners();
        return;
      }

      final file = File(path);
      final audioBytes = await file.readAsBytes();

      // 剥离 WAV 文件头（44 字节），取原始 PCM
      Uint8List pcmData;
      if (audioBytes.length > 44 &&
          audioBytes[0] == 0x52 && audioBytes[1] == 0x49 &&
          audioBytes[2] == 0x46 && audioBytes[3] == 0x46) {
        pcmData = Uint8List.sublistView(audioBytes, 44);
      } else {
        pcmData = Uint8List.fromList(audioBytes);
      }

      // 删除临时文件
      try { await file.delete(); } catch (_) {}

      _state = AsrServiceState.connecting;
      notifyListeners();

      await _sendAsrRequest(pcmData);

    } catch (e) {
      _lastError = '停止录音失败: $e';
      _state = AsrServiceState.error;
      onError?.call(_lastError);
      onListeningStopped?.call();
      notifyListeners();
    }
  }

  // ========== 发送火山引擎 ASR v2 二进制帧请求 ==========

  Future<void> _sendAsrRequest(Uint8List pcmData) async {
    try {
      _state = AsrServiceState.recognizing;
      notifyListeners();

      // === 1. 建立 WebSocket 连接 ===
      final wsUrl = _config.url.trim();
      if (!wsUrl.startsWith('wss://')) {
        _lastError = '接口地址必须以 wss:// 开头';
        onError?.call(_lastError);
        _state = AsrServiceState.idle;
        onListeningStopped?.call();
        notifyListeners();
        return;
      }

      // 火山引擎 v2 协议鉴权头格式：Authorization: Bearer;<token>
      // 注意：分号后直接跟 token 值，无 access_token= 前缀
      final authValue = 'Bearer;${_config.accessToken}';
      debugPrint('ASR: 连接 $wsUrl');
      debugPrint('ASR: Auth Header 格式验证...');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {'Authorization': authValue},
      );
      await _channel!.ready;
      debugPrint('ASR: WebSocket 连接成功');

      // === 2. 发送首包（full client request, message_type=0x01）===
      _sequence = 1;
      final firstJson = jsonEncode({
        'app': {
          'appid': _config.appId,
          'token': _config.accessToken,
          'cluster': _config.clusterId,
        },
        'user': {
          'uid': 'flutter_user_001',
        },
        'audio': {
          'format': 'pcm',
          'rate': 16000,
          'bits': 16,
          'channel': 1,
        },
        'request': {
          'reqid': _reqId,
          'sequence': _sequence,
          'nbest': 1,
          'show_utterances': false,
          'result_type': 'single',
        },
      });
      final firstPayload = Uint8List.fromList(utf8.encode(firstJson));
      final firstFrame = _buildFrame(
        _MSG_FULL_CLIENT_REQUEST, _FLAG_NORMAL,
        _SERIAL_JSON, _COMPRESS_NONE,
        firstPayload,
      );
      _channel!.sink.add(firstFrame);
      debugPrint('ASR: 首包已发送 (${firstPayload.length} bytes JSON)');

      // === 3. 分片发送音频数据（audio only, message_type=0x02）===
      const int chunkSize = 3200; // 100ms PCM 数据
      int totalSent = 0;
      final totalLen = pcmData.length;

      for (int offset = 0; offset < totalLen; offset += chunkSize) {
        _sequence++;
        final end = (offset + chunkSize > totalLen) ? totalLen : offset + chunkSize;
        final chunk = Uint8List.sublistView(pcmData, offset, end);
        final isLast = (end >= totalLen);
        final flags = isLast ? _FLAG_LAST : _FLAG_NORMAL;

        final audioFrame = _buildFrame(
          _MSG_AUDIO_ONLY, flags,
          _SERIAL_BYTES, _COMPRESS_NONE,
          chunk,
        );
        _channel!.sink.add(audioFrame);
        totalSent += chunk.length;

        // 控制发送速率
        await Future.delayed(const Duration(milliseconds: 30));
      }

      debugPrint('ASR: 音频数据发送完成 ($totalSent bytes, $_sequence frames)');

      // === 4. 接收服务端响应 ===
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

      // 5 秒响应超时
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
      debugPrint('ASR: 请求失败: $e');
      _lastError = '连接火山引擎 ASR 失败，请检查配置和网络';
      _state = AsrServiceState.error;
      onError?.call(_lastError);
      onListeningStopped?.call();
      _cleanupWs();
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
      if (serialization == _SERIAL_JSON) {
        try {
          final text = utf8.decode(payload);
          final data = jsonDecode(text) as Map<String, dynamic>;
          errorMsg = data['message'] as String? ??
                     data['code'] as String? ??
                     '服务端错误';
        } catch (_) {}
      }
      _lastError = '火山引擎 ASR 错误: $errorMsg';
      onError?.call(_lastError);
      _cleanupWs();
      _state = AsrServiceState.idle;
      onListeningStopped?.call();
      notifyListeners();
      return;
    }

    if (messageType == _MSG_FULL_SERVER_RESPONSE && serialization == _SERIAL_JSON) {
      try {
        final text = utf8.decode(payload);
        final data = jsonDecode(text) as Map<String, dynamic>;

        // 提取识别结果
        final resultList = data['result'] as List<dynamic>?;
        if (resultList != null && resultList.isNotEmpty) {
          final first = resultList[0] as Map<String, dynamic>;
          final recognizedText = first['text'] as String? ?? '';
          final isFinal = data['type'] == 'final' || flags == _FLAG_LAST;

          if (recognizedText.isNotEmpty) {
            _partialText = recognizedText;
            onResult?.call();
            notifyListeners();
          }
        }

        // 识别结束
        if (flags == _FLAG_LAST || data['type'] == 'final') {
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
    if (_recorder != null) {
      _recorder!.stop().then((_) {
        _recorder?.dispose();
        _recorder = null;
      }).catchError((_) {});
    }
    _cleanupWs();
    if (_tempFilePath.isNotEmpty) {
      File(_tempFilePath).delete().catchError((_) {});
    }
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