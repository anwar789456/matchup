import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import 'media/media_source.dart';

/// The bytes of a `data:…;base64,…` source (how the phone keeps post media until they are
/// uploaded to Supabase Storage), or null for a URL.
Uint8List? forumImageBytes(String src) {
  if (!src.startsWith('data:')) return null;
  final comma = src.indexOf(',');
  return comma < 0 ? null : base64Decode(src.substring(comma + 1));
}

/// A video (`data:video/…` or a .mp4 / .mov / .webm URL); everything else is an image.
bool isVideoSource(String src) => src.startsWith('data:video/') || RegExp(r'\.(mp4|mov|webm)(\?|$)', caseSensitive: false).hasMatch(src);

/// « 0:42 ».
String mediaClock(Duration d) => formatClock(d);

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
      child: bytes != null
          ? Image.memory(bytes, fit: fit, gaplessPlayback: true, errorBuilder: broken)
          : Image.network(src, fit: fit, errorBuilder: broken),
    );
  }
}

/// One tile of a collage: the image, or the video's first frame with a play disc and its
/// length.
class ForumMediaTile extends StatelessWidget {
  const ForumMediaTile(this.src, {super.key});

  final String src;

  @override
  Widget build(BuildContext context) => isVideoSource(src) ? _VideoThumb(src) : ForumImage(src);
}

class _VideoThumb extends StatefulWidget {
  const _VideoThumb(this.src);

  final String src;

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  late final VideoPlayerController _video = mediaController(widget.src);
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _video.setVolume(0);
    _video.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      label: l10n.mediaVideo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.surfaceInverse),
          if (_ready)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: _video.value.size.width, height: _video.value.size.height, child: VideoPlayer(_video)),
            ),
          Center(child: _PlayDisc(icon: PhosphorIcons.play(PhosphorIconsStyle.fill))),
          if (_ready)
            PositionedDirectional(
              end: MuSpace.s2,
              bottom: MuSpace.s2,
              child: _Pill(text: mediaClock(_video.value.duration)),
            ),
        ],
      ),
    );
  }
}

class _PlayDisc extends StatelessWidget {
  const _PlayDisc({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      width: MuSize.controlL,
      height: MuSize.controlL,
      decoration: BoxDecoration(color: c.scrim, shape: BoxShape.circle),
      child: Icon(icon, size: MuSize.iconM, color: c.textInverse),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
      decoration: BoxDecoration(color: c.scrim, borderRadius: MuRadius.fullAll),
      child: Text(text, style: MuType.numXs.copyWith(color: c.textInverse)),
    );
  }
}

/// A post's photos and videos the way a social feed shows them: one large, two side by side,
/// three as one tall and two stacked, four and more as a grid with « +N » on the last tile.
/// A tap opens them full screen (videos play there).
class ForumMediaCollage extends StatelessWidget {
  const ForumMediaCollage({super.key, required this.media, this.radius = MuRadius.mdAll});

  final List<String> media;
  final BorderRadius radius;

  // A single photo is 4:3, the collages are 1:1 tiles side by side.
  static const double _single = 4 / 3;
  static const double _pair = 2;
  static const double _three = 4 / 3;
  static const int _shown = 4;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    Widget tile(int i, {int more = 0}) => _CollageTile(
      src: media[i],
      more: more,
      label: l10n.mediaOuvrirNSurM(i + 1, media.length),
      onTap: () => ForumMediaViewer.open(context, media, i),
    );
    const gap = SizedBox(width: MuSpace.s1, height: MuSpace.s1);
    final Widget layout = switch (media.length) {
      1 => AspectRatio(aspectRatio: _single, child: tile(0)),
      2 => AspectRatio(
        aspectRatio: _pair,
        child: Row(children: [Expanded(child: tile(0)), gap, Expanded(child: tile(1))]),
      ),
      3 => AspectRatio(
        aspectRatio: _three,
        child: Row(
          children: [
            Expanded(flex: 2, child: tile(0)),
            gap,
            Expanded(child: Column(children: [Expanded(child: tile(1)), gap, Expanded(child: tile(2))])),
          ],
        ),
      ),
      _ => AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: [
            Expanded(child: Row(children: [Expanded(child: tile(0)), gap, Expanded(child: tile(1))])),
            gap,
            Expanded(
              child: Row(
                children: [
                  Expanded(child: tile(2)),
                  gap,
                  Expanded(child: tile(3, more: media.length - _shown)),
                ],
              ),
            ),
          ],
        ),
      ),
    };
    return ClipRRect(borderRadius: radius, child: layout);
  }
}

