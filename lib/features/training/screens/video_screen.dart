import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/video_analysis_controller.dart';
import '../data/training_models.dart';
import '../data/training_story.dart';
import '../data/video_analyst.dart';
import '../training_routes.dart';
import '../widgets/plan_labels.dart';

/// ENT-08 · Analyse vidéo: the move, the clip (sent with progress), the AI's steps, sharing
/// with the coach — the player can leave (« Me prévenir ») and come back to the result.
class VideoScreen extends ConsumerWidget {
  const VideoScreen({super.key});

  static const double _thumbW = 96;
  static const double _thumbH = 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final s = ref.watch(videoAnalysisProvider);
    final ctl = ref.read(videoAnalysisProvider.notifier);
    const coach = TrainingStory.karim;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    void back() => context.canPop() ? context.pop() : context.go(TrainingRoutes.root);

    return FlowScaffold(
      onBack: back,
      topAction: Padding(
        padding: const EdgeInsetsDirectional.only(end: MuSpace.s2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
          decoration: ShapeDecoration(color: c.infoSoft, shape: const StadiumBorder()),
          child: Text(l10n.entBeta, style: MuType.labelS.copyWith(color: c.infoText)),
        ),
      ),
      body: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(
                  child: Semantics(
                    header: true,
                    child: Text(l10n.entAnalyseVideoTitle, style: MuType.h1.copyWith(color: c.text)),
                  ),
                ),
                const SizedBox(width: MuSpace.s2),
                MuAiLabel(),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            Text(l10n.entVideoIntro, style: MuType.bodyL.copyWith(color: c.textSecondary)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.entWhichMove, style: MuType.h3.copyWith(color: c.text)),
            ),
            const SizedBox(height: MuSpace.s3),
            Wrap(
              spacing: MuSpace.s2,
              runSpacing: MuSpace.s2,
              children: [
                for (final m in VideoMove.values)
                  MuChip(
                    kind: MuChipKind.choice,
                    label: videoMoveLabel(m),
                    selected: s.move == m,
                    onSelected: s.step == VideoAnalysisState.idle && !s.uploading
                        ? (_) => ctl.setMove(m)
                        : null,
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuFileUpload.dropzone(
              label: l10n.entYourVideo,
              title: l10n.entFilmOrChoose,
              hint: l10n.entVideoHint,
              error: s.error,
              files: [?s.file],
              onAdd: s.file == null ? () => ctl.pick(l10n.entVideoTooBig, l10n.entVideoWrongFormat) : null,
              onRemove: (_) => ctl.cancel(),
            ),
            const SizedBox(height: MuSpace.s2),
            Text(l10n.entFilmTip, style: caption),
          ],
        ),
        if (s.file != null && !s.uploading)
          _Processing(
            state: s,
            now: ref.read(clockProvider)(),
            onResult: () => context.push(TrainingRoutes.videoResult),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(height: 1, thickness: 1, color: c.border),
            const SizedBox(height: MuSpace.s4),
            MuSwitch(
              value: s.share,
              labelAtStart: true,
              label: l10n.entShareWith(coach.ref.name),
              description: l10n.entShareWithDetail,
              onChanged: ctl.setShare,
            ),
            const SizedBox(height: MuSpace.s2),
            Row(
              children: [
                Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
                const SizedBox(width: MuSpace.s2),
                Expanded(child: Text(l10n.entVideoPrivate, style: caption)),
              ],
            ),
          ],
        ),
      ],
      bottomBar: [
        Row(
          children: [
            Expanded(
              child: MuButton.tertiary(
                label: s.done ? l10n.fermer : l10n.annuler,
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: () {
                  if (!s.done) ctl.cancel();
                  back();
                },
              ),
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: s.done
                  ? MuButton.primary(
                      label: l10n.entSeeResult,
                      size: MuButtonSize.l,
                      fullWidth: true,
                      onPressed: () => context.push(TrainingRoutes.videoResult),
                    )
                  : MuButton.secondary(
                      label: l10n.entNotifyMe,
                      size: MuButtonSize.l,
                      fullWidth: true,
                      onPressed: s.file == null
                          ? null
                          : () {
                              MuToast.show(
                                context,
                                title: l10n.entWeLetYouKnow,
                                description: l10n.entWeLetYouKnowText,
                              );
                              context.go(TrainingRoutes.root);
                            },
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The clip being analysed: thumbnail, « Bandeja · 0:42 », where and when, the AI's steps.
class _Processing extends StatelessWidget {
  const _Processing({required this.state, required this.now, required this.onResult});

  final VideoAnalysisState state;
  final DateTime now;
  final VoidCallback onResult;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = state.result;
    final move = videoMoveLabel(state.move);
    final clip = formatClock(VideoAnalyst.clip);
    final steps = videoSteps(state.move, VideoAnalyst.tipCount);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: MuRadius.mdAll,
          border: Border.all(color: c.aiSoft, width: MuSpace.s1 / 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: MuRadius.smAll,
                  child: SizedBox(
                    width: VideoScreen._thumbW,
                    height: VideoScreen._thumbH,
                    child: MuCourtArt(
                      sport: MuSport.padel,
                      child: Align(
                        alignment: AlignmentDirectional.bottomEnd,
                        child: Padding(
                          padding: const EdgeInsets.all(MuSpace.s1),
                          child: Text(clip, style: MuType.numXs.copyWith(color: MuPalette.white)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          '$move · $clip',
                          style: MuType.labelL.copyWith(color: c.text),
                        ),
                      ),
                      Text(
                        l10n.entFilmedAt(
                          formatDay(r?.filmedAt ?? now),
                          r?.venue ?? VideoAnalyst.venue,
                        ),
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MuSpace.s4),
            MuAiShimmer.steps(
              label: l10n.entAiAnalysing(videoMoveYour(state.move)),
              steps: steps,
              current: state.step,
            ),
            const SizedBox(height: MuSpace.s3),
            if (state.done)
              MuButton.primary(
                label: l10n.entSeeTips(r!.tips.length),
                leading: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                fullWidth: true,
                onPressed: onResult,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIcons.clock(), size: MuSize.iconXs, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.entAboutAMinute,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
