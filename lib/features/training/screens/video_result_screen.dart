import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/video_analysis_controller.dart';
import '../data/training_models.dart';
import '../data/training_story.dart';
import '../training_routes.dart';
import '../widgets/training_video_player.dart';
import '../widgets/plan_labels.dart';

/// ENT-09 · Analyse vidéo · résultats: the clip with its three moments, what the AI saw (to
/// regenerate, edit, copy, rate), the tips by priority with their exercise, and the next steps.
class VideoResultScreen extends ConsumerStatefulWidget {
  const VideoResultScreen({super.key});

  @override
  ConsumerState<VideoResultScreen> createState() => _VideoResultScreenState();
}

class _VideoResultScreenState extends ConsumerState<VideoResultScreen> {
  /// The tip « En lecture » (its priority).
  int _playing = 1;
  bool _regenerating = false;
  bool _edited = false;
  bool _sending = false;

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);
    // The fake AI writes the same reading again (phase 18 brings the real one).
    await Future<void>.delayed(MuMotion.shimmer);
    if (mounted) setState(() => _regenerating = false);
  }

  Future<void> _askCoach() async {
    setState(() => _sending = true);
    await ref.read(videoAnalysisProvider.notifier).shareWithCoach();
    if (!mounted) return;
    setState(() => _sending = false);
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.entSentToCoach(TrainingStory.karim.name),
      description: l10n.entSentToCoachText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = ref.watch(videoAnalysisProvider);
    final r = s.result;
    void back() => context.canPop() ? context.pop() : context.go(TrainingRoutes.video);

    if (r == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            MuTopAppBar.compact(title: l10n.entAnalyseVideoTitle, onBack: back),
            Expanded(
              child: Center(
                child: MuEmptyState(
                  title: l10n.entNoAnalysisTitle,
                  description: l10n.entNoAnalysisText,
                  illustration: MuEmptyIllustration.results,
                  actions: [
                    MuButton.primary(
                      label: l10n.entAnalyseVideo,
                      onPressed: () => context.go(TrainingRoutes.video),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final tips = [...r.tips]..sort((a, b) => a.priority.compareTo(b.priority));
    final playing = tips.firstWhere((t) => t.priority == _playing, orElse: () => tips.first);
    final your = videoMoveYour(r.move);
    final coachName = TrainingStory.karim.name;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.entAnalyseVideoTitle,
            onBack: back,
            actions: [
              MuBarAction(
                icon: PhosphorIcons.shareNetwork(),
                label: l10n.entShareAnalysis,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: l10n.entShareAnalysisText(your, tips.first.title)),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(
                          your[0].toUpperCase() + your.substring(1),
                          style: MuType.h1.copyWith(color: c.text),
                        ),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s2),
                    MuAiLabel(),
                  ],
                ),
                const SizedBox(height: MuSpace.s1),
                Text(
                  l10n.entMomentsLine(tips.length, formatDay(r.filmedAt), formatClock(r.duration)),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s4),
                _Player(
                  analysis: r,
                  tips: tips,
                  playing: playing,
                  onMoment: (t) => setState(() => _playing = t.priority),
                ),
                const SizedBox(height: MuSpace.s2),
                Row(
                  children: [
                    Icon(PhosphorIcons.handPointing(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.entTapMoment,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuAiTextBlock(
                  title: l10n.entWhatAiSaw,
                  meta: l10n.entAnalysedAt(formatTime(r.analysedAt), l10n.entConfidenceMedium),
                  text: r.summary,
                  edited: _edited,
                  regenerating: _regenerating,
                  regeneratingLabel: l10n.entAiRereading,
                  onRegenerate: _regenerate,
                  onChanged: (text) {
                    ref.read(videoAnalysisProvider.notifier).editSummary(text);
                    setState(() => _edited = true);
                  },
                  onFeedback: (_) {},
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.entTipsByPriority(tips.length),
                    style: MuType.h2.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: MuSpace.s3),
                for (final t in tips) ...[
                  _TipCard(
                    tip: t,
                    playing: t.priority == playing.priority,
                    onPlay: () => setState(() => _playing = t.priority),
                    onLink: t.programId == null
                        ? null
                        : () => context.push(TrainingRoutes.program(t.programId!)),
                  ),
                  const SizedBox(height: MuSpace.s3),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        r.confidenceNote,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          StickyActionBar(
            children: [
              MuButton.primary(
                label: l10n.entAddExercisesToPlan,
                leading: PhosphorIcons.calendarPlus(),
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: () => context.push(TrainingRoutes.plan),
              ),
              MuButton.tertiary(
                label: r.sharedWithCoach
                    ? l10n.entSentToCoach(coachName)
                    : l10n.entAskCoach(coachName),
                leading: r.sharedWithCoach
                    ? PhosphorIcons.check(PhosphorIconsStyle.bold)
                    : PhosphorIcons.paperPlaneRight(),
                size: MuButtonSize.l,
                fullWidth: true,
                loading: _sending,
                onPressed: r.sharedWithCoach || _sending ? null : _askCoach,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The analysed clip: « IA · 3 moments », play, « 0:21 / 0:42 », and the timeline with the three
/// numbered moments (the one playing in Volt).
class _Player extends StatelessWidget {
  const _Player({
    required this.analysis,
    required this.tips,
    required this.playing,
    required this.onMoment,
  });

  final VideoAnalysis analysis;
  final List<AnalysisTip> tips;
  final AnalysisTip playing;
  final ValueChanged<AnalysisTip> onMoment;

  // ENT-09: player 16:10; play disc 56; markers 24 (the one playing 28); track 4.
  static const double _play = 56;
  static const double _marker = 24;
  static const double _markerPlaying = 28;
  static const double _track = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final total = analysis.duration.inMilliseconds;
    double at(AnalysisTip t) => total == 0 ? 0 : t.at.inMilliseconds / total;
    return ClipRRect(
      borderRadius: MuRadius.mdAll,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MuCourtArt(
              sport: MuSport.padel,
              semanticLabel: l10n.entClipAt(formatClock(playing.at)),
            ),
            PositionedDirectional(
              start: MuSpace.s3,
              top: MuSpace.s3,
              child: MuAiLabel(
                variant: MuAiLabelVariant.media,
                size: MuAiLabelSize.s,
                text: l10n.entAiMoments(tips.length),
              ),
            ),
            Center(
              child: Semantics(
                button: true,
                label: l10n.entPlayFrom(formatClock(playing.at)),
                excludeSemantics: true,
                child: Material(
                  // A media overlay: the same white disc in both themes.
                  color: MuPalette.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => showTrainingVideo(
                      context,
                      title: playing.title,
                      videoKey: 'analysis/${analysis.id}',
                      // The moves analysed are padel strokes (ENT-08).
                      sport: MuSport.padel,
                      startAt: playing.at,
                    ),
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
            PositionedDirectional(
              end: MuSpace.s3,
              bottom: MuSpace.s10 + MuSpace.s1,
              child: Text(
                ltr('${formatClock(playing.at)} / ${formatClock(analysis.duration)}'),
                style: MuType.numXs.copyWith(color: MuPalette.white),
              ),
            ),
            Positioned(
              left: MuSpace.s3,
              right: MuSpace.s3,
              bottom: MuSpace.s3,
              height: _markerPlaying,
              child: Semantics(
                slider: true,
                label: l10n.entPlayback,
                value: l10n.entPlaybackValue(formatClock(playing.at), formatClock(analysis.duration)),
                child: Directionality(
                  // A timeline runs left to right in every language.
                  textDirection: TextDirection.ltr,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final w = box.maxWidth;
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: _track,
                            decoration: BoxDecoration(
                              color: MuPalette.white.withValues(alpha: MuOpacity.disabled),
                              borderRadius: MuRadius.fullAll,
                            ),
                          ),
                          Container(
                            width: w * at(playing),
                            height: _track,
                            decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.fullAll),
                          ),
                          for (final t in tips)
                            Positioned(
                              left: (w * at(t) - (t == playing ? _markerPlaying : _marker) / 2)
                                  .clamp(0, w - _marker),
                              child: Semantics(
                                button: true,
                                label: l10n.entTipAt(t.priority, formatClock(t.at)),
                                excludeSemantics: true,
                                child: GestureDetector(
                                  onTap: () => onMoment(t),
                                  child: Container(
                                    width: t == playing ? _markerPlaying : _marker,
                                    height: t == playing ? _markerPlaying : _marker,
                                    decoration: BoxDecoration(
                                      color: t == playing ? c.accent : MuPalette.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: MuPalette.ink900, width: _track / 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${t.priority}',
                                      style: MuType.numXs.copyWith(
                                        color: t == playing ? c.onAccent : MuPalette.ink900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tip: its number and moment (« ▶ 0:21 »), « En lecture », what to change, and the exercise
/// (or next session) that works on it.
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.tip,
    required this.playing,
    required this.onPlay,
    required this.onLink,
  });

  final AnalysisTip tip;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback? onLink;

  static const double _index = 22;
  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final t = tip;
    final card = MuCardSurface(
      semanticLabel: playing ? l10n.entPlayingNow : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: l10n.entReplayAt(formatClock(t.at)),
                excludeSemantics: true,
                child: Material(
                  color: c.surfaceMuted,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: onPlay,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: MuSize.controlS),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          MuSpace.s1,
                          MuSpace.s1,
                          MuSpace.s3,
                          MuSpace.s1,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: _index,
                              height: _index,
                              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(
                                '${t.priority}',
                                style: MuType.numXs.copyWith(color: c.onPrimary),
                              ),
                            ),
                            const SizedBox(width: MuSpace.s2),
                            Icon(
                              PhosphorIcons.play(PhosphorIconsStyle.fill),
                              size: MuSize.iconXs,
                              color: c.text,
                            ),
                            const SizedBox(width: MuSpace.s1),
                            Text(formatClock(t.at), style: MuType.numS.copyWith(color: c.text)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (playing)
                Text(l10n.entPlayingNow, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Text(t.title, style: MuType.labelL.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s2),
          Text(t.text, style: MuType.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s3),
          Material(
            color: c.surfaceMuted,
            borderRadius: MuRadius.smAll,
            child: InkWell(
              borderRadius: MuRadius.smAll,
              onTap: onLink,
              child: Padding(
                padding: const EdgeInsets.all(MuSpace.s3),
                child: Row(
                  children: [
                    Icon(
                      t.linkKind == TipLinkKind.exercise
                          ? PhosphorIcons.barbell()
                          : PhosphorIcons.calendarCheck(),
                      size: MuSize.iconXs,
                      color: c.text,
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.linkKind == TipLinkKind.exercise
                                ? l10n.entSuggestedExercise
                                : l10n.entYourNextSession,
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                          Text(t.link, style: MuType.label.copyWith(color: c.text)),
                        ],
                      ),
                    ),
                    if (onLink != null)
                      MuDirectionalIcon(
                        PhosphorIcons.caretRight(),
                        size: MuSize.iconXs,
                        color: c.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (!playing) return card;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.primary, width: _ring),
      ),
      child: card,
    );
  }
}