class _CollageTile extends StatelessWidget {
  const _CollageTile({required this.src, required this.more, required this.label, required this.onTap});

  final String src;
  final int more;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: label,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ForumMediaTile(src),
          if (more > 0)
            ColoredBox(
              color: c.scrim,
              child: Center(child: Text('+$more', style: MuType.numL.copyWith(color: c.textInverse))),
            ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: onTap),
          ),
        ],
      ),
    );
  }
}

/// Full screen: swipe between the photos and videos, pinch a photo, the video plays with its
/// controls; « 2 / 5 » and « Fermer » on top.
class ForumMediaViewer extends StatefulWidget {
  const ForumMediaViewer({super.key, required this.media, required this.initial});

  final List<String> media;
  final int initial;

  static Future<void> open(BuildContext context, List<String> media, int index) => showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: context.mu.surfaceInverse,
    builder: (_) => ForumMediaViewer(media: media, initial: index),
  );

  @override
  State<ForumMediaViewer> createState() => _ForumMediaViewerState();
}

class _ForumMediaViewerState extends State<ForumMediaViewer> {
  late final PageController _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Dialog.fullscreen(
      backgroundColor: c.surfaceInverse,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: widget.media.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final src = widget.media[i];
                return isVideoSource(src)
                    ? Center(child: ForumVideoPlayer(src: src, autoplay: i == _index))
                    : InteractiveViewer(child: Center(child: ForumImage(src, fit: BoxFit.contain)));
              },
            ),
            PositionedDirectional(
              top: MuSpace.s2,
              start: MuSpace.s2,
              child: MuIconButton(
                icon: PhosphorIcons.x(),
                label: l10n.fermer,
                variant: MuIconButtonVariant.onMedia,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (widget.media.length > 1)
              PositionedDirectional(
                top: MuSpace.s4,
                end: MuSpace.s4,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: _Pill(text: '${_index + 1} / ${widget.media.length}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A video with its controls: a tap plays or pauses, the bar shows and moves the position,
/// the time and the sound.
class ForumVideoPlayer extends StatefulWidget {
  const ForumVideoPlayer({super.key, required this.src, this.autoplay = false});

  final String src;
  final bool autoplay;

  @override
  State<ForumVideoPlayer> createState() => _ForumVideoPlayerState();
}

class _ForumVideoPlayerState extends State<ForumVideoPlayer> {
  late final VideoPlayerController _video = mediaController(widget.src);
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _video.addListener(_tick);
    _video.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      if (widget.autoplay) _video.play();
    }, onError: (_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ForumVideoPlayer old) {
    super.didUpdateWidget(old);
    // Swiped away in the viewer: stop.
    if (old.autoplay && !widget.autoplay && _video.value.isPlaying) _video.pause();
  }

  @override
  void dispose() {
    _video.removeListener(_tick);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    if (_failed) return Text(l10n.mediaVideoIllisible, style: MuType.body.copyWith(color: c.textInverse));
    if (!_ready) return const MuSpinner();
    final v = _video.value;
    final playing = v.isPlaying;
    return AspectRatio(
      aspectRatio: v.aspectRatio,
      child: Stack(
        children: [
          Positioned.fill(child: VideoPlayer(_video)),
          Positioned.fill(
            child: Semantics(
              button: true,
              label: playing ? l10n.mediaPause : l10n.mediaLire,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => playing ? _video.pause() : _video.play(),
                child: AnimatedOpacity(
                  opacity: playing ? 0 : 1,
                  duration: MuMotion.durationOf(context, MuMotion.fast),
                  child: Center(child: _PlayDisc(icon: PhosphorIcons.play(PhosphorIconsStyle.fill))),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Container(
              color: c.scrim,
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
              child: Row(
                children: [
                  MuIconButton(
                    icon: playing ? PhosphorIcons.pause(PhosphorIconsStyle.fill) : PhosphorIcons.play(PhosphorIconsStyle.fill),
                    label: playing ? l10n.mediaPause : l10n.mediaLire,
                    variant: MuIconButtonVariant.onMedia,
                    size: MuIconButtonSize.s,
                    onPressed: () => playing ? _video.pause() : _video.play(),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: VideoProgressIndicator(
                      _video,
                      allowScrubbing: true,
                      colors: VideoProgressColors(playedColor: c.accent, bufferedColor: c.textSecondary, backgroundColor: c.border),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${mediaClock(v.position)} / ${mediaClock(v.duration)}',
                      style: MuType.numXs.copyWith(color: c.textInverse),
                    ),
                  ),
                  MuIconButton(
                    icon: v.volume == 0 ? PhosphorIcons.speakerSlash() : PhosphorIcons.speakerHigh(),
                    label: v.volume == 0 ? l10n.mediaActiverLeSon : l10n.mediaCouperLeSon,
                    variant: MuIconButtonVariant.onMedia,
                    size: MuIconButtonSize.s,
                    onPressed: () => _video.setVolume(v.volume == 0 ? 1 : 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A voice message: play / pause, a bar of the message's length that fills while it plays,
/// and the time (the elapsed time while playing).
class ForumVoicePlayer extends StatefulWidget {
  const ForumVoicePlayer({super.key, required this.src, required this.duration, required this.foreground});

  final String src;

  /// Known when recorded, so it shows before loading.
  final Duration duration;
  final Color foreground;

  @override
  State<ForumVoicePlayer> createState() => _ForumVoicePlayerState();
}

class _ForumVoicePlayerState extends State<ForumVoicePlayer> {
  VideoPlayerController? _audio;
  bool _loading = true;
  bool _failed = false;

  // A voice bubble's bar is 140 wide, 4 high.
  static const double _bar = 140;
  static const double _barHeight = 4;

  // The player's element stays in the page (a browser may keep a detached one silent), 1 px
  // and invisible.
  static const double _host = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loaded as soon as the bubble shows: the tap then starts the sound at once, inside the
  /// gesture (a browser blocks sound started later).
  Future<void> _load() async {
    final a = mediaController(widget.src);
    try {
      await a.initialize();
      await a.setVolume(1);
    } catch (_) {
      await a.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) {
      await a.dispose();
      return;
    }
    a.addListener(_tick);
    setState(() {
      _audio = a;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _audio?.removeListener(_tick);
    _audio?.dispose();
    super.dispose();
  }

  void _tick() {
    final a = _audio;
    if (a == null || !mounted) return;
    // Back to the start at the end, ready to play again.
    if (a.value.isCompleted) {
      a.pause();
      a.seekTo(Duration.zero);
    }
    setState(() {});
  }

  void _toggle() {
    final a = _audio;
    if (a == null) return;
    if (a.value.isPlaying) {
      a.pause();
    } else {
      // No await before play(): it must run inside the tap.
      a.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.foreground;
    final a = _audio?.value;
    final playing = a?.isPlaying ?? false;
    final total = (a?.duration ?? Duration.zero) > Duration.zero ? a!.duration : widget.duration;
    final position = a?.position ?? Duration.zero;
    final share = total.inMilliseconds == 0 ? 0.0 : math.min(1.0, position.inMilliseconds / total.inMilliseconds);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_audio case final a?) SizedBox(width: _host, height: _host, child: Opacity(opacity: 0, child: VideoPlayer(a))),
        _loading
            ? const SizedBox(width: MuSize.touchTarget, height: MuSize.touchTarget, child: Center(child: MuSpinner()))
            : MuIconButton(
                icon: _failed
                    ? PhosphorIcons.warningCircle()
                    : (playing ? PhosphorIcons.pause(PhosphorIconsStyle.fill) : PhosphorIcons.play(PhosphorIconsStyle.fill)),
                label: _failed ? l10n.msgVocalIllisible : (playing ? l10n.mediaPause : l10n.mediaEcouterLeVocal),
                color: fg,
                onPressed: _failed ? null : _toggle,
              ),
        SizedBox(
          width: _bar,
          child: ClipRRect(
            borderRadius: MuRadius.fullAll,
            child: Stack(
              children: [
                Container(height: _barHeight, color: fg.withValues(alpha: MuOpacity.disabled)),
                FractionallySizedBox(widthFactor: share, child: Container(height: _barHeight, color: fg)),
              ],
            ),
          ),
        ),
        const SizedBox(width: MuSpace.s2),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(mediaClock(playing || position > Duration.zero ? position : total), style: MuType.numXs.copyWith(color: fg)),
        ),
      ],
    );
  }
}

