import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../payments/controllers/checkout_controller.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../subscription/data/subscription_repository.dart';
import '../controllers/training_providers.dart';
import '../data/training_models.dart';
import '../data/training_story.dart';
import '../training_routes.dart';
import '../widgets/training_video_player.dart';
import '../widgets/review_widgets.dart';
import '../widgets/training_widgets.dart';

/// ENT-03 · Détail du programme: what it is, week by week, the coach, reviews, the price or
/// « Inclus dans Premium », and the sticky « S’inscrire au programme » (« Continuer » once joined).
class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key, required this.programId});

  final String programId;

  // ENT-03: hero 192 high, the sheet overlaps it by 32.
  static const double _hero = 192;
  static const double _overlap = MuSpace.s8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final programs = ref.watch(programsProvider);
    final program = ref.watch(programProvider(programId));
    final progress = ref.watch(trainingProgressProvider).value;
    final subscription = ref.watch(subscriptionProvider).value;

    void back() => context.canPop() ? context.pop() : context.go(TrainingRoutes.programs);

    if (program == null || progress == null) {
      return Scaffold(
        backgroundColor: c.surface,
        body: Column(
          children: [
            MuTopAppBar.compact(title: l10n.entProgram, onBack: back),
            Expanded(
              // « Introuvable » only once the catalogue is loaded and the program is not in it;
              // while the player's progress loads, the skeleton stays.
              child: programs.hasValue && program == null
                  ? Center(
                      child: MuEmptyState(
                        title: l10n.entProgramGone,
                        description: l10n.entProgramGoneText,
                        illustration: MuEmptyIllustration.programs,
                        actions: [
                          MuButton.primary(
                            label: l10n.entSeeCatalogue,
                            onPressed: () => context.go(TrainingRoutes.programs),
                          ),
                        ],
                      ),
                    )
                  : programs.hasError || ref.watch(trainingProgressProvider).hasError
                  ? Padding(
                      padding: const EdgeInsets.all(MuSpace.s4),
                      child: TrainingRetry(
                        onRetry: () => ref
                          ..invalidate(programsProvider)
                          ..invalidate(trainingProgressProvider),
                      ),
                    )
                  : MuSkeletonGroup(
                      label: l10n.entLoadingPrograms,
                      child: const Padding(
                        padding: EdgeInsets.all(MuSpace.s4),
                        child: MuSkeleton.text(lines: 8),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    final p = program;
    final coach = TrainingStory.coach(p.coachId);
    final joined = progress.isEnrolled(p.id);
    final next = progress.nextLesson(p);
    final premiumActive = subscription?.premium ?? false;
    final freeForYou = p.card.price == 0 || (p.card.premium && premiumActive);

    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(
                      height: _hero,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MuCourtArt(sport: p.sport, semanticLabel: l10n.entHeroLabel(p.sport.label.toLowerCase())),
                          PositionedDirectional(
                            start: MuSpace.s4,
                            bottom: _overlap + MuSpace.s4,
                            child: _PreviewPill(
                              duration: p.preview,
                              onTap: () => showTrainingVideo(
                                context,
                                title: l10n.entProgramPreview(p.title),
                                videoKey: 'preview/${p.id}',
                                sport: p.sport,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -_overlap),
                      child: Container(
                        decoration: BoxDecoration(color: c.surface, borderRadius: MuRadius.lgTop),
                        padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, 0),
                        child: _Body(
                          program: p,
                          coach: coach,
                          progress: progress,
                          subscription: subscription,
                          freeForYou: freeForYou,
                        ),
                      ),
                    ),
                  ],
                ),
                MuTopAppBar.media(
                  onBack: back,
                  backLabel: l10n.entBackToCatalogue,
                  actions: [
                    MuBarAction(
                      icon: progress.saved.contains(p.id)
                          ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
                          : PhosphorIcons.bookmarkSimple(),
                      label: progress.saved.contains(p.id) ? l10n.entUnsaveProgram : l10n.entSaveProgram,
                      onPressed: () async {
                        final wasSaved = progress.saved.contains(p.id);
                        await ref.read(trainingProgressProvider.notifier).toggleSaved(p.id);
                        if (context.mounted) {
                          MuToast.show(
                            context,
                            tone: wasSaved ? MuToastTone.neutral : MuToastTone.success,
                            title: wasSaved ? l10n.entProgramUnsaved : l10n.entProgramSaved,
                          );
                        }
                      },
                    ),
                    MuBarAction(
                      icon: PhosphorIcons.shareNetwork(),
                      label: l10n.entShareProgram,
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: l10n.entShareText(p.title, p.card.coach.label)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _BottomBar(
            program: p,
            joined: joined,
            next: next,
            done: progress.doneCount(p.id),
            subscription: subscription,
            freeForYou: freeForYou,
          ),
        ],
      ),
    );
  }
}

/// « ▶ Voir l’aperçu 1:30 » over the hero.
class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.duration, required this.onTap});

  final Duration duration;
  final VoidCallback onTap;

  static const double _disc = 24;
  static const double _icon = 12;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: l10n.entSeePreview(formatClock(duration)),
      excludeSemantics: true,
      child: Material(
        // A media overlay: the same white pill in both themes.
        color: MuPalette.white,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: MuSize.touchTarget - MuSpace.s3),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s1, MuSpace.s1, MuSpace.s3, MuSpace.s1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _disc,
                    height: _disc,
                    decoration: const BoxDecoration(color: MuPalette.ink900, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(
                      PhosphorIcons.play(PhosphorIconsStyle.fill),
                      size: _icon,
                      color: MuPalette.white,
                    ),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  Text(l10n.entSeePreviewShort, style: MuType.labelS.copyWith(color: MuPalette.ink900)),
                  const SizedBox(width: MuSpace.s2),
                  Text(formatClock(duration), style: MuType.numXs.copyWith(color: MuPalette.ink900)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.program,
    required this.coach,
    required this.progress,
    required this.subscription,
    required this.freeForYou,
  });

  final TrainingProgram program;
  final MuCoach coach;
  final TrainingProgress progress;
  final Subscription? subscription;
  final bool freeForYou;

  static const double _check = 18;
  static const double _small = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final p = program;
    final premiumActive = subscription?.premium ?? false;
    final secondary = MuType.caption.copyWith(color: c.textSecondary);

    Widget heading(String text, {Widget? trailing}) => Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: MuType.h2.copyWith(color: c.text)),
          ),
        ),
        ?trailing,
      ],
    );

    final String forYouValue;
    final String forYouCaption;
    if (p.card.price == 0) {
      forYouValue = l10n.gratuit;
      forYouCaption = l10n.entNoCommitment;
    } else if (p.card.premium && premiumActive) {
      forYouValue = formatDT(0);
      forYouCaption = l10n.entInsteadOf(formatDT(p.card.price));
    } else {
      forYouValue = formatDT(p.card.price);
      forYouCaption = l10n.entOneOff;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: MuSpace.s2,
          runSpacing: MuSpace.s2,
          children: [
            MuChip.sport(p.sport, size: MuChipSize.s),
            MuChip(
              kind: MuChipKind.input,
              label: l10n.entLevelSpan(ltr('${formatLevel(p.levelMin)} – ${formatLevel(p.levelMax)}')),
              icon: PhosphorIcons.gauge(),
              size: MuChipSize.s,
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s3),
        Semantics(header: true, child: Text(p.title, style: MuType.h1.copyWith(color: c.text))),
        const SizedBox(height: MuSpace.s2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MuStarRating.display(value: p.card.rating, count: p.card.reviews, size: _small),
            Text(' · ${p.card.coach.label}', style: secondary),
          ],
        ),
        const SizedBox(height: MuSpace.s5),
        Semantics(
          container: true,
          label: l10n.entInBrief,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: MuRadius.mdAll,
              border: Border.all(color: c.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Stat(
                    label: l10n.entDuration,
                    value: l10n.entWeeksShort(p.card.weeks),
                    caption: l10n.entPerWeek(p.perWeek),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: c.border),
                  _Stat(
                    label: l10n.entSessions,
                    value: '${p.card.sessions}',
                    caption: l10n.entMinutesRange(ltr('${p.minutesMin}–${p.minutesMax}')),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: c.border),
                  _Stat(label: l10n.entForYou, value: forYouValue, caption: forYouCaption),
                ],
              ),
            ),
          ),
        ),
        if (p.card.premium) ...[
          const SizedBox(height: MuSpace.s4),
          _PremiumBox(program: p, subscription: subscription),
        ],
        const SizedBox(height: MuSpace.s8),
        heading(l10n.entAbout),
        const SizedBox(height: MuSpace.s3),
        Text(p.about, style: MuType.bodyL.copyWith(color: c.textSecondary)),
        const SizedBox(height: MuSpace.s4),
        for (final o in p.outcomes)
          Padding(
            padding: const EdgeInsets.only(bottom: MuSpace.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: _check, color: c.success),
                const SizedBox(width: MuSpace.s3),
                Expanded(child: Text(o, style: MuType.body.copyWith(color: c.text))),
              ],
            ),
          ),
        const SizedBox(height: MuSpace.s1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(PhosphorIcons.tennisBall(), size: _small, color: c.textSecondary),
            const SizedBox(width: MuSpace.s2),
            Expanded(child: Text(l10n.entYouNeed(p.equipment), style: secondary)),
          ],
        ),
        const SizedBox(height: MuSpace.s8),
        heading(
          l10n.entTheProgram,
          trailing: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${p.card.weeks}', style: MuType.labelS),
                TextSpan(text: ' ${l10n.entWeeksWord(p.card.weeks)} · '),
                TextSpan(text: '${p.card.sessions}', style: MuType.labelS),
                TextSpan(text: ' ${l10n.entSessionsUnit}'),
              ],
            ),
            style: secondary,
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        _Curriculum(program: p, progress: progress),
        const SizedBox(height: MuSpace.s8),
        heading(l10n.entYourCoach),
        const SizedBox(height: MuSpace.s3),
        MuCoachCard(
          coach: coach,
          variant: MuCardVariant.compact,
          onTap: () => context.go(TrainingRoutes.programs),
        ),
        if (coach.certification != null) ...[
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Icon(PhosphorIcons.certificate(), size: _small, color: c.successText),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Text(
                  l10n.entCertifiedLine(coach.certification!),
                  style: MuType.caption.copyWith(color: c.successText),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: MuSpace.s8),
        heading(
          l10n.entStudentReviews,
          trailing: MuButton.tertiary(
            label: l10n.entSeeAllReviews(p.card.reviews),
            size: MuButtonSize.s,
            onPressed: () => context.push(TrainingRoutes.reviews(p.id)),
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        _Reviews(program: p),
        const SizedBox(height: MuSpace.s8),
      ],
    );
  }
}

