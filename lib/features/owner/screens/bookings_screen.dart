import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../core/search.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_header.dart';
import '../../../l10n/l10n.dart';

/// The list filters of OWN-14.
enum OwnerBookingFilter { upcoming, pendingPayment, done, cancelled, noShow }

/// OWN-14 · Réservations: search (name, MU-… reference), filter chips, then the bookings grouped
/// by day with their status; a row opens the booking (OWN-12).
class OwnerBookingsScreen extends ConsumerStatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  ConsumerState<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen> {
  final _search = TextEditingController();
  var _filter = OwnerBookingFilter.upcoming;
  var _nearestFirst = true;
  final _expanded = <DateTime>{};

  /// A day shows this many rows, then « Voir les N autres ».
  static const _folded = 4;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isUpcoming(OwnerBooking b, DateTime now) =>
      b.start.isAfter(now) &&
      b.status != OwnerBookingStatus.cancelled &&
      b.status != OwnerBookingStatus.noShow &&
      b.status != OwnerBookingStatus.done;

  bool _matchesFilter(OwnerBooking b, OwnerBookingFilter f, DateTime now) => switch (f) {
    OwnerBookingFilter.upcoming => _isUpcoming(b, now),
    OwnerBookingFilter.pendingPayment =>
      _isUpcoming(b, now) && b.status == OwnerBookingStatus.pendingPayment,
    OwnerBookingFilter.done => b.status == OwnerBookingStatus.done,
    OwnerBookingFilter.cancelled => b.status == OwnerBookingStatus.cancelled,
    OwnerBookingFilter.noShow => b.status == OwnerBookingStatus.noShow,
  };

  static bool _matchesQuery(OwnerBooking b, String query) {
    final q = foldAccents(query.trim());
    if (q.isEmpty) return true;
    return foldAccents(b.organiser).contains(q) ||
        foldAccents(b.ref).contains(q) ||
        foldAccents(b.ref.replaceAll('MU-', '')).contains(q) ||
        (b.note != null && foldAccents(b.note!).contains(q));
  }

  String _summary(int n) => switch (_filter) {
    OwnerBookingFilter.upcoming => n == 1 ? l10n.reservationAVenir : l10n.reservationsAVenir,
    OwnerBookingFilter.pendingPayment => n == 1 ? l10n.paiementEnAttente : l10n.paiementsEnAttente,
    OwnerBookingFilter.done => n == 1 ? l10n.reservationTerminee : l10n.reservationsTerminees,
    OwnerBookingFilter.cancelled => n == 1 ? l10n.reservationAnnulee2 : l10n.reservationsAnnulees,
    OwnerBookingFilter.noShow => n == 1 ? 'no-show' : 'no-shows',
  };

