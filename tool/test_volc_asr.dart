import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';

String genUuid() {
  final r = Random();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

const int PROTOCOL_VERSION = 0x01;
const int HEADER_SIZE = 0x01;
const int MSG_FULL_CLIENT_REQUEST = 0x01;
const int MSG_AUDIO_ONLY = 0x02;
const int MSG_FULL_SERVER_RESPONSE = 0x09;
const int MSG_ERROR = 0x0F;
const int SERIAL_JSON = 0x01;
const int SERIAL_BYTES = 0x00;
const int COMPRESS_GZIP = 0x01;
const int COMPRESS_NONE = 0x00;
const int FLAG_NO_SEQUENCE = 0x00;
const int FLAG_LAST = 0x02;

Uint8List gzipBytes(List<int> data) =>
    Uint8List.fromList(gzip.encode(data));

// 客户端帧：无 sequence，[4B header][4B payload size][payload]
Uint8List buildFrame(int messageType, int flags, int serialization,
    int compression, Uint8List payload) {
  final frame = Uint8List(8 + payload.length);
  final data = ByteData.view(frame.buffer, 0, 8);
  data.setUint8(0, (PROTOCOL_VERSION << 4) | HEADER_SIZE);
  data.setUint8(1, (messageType << 4) | flags);
  data.setUint8(2, (serialization << 4) | compression);
  data.setUint8(3, 0x00);
  data.setUint32(4, payload.length, Endian.big);
  frame.setRange(8, 8 + payload.length, payload);
  return frame;
}

void parseResponse(Uint8List frame) {
  if (frame.length < 8) {
    print('RESP: frame too short');
    return;
  }
  final h = ByteData.sublistView(frame, 0, 4);
  final messageType = h.getUint8(1) >> 4;
  final flags = h.getUint8(1) & 0x0F;
  final serialization = h.getUint8(2) >> 4;
  final compression = h.getUint8(2) & 0x0F;

  // 服务端帧可能带 seq(12B头) 或不带 seq(8B头)，取能匹配长度的
  Uint8List? payload;
  for (final offset in [8, 4]) {
    if (frame.length < offset + 4) continue;
    final len = ByteData.sublistView(frame, offset, offset + 4).getUint32(0, Endian.big);
    if (len > 0 && len <= frame.length - offset - 4 && len < 20 * 1024 * 1024) {
      payload = Uint8List.sublistView(frame, offset + 4, offset + 4 + len);
      break;
    }
  }
  if (payload == null) {
    print('  cannot locate payload');
    return;
  }

  print('HEADER: ${frame.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')} '
      'type=$messageType flags=$flags ser=$serialization comp=$compression payloadLen=${payload.length}');

  if (compression == COMPRESS_GZIP) {
    try {
      final inflated = gzip.decode(payload);
      print('  PAYLOAD(GZIP): ${utf8.decode(inflated)}');
    } catch (e) {
      print('  GZIP decode failed: $e');
      print('  RAW: ${utf8.decode(payload, allowMalformed: true)}');
    }
  } else {
    print('  PAYLOAD: ${utf8.decode(payload, allowMalformed: true)}');
  }
}

Future<void> main() async {
  const appId = '4261051259';
  const token = 'jA6AnlD0kDzKXO0t-gpFMZ2lz9x566TJ';
  const resourceId = 'volc.seedasr.sauc.duration';
  const wsUrl = 'wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async';

  final connectId = genUuid();
  print('Connecting to $wsUrl');
  print('AppId: $appId');
  print('ResourceId: $resourceId');

  try {
    final channel = IOWebSocketChannel.connect(
      Uri.parse(wsUrl),
      headers: {
        'X-Api-App-Key': appId,
        'X-Api-Access-Key': token,
        'X-Api-Resource-Id': resourceId,
        'X-Api-Connect-Id': connectId,
      },
    );
    await channel.ready.timeout(const Duration(seconds: 15));
    print('WS CONNECTED OK');

    final firstJson = jsonEncode({
      'user': {'uid': 'flutter_user_001'},
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
    final firstPayload = gzipBytes(utf8.encode(firstJson));
    final firstFrame = buildFrame(
        MSG_FULL_CLIENT_REQUEST, FLAG_NO_SEQUENCE, SERIAL_JSON, COMPRESS_GZIP,
        firstPayload);
    channel.sink.add(firstFrame);
    print('FIRST FRAME SENT (${firstPayload.length} bytes gzip)');

    // 读取真实语音 PCM (去掉44字节WAV头)
    final wavFile = File(r'C:\Users\wzl\AppData\Local\Temp\opencode\real_16k.wav');
    final wavBytes = await wavFile.readAsBytes();
    final pcm = Uint8List.sublistView(wavBytes, 44);
    print('PCM bytes: ${pcm.length}');

    const chunkSize = 3200;
    var offset = 0;
    var sent = 0;
    while (offset < pcm.length) {
      final end = (offset + chunkSize > pcm.length) ? pcm.length : offset + chunkSize;
      final chunk = Uint8List.sublistView(pcm, offset, end);
      final isLast = end >= pcm.length;
      final audioFrame = buildFrame(
          MSG_AUDIO_ONLY,
          isLast ? FLAG_LAST : FLAG_NO_SEQUENCE,
          SERIAL_BYTES, COMPRESS_GZIP,
          gzipBytes(chunk));
      channel.sink.add(audioFrame);
      offset = end;
      sent++;
      await Future.delayed(const Duration(milliseconds: 50));
    }
    print('AUDIO SENT: $sent frames');

    final sub = channel.stream.listen(
      (message) {
        print('MSG TYPE: ${message.runtimeType} LEN: ${message.length}');
        if (message is Uint8List) {
          parseResponse(message);
        } else {
          print('TEXT MSG: $message');
        }
      },
      onError: (e) => print('WS ERROR: $e'),
      onDone: () {
        print('WS DONE');
      },
    );

    await Future.delayed(const Duration(seconds: 20));
    await sub.cancel();
    await channel.sink.close();
    print('TEST FINISHED');
  } catch (e) {
    print('CONNECT FAILED: $e');
  }
}