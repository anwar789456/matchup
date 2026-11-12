import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/training_providers.dart';
import '../data/training_models.dart';
import '../training_routes.dart';
import '../widgets/review_widgets.dart';
import '../widgets/training_widgets.dart';

/// ENT-02 · Programmes: search and quick filters, the AI pick « Pour toi », every program, and the
/// verified coaches.
class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

/// « Durée »: any, 3 weeks or less, 4 weeks, 5 weeks or more.
enum _Length { any, short, four, long }

/// « Prix »: any, free, 30 DT or less, included in Premium.
enum _Price { any, free, upTo30, premium }

/// « Pertinence », best rated, cheapest, shortest.
enum _Sort { relevance, rating, price, length }

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String _query = '';
  bool _myLevel = true;
  bool _premiumOnly = false;
  bool _savedOnly = false;
  final Set<MuSport> _sports = {};
  _Length _length = _Length.any;
  _Price _price = _Price.any;
  String? _coach;
  _Sort _sort = _Sort.relevance;

  static const _upTo = 30;

  // ENT-02: « Mon niveau » keeps programs within one point of the player's level.
  static const double _levelSpan = 1;
  static const double _bottomRoom = MuSpace.s16 + MuSpace.s16 + MuSpace.s2;

  int get _filterCount =>
      (_myLevel ? 1 : 0) +
      (_premiumOnly ? 1 : 0) +
      (_savedOnly ? 1 : 0) +
      _sports.length +
      (_length == _Length.any ? 0 : 1) +
      (_price == _Price.any ? 0 : 1) +
      (_coach == null ? 0 : 1);

  double _levelFor(MuSport sport) =>
      ref.read(meProvider).value?.levels[sport] ?? Story.myLevels[sport] ?? Story.myLevels.values.first;

  /// The player's main level (padel in the story) for « niveau 2,5 – 4,5 ».
  double get _mainLevel {
    final levels = ref.read(meProvider).value?.levels ?? Story.myLevels;
    return levels.values.fold(0, (a, b) => a > b ? a : b);
  }

  String _coachLabel(List<MuCoach> coaches) => _coach == null
      ? l10n.entCoach
      : coaches.where((k) => k.id == _coach).map((k) => k.ref.label).firstOrNull ?? l10n.entCoach;

  bool _matches(TrainingProgram p) {
    if (_myLevel && (p.card.level - _levelFor(p.sport)).abs() > _levelSpan) return false;
    if (_premiumOnly && !p.card.premium) return false;
    if (_sports.isNotEmpty && !_sports.contains(p.sport)) return false;
    if (_savedOnly && !(ref.read(trainingProgressProvider).value?.saved.contains(p.id) ?? false)) {
      return false;
    }
    final weeks = p.card.weeks;
    final lengthOut = switch (_length) {
      _Length.any => false,
      _Length.short => weeks > 3,
      _Length.four => weeks != 4,
      _Length.long => weeks < 5,
    };
    if (lengthOut) return false;
    final priceOut = switch (_price) {
      _Price.any => false,
      _Price.free => p.card.price != 0,
      _Price.upTo30 => p.card.price > _upTo,
      _Price.premium => !p.card.premium,
    };
    if (priceOut) return false;
    if (_coach != null && p.coachId != _coach) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [p.title, p.card.coach.label, p.sport.label, p.about]
        .any((s) => s.toLowerCase().contains(q));
  }

  void _clearFilters() => setState(() {
    _query = '';
    _myLevel = false;
    _premiumOnly = false;
    _savedOnly = false;
    _sports.clear();
    _length = _Length.any;
    _price = _Price.any;
    _coach = null;
  });

  String _lengthLabel(_Length l) => switch (l) {
    _Length.any => l10n.entAnyLength,
    _Length.short => l10n.entShortLength,
    _Length.four => l10n.entWeeksShort(4),
    _Length.long => l10n.entLongLength,
  };

  String _priceLabel(_Price p) => switch (p) {
    _Price.any => l10n.entAnyPrice,
    _Price.free => l10n.gratuit,
    _Price.upTo30 => l10n.entUpTo(formatDT(_upTo)),
    _Price.premium => l10n.entIncludedInPremium,
  };

  String _sortLabel(_Sort s) => switch (s) {
    _Sort.relevance => l10n.entRelevance,
    _Sort.rating => l10n.entBestRated,
    _Sort.price => l10n.entCheapest,
    _Sort.length => l10n.entShortest,
  };

  /// « Filtres », « Durée », « Prix », « Coach »: one sheet, applied as you pick.
  Future<void> _openFilters(List<TrainingProgram> all, List<MuCoach> coaches) {
    // Bumped on each pick so the footer's « Voir N programmes » follows.
    final tick = ValueNotifier(0);
    return MuBottomSheet.show<void>(
      context,
      title: l10n.entFilters,
      height: MuSheetHeight.auto,
      footer: ValueListenableBuilder<int>(
        valueListenable: tick,
        builder: (context, _, _) => Row(
          children: [
            MuButton.tertiary(
              label: l10n.entClearFilters,
              onPressed: () {
                _clearFilters();
                tick.value++;
              },
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: MuButton.primary(
                label: l10n.entSeeCount(all.where(_matches).length),
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
      child: StatefulBuilder(
        builder: (context, setSheet) {
          final c = context.mu;
          void pick(VoidCallback change) {
            setState(change);
            setSheet(() {});
            tick.value++;
          }

          Widget group(String title, List<Widget> chips) => Padding(
            padding: const EdgeInsets.only(bottom: MuSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MuType.label.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                Wrap(spacing: MuSpace.s2, runSpacing: MuSpace.s2, children: chips),
              ],
            ),
          );

          return Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                group(l10n.entDuration, [
                  for (final l in _Length.values)
                    MuChip(
                      kind: MuChipKind.choice,
                      label: _lengthLabel(l),
                      selected: _length == l,
                      onSelected: (_) => pick(() => _length = l),
                    ),
                ]),
                group(l10n.entPrice, [
                  for (final p in _Price.values)
                    MuChip(
                      kind: MuChipKind.choice,
                      label: _priceLabel(p),
                      selected: _price == p,
                      onSelected: (_) => pick(() => _price = p),
                    ),
                ]),
                group(l10n.entCoach, [
                  MuChip(
                    kind: MuChipKind.choice,
                    label: l10n.entAnyCoach,
                    selected: _coach == null,
                    onSelected: (_) => pick(() => _coach = null),
                  ),
                  for (final k in coaches)
                    MuChip(
                      kind: MuChipKind.choice,
                      label: k.ref.label,
                      selected: _coach == k.id,
                      onSelected: (_) => pick(() => _coach = k.id),
                    ),
                ]),
              ],
            ),
          );
        },
      ),
    ).whenComplete(tick.dispose);
  }

  Future<void> _openSort() => MuBottomSheet.show<void>(
    context,
    title: l10n.entSortTitle,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
      child: Builder(
        builder: (context) => MuRadioGroup<_Sort>(
          label: l10n.entSortTitle,
          hideLabel: true,
          value: _sort,
          options: [for (final s in _Sort.values) MuRadioOption(value: s, label: _sortLabel(s))],
          onChanged: (s) {
            setState(() => _sort = s);
            Navigator.of(context).pop();
          },
        ),
      ),
    ),
  );

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
                      onSelected: (_) => _openFilters(
                        programs.value ?? const [],
                        coaches.value ?? const [],
                      ),
                    ),
                    if (progress?.saved.isNotEmpty ?? false)
                      MuChip(
                        label: l10n.entSaved,
                        icon: PhosphorIcons.bookmarkSimple(),
                        selected: _savedOnly,
                        onSelected: (v) => setState(() => _savedOnly = v),
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
                    for (final (label, isSet) in [
                      (
                        _length == _Length.any ? l10n.entDuration : _lengthLabel(_length),
                        _length != _Length.any,
                      ),
                      (_price == _Price.any ? l10n.entPrice : _priceLabel(_price), _price != _Price.any),
                      (_coachLabel(coaches.value ?? const []), _coach != null),
                    ])
                      MuChip(
                        label: label,
                        selected: isSet,
                        trailingIcon: PhosphorIcons.caretDown(),
                        onSelected: (_) => _openFilters(
                          programs.value ?? const [],
                          coaches.value ?? const [],
                        ),
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
      switch (_sort) {
        case _Sort.relevance:
          break;
        case _Sort.rating:
          shown.sort((a, b) => b.card.rating.compareTo(a.card.rating));
        case _Sort.price:
          shown.sort((a, b) => a.card.price.compareTo(b.card.price));
        case _Sort.length:
          shown.sort((a, b) => a.card.weeks.compareTo(b.card.weeks));
      }
      // « Pour toi » only in the default order: a sort shows every program in one list.
      final pick = _sort == _Sort.relevance
          ? shown.where((p) => p.forYouReason != null).firstOrNull
          : null;
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
          onRate: () async {
            final res = await showRateSheet(
              context,
              programTitle: p.title,
              current: progress?.ratings[p.id],
            );
            if (res != null) {
              await ref.read(trainingProgressProvider.notifier).rateProgram(p.id, res.$1, res.$2);
            }
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
                  label: l10n.entSortBy(_sortLabel(_sort)),
                  excludeSemantics: true,
                  child: MuButton.tertiary(
                    label: _sortLabel(_sort),
                    leading: PhosphorIcons.arrowsDownUp(),
                    size: MuButtonSize.s,
                    onPressed: _openSort,
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