  String _dayTitle(DateTime day, DateTime now) {
    final today = _day(now);
    final label = formatDay(day);
    if (day == today) {
      return _filter == OwnerBookingFilter.upcoming ? l10n.ceSoir3(label) : l10n.aujourdHui4(label);
    }
    if (day == today.add(const Duration(days: 1))) return l10n.demain(label);
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.read(clockProvider)();
    final all = ref.watch(ownerUpcomingProvider(_day(now))).value;
    final courts = ref.watch(ownerCourtsProvider).value;

    int count(OwnerBookingFilter f) => all?.where((b) => _matchesFilter(b, f, now)).length ?? 0;

    final query = _search.text;
    final shown = [
      for (final b in all ?? const <OwnerBooking>[])
        if (_matchesFilter(b, _filter, now) && _matchesQuery(b, query)) b,
    ];
    final days = <DateTime, List<OwnerBooking>>{};
    for (final b in shown) {
      days.putIfAbsent(_day(b.start), () => []).add(b);
    }
    final order = days.keys.toList()
      ..sort((a, b) => _nearestFirst ? a.compareTo(b) : b.compareTo(a));
    if (!_nearestFirst) {
      for (final list in days.values) {
        list.sort((a, b) => b.start.compareTo(a.start));
      }
    }

    Widget chip(OwnerBookingFilter f, String label, {bool counted = false}) => MuChip(
      kind: MuChipKind.choice,
      label: label,
      selected: _filter == f,
      count: counted && all != null ? count(f) : null,
      onSelected: (_) => setState(() {
        _filter = f;
        _expanded.clear();
      }),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerHeader(
            title: l10n.reservations,
            actions: [
              MuIconButton(
                icon: PhosphorIcons.downloadSimple(),
                label: l10n.exporterLesReservationsCsv,
                size: MuIconButtonSize.l,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              MuSpace.s4,
              MuSpace.s1,
              MuSpace.s4,
              MuSpace.s3,
            ),
            child: MuSearchField<String>(
              label: l10n.rechercherUneReservation,
              placeholder: l10n.nomRefMuTelephone,
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Semantics(
            container: true,
            label: l10n.filtrerLesReservations,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Row(
                children: [
                  for (final (i, w) in [
                    MuChip(
                      label: l10n.filtres,
                      icon: PhosphorIcons.slidersHorizontal(),
                      onSelected: (_) => showComingSoon(context),
                    ),
                    chip(OwnerBookingFilter.upcoming, l10n.aVenir, counted: true),
                    chip(OwnerBookingFilter.pendingPayment, l10n.paiementEnAttente2, counted: true),
                    chip(OwnerBookingFilter.done, l10n.terminees),
                    chip(OwnerBookingFilter.cancelled, l10n.annulees),
                    chip(OwnerBookingFilter.noShow, l10n.noShows),
                  ].indexed) ...[if (i > 0) const SizedBox(width: MuSpace.s2), w],
                ],
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Expanded(
            child: all == null
                ? const Center(child: MuSpinner())
                : ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      MuSpace.s4,
                      MuSpace.s1,
                      MuSpace.s4,
                      MuSpace.s16 + MuSpace.s10,
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${shown.length}', style: MuType.numS),
                                  TextSpan(text: ' ${_summary(shown.length)} '),
                                  if (courts != null)
                                    TextSpan(
                                      text: l10n.terrains3(courts.length),
                                      style: TextStyle(color: c.textSecondary),
                                    ),
                                ],
                              ),
                              style: MuType.label.copyWith(color: c.text),
                            ),
                          ),
                          Semantics(
                            label: _nearestFirst
                                ? l10n.trierParDateLaPlus
                                : l10n.trierParDateLaPlus2,
                            excludeSemantics: true,
                            button: true,
                            child: MuButton.tertiary(
                              label: l10n.date,
                              size: MuButtonSize.s,
                              leading: PhosphorIcons.arrowsDownUp(),
                              onPressed: () => setState(() => _nearestFirst = !_nearestFirst),
                            ),
                          ),
                        ],
                      ),
                      if (shown.isEmpty) ...[
                        const SizedBox(height: MuSpace.s8),
                        MuEmptyState(
                          illustration: MuEmptyIllustration.bookings,
                          compact: true,
                          title: query.trim().isEmpty
                              ? l10n.aucuneReservationIci
                              : l10n.aucuneReservationPour(query.trim()),
                          description: l10n.essaieUnAutreFiltreOu,
                        ),
                      ],
                      for (final day in order) ...[
                        const SizedBox(height: MuSpace.s6),
                        _DayGroup(
                          title: _dayTitle(day, now),
                          count: _filter == OwnerBookingFilter.upcoming && day == _day(now)
                              ? l10n.aVenir5(days[day]!.length)
                              : days[day]!.length == 1
                              ? l10n.reservation3
                              : l10n.reservations2(days[day]!.length),
                          bookings: days[day]!,
                          folded:
                              query.trim().isEmpty &&
                              !_expanded.contains(day) &&
                              days[day]!.length > _folded + 1,
                          foldedCount: _folded,
                          moreLabel: day == _day(now)
                              ? l10n.voirLesAutresDeCe(days[day]!.length - _folded)
                              : l10n.voirLesAutres(days[day]!.length - _folded),
                          onMore: () => setState(() => _expanded.add(day)),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// One day: its overline and count, then a card of rows.
class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.title,
    required this.count,
    required this.bookings,
    required this.folded,
    required this.foldedCount,
    required this.moreLabel,
    required this.onMore,
  });

  final String title;
  final String count;
  final List<OwnerBooking> bookings;
  final bool folded;
  final int foldedCount;
  final String moreLabel;
  final VoidCallback onMore;

  // OWN-14: the « Voir les … autres » row is 52 high.
  static const double _moreHeight = 52;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final rows = folded ? bookings.take(foldedCount).toList() : bookings;
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: MuSpace.s6,
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title.toUpperCase(),
                      style: MuType.overline.copyWith(color: c.textSecondary),
                    ),
                  ),
                ),
                Text(count, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          MuCardSurface(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: MuRadius.mdAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, b) in rows.indexed) ...[
                    if (i > 0) const _Rule(),
                    OwnerBookingRow(booking: b),
                  ],
                  if (folded) ...[
                    const _Rule(),
                    InkWell(
                      onTap: onMore,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: _moreHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(moreLabel, style: MuType.label.copyWith(color: c.text)),
                              ),
                              Icon(
                                PhosphorIcons.caretDown(),
                                size: MuSize.iconS,
                                color: c.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: MuSpace.s4),
    child: Divider(height: 1, thickness: 1, color: context.mu.border),
  );
}

