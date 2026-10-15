import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A file the person picked.
class PickedFile {
  const PickedFile({required this.name, required this.sizeBytes, this.bytes});

  final String name;
  final int sizeBytes;
  final Uint8List? bytes;
}

/// Opens the system file picker.
abstract interface class FileSource {
  /// Images (JPG, PNG); empty when cancelled.
  Future<List<PickedFile>> pickImages();

  /// One file among [extensions] (« pdf », « jpg », « png »); null when cancelled.
  Future<PickedFile?> pickOne(List<String> extensions);
}

class DeviceFileSource implements FileSource {
  const DeviceFileSource();

  static Future<PickedFile> _read(PlatformFile f) async {
    final bytes = await f.xFile.readAsBytes();
    return PickedFile(name: f.name, sizeBytes: bytes.length, bytes: bytes);
  }

  @override
  Future<List<PickedFile>> pickImages() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    return Future.wait(files.map(_read));
  }

  @override
  Future<PickedFile?> pickOne(List<String> extensions) async {
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: extensions);
    return f == null ? null : _read(f);
  }
}

/// Sends files to the backend, reporting progress from 0 to 1.
abstract interface class UploadService {
  Stream<double> upload(String name, int sizeBytes);
}

/// Simulates an upload: about a second per megabyte, at least [minimum].
class FakeUploadService implements UploadService {
  const FakeUploadService({this.minimum = const Duration(milliseconds: 1200)});

  final Duration minimum;

  static const _tick = Duration(milliseconds: 100);

  @override
  Stream<double> upload(String name, int sizeBytes) async* {
    final total = Duration(milliseconds: (sizeBytes / 1000).round());
    final duration = total > minimum ? total : minimum;
    if (duration == Duration.zero) {
      yield 1;
      return;
    }
    final steps = (duration.inMilliseconds / _tick.inMilliseconds).ceil();
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(_tick);
      yield i / steps;
    }
  }
}