/// A cell of « Le programme en bref »: « DURÉE » / « 4 sem. » / « 3 par semaine ».
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.caption});

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(MuSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
            const SizedBox(height: MuSpace.s1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value, style: MuType.numXl.copyWith(color: c.text)),
            ),
            const SizedBox(height: MuSpace.s1),
            Text(caption, style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// « Inclus dans Premium »: what the trial gives, or the offer to start it.
class _PremiumBox extends StatelessWidget {
  const _PremiumBox({required this.program, required this.subscription});

  final TrainingProgram program;
  final Subscription? subscription;

  static const double _ring = 1.5;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = subscription;
    final active = s?.premium ?? false;
    final price = formatDT(program.card.price);
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.accent, width: _ring),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MuPremiumBadge(),
          const SizedBox(height: MuSpace.s3),
          Text(
            active
                ? l10n.entPremiumActive(program.card.sessions)
                : l10n.entPremiumOffer(program.card.sessions),
            style: MuType.body.copyWith(color: c.text),
          ),
          const SizedBox(height: MuSpace.s2),
          Text(
            active
                ? l10n.entPremiumTrialTerms(
                    formatDay(s!.trialEnds),
                    formatDT(Subscription.monthly),
                    price,
                  )
                : l10n.entPremiumTerms(Subscription.trialDays, formatDT(Subscription.monthly), price),
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
          if (!active) ...[
            const SizedBox(height: MuSpace.s3),
            MuButton.secondary(
              label: l10n.entTryPremium,
              leading: PhosphorIcons.crownSimple(),
              size: MuButtonSize.s,
              onPressed: () => context.push(Routes.subscriptionOffers),
            ),
          ],
        ],
      ),
    );
  }
}

