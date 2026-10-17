import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../data/owner_drafts.dart';
import '../data/owner_repository.dart';
import '../data/tariffs_repository.dart';
import '../../../l10n/l10n.dart';

final _weekdays = [l10n.lundi, l10n.mardi, l10n.mercredi, l10n.jeudi, l10n.vendredi, l10n.samedi, l10n.dimanche];
final _everyWeekday = [
  l10n.tousLesLundis,
  l10n.tousLesMardis,
  l10n.tousLesMercredis,
  l10n.tousLesJeudis,
  l10n.tousLesVendredis,
  l10n.tousLesSamedis,
  l10n.tousLesDimanches,
];
final _lastWeekdays = [
  l10n.derniersLundis,
  l10n.derniersMardis,
  l10n.derniersMercredis,
  l10n.derniersJeudis,
  l10n.derniersVendredis,
  l10n.derniersSamedis,
  l10n.derniersDimanches,
];

/// The share of a promo's slots that stayed empty, as the assistant measured it (OWN-10: « 80 %
/// de créneaux vides »), over the last [_weeksMeasured] weeks.
const _emptyShare = 0.8;
const _weeksMeasured = 5;

/// Players a court price is split between (« calculé pour 10 joueurs »).
const _players = 10;

String _capitalized(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// OWN-16 · Tarifs: off-peak and peak hours, the price of each court, the AI promo, what players
/// see and special dates. Opened from OWN-10 « Appliquer » with a [promo]: the promo shows filled
/// in, « À confirmer », and nothing is written until the owner publishes it or saves; leaving
/// discards it.
class OwnerPricesScreen extends ConsumerStatefulWidget {
  const OwnerPricesScreen({super.key, this.promo});
  final PromoDraft? promo;

  @override
  ConsumerState<OwnerPricesScreen> createState() => _OwnerPricesScreenState();
}

class _OwnerPricesScreenState extends ConsumerState<OwnerPricesScreen> {
  Tariffs? _tariffs;
  final _offPeak = <String, TextEditingController>{};
  final _peak = <String, TextEditingController>{};
  bool _weekendPeak = true;
  PromoDraft? _promo;
  bool _promoWeekly = false;
  bool _promoPublished = false;
  bool _publishing = false;
  bool _saving = false;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _promo = widget.promo;
    ref.read(tariffsRepositoryProvider).load().then((t) {
      if (!mounted) return;
      setState(() {
        _tariffs = t;
        _weekendPeak = t.weekendPeak;
        for (final p in t.prices) {
          _offPeak[p.id] = TextEditingController(text: formatAmount(p.offPeak));
          _peak[p.id] = TextEditingController(text: formatAmount(p.peak));
        }
      });
    });
  }

  @override
  void dispose() {
    for (final c in [..._offPeak.values, ..._peak.values]) {
      c.dispose();
    }
    super.dispose();
  }

  static num? _parse(TextEditingController c) {
    final v = num.tryParse(c.text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'));
    return v == null || v <= 0 ? null : v;
  }

  String? _error(TextEditingController c) => _tried && _parse(c) == null ? l10n.indiqueUnPrix2 : null;

  String? _perPlayer(TextEditingController c) {
    final v = _parse(c);
    return v == null ? null : l10n.soitPers(formatDT(v / _players));
  }

  DateTime get _now => ref.read(clockProvider)();

  /// The first day the promo applies (« jeu. 22 oct. »).
  DateTime _promoDay(PromoDraft p) => nextWeekday(_now, p.weekday);

  OwnerPromo _ownerPromo(PromoDraft p) =>
      OwnerPromo(draft: p, firstDay: _promoDay(p), weekly: _promoWeekly);

  String _promoTitle(PromoDraft p) =>
      '${_weekdays[p.weekday - 1]} ${formatHour(p.fromHour * 60)} – '
      '${formatHour(p.toHour * 60)} · −${p.percent} %';

  Future<void> _publishPromo() async {
    final p = _promo;
    if (p == null) return;
    setState(() => _publishing = true);
    await ref.read(tariffsRepositoryProvider).publishPromo(_ownerPromo(p));
    ref.invalidate(tariffsProvider);
    if (!mounted) return;
    setState(() {
      _publishing = false;
      _promoPublished = true;
    });
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.promoPubliee,
      description: _promoWeekly
          ? '${_promoTitle(p)}, ${_everyWeekday[p.weekday - 1].toLowerCase()}.'
          : l10n.le3(_promoTitle(p), formatDay(_promoDay(p))),
    );
  }

  Future<void> _save() async {
    final t = _tariffs;
    if (t == null) return;
    setState(() => _tried = true);
    final fields = [..._offPeak.values, ..._peak.values];
    if (fields.any((c) => _parse(c) == null)) return;
    setState(() => _saving = true);
    final withPromo = _promo != null && !_promoPublished;
    await ref
        .read(tariffsRepositoryProvider)
        .save(
          t.copyWith(
            weekendPeak: _weekendPeak,
            prices: [
              for (final p in t.prices)
                p.copyWith(offPeak: _parse(_offPeak[p.id]!), peak: _parse(_peak[p.id]!)),
            ],
            promos: [...t.promos, if (withPromo) _ownerPromo(_promo!)],
          ),
        );
    ref.invalidate(tariffsProvider);
    if (!mounted) return;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.tarifsEnregistres,
      description: withPromo
          ? l10n.promoPubliee2(_promoTitle(_promo!))
          : l10n.lesReservationsDejaPayeesGardent,
    );
    goBack(context, Routes.ownerMore);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final t = _tariffs;
    final courts = ref.watch(ownerCourtsProvider).value;
    final courtCount = courts?.length ?? 3;
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.tarifs,
            subtitle: l10n.terrains4(Story.arenaFive.name, courtCount),
            onBack: () => goBack(context, Routes.ownerMore),
          ),
          Expanded(
            child: t == null
                ? const Center(child: MuSpinner())
                : ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      MuSpace.s4,
                      MuSpace.s3,
                      MuSpace.s4,
                      MuSpace.s8,
                    ),
                    children: [
                      _hours(t),
                      const SizedBox(height: MuSpace.s6 + MuSpace.s1),
                      _prices(t),
                      const SizedBox(height: MuSpace.s6 + MuSpace.s1),
                      _promotions(t, courtCount),
                      const SizedBox(height: MuSpace.s6 + MuSpace.s1),
                      _preview(t),
                      const SizedBox(height: MuSpace.s6 + MuSpace.s1),
                      _specialDates(t),
                    ],
                  ),
          ),
          StickyActionBar(
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.info(), size: _Sizes.icon14, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.lesReservationsDejaPayeesGardent,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
              MuButton.primary(
                label: l10n.enregistrerLesTarifs,
                size: MuButtonSize.xl,
                fullWidth: true,
                loading: _saving,
                onPressed: t == null || _saving ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHead(String title, {String? lead, Widget? action}) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.only(bottom: MuSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: MuType.h3.copyWith(color: c.text)),
                ),
                if (lead != null) ...[
                  const SizedBox(height: MuSpace.s1 / 2),
                  Text(lead, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }

  // ── Plages horaires ──────────────────────────────────────────────────────────────────────────
  Widget _hours(Tariffs t) {
    final c = context.mu;
    final before = t.peakFrom - ownerOpens;
    final peak = t.peakTo - t.peakFrom;
    final after = ownerCloses - t.peakTo;
    const span = ownerCloses - ownerOpens;
    Widget band(int flex, {String? label, required bool isPeak}) => Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPeak ? c.warningSoft : c.surfaceMuted,
          border: isPeak ? null : Border.all(color: c.border),
        ),
        child: label == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPeak ? PhosphorIcons.lightning(PhosphorIconsStyle.fill) : PhosphorIcons.sun(),
                    size: _Sizes.icon14,
                    color: isPeak ? c.warningText : c.textSecondary,
                  ),
                  const SizedBox(width: MuSpace.s1),
                  Text(
                    label,
                    style: MuType.labelS.copyWith(color: isPeak ? c.warningText : c.textSecondary),
                  ),
                ],
              ),
      ),
    );
    final tick = MuType.numXs.copyWith(color: c.textSecondary);
    String h(int hour) => '${(hour % 24).toString().padLeft(2, '0')}h';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(
          l10n.plagesHoraires,
          action: MuButton.tertiary(
            label: l10n.modifier,
            size: MuButtonSize.s,
            leading: PhosphorIcons.clock(),
            onPressed: () => showComingSoon(context),
          ),
        ),
        MuCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.duLundiAuVendredi, style: MuType.label.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s2),
              Semantics(
                label:
                    l10n.heuresCreusesDeAHeures(formatHour(ownerOpens * 60), formatHour(t.peakFrom * 60), formatHour(t.peakFrom * 60), formatHour(t.peakTo * 60), formatHour(t.peakTo * 60)),
                excludeSemantics: true,
                child: ClipRRect(
                  borderRadius: MuRadius.smAll,
                  child: SizedBox(
                    height: _Sizes.band,
                    child: Row(
                      children: [
                        band(before, label: l10n.creuses, isPeak: false),
                        const SizedBox(width: _Sizes.bandGap),
                        band(peak, label: l10n.pointe, isPeak: true),
                        if (after > 0) ...[
                          const SizedBox(width: _Sizes.bandGap),
                          band(after, isPeak: false),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MuSpace.s1),
              ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, box) {
                    double at(int hour) => box.maxWidth * (hour - ownerOpens) / span;
                    return SizedBox(
                      height: MuSpace.s4,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PositionedDirectional(start: 0, child: Text(h(ownerOpens), style: tick)),
                          PositionedDirectional(
                            start: at(t.peakFrom),
                            child: FractionalTranslation(
                              translation: const Offset(-0.5, 0),
                              child: Text(h(t.peakFrom), style: tick),
                            ),
                          ),
                          PositionedDirectional(
                            start: at(t.peakTo),
                            child: FractionalTranslation(
                              translation: const Offset(-1, 0),
                              child: Text(h(t.peakTo), style: tick),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: MuSpace.s4),
              MuSwitch(
                value: _weekendPeak,
                onChanged: (v) => setState(() => _weekendPeak = v),
                labelAtStart: true,
                icon: PhosphorIcons.calendarStar(),
                label: l10n.weekEndEnHeuresDe,
                description:
                    l10n.samediEtDimancheDeA(formatHour(ownerOpens * 60), formatHour(ownerCloses * 60)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Prix du terrain à l’heure ────────────────────────────────────────────────────────────────
  Widget _prices(Tariffs t) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(
          l10n.prixDuTerrainAL,
          lead: l10n.lesJoueursVoientLePrix(_players),
        ),
        MuCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, p) in t.prices.indexed) ...[
                if (i > 0) ...[
                  const SizedBox(height: MuSpace.s4),
                  Divider(height: 1, thickness: 1, color: c.border),
                  const SizedBox(height: MuSpace.s4),
                ],
                _courtPrices(p),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _courtPrices(CourtPrice p) {
    final c = context.mu;
    final title = p.courts.length == 1
        ? l10n.terrain4(p.courts.single)
        : l10n.terrainsEt(p.courts.take(p.courts.length - 1).join(', '), p.courts.last);
    final detail = p.indoor ? l10n.indoorCouvert : l10n.exterieurGazonSynthetiqueEclaires;
    final off = _offPeak[p.id]!;
    final peak = _peak[p.id]!;
    Widget field(String label, TextEditingController ctl) => MuTextField(
      label: label,
      controller: ctl,
      suffixText: l10n.dtH2,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
      helper: _perPlayer(ctl),
      error: _error(ctl),
      onChanged: (_) => setState(() {}),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: _Sizes.tile,
              height: _Sizes.tile,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.footballSoft, borderRadius: MuRadius.smAll),
              child: p.indoor
                  ? Icon(PhosphorIcons.umbrella(), size: MuSize.iconS, color: c.footballText)
                  : SvgPicture.asset(
                      MuGlyph.court,
                      width: MuSize.iconS,
                      height: MuSize.iconS,
                      excludeFromSemantics: true,
                      colorFilter: ColorFilter.mode(c.footballText, BlendMode.srcIn),
                    ),
            ),
            const SizedBox(width: MuSpace.s2 + MuSpace.s1 / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MuType.label.copyWith(color: c.text)),
                  Text(detail, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field(l10n.creuses, off)),
            const SizedBox(width: MuSpace.s3),
            Expanded(child: field(l10n.pointe, peak)),
          ],
        ),
      ],
    );
  }

  // ── Promotions ───────────────────────────────────────────────────────────────────────────────
  Widget _promotions(Tariffs t, int courtCount) {
    final c = context.mu;
    final p = _promo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(l10n.promotions),
        if (p == null)
          MuCardSurface(
            child: Text(
              t.promos.isEmpty
                  ? l10n.aucunePromotionEnCoursL
                  : [
                      for (final o in t.promos)
                        '${_promoTitle(o.draft)} · '
                            '${o.weekly ? _everyWeekday[o.draft.weekday - 1] : formatDay(o.firstDay)}',
                    ].join('\n'),
              style: MuType.body.copyWith(color: c.textSecondary),
            ),
          )
        else
          _promoCard(p, courtCount),
      ],
    );
  }

  Widget _promoCard(PromoDraft p, int courtCount) {
    final c = context.mu;
    final day = _promoDay(p);
    final slots = courtCount * (p.toHour - p.fromHour);
    final measured = slots * _weeksMeasured;
    final empty = (measured * _emptyShare).round();
    final when = _promoWeekly
        ? 'chaque ${_weekdays[p.weekday - 1].toLowerCase()}'
        : 'le ${formatDay(day)}';
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.ai500, width: _Sizes.aiRing),
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuAiLabel(size: MuAiLabelSize.s),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Text(
                  l10n.dApresTaSuggestion,
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ),
              _promoPublished
                  ? MuStatusBadge(
                      status: MuStatus.confirmed,
                      label: l10n.publiee,
                      size: MuBadgeSize.s,
                    )
                  : MuStatusBadge(
                      status: MuStatus.draft,
                      label: l10n.aConfirmer,
                      size: MuBadgeSize.s,
                    ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Text(_promoTitle(p), style: MuType.labelL.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s1),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s1,
            children: [
              Semantics(
                label: l10n.avant(formatDT(p.priceBefore)),
                excludeSemantics: true,
                child: Text(
                  formatDT(p.priceBefore),
                  style: MuType.numM.copyWith(
                    color: c.textSecondary,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: c.textSecondary,
                  ),
                ),
              ),
              Icon(
                PhosphorIcons.arrowRight(),
                size: MuSize.iconXs,
                color: c.textSecondary,
                semanticLabel: 'puis',
              ),
              Text(formatDT(p.priceAfter), style: MuType.numM.copyWith(color: c.text)),
              Text(
                l10n.soitPers(formatDT(p.priceAfter / _players)),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          MuSegmentedControl<bool>(
            semanticLabel: l10n.dureeDeLaPromo,
            size: MuSegmentedSize.s,
            expand: true,
            value: _promoWeekly,
            onChanged: _promoPublished ? (_) {} : (v) => setState(() => _promoWeekly = v),
            segments: [
              MuSegment(value: false, label: _capitalized(formatDay(day))),
              MuSegment(value: true, label: _everyWeekday[p.weekday - 1]),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Text(
            l10n.terrainsCreneauxRecommandeCarCreneaux(courtCount, slots, withFullStop(when), empty, measured, _weeksMeasured, _lastWeekdays[p.weekday - 1]),
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
          if (!_promoPublished) ...[
            const SizedBox(height: MuSpace.s3),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: MuButton.secondary(
                    label: l10n.retirer3,
                    fullWidth: true,
                    onPressed: _publishing ? null : () => setState(() => _promo = null),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  flex: 7,
                  child: MuButton.primary(
                    label: l10n.publierLaPromo,
                    fullWidth: true,
                    loading: _publishing,
                    onPressed: _publishing ? null : _publishPromo,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Ce que voient les joueurs ────────────────────────────────────────────────────────────────
  Widget _preview(Tariffs t) {
    final p = _promo;
    final day = p != null ? _promoDay(p) : DateTime(_now.year, _now.month, _now.day + 1);
    const from = 16;
    const to = 20;
    final bookings = ref.watch(ownerBookingsOnProvider(day)).value ?? const <OwnerBooking>[];
    final weekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    MuSlot slot(int court, int hour) {
      final booked = bookings.any(
        (b) => b.court == court && b.start.hour <= hour && b.end.hour > hour,
      );
      if (booked) return const MuSlot(status: MuSlotStatus.booked);
      final group = t.priceOf(court);
      final peakHour = (weekend && _weekendPeak) || (hour >= t.peakFrom && hour < t.peakTo);
      final base =
          (peakHour ? _parse(_peak[group.id]!) : _parse(_offPeak[group.id]!)) ??
          (peakHour ? group.peak : group.offPeak);
      if (p != null && hour >= p.fromHour && hour < p.toHour && !peakHour) {
        return MuSlot(price: base * (100 - p.percent) / 100, discount: p.percent, oldPrice: base);
      }
      return MuSlot(price: base, peak: peakHour);
    }

    final courts = ref.watch(ownerCourtsProvider).value ?? const <OwnerCourt>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(
          l10n.ceQueVoientLesJoueurs,
          lead: l10n.hHPrixDuTerrain(_capitalized(formatDay(day)), from, to),
        ),
        MuCardSurface(
          padding: const EdgeInsets.only(top: MuSpace.s3, bottom: MuSpace.s1),
          child: MuSlotGrid(
            legend: false,
            padding: 0,
            priceNote: l10n.terrains,
            start: from * 60,
            label: l10n.apercuJoueur(formatDay(day)),
            courts: [
              for (final court in courts)
                MuSlotCourt(
                  id: court.id,
                  name: l10n.terrain4(court.number),
                  detail: court.indoor ? l10n.indoor : l10n.exterieur,
                  icon: court.indoor ? PhosphorIcons.umbrella() : null,
                  iconLabel: court.indoor ? l10n.couvert : null,
                  slots: [for (var h = from; h < to; h++) slot(court.number, h)],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Dates spéciales ──────────────────────────────────────────────────────────────────────────
  Widget _specialDates(Tariffs t) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(
          l10n.datesSpeciales,
          action: MuButton.tertiary(
            label: l10n.ajouter,
            size: MuButtonSize.s,
            leading: PhosphorIcons.plus(),
            onPressed: () => showComingSoon(context),
          ),
        ),
        MuCardSurface(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s1),
          child: Column(
            children: [
              for (final (i, d) in t.specialDates.indexed) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: MuSize.controlXl),
                  child: Row(
                    children: [
                      Container(
                        width: _Sizes.dateTile,
                        padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: MuRadius.smAll,
                        ),
                        child: Column(
                          children: [
                            Text(
                              formatMonth(d.day).toUpperCase(),
                              style: MuType.overline.copyWith(color: c.textSecondary),
                            ),
                            Text('${d.day.day}', style: MuType.numM.copyWith(color: c.text)),
                          ],
                        ),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name, style: MuType.label.copyWith(color: c.text)),
                            const SizedBox(height: MuSpace.s1 / 2),
                            Row(
                              children: [
                                if (d.allDayPeak) ...[
                                  Icon(
                                    PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                                    size: _Sizes.icon14,
                                    color: c.warningText,
                                  ),
                                  const SizedBox(width: MuSpace.s1),
                                ],
                                Expanded(
                                  child: Text(
                                    d.allDayPeak
                                        ? l10n.pointeTouteLaJournee(formatDT(t.maxPrice))
                                        : l10n.pointe2(formatHour((d.fromHour ?? t.peakFrom) * 60), formatHour((d.toHour ?? t.peakTo) * 60), d.tentative ? l10n.datesAConfirmer : ''),
                                    style: MuType.caption.copyWith(color: c.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      MuIconButton(
                        icon: PhosphorIcons.pencilSimple(),
                        label: l10n.modifier3(d.name),
                        onPressed: () => showComingSoon(context),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// OWN-16 measures: the hours band 28 high with 2 px gaps, icon tiles 36, date tiles 44, the AI
/// ring 1,5 px, 14 px icons.
abstract final class _Sizes {
  static const double band = 28;
  static const double bandGap = 2;
  static const double tile = 36;
  static const double dateTile = 44;
  static const double aiRing = 1.5;
  static const double icon14 = 14;
}
