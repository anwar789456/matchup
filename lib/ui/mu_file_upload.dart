import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_button.dart';
import 'mu_court_art.dart';
import 'mu_icon_button.dart';
import 'mu_text_field.dart';
import 'src/interaction.dart';
import '../l10n/l10n.dart';

enum MuUploadStatus { uploading, done, error }

/// A file in a [MuFileUpload].
@immutable
class MuUploadFile {
  const MuUploadFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    this.status = MuUploadStatus.done,
    this.progress = 0,
    this.error,
    this.shortError,
    this.bytes,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final MuUploadStatus status;

  /// 0–1 while uploading.
  final double progress;

  /// « Fichier trop lourd (max 10 Mo) ».
  final String? error;

  /// The grid tile's short form (« Fichier trop lourd »).
  final String? shortError;

  /// Image bytes for the thumbnail; CourtArt `pattern` stands in without them.
  final Uint8List? bytes;

  bool get isPdf => name.toLowerCase().endsWith('.pdf');

  MuUploadFile copyWith({MuUploadStatus? status, double? progress}) => MuUploadFile(
    id: id,
    name: name,
    sizeBytes: sizeBytes,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    error: error,
    shortError: shortError,
    bytes: bytes,
  );
}

/// « 1,8 Mo », « 410 Ko ».
String formatFileSize(int bytes) {
  // Decimal units, as file managers show them (« 14,2 Mo »).
  const kb = 1000;
  const mb = kb * 1000;
  if (bytes >= mb) {
    final v = (bytes / mb * 10).round() / 10;
    final text = v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
    return l10n.mo(text.replaceAll('.', ','));
  }
  return l10n.ko((bytes / kb).round());
}

/// FileUpload (components/FileUpload.md).
///
/// - [MuFileUpload.dropzone]: the dashed zone that opens the picker (« Glisse … ou parcours tes
///   fichiers »), with the files as rows under it.
/// - [MuFileUpload.grid]: square photo tiles with « Couverture » on the first, progress rings,
///   error tiles and the dashed « Ajouter » tile, plus the counter.
/// - [MuFileUpload.avatar]: a 96 circle with « Changer » / « Retirer » beside it.
///
/// Drag and drop from the desktop (drag-over state) comes with the web dashboards; the zone opens
/// the picker on tap.
class MuFileUpload extends StatelessWidget {
  MuFileUpload.dropzone({
    super.key,
    required this.label,
    required this.onAdd,
    String? title,
    String? linkPart,
    this.hint,
    this.files = const [],
    this.onRemove,
    this.onRetry,
    this.error,
  }) : linkPart = linkPart ?? l10n.parcoursTesFichiers, title = title ?? l10n.glisseTesPhotosIciOu, _variant = _Variant.dropzone,
       onReorder = null,
       maxFiles = null,
       helper = null,
       name = null,
       image = null;

  const MuFileUpload.grid({
    super.key,
    required this.label,
    required this.onAdd,
    required this.files,
    this.maxFiles,
    this.helper,
    this.onRemove,
    this.onRetry,
    this.onReorder,
    this.error,
  }) : _variant = _Variant.grid,
       title = '',
       linkPart = null,
       hint = null,
       name = null,
       image = null;

  const MuFileUpload.avatar({
    super.key,
    required this.label,
    required this.name,
    required this.onAdd,
    this.image,
    this.helper,
    this.onRemove,
  }) : _variant = _Variant.avatar,
       title = '',
       linkPart = null,
       hint = null,
       files = const [],
       maxFiles = null,
       onRetry = null,
       onReorder = null,
       error = null;

  final _Variant _variant;
  final String label;
  final String title;

  /// The part of [title] shown as a link.
  final String? linkPart;
  final String? hint;
  final List<MuUploadFile> files;
  final int? maxFiles;
  final String? helper;
  final String? error;
  final String? name;
  final ImageProvider? image;
  final VoidCallback? onAdd;
  final ValueChanged<MuUploadFile>? onRemove;
  final ValueChanged<MuUploadFile>? onRetry;

  /// Grid: a tile dragged onto another (or moved with the screen-reader actions) — the first one
  /// is the cover.
  final void Function(int from, int to)? onReorder;

