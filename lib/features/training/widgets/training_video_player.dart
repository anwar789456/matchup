import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/training_videos.dart';

/// Builds the player for a URL (tests swap it for one that never touches the platform).
final videoControllerFactoryProvider =
    Provider<VideoPlayerController Function(Uri)>(
      (ref) => VideoPlayerController.networkUrl,
    );

/// Opens the full-screen player for the video [videoKey] (see [TrainingVideoSource]),
/// from [startAt]. Exercise demos [loop].
Future<void> showTrainingVideo(
  BuildContext context, {
  required String title,
  required String videoKey,
  Duration startAt = Duration.zero,
  bool loop = false,
}) {
  final arabic = Directionality.of(context) == TextDirection.rtl;
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      // A media screen: the Night match surfaces in both themes.
      builder: (_) => Theme(
        data: MuTheme.dark(arabic: arabic),
        child: TrainingVideoPlayer(
          title: title,
          videoKey: videoKey,
          startAt: startAt,
          loop: loop,
        ),
      ),
    ),
  );
}

/// The full-screen player: close, title, the video (tap to pause), a scrubber and the time.
class TrainingVideoPlayer extends ConsumerStatefulWidget {
  const TrainingVideoPlayer({
    super.key,
    required this.title,
    required this.videoKey,
    this.startAt = Duration.zero,
    this.loop = false,
  });

  final String title;
  final String videoKey;
  final Duration startAt;
  final bool loop;

  @override
  ConsumerState<TrainingVideoPlayer> createState() =>
      _TrainingVideoPlayerState();
}

class _TrainingVideoPlayerState extends ConsumerState<TrainingVideoPlayer> {
  VideoPlayerController? _video;
  bool _failed = false;

  static const double _play = 64;
  static const double _track = 4;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final old = _video;
    setState(() {
      _video = null;
      _failed = false;
    });
    old?.dispose();
    final url = ref.read(trainingVideoSourceProvider).urlFor(widget.videoKey);
    final video = ref.read(videoControllerFactoryProvider)(url);
    try {
      await video.initialize();
      await video.setLooping(widget.loop);
      if (widget.startAt > Duration.zero &&
          widget.startAt < video.value.duration) {
        await video.seekTo(widget.startAt);
      }
      if (!mounted) {
        await video.dispose();
        return;
      }
      setState(() => _video = video..addListener(_onTick));
      await video.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTick() {
    final v = _video?.value;
    if (v != null && v.hasError && !_failed) setState(() => _failed = true);
  }

  void _toggle() {
    final v = _video;
    if (v == null) return;
    v.value.isPlaying ? v.pause() : v.play();
  }

  @override
  void dispose() {
    _video?.removeListener(_onTick);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MuSpace.s1,
                MuSpace.s1,
                MuSpace.s4,
                MuSpace.s1,
              ),
              child: Row(
                children: [
                  MuIconButton(
                    icon: PhosphorIcons.x(),
                    label: l10n.fermer,
                    size: MuIconButtonSize.l,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: MuSpace.s1),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.h3.copyWith(color: c.text),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: Center(child: _body(c))),
          ],
        ),
      ),
    );
  }

  Widget _body(MuColors c) {
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.all(MuSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.videoCamera(),
              size: MuSize.iconL,
              color: c.textSecondary,
            ),
            const SizedBox(height: MuSpace.s3),
            Text(
              l10n.entVideoError,
              textAlign: TextAlign.center,
              style: MuType.body.copyWith(color: c.text),
            ),
            const SizedBox(height: MuSpace.s4),
            MuButton.secondary(label: l10n.reessayer, onPressed: _open),
          ],
        ),
      );
    }
    final video = _video;
    if (video == null) {
      return MuSpinner(size: MuSize.iconL, semanticLabel: l10n.entVideoLoading);
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: video,
      builder: (context, v, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: v.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(onTap: _toggle, child: VideoPlayer(video)),
                if (!v.isPlaying)
                  Center(
                    child: Semantics(
                      button: true,
                      label: l10n.entVideoPlay,
                      excludeSemantics: true,
                      child: Material(
                        // A media overlay: the same white disc in both themes.
                        color: MuPalette.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _toggle,
                          child: SizedBox.square(
                            dimension: _play,
                            child: Icon(
                              PhosphorIcons.play(PhosphorIconsStyle.fill),
                              size: MuSize.iconM,
                              color: MuPalette.ink900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MuSpace.s2,
              MuSpace.s3,
              MuSpace.s4,
              0,
            ),
            // A timeline runs left to right in every language.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  MuIconButton(
                    icon: v.isPlaying
                        ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                        : PhosphorIcons.play(PhosphorIconsStyle.fill),
                    label: v.isPlaying ? l10n.pause : l10n.entVideoPlay,
                    onPressed: _toggle,
                  ),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: SizedBox(
                      height: MuSize.touchTarget,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: MuRadius.fullAll,
                          child: SizedBox(
                            height: _track,
                            child: VideoProgressIndicator(
                              video,
                              allowScrubbing: true,
                              padding: EdgeInsets.zero,
                              colors: VideoProgressColors(
                                playedColor: c.primary,
                                bufferedColor: c.borderStrong,
                                backgroundColor: c.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Text(
                    '${formatClock(v.position)} / ${formatClock(v.duration)}',
                    style: MuType.numXs.copyWith(color: c.textSecondary),
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
