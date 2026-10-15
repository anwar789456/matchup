import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../ui/ui.dart';
import 'file_services.dart';

/// Files being sent (with their progress) or refused, until [onDone] hands each finished one to
/// the draft.
class UploadQueue extends ChangeNotifier {
  UploadQueue({
    required this.service,
    required this.maxBytes,
    required this.tooBig,
    required this.onDone,
  });

  final UploadService service;
  final int maxBytes;

  /// The error for a file over [maxBytes]: (long message, short tile label).
  final (String, String) Function(PickedFile file) tooBig;
  final void Function(MuUploadFile file, PickedFile picked) onDone;

  final List<MuUploadFile> _files = [];
  final Map<String, StreamSubscription<double>> _uploads = {};
  int _seq = 0;

  List<MuUploadFile> get files => List.unmodifiable(_files);

  bool get busy => _uploads.isNotEmpty;

  /// The message of the latest refused file.
  String? get lastError => _files.where((f) => f.status == MuUploadStatus.error).lastOrNull?.error;

  void add(PickedFile picked) {
    final id = 'u${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    if (picked.sizeBytes > maxBytes) {
      final (long, short) = tooBig(picked);
      _files.add(
        MuUploadFile(
          id: id,
          name: picked.name,
          sizeBytes: picked.sizeBytes,
          status: MuUploadStatus.error,
          error: long,
          shortError: short,
        ),
      );
      notifyListeners();
      return;
    }
    var file = MuUploadFile(
      id: id,
      name: picked.name,
      sizeBytes: picked.sizeBytes,
      status: MuUploadStatus.uploading,
      bytes: picked.bytes,
    );
    _files.add(file);
    notifyListeners();
    _uploads[id] = service
        .upload(picked.name, picked.sizeBytes)
        .listen(
          (p) {
            file = file.copyWith(progress: p);
            _replace(file);
          },
          onDone: () {
            _uploads.remove(id);
            _files.removeWhere((f) => f.id == id);
            notifyListeners();
            onDone(file.copyWith(status: MuUploadStatus.done, progress: 1), picked);
          },
        );
  }

  void _replace(MuUploadFile file) {
    final i = _files.indexWhere((f) => f.id == file.id);
    if (i < 0) return;
    _files[i] = file;
    notifyListeners();
  }

  /// Cancels an upload or drops a refused file.
  void remove(String id) {
    _uploads.remove(id)?.cancel();
    _files.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _uploads.values) {
      s.cancel();
    }
    super.dispose();
  }
}
