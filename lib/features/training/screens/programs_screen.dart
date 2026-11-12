import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/training_providers.dart';
import '../data/training_models.dart';
import '../training_routes.dart';
import '../widgets/training_widgets.dart';

/// ENT-02 · Programmes: search and quick filters, the AI pick « Pour toi », every program, and the
/// verified coaches.
class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String _query = '';
  bool _myLevel = true;
  bool _premiumOnly = false;
  final Set<MuSport> _sports = {};

  // ENT-02: « Mon niveau » keeps programs within one point of the player's level.
  static const double _levelSpan = 1;
  static const double _bottomRoom = MuSpace.s16 + MuSpace.s16 + MuSpace.s2;

  int get _filterCount => (_myLevel ? 1 : 0) + (_premiumOnly ? 1 : 0) + _sports.length;

  double _levelFor(MuSport sport) =>
      ref.read(meProvider).value?.levels[sport] ?? Story.myLevels[sport] ?? Story.myLevels.values.first;

  /// The player's main level (padel in the story) for « niveau 2,5 – 4,5 ».
  double get _mainLevel {
    final levels = ref.read(meProvider).value?.levels ?? Story.myLevels;
    return levels.values.fold(0, (a, b) => a > b ? a : b);
  }

  bool _matches(TrainingProgram p) {
    if (_myLevel && (p.card.level - _levelFor(p.sport)).abs() > _levelSpan) return false;
    if (_premiumOnly && !p.card.premium) return false;
    if (_sports.isNotEmpty && !_sports.contains(p.sport)) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [p.title, p.card.coach.label, p.sport.label, p.about]
        .any((s) => s.toLowerCase().contains(q));
  }

  void _clearFilters() => setState(() {
    _query = '';
    _myLevel = false;
    _premiumOnly = false;
    _sports.clear();
  });

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    ref.watch(meProvider);
    final programs = ref.watch(programsProvider);
    final coaches = ref.watch(coachesProvider);
    final progress = ref.watch(trainingProgressProvider).value;

    final header = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s1, MuSpace.s2, MuSpace.s4, 0),
            child: Row(
              children: [
                MuIconButton(
                  icon: PhosphorIcons.arrowLeft(),
                  label: l10n.retour,
                  size: MuIconButtonSize.l,
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go(TrainingRoutes.root),
                ),
                const SizedBox(width: MuSpace.s1),
                Semantics(
                  header: true,
                  child: Text(l10n.entPrograms, style: MuType.h1.copyWith(color: c.text)),
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: MuSearchField<String>(
              label: l10n.entSearchProgram,
              placeholder: l10n.entSearchPlaceholder,
              onChanged: (q) => setState(() => _query = q),
              onSubmitted: (q) => setState(() => _query = q),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Semantics(
            container: true,
            label: l10n.entQuickFilters,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Row(
                children: [
                  for (final (i, chip) in [
                    MuChip(
                      label: l10n.entFilters,
                      icon: PhosphorIcons.slidersHorizontal(),
                      count: _filterCount == 0 ? null : _filterCount,
                      onSelected: (_) => showComingSoon(context),
                    ),
                    MuChip(
                      label: l10n.entMyLevel,
                      selected: _myLevel,
                      onSelected: (v) => setState(() => _myLevel = v),
                    ),
                    MuChip(
                      label: l10n.entIncludedInPremium,
                      icon: PhosphorIcons.crownSimple(),
                      selected: _premiumOnly,
                      onSelected: (v) => setState(() => _premiumOnly = v),
                    ),
                    for (final s in MuSport.values)
                      MuChip.sport(
                        s,
                        selected: _sports.contains(s),
                        onSelected: (v) => setState(() => v ? _sports.add(s) : _sports.remove(s)),
                      ),
                    for (final label in [l10n.entDuration, l10n.entPrice, l10n.entCoach])
                      MuChip(
                        label: label,
                        trailingIcon: PhosphorIcons.caretDown(),
                        onSelected: (_) => showComingSoon(context),
                      ),
                  ].indexed) ...[
                    if (i > 0) const SizedBox(width: MuSpace.s2),
                    chip,
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Divider(height: 1, thickness: 1, color: c.border),
        ],
      ),
    );

    Widget body;
    if (programs.hasError && !programs.hasValue) {
      body = Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: TrainingRetry(onRetry: () => ref.invalidate(programsProvider)),
      );
    } else if (!programs.hasValue) {
      body = MuSkeletonGroup(
        label: l10n.entLoadingPrograms,
        child: const Padding(
          padding: EdgeInsets.all(MuSpace.s4),
          child: Column(
            children: [
              MuProgramCard.loading(),
              SizedBox(height: MuSpace.s3),
              MuProgramCard.loading(variant: MuCardVariant.compact),
            ],
          ),
        ),
      );
    } else {
      final shown = programs.value!.where(_matches).toList();
      final pick = shown.where((p) => p.forYouReason != null).firstOrNull;
      final rest = [for (final p in shown) if (p != pick) p];
      final level = _mainLevel;
      final range = ltr('${formatLevel(level - _levelSpan)} – ${formatLevel(level + _levelSpan)}');

      MuProgramCard card(TrainingProgram p, MuCardVariant variant) {
        final joined = progress?.isEnrolled(p.id) ?? false;
        final finished = joined && progress!.nextLesson(p) == null;
        return MuProgramCard(
          program: p.card,
          variant: variant,
          status: finished
              ? MuProgramStatus.completed
              : joined
              ? MuProgramStatus.enrolled
              : MuProgramStatus.available,
          progress: progress?.doneCount(p.id) ?? 0,
          nextLesson: joined ? progress!.nextLesson(p)?.title : null,
          onTap: () => context.push(TrainingRoutes.program(p.id)),
          onContinue: () {
            final next = progress?.nextLesson(p);
            if (next != null) context.push(TrainingRoutes.lesson(p.id, next.index));
          },
        );
      }

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s3, MuSpace.s1, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.entProgramCount(shown.length),
                          style: MuType.label.copyWith(color: c.text),
                        ),
                        if (_myLevel)
                          TextSpan(
                            text: ' · ${l10n.entLevelRange(range)}',
                            style: MuType.body.copyWith(color: c.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
                Semantics(
                  label: l10n.entSortBy(l10n.entRelevance),
                  excludeSemantics: true,
                  child: MuButton.tertiary(
                    label: l10n.entRelevance,
                    leading: PhosphorIcons.arrowsDownUp(),
                    size: MuButtonSize.s,
                    onPressed: () => showComingSoon(context),
                  ),
                ),
              ],
            ),
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(MuSpace.s4),
              child: MuEmptyState(
                title: l10n.entNoMatchTitle,
                description: l10n.entNoMatchText,
                illustration: MuEmptyIllustration.programs,
                actions: [MuButton.secondary(label: l10n.entClearFilters, onPressed: _clearFilters)],
              ),
            ),
          if (pick != null) ...[
            const SizedBox(height: MuSpace.s5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Row(
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.entForYou, style: MuType.h3.copyWith(color: c.text)),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  MuAiLabel(size: MuAiLabelSize.s),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Text(
                l10n.entRecommendedBecause(pick.forYouReason!),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ),
            const SizedBox(height: MuSpace.s3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: card(pick, MuCardVariant.regular),
            ),
          ],
          if (rest.isNotEmpty) ...[
            const SizedBox(height: MuSpace.s8),
            TrainingSectionHeader(title: l10n.entAllPrograms),
            const SizedBox(height: MuSpace.s3),
            for (final (i, p) in rest.indexed) ...[
              if (i > 0) const SizedBox(height: MuSpace.s3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: card(p, MuCardVariant.compact),
              ),
            ],
          ],
          if (coaches.hasValue) ...[
            const SizedBox(height: MuSpace.s8),
            TrainingSectionHeader(title: l10n.entCoaches, caption: l10n.entCoachesCaption),
            const SizedBox(height: MuSpace.s3),
            for (final (i, k) in coaches.value!.indexed) ...[
              if (i > 0) const SizedBox(height: MuSpace.s3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: MuCoachCard(
                  coach: k,
                  variant: MuCardVariant.compact,
                  onTap: () => setState(() {
                    _query = '';
                    _myLevel = false;
                    _premiumOnly = false;
                    _sports
                      ..clear()
                      ..add(k.sport);
                  }),
                ),
              ),
            ],
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          header,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: _bottomRoom),
              children: [body],
            ),
          ),
        ],
      ),
    );
  }
}
