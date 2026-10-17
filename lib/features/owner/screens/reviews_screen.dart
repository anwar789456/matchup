import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/reviews_repository.dart';
import '../../../l10n/l10n.dart';

enum _ReviewFilter { all, unanswered, fiveStars, lowRated }

/// A reply is at most this long (OWN-19 « 137/500 »).
const _replyMax = 500;

/// OWN-19 · Avis: the average and the split by stars, filters, then the latest reviews; an
/// unanswered one opens with « Ta réponse publique » and « Publier la réponse ».
class OwnerReviewsScreen extends ConsumerStatefulWidget {
  const OwnerReviewsScreen({super.key});

  @override
  ConsumerState<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends ConsumerState<OwnerReviewsScreen> {
  var _filter = _ReviewFilter.all;

  bool _matches(VenueReview r) => switch (_filter) {
    _ReviewFilter.all => true,
    _ReviewFilter.unanswered => !r.answered,
    _ReviewFilter.fiveStars => r.rating == 5,
    _ReviewFilter.lowRated => r.rating <= 3,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final data = ref.watch(ownerReviewsProvider).value;
    Widget chip(_ReviewFilter f, String label, int count) => MuChip(
      kind: MuChipKind.choice,
      size: MuChipSize.s,
      label: label,
      count: count,
      selected: _filter == f,
      onSelected: (_) => setState(() => _filter = f),
    );
    final shown = [
      for (final r in data?.latest ?? const <VenueReview>[])
        if (_matches(r)) r,
    ];
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.avis,
            subtitle: l10n.espaceProprietaire2(Story.arenaFive.name),
            backLabel: l10n.retourAPlus,
            onBack: () => goBack(context, Routes.ownerMore),
          ),
          Expanded(
            child: data == null
                ? const Center(child: MuSpinner())
                : ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      MuSpace.s4,
                      MuSpace.s2,
                      MuSpace.s4,
                      MuSpace.s8,
                    ),
                    children: [
                      _Summary(data: data),
                      const SizedBox(height: MuSpace.s3),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              PhosphorIcons.sealCheck(),
                              size: MuSize.iconXs,
                              color: c.textSecondary,
                            ),
                            const SizedBox(width: MuSpace.s2),
                            Expanded(
                              child: Text(
                                l10n.seulsLesJoueursQuiOnt,
                                style: caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Semantics(
                        container: true,
                        label: l10n.filtrerLesAvis,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              chip(_ReviewFilter.all, l10n.tous, data.total),
                              const SizedBox(width: MuSpace.s2),
                              chip(_ReviewFilter.unanswered, l10n.sansReponse, data.unanswered),
                              const SizedBox(width: MuSpace.s2),
                              chip(_ReviewFilter.fiveStars, l10n.etoiles, data.byStars[5] ?? 0),
                              const SizedBox(width: MuSpace.s2),
                              chip(_ReviewFilter.lowRated, l10n.etoilesEtMoins, data.lowRated),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.plusRecents,
                            style: MuType.overline.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ),
                      if (shown.isEmpty) ...[
                        const SizedBox(height: MuSpace.s4),
                        MuEmptyState(
                          compact: true,
                          title: _filter == _ReviewFilter.unanswered
                              ? l10n.tuAsReponduATous
                              : l10n.aucunAvisRecentIci,
                          description: l10n.lesPlusAnciensSontDans,
                        ),
                      ],
                      for (final r in shown) ...[
                        const SizedBox(height: MuSpace.s4),
                        _ReviewCard(key: ValueKey(r.id), review: r),
                      ],
                      const SizedBox(height: MuSpace.s4),
                      MuButton.secondary(
                        label: l10n.voirLesAutresAvis(data.total - data.latest.length),
                        fullWidth: true,
                        onPressed: () => showComingSoon(context),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                        child: Text(
                          l10n.unAvisInjurieuxOuFaux,
                          textAlign: TextAlign.center,
                          style: caption,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// « 4,7 », the stars, « 128 avis vérifiés », and the bars per star.
class _Summary extends StatelessWidget {
  const _Summary({required this.data});

  final ReviewsSummary data;

  // OWN-19: stars 16, bars 6 high, the star column 12 and the count column 28 wide.
  static const double _stars = 16;
  static const double _bar = 6;
  static const double _starCol = 12;
  static const double _countCol = 28;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final average = data.average.toStringAsFixed(1).replaceAll('.', ',');
    return Semantics(
      container: true,
      label: l10n.noteMoyenneSurAvis(average, data.total),
      child: MuCardSurface(
        padding: const EdgeInsetsDirectional.fromSTEB(
          MuSpace.s5,
          MuSpace.s4,
          MuSpace.s4,
          MuSpace.s4,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(average, style: MuType.numHero.copyWith(color: c.text)),
                  MuStarRating.display(value: data.average, size: _stars, showValue: false),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    l10n.avisVerifies(data.total),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MuSpace.s5),
            Expanded(
              child: Semantics(
                label: l10n.repartitionDesNotes,
                child: Column(
                  children: [
                    for (var s = 5; s >= 1; s--) ...[
                      if (s < 5) const SizedBox(height: MuSpace.s1 + MuSpace.s1 / 2),
                      Semantics(
                        label: l10n.etoileAvis(s, s > 1 ? 's' : '', data.byStars[s] ?? 0),
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            SizedBox(
                              width: _starCol,
                              child: Text('$s', style: MuType.labelS.copyWith(color: c.text)),
                            ),
                            const SizedBox(width: MuSpace.s2),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: MuRadius.fullAll,
                                child: Container(
                                  height: _bar,
                                  color: c.surfaceMuted,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: FractionallySizedBox(
                                    widthFactor: data.total == 0
                                        ? 0
                                        : (data.byStars[s] ?? 0) / data.total,
                                    heightFactor: 1,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: c.warning,
                                        borderRadius: MuRadius.fullAll,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: MuSpace.s2),
                            SizedBox(
                              width: _countCol,
                              child: Text(
                                '${data.byStars[s] ?? 0}',
                                textAlign: TextAlign.end,
                                style: MuType.numXs.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One review: author, stars, date and court, text; the venue's reply, or the composer.
class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({super.key, required this.review});

  final VenueReview review;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  late final _reply = TextEditingController(text: widget.review.draft ?? '');
  late bool _composing = !widget.review.answered;
  bool _posting = false;

  // OWN-19: stars 16, the reply arrow 14, the « Sans réponse » pill padded 1 px.
  static const double _stars = 16;
  static const double _arrow = 14;
  static const double _pillPadV = 1;

  /// Just answered: « Répondu » and « Modifier » show for a day.
  bool _fresh(VenueReview r) =>
      r.replyDate != null && ref.read(clockProvider)().difference(r.replyDate!).inDays < 1;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _reply.text.trim();
    if (text.isEmpty || text.length > _replyMax) return;
    setState(() => _posting = true);
    await ref.read(reviewsRepositoryProvider).reply(widget.review.id, text);
    ref.invalidate(ownerReviewsProvider);
    await ref.read(ownerReviewsProvider.future);
    if (!mounted) return;
    setState(() {
      _posting = false;
      _composing = false;
    });
    MuSnackbar.show(
      context,
      icon: PhosphorIcons.checkCircle(),
      tone: MuToastTone.success,
      message: l10n.reponsePublieeSurLaPage(Story.arenaFive.name),
    );
  }

  String _replyWhen(DateTime at) {
    final now = ref.read(clockProvider)();
    if (now.difference(at).inMinutes < 1) return l10n.aLInstant;
    return formatDay(at);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = widget.review;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return Semantics(
      container: true,
      label: l10n.avisDeSur(r.author, r.rating),
      child: MuCardSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MuAvatar(name: r.author),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.author, style: MuType.labelL.copyWith(color: c.text)),
                      const SizedBox(height: MuSpace.s1 / 2),
                      MuStarRating.display(
                        value: r.rating.toDouble(),
                        size: _stars,
                        showValue: false,
                      ),
                      const SizedBox(height: MuSpace.s1 / 2),
                      Text(l10n.terrain6(formatDay(r.date), r.court), style: caption),
                    ],
                  ),
                ),
                if (!r.answered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MuSpace.s2,
                      vertical: _pillPadV,
                    ),
                    decoration: BoxDecoration(color: c.warningSoft, borderRadius: MuRadius.fullAll),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.chatCircleDots(), size: _arrow, color: c.warningText),
                        const SizedBox(width: MuSpace.s1),
                        Text(l10n.sansReponse, style: MuType.labelS.copyWith(color: c.warningText)),
                      ],
                    ),
                  )
                else if (_fresh(r))
                  MuStatusBadge(
                    status: MuStatus.confirmed,
                    label: l10n.repondu,
                    size: MuBadgeSize.s,
                  )
                else
                  MuIconButton(
                    icon: PhosphorIcons.dotsThree(),
                    label: l10n.plusDActionsSurL(r.author),
                    color: c.textSecondary,
                    onPressed: () => showComingSoon(context),
                  ),
              ],
            ),
            const SizedBox(height: MuSpace.s3),
            Text(r.text, style: MuType.body.copyWith(color: c.text)),
            if (_composing) ...[
              const SizedBox(height: MuSpace.s3),
              Divider(height: 1, thickness: 1, color: c.border),
              const SizedBox(height: MuSpace.s3),
              MuTextField(
                label: l10n.taReponsePublique,
                controller: _reply,
                multiline: true,
                minLines: 4,
                maxLength: _replyMax,
                helper: l10n.visibleParTousSurLa(Story.arenaFive.name),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: MuSpace.s3),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MuButton.tertiary(
                    label: l10n.annuler,
                    onPressed: _posting
                        ? null
                        : () => setState(() {
                            _composing = false;
                            _reply.text = r.reply ?? r.draft ?? '';
                          }),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  MuButton.primary(
                    label: l10n.publierLaReponse,
                    leading: PhosphorIcons.paperPlaneRight(),
                    loading: _posting,
                    onPressed:
                        _posting || _reply.text.trim().isEmpty || _reply.text.length > _replyMax
                        ? null
                        : _publish,
                  ),
                ],
              ),
            ] else if (r.answered) ...[
              const SizedBox(height: MuSpace.s3),
              Container(
                padding: const EdgeInsets.all(MuSpace.s3),
                decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MuDirectionalIcon(
                          PhosphorIcons.arrowBendUpLeft(),
                          size: _arrow,
                          color: c.text,
                        ),
                        const SizedBox(width: MuSpace.s1 + MuSpace.s1 / 2),
                        Text(
                          '${Story.arenaFive.name} · ${_replyWhen(r.replyDate!)}',
                          style: MuType.labelS.copyWith(color: c.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuSpace.s1),
                    Text(r.reply!, style: MuType.body.copyWith(color: c.text)),
                    if (_fresh(r))
                      MuButton(
                        variant: MuButtonVariant.link,
                        size: MuButtonSize.s,
                        label: l10n.modifier,
                        onPressed: () => setState(() {
                          _reply.text = r.reply!;
                          _composing = true;
                        }),
                      ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: MuSpace.s2),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MuButton.tertiary(
                  label: l10n.repondre,
                  size: MuButtonSize.s,
                  leading: PhosphorIcons.arrowBendUpLeft(),
                  onPressed: () => setState(() => _composing = true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