/// One booking of OWN-14: time and length, organiser, court, kind, reference and price, status.
class OwnerBookingRow extends StatelessWidget {
  const OwnerBookingRow({super.key, required this.booking});

  final OwnerBooking booking;

  // OWN-14: rows 76 high, the time column 44 wide, the court tag 18 high (padding 6), icons 14.
  static const double _minHeight = 76;
  static const double _timeWidth = 44;
  static const double _tagHeight = 18;
  static const double _tagMinWidth = 24;
  static const double _tagPad = 6;
  static const double _kindIcon = 14;

  /// « Publique · 8/10 » or « Privée ».
  static String kindLabel(OwnerBooking b) =>
      b.kind == OwnerBookingKind.public ? l10n.publique3(b.players, b.capacity) : l10n.privee;

  /// The badge of a booking: public games are confirmed (or full), private ones paid or
  /// « 9/10 payé ».
  static MuStatusBadge badge(OwnerBooking b) {
    MuStatusBadge s(MuStatus status, [String? label]) =>
        MuStatusBadge(status: status, label: label, size: MuBadgeSize.s);
    return switch (b.status) {
      OwnerBookingStatus.cancelled => s(MuStatus.cancelled, l10n.annulee),
      OwnerBookingStatus.noShow => s(MuStatus.failed, l10n.noShow),
      OwnerBookingStatus.done => s(MuStatus.neutral, l10n.terminee),
      OwnerBookingStatus.inProgress => s(MuStatus.live, l10n.enCours2),
      _ when b.kind == OwnerBookingKind.public =>
        b.players >= b.capacity ? s(MuStatus.full) : s(MuStatus.confirmed),
      _ when b.fullyPaid => s(MuStatus.paid),
      _ => s(MuStatus.pending, '${(b.paid / b.price * b.capacity).floor()}/${b.capacity} payé'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final b = booking;
    final secondary = MuType.caption.copyWith(color: c.textSecondary);
    final amount = b.fullyPaid
        ? formatDT(b.price)
        : '${formatAmount(b.paid)} / ${formatDT(b.price)}';
    return Semantics(
      button: true,
      label: l10n.tRef(formatTime(b.start), b.court, b.organiser, kindLabel(b), b.ref),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(Routes.ownerBooking(b.ref)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s2),
            child: Row(
              children: [
                SizedBox(
                  width: _timeWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatTime(b.start), style: MuType.numM.copyWith(color: c.text)),
                      Text('${b.hours} h', style: secondary),
                    ],
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              b.organiser,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MuType.label.copyWith(color: c.text),
                            ),
                          ),
                          if (b.mine) ...[
                            const SizedBox(width: MuSpace.s1),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: _tagPad),
                              decoration: BoxDecoration(
                                color: c.surfaceInverse,
                                borderRadius: MuRadius.fullAll,
                              ),
                              child: Text(
                                l10n.toi,
                                style: MuType.labelS.copyWith(color: c.textInverse),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: MuSpace.s1 / 2),
                      Row(
                        children: [
                          Container(
                            height: _tagHeight,
                            constraints: const BoxConstraints(minWidth: _tagMinWidth),
                            padding: const EdgeInsets.symmetric(horizontal: _tagPad),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.surfaceMuted,
                              borderRadius: MuRadius.xsAll,
                            ),
                            child: Text(
                              'T${b.court}',
                              style: MuType.labelS.copyWith(color: c.text),
                            ),
                          ),
                          const SizedBox(width: MuSpace.s1),
                          Icon(
                            b.kind == OwnerBookingKind.public
                                ? PhosphorIcons.usersThree()
                                : PhosphorIcons.lockSimple(),
                            size: _kindIcon,
                            color: c.textSecondary,
                          ),
                          const SizedBox(width: MuSpace.s1),
                          Flexible(
                            child: Text(
                              kindLabel(b),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s1 / 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: b.ref,
                              style: MuType.numXs.copyWith(color: c.text),
                            ),
                            TextSpan(text: ' · ${b.note ?? amount}'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                badge(b),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