/// The weeks, as an accordion: index, title, topics (or « 3 séances · 1 h 05 au total » when
/// open); open, its sessions — and the exercises of the one picked.
class _Curriculum extends StatefulWidget {
  const _Curriculum({required this.program, required this.progress});

  final TrainingProgram program;
  final TrainingProgress progress;

  @override
  State<_Curriculum> createState() => _CurriculumState();
}

class _CurriculumState extends State<_Curriculum> {
  late final Set<int> _open;
  late int? _lesson;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    final joined = widget.progress.isEnrolled(p.id);
    final next = widget.progress.nextLesson(p);
    // Joined: the week of the next session, that session open; else the first week and session.
    final lesson = joined && next != null ? next.index : 1;
    _open = {p.weekOf(lesson)};
    _lesson = lesson;
  }

  String _total(int minutes) => minutes >= 60
      ? l10n.entHoursMinutes(minutes ~/ 60, (minutes % 60).toString().padLeft(2, '0'))
      : l10n.entMinutes(minutes);

  MuLessonStatus _status(TrainingLesson l) {
    final p = widget.program;
    final pr = widget.progress;
    if (!pr.isEnrolled(p.id)) return MuLessonStatus.available;
    if (pr.isDone(p.id, l.index)) return MuLessonStatus.done;
    return pr.nextLesson(p)?.index == l.index ? MuLessonStatus.current : MuLessonStatus.available;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final p = widget.program;
    final joined = widget.progress.isEnrolled(p.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in p.weeks) ...[
          MuCardSurface(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  expanded: _open.contains(w.index),
                  child: InkWell(
                    borderRadius: MuRadius.mdAll,
                    onTap: () => setState(
                      () => _open.contains(w.index) ? _open.remove(w.index) : _open.add(w.index),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(MuSpace.s4),
                      child: Row(
                        children: [
                          Container(
                            width: MuSize.controlS + MuSpace.s1,
                            height: MuSize.controlS + MuSpace.s1,
                            decoration: BoxDecoration(
                              color: p.sport.soft(c),
                              borderRadius: MuRadius.smAll,
                            ),
                            alignment: Alignment.center,
                            child: Text('${w.index}', style: MuType.numM.copyWith(color: p.sport.text(c))),
                          ),
                          const SizedBox(width: MuSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w.title, style: MuType.labelL.copyWith(color: c.text)),
                                Text(
                                  _open.contains(w.index)
                                      ? l10n.entWeekTotal(w.lessons.length, _total(w.minutes))
                                      : w.topics,
                                  style: MuType.caption.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _open.contains(w.index)
                                ? PhosphorIcons.caretUp()
                                : PhosphorIcons.caretDown(),
                            size: MuSize.iconS,
                            color: c.text,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_open.contains(w.index))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(MuSpace.s3, 0, MuSpace.s3, MuSpace.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final l in w.lessons) ...[
                          MuLessonCard(
                            lesson: l.toMu(p.sport),
                            status: _status(l),
                            variant: MuCardVariant.compact,
                            onTap: () => setState(() => _lesson = _lesson == l.index ? null : l.index),
                          ),
                          if (_lesson == l.index)
                            _ExerciseList(
                              lesson: l,
                              onStart: joined && !widget.progress.isDone(p.id, l.index)
                                  ? () => context.push(TrainingRoutes.lesson(p.id, l.index))
                                  : null,
                            ),
                          const SizedBox(height: MuSpace.s2),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
        ],
      ],
    );
  }
}

/// The exercises of a session: number, title, dose — and « Lancer la séance » once joined.
class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.lesson, this.onStart});

  final TrainingLesson lesson;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      margin: const EdgeInsets.only(top: MuSpace.s2),
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s1),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
      child: Semantics(
        container: true,
        label: l10n.entExercisesOf(lesson.index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, e) in lesson.exercises.indexed) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: MuSpace.s2 + MuSpace.s1 / 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: MuSpace.s6,
                      child: Text('${i + 1}', style: MuType.caption.copyWith(color: c.textSecondary)),
                    ),
                    Expanded(child: Text(e.title, style: MuType.body.copyWith(color: c.text))),
                    const SizedBox(width: MuSpace.s2),
                    Text(e.dose, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
            if (onStart != null) ...[
              const SizedBox(height: MuSpace.s1),
              MuButton.primary(
                label: l10n.entStartSession,
                leading: PhosphorIcons.play(PhosphorIconsStyle.fill),
                size: MuButtonSize.s,
                onPressed: onStart,
              ),
              const SizedBox(height: MuSpace.s2),
            ],
          ],
        ),
      ),
    );
  }
}

