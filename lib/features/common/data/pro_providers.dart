import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'draft_store.dart';
import 'file_services.dart';

// Backends shared by the pro onboardings. Swap the fakes for the API implementations here.
final draftStoreProvider = Provider<DraftStore>((ref) => const LocalDraftStore());
final fileSourceProvider = Provider<FileSource>((ref) => const DeviceFileSource());
final uploadServiceProvider = Provider<UploadService>((ref) => const FakeUploadService());

/// The clock (tests pin it).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Bytes of the images sent during this session, by file id, for their thumbnails (the backend
/// keeps the files; a reload shows placeholders until the API serves them).
final uploadedBytesProvider = Provider<Map<String, Uint8List>>((ref) => {});
