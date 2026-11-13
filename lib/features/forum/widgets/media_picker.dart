import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/file_services.dart';
import 'forum_image.dart';

/// Photos above this size are refused (« 10 Mo max »).
const maxPhotoBytes = 10 * 1024 * 1024;

/// Videos stay on the phone until Supabase Storage: short clips only (« 25 Mo max »).
const maxVideoBytes = 25 * 1024 * 1024;

const _videoTypes = {'mp4': 'video/mp4', 'mov': 'video/quicktime', 'webm': 'video/webm'};

/// Picks up to [room] photos as `data:` sources; too heavy ones are refused with a toast.
Future<List<String>> pickPhotos(BuildContext context, FileSource files, {required int room}) async {
  if (room <= 0) return const [];
  final picked = await files.pickImages();
  if (!context.mounted) return const [];
  final out = <String>[];
  for (final f in picked.take(room)) {
    if (f.bytes == null) continue;
    if (f.sizeBytes > maxPhotoBytes) {
      MuToast.show(context, tone: MuToastTone.error, title: l10n.forumImageTropLourde(f.name));
      continue;
    }
    final type = f.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    out.add('data:image/$type;base64,${base64Encode(f.bytes!)}');
  }
  if (picked.length > room) MuToast.show(context, tone: MuToastTone.warning, title: l10n.mediaNMax(room));
  return out;
}

/// Picks one video (MP4, MOV, WebM) as a `data:` source, or null.
Future<String?> pickVideo(BuildContext context, FileSource files) async {
  final f = await files.pickOne(_videoTypes.keys.toList());
  if (f == null || f.bytes == null || !context.mounted) return null;
  if (f.sizeBytes > maxVideoBytes) {
    MuToast.show(context, tone: MuToastTone.error, title: l10n.mediaVideoTropLourde(f.name));
    return null;
  }
  final ext = f.name.split('.').last.toLowerCase();
  return 'data:${_videoTypes[ext] ?? 'video/mp4'};base64,${base64Encode(f.bytes!)}';
}

/// FRM-02 « Photos et vidéo »: the chosen media as square tiles with « Retirer », then
/// « Photos » and « Vidéo ».
class MediaPickerField extends StatelessWidget {
  const MediaPickerField({
    super.key,
    required this.label,
    required this.media,
    required this.max,
    required this.onAddPhotos,
    required this.onAddVideo,
    required this.onRemove,
    this.helper,
    this.optional = true,
  });

  final String label;
  final String? helper;
  final bool optional;
  final List<String> media;
  final int max;
  final VoidCallback onAddPhotos;
  final VoidCallback onAddVideo;
  final ValueChanged<int> onRemove;

  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final full = media.length >= max;
    final hasVideo = media.any(isVideoSource);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuFieldLabel(label: label, optional: optional),
        if (helper != null) ...[
          const SizedBox(height: MuSpace.s1),
          Text(helper!, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
        const SizedBox(height: MuSpace.s2),
        if (media.isNotEmpty) ...[
          GridView.count(
            crossAxisCount: _columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: MuSpace.s2,
            crossAxisSpacing: MuSpace.s2,
            children: [
              for (final (i, src) in media.indexed)
                ClipRRect(
                  borderRadius: MuRadius.mdAll,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ForumMediaTile(src),
                      PositionedDirectional(
                        top: 0,
                        end: 0,
                        child: MuIconButton(
                          icon: PhosphorIcons.x(),
                          label: l10n.mediaRetirerN(i + 1),
                          variant: MuIconButtonVariant.onMedia,
                          size: MuIconButtonSize.s,
                          onPressed: () => onRemove(i),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
        ],
        Row(
          children: [
            Expanded(
              child: MuButton.secondary(
                label: l10n.mediaPhotos,
                leading: PhosphorIcons.image(),
                onPressed: full ? null : onAddPhotos,
              ),
            ),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: MuButton.secondary(
                label: l10n.mediaVideo,
                leading: PhosphorIcons.videoCamera(),
                onPressed: full || hasVideo ? null : onAddVideo,
              ),
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s1),
        Text(l10n.mediaNSurM(media.length, max), style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }
}
