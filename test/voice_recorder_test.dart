import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/features/forum/data/voice_recorder.dart';

/// Voice messages: 16-bit PCM wrapped as a valid WAV, and silence detected.
void main() {
  Uint8List tone({double amplitude = 0.5, int ms = 1000}) {
    final n = 16 * ms;
    final b = ByteData(n * 2);
    for (var i = 0; i < n; i++) {
      b.setInt16(i * 2, (math.sin(2 * math.pi * 440 * i / 16000) * 32767 * amplitude).round(), Endian.little);
    }
    return b.buffer.asUint8List();
  }

  test('a WAV header around the PCM: RIFF, PCM 16 kHz mono 16-bit, the data length', () {
    final pcm = tone();
    final wav = DeviceVoiceRecorder.wav(pcm);
    final h = ByteData.sublistView(wav);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(h.getUint16(20, Endian.little), 1);
    expect(h.getUint16(22, Endian.little), 1);
    expect(h.getUint32(24, Endian.little), 16000);
    expect(h.getUint16(34, Endian.little), 16);
    expect(h.getUint32(40, Endian.little), pcm.length);
    expect(wav.length, 44 + pcm.length);
    final out = Platform.environment['MATCHUP_WAV_OUT'];
    if (out != null) File(out).writeAsBytesSync(wav);
  });

  test('silence is told apart from a voice', () {
    expect(DeviceVoiceRecorder.peak(Uint8List(32000)), 0);
    expect(DeviceVoiceRecorder.peak(tone(amplitude: 0.002)), lessThan(DeviceVoiceRecorder.silencePeak));
    expect(DeviceVoiceRecorder.peak(tone()), greaterThan(16000));
  });
}