  @override
  Widget build(BuildContext context) => switch (_variant) {
    _Variant.dropzone => _dropzone(context),
    _Variant.grid => _grid(context),
    _Variant.avatar => _avatar(context),
  };

  // FileUpload.md: zone min 176, 1,5 px dashed border, 48 icon circle; rows with a 40 type tile;
  // grid tiles min 104, 28 remove button, 56 progress ring.
  static const double _zoneMin = 176;
  static const double _dash = 1.5;
  static const double _iconCircle = 48;
  static const double _typeTile = 40;
  static const double _tileMin = 104;
  static const double _ring = 56;
  static const double _dragOpacity = 0.6;
  static const double _dropScale = 0.94;

  Widget _dropzone(BuildContext context) {
    final c = context.mu;
    final link = linkPart != null && title.contains(linkPart!) ? linkPart! : null;
    final before = link == null ? title : title.substring(0, title.indexOf(link));
    final after = link == null ? '' : title.substring(title.indexOf(link) + link.length);

    final zone = Semantics(
      button: true,
      label: '$label. $title',
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.smAll,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onAdd,
            borderRadius: MuRadius.smAll,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: error != null ? c.error : c.borderStrong,
                width: _dash,
                radius: MuRadius.sm,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _zoneMin, minWidth: double.infinity),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: _iconCircle,
                        height: _iconCircle,
                        decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
                        child: Icon(
                          PhosphorIcons.uploadSimple(),
                          size: MuSize.iconM,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: MuSpace.s3),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: before),
                            if (link != null)
                              TextSpan(
                                text: link,
                                style: TextStyle(
                                  color: c.link,
                                  decoration: TextDecoration.underline,
                                  decorationColor: c.link,
                                ),
                              ),
                            TextSpan(text: after),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: MuType.label.copyWith(color: c.text),
                      ),
                      if (hint != null)
                        Text(
                          hint!,
                          textAlign: TextAlign.center,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MuFieldLabel(label: label),
        const SizedBox(height: MuSpace.s2),
        zone,
        for (final f in files) ...[
          const SizedBox(height: MuSpace.s3),
          _FileRow(file: f, onRemove: onRemove, onRetry: onRetry),
        ],
        if (error != null) ...[const SizedBox(height: MuSpace.s1), MuFieldMessage.error(error!)],
      ],
    );
  }

  Widget _grid(BuildContext context) {
    final c = context.mu;
    final count = files.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MuFieldLabel(label: label),
        const SizedBox(height: MuSpace.s2),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = math.max(1, (constraints.maxWidth / (_tileMin + MuSpace.s2)).floor());
            final tile = (constraints.maxWidth - MuSpace.s2 * (columns - 1)) / columns;
            return Wrap(
              spacing: MuSpace.s2,
              runSpacing: MuSpace.s2,
              children: [
                for (final (i, f) in files.indexed)
                  _reorderable(
                    i,
                    tile,
                    SizedBox.square(
                      dimension: tile,
                      child: _PhotoTile(
                        file: f,
                        cover: i == 0,
                        onRemove: onRemove,
                        onRetry: onRetry,
                        onMove: onReorder == null || f.status != MuUploadStatus.done
                            ? null
                            : (to) => onReorder!(i, to),
                        index: i,
                        count: files.length,
                      ),
                    ),
                  ),
                if (maxFiles == null || files.length < maxFiles!)
                  SizedBox.square(
                    dimension: tile,
                    child: _AddTile(onTap: onAdd),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: MuSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (helper != null)
              Expanded(
                child: Text(helper!, style: MuType.caption.copyWith(color: c.textSecondary)),
              )
            else
              const Spacer(),
            if (maxFiles != null)
              Text('$count/$maxFiles', style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
        if (error != null) ...[const SizedBox(height: MuSpace.s2), MuFieldMessage.error(error!)],
      ],
    );
  }

  /// Drag a done photo onto another tile to take its place.
  Widget _reorderable(int index, double size, Widget child) {
    if (onReorder == null || files[index].status != MuUploadStatus.done) return child;
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) => onReorder!(d.data, index),
      builder: (context, candidates, _) => Draggable<int>(
        data: index,
        feedback: Opacity(
          opacity: _dragOpacity,
          child: SizedBox.square(dimension: size, child: child),
        ),
        childWhenDragging: Opacity(opacity: _dragOpacity, child: child),
        child: AnimatedScale(
          scale: candidates.isEmpty ? 1 : _dropScale,
          duration: MuMotion.durationOf(context, MuMotion.fast),
          child: child,
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    final c = context.mu;
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            MuAvatar(name: name ?? '', image: image, size: MuAvatarSize.xl),
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surface,
                  boxShadow: MuElevation.of(context).level1,
                ),
                child: MuIconButton(
                  icon: PhosphorIcons.camera(),
                  label: l10n.changerLaPhoto,
                  size: MuIconButtonSize.s,
                  onPressed: onAdd,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: MuSpace.s5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: MuType.label.copyWith(color: c.text)),
              if (helper != null)
                Text(helper!, style: MuType.caption.copyWith(color: c.textSecondary)),
              const SizedBox(height: MuSpace.s2),
              Wrap(
                spacing: MuSpace.s3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  MuButton.secondary(
                    label: image == null ? l10n.choisirUnePhoto : l10n.changer,
                    leading: PhosphorIcons.uploadSimple(),
                    size: MuButtonSize.s,
                    onPressed: onAdd,
                  ),
                  if (onRemove != null && image != null)
                    MuButton.tertiary(
                      label: l10n.retirer3,
                      size: MuButtonSize.s,
                      onPressed: () =>
                          onRemove!(const MuUploadFile(id: 'avatar', name: '', sizeBytes: 0)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Variant { dropzone, grid, avatar }

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove, required this.onRetry});

  final MuUploadFile file;
  final ValueChanged<MuUploadFile>? onRemove;
  final ValueChanged<MuUploadFile>? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final error = file.status == MuUploadStatus.error;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.smAll,
        border: Border.all(color: error ? c.error : c.border),
      ),
      child: Row(
        children: [
          Container(
            width: MuFileUpload._typeTile,
            height: MuFileUpload._typeTile,
            decoration: BoxDecoration(
              color: error ? c.errorSoft : c.surfaceMuted,
              borderRadius: MuRadius.smAll,
            ),
            child: Icon(
              error
                  ? PhosphorIcons.warningCircle(PhosphorIconsStyle.fill)
                  : (file.isPdf ? PhosphorIcons.filePdf() : PhosphorIcons.fileImage()),
              size: MuSize.iconS,
              color: error ? c.errorText : c.textSecondary,
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.label.copyWith(color: c.text),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        error ? file.error ?? '' : formatFileSize(file.sizeBytes),
                        style: MuType.caption.copyWith(
                          color: error ? c.errorText : c.textSecondary,
                        ),
                      ),
                    ),
                    if (file.status == MuUploadStatus.done) ...[
                      Icon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        size: MuSize.iconXs,
                        color: c.successText,
                      ),
                      const SizedBox(width: MuSpace.s1),
                      Text(l10n.envoye, style: MuType.caption.copyWith(color: c.successText)),
                    ],
                    if (file.status == MuUploadStatus.uploading)
                      Text(
                        '${(file.progress * 100).round()} %',
                        style: MuType.numXs.copyWith(color: c.textSecondary),
                      ),
                  ],
                ),
                if (file.status == MuUploadStatus.uploading) ...[
                  const SizedBox(height: MuSpace.s1),
                  ClipRRect(
                    borderRadius: MuRadius.fullAll,
                    child: LinearProgressIndicator(
                      value: file.progress,
                      minHeight: MuSpace.s1,
                      backgroundColor: c.border,
                      color: c.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s2),
          if (error && onRetry != null)
            MuButton.tertiary(
              label: l10n.remplacer,
              size: MuButtonSize.s,
              onPressed: () => onRetry!(file),
            )
          else if (onRemove != null)
            MuIconButton(
              icon: file.status == MuUploadStatus.uploading
                  ? PhosphorIcons.x()
                  : PhosphorIcons.trash(),
              label: file.status == MuUploadStatus.uploading
                  ? l10n.annulerLEnvoi
                  : l10n.supprimer3(file.name),
              size: MuIconButtonSize.s,
              color: c.textSecondary,
              onPressed: () => onRemove!(file),
            ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.file,
    required this.cover,
    required this.onRemove,
    required this.onRetry,
    this.onMove,
    this.index = 0,
    this.count = 1,
  });

  final MuUploadFile file;
  final bool cover;
  final ValueChanged<MuUploadFile>? onRemove;
  final ValueChanged<MuUploadFile>? onRetry;

  /// Moves this photo to another position (screen-reader actions).
  final ValueChanged<int>? onMove;
  final int index;
  final int count;

  // FileUpload.md: faded thumbnail while uploading; 3 px ring; 2 px pill padding.
  static const double _fade = 0.45;
  static const double _remove = 28;
  static const double _ringStroke = 3;
  static const double _pillPadY = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final error = file.status == MuUploadStatus.error;
    final uploading = file.status == MuUploadStatus.uploading;

    final Widget content = error
        ? Material(
            color: c.errorSoft,
            child: InkWell(
              onTap: onRetry == null ? null : () => onRetry!(file),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.imageBroken(), size: MuSize.iconS, color: c.errorText),
                    const SizedBox(height: MuSpace.s1),
                    Text(
                      file.shortError ?? l10n.erreur,
                      textAlign: TextAlign.center,
                      style: MuType.labelS.copyWith(color: c.errorText),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: uploading ? _fade : 1,
                child: file.bytes != null
                    ? Image.memory(file.bytes!, fit: BoxFit.cover)
                    : const MuCourtArt(variant: MuCourtArtVariant.pattern),
              ),
              if (uploading)
                Center(
                  child: Container(
                    width: MuFileUpload._ring,
                    height: MuFileUpload._ring,
                    decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: file.progress,
                            strokeWidth: _ringStroke,
                            color: c.primary,
                            backgroundColor: c.border,
                          ),
                        ),
                        Text(
                          '${(file.progress * 100).round()} %',
                          style: MuType.numXs.copyWith(color: c.text),
                        ),
                      ],
                    ),
                  ),
                ),
              if (cover)
                PositionedDirectional(
                  start: MuSpace.s2,
                  bottom: MuSpace.s2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MuSpace.s2,
                      vertical: _pillPadY,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceInverse,
                      borderRadius: MuRadius.fullAll,
                    ),
                    child: Text(l10n.couverture, style: MuType.labelS.copyWith(color: c.textInverse)),
                  ),
                ),
            ],
          );

    return Semantics(
      label:
          '${file.name}${cover ? l10n.couverture2 : ''}'
          '${uploading ? l10n.envoi((file.progress * 100).round()) : ''}'
          '${error ? ', ${file.error ?? 'erreur'}' : ''}',
      container: true,
      customSemanticsActions: onMove == null
          ? null
          : {
              if (index > 0) ...{
                CustomSemanticsAction(label: l10n.utiliserCommeCouverture): () => onMove!(0),
                CustomSemanticsAction(label: l10n.deplacerAvant): () => onMove!(index - 1),
              },
              if (index < count - 1)
                CustomSemanticsAction(label: l10n.deplacerApres): () => onMove!(index + 1),
            },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: MuRadius.smAll,
          border: error ? Border.all(color: c.error) : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(child: content),
            if (onRemove != null)
              PositionedDirectional(
                top: MuSpace.s1,
                end: MuSpace.s1,
                child: SizedBox.square(
                  dimension: _remove + MuSpace.s2,
                  child: MuIconButton(
                    icon: PhosphorIcons.x(),
                    label: l10n.retirer(file.name),
                    size: MuIconButtonSize.s,
                    variant: MuIconButtonVariant.onMedia,
                    onPressed: () => onRemove!(file),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: l10n.ajouterDesPhotos,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: MuRadius.smAll,
          child: CustomPaint(
            painter: _DashedBorderPainter(color: c.borderStrong, width: 1, radius: MuRadius.sm),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.plus(), size: MuSize.iconM, color: c.text),
                  const SizedBox(height: MuSpace.s1),
                  Text(l10n.ajouter, style: MuType.labelS.copyWith(color: c.text)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed rounded-rectangle outline.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.width, required this.radius});

  final Color color;
  final double width;
  final double radius;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(radius),
    );
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.width != width || old.radius != radius;
}
