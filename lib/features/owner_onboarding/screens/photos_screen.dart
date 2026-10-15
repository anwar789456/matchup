import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../../common/data/upload_queue.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/owner_controller.dart';
import '../data/owner_draft.dart';
import '../widgets/owner_wizard.dart';

/// OWN-06 — the venue photos: the drop zone, then the grid (cover first, progress rings, refused
/// files), reordered by dragging.
class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});

  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  // OWN-06: JPG, PNG · 10 Mo max · up to 20 photos.
  static const _maxPhotos = 20;
  static const _maxBytes = 10 * 1000 * 1000;

  late final UploadQueue _queue = UploadQueue(
    service: ref.read(uploadServiceProvider),
    maxBytes: _maxBytes,
    tooBig: (f) => (
      '${f.name} pèse ${formatFileSize(f.sizeBytes)} (max 10 Mo). Réduis sa taille ou choisis '
          'une autre photo.',
      'Fichier trop lourd',
    ),
    onDone: (file, picked) {
      if (picked.bytes != null) ref.read(uploadedBytesProvider)[file.id] = picked.bytes!;
      _owner.edit(
        (d) => d.copyWith(
          photos: [
            ...d.photos,
            DraftFile(id: file.id, name: file.name, sizeBytes: file.sizeBytes),
          ],
        ),
      );
    },
  )..addListener(_changed);

  String? _error;

  OwnerController get _owner => ref.read(ownerProvider.notifier);

  void _changed() => setState(() {});

  @override
  void dispose() {
    _queue
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await ref.read(fileSourceProvider).pickImages();
    if (!mounted || picked.isEmpty) return;
    final room =
        _maxPhotos -
        ref.read(ownerProvider).requireValue.photos.length -
        _queue.files.where((f) => f.status == MuUploadStatus.uploading).length;
    setState(() => _error = null);
    for (final f in picked.take(room.clamp(0, picked.length))) {
      _queue.add(f);
    }
    if (picked.length > room) {
      MuToast.show(
        context,
        tone: MuToastTone.warning,
        title: '$_maxPhotos photos maximum : les suivantes sont ignorées.',
      );
    }
  }

  void _remove(MuUploadFile f) {
    if (f.status == MuUploadStatus.done) {
      _owner.edit((d) => d.copyWith(photos: d.photos.where((p) => p.id != f.id).toList()));
    } else {
      _queue.remove(f.id);
    }
  }

  void _reorder(int from, int to) {
    _owner.edit((d) {
      final photos = [...d.photos];
      if (from >= photos.length || to >= photos.length) return d;
      photos.insert(to, photos.removeAt(from));
      return d.copyWith(photos: photos);
    });
  }

  bool _validate() {
    final photos = ref.read(ownerProvider).requireValue.photos;
    setState(() {
      _error = _queue.busy
          ? 'Attends la fin de l’envoi de tes photos.'
          : (photos.isEmpty ? 'Ajoute au moins une photo de ton terrain.' : null);
    });
    return _error == null;
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(ownerProvider.select((v) => v.requireValue.photos));
    final bytes = ref.read(uploadedBytesProvider);
    final files = [
      for (final p in photos)
        MuUploadFile(id: p.id, name: p.name, sizeBytes: p.sizeBytes, bytes: bytes[p.id]),
      ..._queue.files,
    ];

    return OwnerWizard(
      step: 5,
      title: 'Montre ton terrain',
      lead: 'Montre l’éclairage, les vestiaires et le parking : les joueurs réservent plus vite.',
      validate: _validate,
      body: ProFormCard(
        divided: false,
        children: [
          ProFormSection(
            children: [
              MuFileUpload.dropzone(
                label: 'Ajoute tes photos',
                hint: 'JPG, PNG · 10 Mo max · jusqu’à 20 photos',
                onAdd: files.length >= _maxPhotos ? null : _pick,
              ),
              if (files.isNotEmpty)
                MuFileUpload.grid(
                  label: 'Tes photos',
                  files: files,
                  maxFiles: _maxPhotos,
                  helper: 'La 1re photo sert de couverture. Glisse une photo pour changer l’ordre.',
                  error: _error ?? _queue.lastError,
                  onAdd: _pick,
                  onRemove: _remove,
                  onRetry: (f) {
                    _queue.remove(f.id);
                    _pick();
                  },
                  onReorder: _reorder,
                )
              else if (_error != null)
                MuFieldMessage.error(_error!),
            ],
          ),
        ],
      ),
    );
  }
}