/// « Avis des élèves »: the average, the split by stars and the latest review.
class _Reviews extends StatelessWidget {
  const _Reviews({required this.program});

  final TrainingProgram program;

  static const double _stars = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final p = program;
    final total = p.ratingCounts.fold(0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuCardSurface(
          child: Row(
            children: [
              Column(
                children: [
                  Text(formatLevel(p.card.rating), style: MuType.numHero.copyWith(color: c.text)),
                  MuStarRating.display(value: p.card.rating, size: _stars, showValue: false),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    l10n.entReviews(p.card.reviews),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: MuSpace.s5),
              Expanded(
                child: Semantics(
                  container: true,
                  label: l10n.entRatingSplit,
                  child: Column(
                    children: [
                      for (final (i, n) in p.ratingCounts.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: MuSpace.s1 / 2),
                          child: Semantics(
                            label: l10n.entStarsCount(5 - i, n),
                            excludeSemantics: true,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: MuSpace.s6,
                                  child: Text(
                                    '${5 - i} ★',
                                    style: MuType.caption.copyWith(color: c.textSecondary),
                                  ),
                                ),
                                Expanded(
                                  child: MuProgressBar(
                                    value: n.toDouble(),
                                    max: total == 0 ? 1 : total.toDouble(),
                                    size: MuProgressSize.s,
                                    showValue: false,
                                  ),
                                ),
                                SizedBox(
                                  width: MuSpace.s8,
                                  child: Text(
                                    '$n',
                                    textAlign: TextAlign.end,
                                    style: MuType.numXs.copyWith(color: c.text),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final r in p.reviews) ...[
          const SizedBox(height: MuSpace.s3),
          MuCardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    MuAvatar(name: r.author, size: MuAvatarSize.s),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.author, style: MuType.label.copyWith(color: c.text)),
                          Text(
                            r.finished ? l10n.entFinishedAgo(r.daysAgo) : l10n.entDaysAgo(r.daysAgo),
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    MuStarRating.display(value: r.stars.toDouble(), size: _stars, showValue: false),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                Text(r.text, style: MuType.body.copyWith(color: c.text)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The sticky bar: the price line and « S’inscrire au programme », « Payer… », or « Continuer ».
class _BottomBar extends ConsumerStatefulWidget {
  const _BottomBar({
    required this.program,
    required this.joined,
    required this.next,
    required this.done,
    required this.subscription,
    required this.freeForYou,
  });

  final TrainingProgram program;
  final bool joined;
  final TrainingLesson? next;
  final int done;
  final Subscription? subscription;
  final bool freeForYou;

  @override
  ConsumerState<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends ConsumerState<_BottomBar> {
  bool _busy = false;

  static const double _crown = 16;

  Future<void> _enroll() async {
    setState(() => _busy = true);
    await ref.read(trainingProgressProvider.notifier).enroll(widget.program.id);
    if (!mounted) return;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.entEnrolled,
      description: l10n.entEnrolledText(widget.program.title),
    );
    context.go(TrainingRoutes.root);
  }

  void _pay() {
    final p = widget.program;
    ref
        .read(checkoutRequestProvider.notifier)
        .start(
          CheckoutRequest(
            kind: CheckoutKind.program,
            eyebrow: l10n.entCheckoutEyebrow.toUpperCase(),
            title: p.title,
            subtitle: l10n.entCheckoutSubtitle(p.card.coach.label, p.card.weeks, p.card.sessions),
            amount: p.card.price,
            lineLabel: l10n.entCheckoutLine,
            sport: p.sport,
            successRoute: TrainingRoutes.root,
            onPaid: (_, _) => ref.read(trainingProgressProvider.notifier).enroll(p.id),
          ),
        );
    context.push(Routes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final p = widget.program;
    final s = widget.subscription;
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    if (widget.joined) {
      final next = widget.next;
      final rating = ref.watch(trainingProgressProvider).value?.ratings[p.id];
      Future<void> rate() async {
        final res = await showRateSheet(context, programTitle: p.title, current: rating);
        if (res == null) return;
        await ref.read(trainingProgressProvider.notifier).rateProgram(p.id, res.$1, res.$2);
        if (mounted) {
          MuToast.show(this.context, tone: MuToastTone.success, title: l10n.entThanksForRating);
        }
      }

      return StickyActionBar(
        children: [
          Text(
            next == null
                ? (rating == null
                      ? l10n.entProgramFinished(p.card.sessions)
                      : l10n.entYouRated(rating.$1))
                : l10n.entJoinedLine(widget.done, p.card.sessions, next.index, next.title),
            textAlign: TextAlign.center,
            style: caption,
          ),
          if (next == null)
            MuButton.secondary(
              label: rating == null ? l10n.entRateProgram : l10n.entEditRating,
              leading: PhosphorIcons.star(),
              size: MuButtonSize.xl,
              fullWidth: true,
              onPressed: rate,
            )
          else
            MuButton.primary(
              label: l10n.entContinueSession(next.index),
              leading: PhosphorIcons.play(PhosphorIconsStyle.fill),
              size: MuButtonSize.xl,
              fullWidth: true,
              onPressed: () => context.push(TrainingRoutes.lesson(p.id, next.index)),
            ),
        ],
      );
    }

    final String line;
    if (p.card.price == 0) {
      line = l10n.entFreeLine;
    } else if (widget.freeForYou) {
      line = l10n.entPremiumLine(
        formatDT(0),
        s?.status == PremiumStatus.trial ? l10n.entYourTrial : l10n.entYourPremium,
      );
    } else {
      line = l10n.entPaidLine(formatDT(p.card.price));
    }

    return StickyActionBar(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.freeForYou && p.card.premium) ...[
              Icon(PhosphorIcons.crownSimple(PhosphorIconsStyle.fill), size: _crown, color: c.text),
              const SizedBox(width: MuSpace.s1),
            ],
            Flexible(child: Text(line, textAlign: TextAlign.center, style: caption)),
          ],
        ),
        widget.freeForYou
            ? MuButton.primary(
                label: l10n.entEnroll,
                size: MuButtonSize.xl,
                fullWidth: true,
                loading: _busy,
                onPressed: _busy ? null : _enroll,
              )
            : MuButton.primary(
                label: l10n.entPayAndEnroll(formatDT(p.card.price)),
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: _pay,
              ),
      ],
    );
  }
}
