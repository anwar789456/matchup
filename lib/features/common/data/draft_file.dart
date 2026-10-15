import 'package:flutter/foundation.dart';

/// A file already sent (photo, RIB certificate, diploma, logo).
@immutable
class DraftFile {
  const DraftFile({required this.id, required this.name, required this.sizeBytes});

  final String id;
  final String name;
  final int sizeBytes;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'size': sizeBytes};

  factory DraftFile.fromJson(Map<String, Object?> j) =>
      DraftFile(id: j['id']! as String, name: j['name']! as String, sizeBytes: j['size']! as int);
}
