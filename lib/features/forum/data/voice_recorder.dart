import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// A recorded voice message: a `data:audio/wav` source and its length.
class VoiceClip {
  const VoiceClip(this.src, this.duration);

  final String src;
  final Duration duration;
}

/// Why recording could not start.
enum VoiceProblem { permission, unsupported }

class VoiceRecordingException implements Exception {
  const VoiceRecordingException(this.problem);
  final VoiceProblem problem;
}

/// Records the microphone for a voice message.
abstract interface class VoiceRecorder {
  /// Starts; throws [VoiceRecordingException] without the microphone.
  Future<void> start();

  /// The input level 0 → 1 while recording (the bubble's pulse).
  Stream<double> get level;

  /// Stops and returns the clip, or null when it is too short to send.
  Future<VoiceClip?> stop();

  /// Stops and throws the recording away.
  Future<void> cancel();
}

final voiceRecorderProvider = Provider<VoiceRecorder>((ref) {
  final r = DeviceVoiceRecorder();
  ref.onDispose(r.dispose);
  return r;
});

/// [VoiceRecorder] with the `record` package: 16 kHz mono PCM streamed into memory, then
/// wrapped as WAV (no file, the same on phones and in the browser): ~32 KB a second.
class DeviceVoiceRecorder implements VoiceRecorder {
  DeviceVoiceRecorder();

  static const _rate = 16000;
  static const _channels = 1;
  static const _bits = 16;

  /// Shorter is a slip of the finger.
  static const minLength = Duration(milliseconds: 700);

  /// A voice message lasts 2 minutes at most.
  static const maxLength = Duration(minutes: 2);

  // dBFS below this is silence for the level meter.
  static const double _floorDb = -45;

  final _recorder = AudioRecorder();
  final _bytes = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _sub;
  DateTime? _started;
  Timer? _limit;

  @override
  Stream<double> get level => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 120))
      .map((a) => a.current <= _floorDb ? 0.0 : ((a.current - _floorDb) / -_floorDb).clamp(0.0, 1.0));

  @override
  Future<void> start() async {
    if (!await _recorder.hasPermission()) throw const VoiceRecordingException(VoiceProblem.permission);
    if (!await _recorder.isEncoderSupported(AudioEncoder.pcm16bits)) throw const VoiceRecordingException(VoiceProblem.unsupported);
    _bytes.clear();
    final stream = await _recorder.startStream(
      const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: _rate, numChannels: _channels),
    );
    _sub = stream.listen(_bytes.add);
    _started = DateTime.now();
    _limit = Timer(maxLength, () => _recorder.pause());
  }

  @override
  Future<VoiceClip?> stop() async {
    _limit?.cancel();
    await _recorder.stop();
    await _sub?.cancel();
    _sub = null;
    final pcm = _bytes.takeBytes();
    final length = Duration(milliseconds: pcm.length * 1000 ~/ (_rate * _channels * _bits ~/ 8));
    _started = null;
    if (length < minLength) return null;
    return VoiceClip('data:audio/wav;base64,${base64Encode(wav(pcm))}', length);
  }

  @override
  Future<void> cancel() async {
    _limit?.cancel();
    if (_started != null) await _recorder.stop();
    await _sub?.cancel();
    _sub = null;
    _bytes.clear();
    _started = null;
  }

  void dispose() {
    _limit?.cancel();
    _sub?.cancel();
    _recorder.dispose();
  }

  /// A WAV file around 16-bit PCM.
  static Uint8List wav(Uint8List pcm, {int rate = _rate, int channels = _channels}) {
    final header = ByteData(44);
    void ascii(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    const bytesPerSample = _bits ~/ 8;
    ascii(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, rate, Endian.little);
    header.setUint32(28, rate * channels * bytesPerSample, Endian.little);
    header.setUint16(32, channels * bytesPerSample, Endian.little);
    header.setUint16(34, _bits, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    return (BytesBuilder(copy: false)
          ..add(header.buffer.asUint8List())
          ..add(pcm))
        .takeBytes();
  }
}
