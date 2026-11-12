import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';

/// The bytes of a `data:image/…;base64,…` image (how the phone keeps post images until they
/// are uploaded to the backend), or null for a URL.
Uint8List? forumImageBytes(String src) {
  if (!src.startsWith('data:')) return null;
  final comma = src.indexOf(',');
  return comma < 0 ? null : base64Decode(src.substring(comma + 1));
}

/// A post image from a `data:` URI or a URL, cropped to its box.
class ForumImage extends StatelessWidget {
  const ForumImage(this.src, {super.key, this.fit = BoxFit.cover});

  final String src;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final bytes = forumImageBytes(src);
    Widget broken(BuildContext _, Object _, StackTrace? _) => ColoredBox(color: c.surfaceMuted);
    return Semantics(
      image: true,
      label: l10n.forumImageDuPost,
      child: bytes != null ? Image.memory(bytes, fit: fit, errorBuilder: broken) : Image.network(src, fit: fit, errorBuilder: broken),
    );
  }
}

/// The post's images (1 to 4): one wide, or a 2-column grid; tap to see one full screen.
class ForumImageGrid extends StatelessWidget {
  const ForumImageGrid({super.key, required this.images});

  final List<String> images;

  // A single image is 16:9, grid cells are square.
  static const double _wide = 16 / 9;

  void _open(BuildContext context, String src) => showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: context.mu.scrim,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: InteractiveViewer(
        child: Center(child: ForumImage(src, fit: BoxFit.contain)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget tile(String src, double ratio) => AspectRatio(
      aspectRatio: ratio,
      child: ClipRRect(
        borderRadius: MuRadius.mdAll,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: () => _open(context, src), child: ForumImage(src)),
        ),
      ),
    );
    if (images.length == 1) return tile(images.single, _wide);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: MuSpace.s2,
      crossAxisSpacing: MuSpace.s2,
      children: [for (final src in images) tile(src, 1)],
    );
  }
}
