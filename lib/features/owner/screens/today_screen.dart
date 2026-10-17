import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/owner_drafts.dart';
import '../data/owner_repository.dart';
import '../data/revenue_repository.dart';
import '../data/review_highlights.dart';
import '../widgets/owner_header.dart';
import '../../../l10n/l10n.dart';

/// OWN-10 Aujourd’hui: the owner's home tab — the day's four KPIs, the next arrival with
/// « Scanner », the day's programme around « Maintenant », the AI price insight (it only
/// proposes: « Appliquer » opens OWN-16 prefilled), the next payout and the latest reviews.
class OwnerTodayScreen extends ConsumerWidget {
  const OwnerTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final now = ref.read(clockProvider)();
    final day = DateTime(now.year, now.month, now.day);
    final bookings = ref.watch(ownerBookingsOnProvider(day)).value;
    final blocks = ref.watch(ownerBlocksOnProvider(day)).value;
    final summary = ref.watch(ownerTodaySummaryProvider).value;
    final payouts = ref.watch(ownerPayoutsProvider).value;
    final reviews = ref.watch(ownerReviewHighlightsProvider).value;
    final courts = ref.watch(ownerCourtsProvider).value;

    final upcoming = [
      for (final b in bookings ?? const <OwnerBooking>[])
        if (b.start.isAfter(now)) b,
    ];
    final left = upcoming.length;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          OwnerHeader(
            title: l10n.aujourdHui2,
            actions: [
              MuIconButton(
                icon: PhosphorIcons.bell(),
                label: l10n.notificationsNonLues2,
                size: MuIconButtonSize.l,
                badge: 2,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MuSpace.s4,
                0,
                MuSpace.s4,
                MuSize.controlXl + MuSpace.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${_capitalize(formatDay(now))} · '),
                        TextSpan(
                          text: formatTime(now),
                          style: MuType.numS.copyWith(color: c.text),
                        ),
                        if (bookings != null && left > 0)
                          TextSpan(
                            text: l10n.encoreCeSoir(left, left == 1 ? 'match' : 'matchs'),
                          ),
                      ],
                    ),
                    style: MuType.body.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: MuSpace.s4),
                  _Kpis(summary: summary),
                  const SizedBox(height: _gap),
                  if (bookings == null)
                    const MuSkeleton(height: _nextSkeleton, radius: MuRadius.mdAll)
                  else if (upcoming.isNotEmpty)
                    _NextArrival(booking: upcoming.first),
                  const SizedBox(height: _gap),
                  _SectionHead(
                    title: l10n.programmeDuJour,
                    action: l10n.planning,
                    onAction: () => context.go(Routes.ownerPlanning),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  if (bookings == null || blocks == null)
                    const MuSkeleton(height: _programmeSkeleton, radius: MuRadius.mdAll)
                  else
                    _Programme(
                      now: now,
                      bookings: bookings,
                      blocks: blocks,
                      courts: courts?.length ?? 3,
                    ),
                  if (summary != null) ...[
                    const SizedBox(height: MuSpace.s2),
                    Text(
                      l10n.dejaEncaissesEnCoursDe(formatDT(summary.collected), formatDT(summary.inPayment)),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                  const SizedBox(height: _gap),
                  _PromoInsight(now: now, courts: courts?.length ?? 3),
                  const SizedBox(height: _gap),
                  if (payouts == null)
                    const MuSkeleton(height: _payoutSkeleton, radius: MuRadius.mdAll)
                  else
                    _PayoutCard(payouts: payouts),
                  const SizedBox(height: _gap),
                  _SectionHead(
                    title: l10n.derniersAvis,
                    action: l10n.tousLesAvis,
                    onAction: () => context.push(Routes.ownerReviews),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  if (reviews == null)
                    const MuSkeleton(height: _reviewsSkeleton, radius: MuRadius.mdAll)
                  else
                    _Reviews(reviews: reviews),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // OWN-10 source: 28 px between sections.
  static const double _gap = MuSpace.s6 + MuSpace.s1;

  // Skeleton heights, close to the loaded blocks.
  static const double _nextSkeleton = 88;
  static const double _programmeSkeleton = 320;
  static const double _payoutSkeleton = 72;
  static const double _reviewsSkeleton = 280;
}

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// « +6 », « −2 », « 0 ».
String _signed(int v) => v > 0 ? '+$v' : (v < 0 ? '−${-v}' : '0');

class _Kpis extends StatelessWidget {
  const _Kpis({required this.summary});

  final OwnerTodaySummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) {
      return const Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MuSkeleton(height: _tile, radius: MuRadius.mdAll),
              ),
              SizedBox(width: MuSpace.s3),
              Expanded(
                child: MuSkeleton(height: _tile, radius: MuRadius.mdAll),
              ),
            ],
          ),
          SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Expanded(
                child: MuSkeleton(height: _tile, radius: MuRadius.mdAll),
              ),
              SizedBox(width: MuSpace.s3),
              Expanded(
                child: MuSkeleton(height: _tile, radius: MuRadius.mdAll),
              ),
            ],
          ),
        ],
      );
    }
    final period = 'vs ${formatDay(s.compareTo)}';
    const pad = EdgeInsets.all(MuSpace.s4);
    Widget pair(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: MuSpace.s3),
          Expanded(child: b),
        ],
      ),
    );
    return Semantics(
      label: l10n.chiffresDuJour,
      container: true,
      child: Column(
        children: [
          pair(
            MuKpiCard(
              label: l10n.tauxDOccupation,
              value: '${s.occupancy} %',
              delta: s.occupancyDelta.toDouble(),
              deltaText: '${_signed(s.occupancyDelta)} pts',
              period: period,
              padding: pad,
            ),
            MuKpiCard(
              label: l10n.revenusDuJour,
              value: formatAmount(s.revenue),
              unit: dtUnit,
              delta: s.revenueDelta.toDouble(),
              deltaText: '${_signed(s.revenueDelta)} %',
              period: period,
              padding: pad,
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          pair(
            MuKpiCard(
              label: l10n.reservations,
              value: formatInt(s.bookings),
              delta: s.bookingsDelta.toDouble(),
              deltaText: _signed(s.bookingsDelta),
              period: period,
              padding: pad,
            ),
            MuKpiCard(
              label: l10n.noShows,
              value: formatInt(s.noShows),
              delta: s.noShowsDelta.toDouble(),
              deltaText: _signed(s.noShowsDelta),
              period: period,
              upIsGood: false,
              padding: pad,
            ),
          ),
        ],
      ),
    );
  }

  static const double _tile = 136;
}

/// The dark « Prochaine arrivée » card with the Volt « Scanner » (Night match emphasis card,
/// CLAUDE.md rule 13).
class _NextArrival extends StatelessWidget {
  const _NextArrival({required this.booking});

  final OwnerBooking booking;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? c.text : c.textInverse;
    final muted = MuType.caption.copyWith(color: ink.withValues(alpha: 0.72));
    final b = booking;
    final who = b.kind == OwnerBookingKind.public
        ? l10n.partiePubliqueJoueurs(b.players, b.capacity)
        : l10n.partiePriveeJoueurs(b.players);
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: dark ? c.night700 : c.surfaceInverse,
        borderRadius: MuRadius.mdAll,
        border: dark ? Border.all(color: c.border) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Row(
                      children: [
                        _Dot(color: c.error),
                        const SizedBox(width: MuSpace.s1 + MuSpace.s1 / 2),
                        Flexible(
                          child: Text(l10n.prochaineArrivee(formatTime(b.start)), style: muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MuSpace.s1 / 2),
                  Text(
                    l10n.terrain6(b.organiser, b.court),
                    style: MuType.labelL.copyWith(color: ink),
                  ),
                  const SizedBox(height: MuSpace.s1 / 2),
                  Text(who, style: muted),
                ],
              ),
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          MuNightTheme(
            child: MuButton.primary(
              label: l10n.scanner,
              leading: PhosphorIcons.qrCode(),
              onPressed: () => context.go(Routes.ownerCheckIn),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: MuSpace.s2,
    height: MuSpace.s2,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: MuType.h3.copyWith(color: c.text)),
          ),
        ),
        Transform.translate(
          // The tertiary button's padding hangs out of the column (`own-sec__head`).
          offset: Offset(
            Directionality.of(context) == TextDirection.rtl ? -MuSpace.s2 : MuSpace.s2,
            0,
          ),
          child: MuButton.tertiary(
            label: action,
            size: MuButtonSize.s,
            trailing: PhosphorIcons.caretRight(),
            onPressed: onAction,
          ),
        ),
      ],
    );
  }
}

enum _LineKind { booking, blocked, free }

class _Line {
  const _Line.booking(OwnerBooking this.booking)
    : kind = _LineKind.booking,
      court = 0,
      block = null;
  const _Line.blocked(OwnerBlock this.block) : kind = _LineKind.blocked, court = 0, booking = null;
  const _Line.free(this.court) : kind = _LineKind.free, booking = null, block = null;

  final _LineKind kind;
  final OwnerBooking? booking;
  final OwnerBlock? block;
  final int court;

  int get courtNumber => booking?.court ?? block?.court ?? court;
}

/// « Programme du jour »: past hours, « Maintenant », the next hour with its free courts, then
/// the rest of the evening summed up in one row.
class _Programme extends StatelessWidget {
  const _Programme({
    required this.now,
    required this.bookings,
    required this.blocks,
    required this.courts,
  });

  final DateTime now;
  final List<OwnerBooking> bookings;
  final List<OwnerBlock> blocks;
  final int courts;

  bool _covers(DateTime start, DateTime end, int hour) => start.hour <= hour && end.hour > hour;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final live = [
      for (final b in bookings)
        if (b.status != OwnerBookingStatus.cancelled) b,
    ];
    if (live.isEmpty && blocks.isEmpty) {
      return MuCardSurface(
        child: MuEmptyState(compact: true, title: l10n.aucuneReservationAujourdHui),
      );
    }
    final hours = [for (final b in live) b.start.hour, for (final b in blocks) b.start.hour];
    final ends = [
      for (final b in live) b.end.hour == 0 ? 24 : b.end.hour,
      for (final b in blocks) b.end.hour == 0 ? 24 : b.end.hour,
    ];
    final first = hours.reduce((a, b) => a < b ? a : b);
    final last = ends.reduce((a, b) => a > b ? a : b);
    final nowHour = now.hour;
    // Hours shown one by one: everything up to the next hour; the rest is summed up.
    final detailEnd = nowHour + 2;

    final rows = <Widget>[];
    for (var h = first; h < detailEnd && h < last; h++) {
      final lines = <_Line>[
        for (final b in live)
          if (b.start.hour == h) _Line.booking(b),
        for (final b in blocks)
          if (b.start.hour == h) _Line.blocked(b),
      ]..sort((a, b) => a.courtNumber - b.courtNumber);
      if (h > nowHour) {
        for (var court = 1; court <= courts; court++) {
          final taken =
              live.any((b) => b.court == court && _covers(b.start, b.end, h)) ||
              blocks.any((b) => b.court == court && _covers(b.start, b.end, h));
          if (!taken) lines.add(_Line.free(court));
        }
      }
      if (lines.isEmpty && h != nowHour) continue;
      rows.add(
        _Hour(
          time: formatHour(h * 60),
          past: h < nowHour,
          now: h == nowHour,
          children: [
            for (final l in lines)
              _LineRow(
                line: l,
                day: DateTime(now.year, now.month, now.day),
                hour: h,
                past: h < nowHour,
              ),
          ],
        ),
      );
    }

    if (last > detailEnd) {
      final rest = [
        for (final b in live)
          if (b.start.hour >= detailEnd) b,
      ];
      var free = 0;
      for (var h = detailEnd; h < last; h++) {
        for (var court = 1; court <= courts; court++) {
          final taken =
              live.any((b) => b.court == court && _covers(b.start, b.end, h)) ||
              blocks.any((b) => b.court == court && _covers(b.start, b.end, h));
          if (!taken) free++;
        }
      }
      final pending = rest.where((b) => b.status == OwnerBookingStatus.pendingPayment).length;
      final title =
          '${rest.length} ${rest.length == 1 ? l10n.reservation4 : l10n.reservations4} · '
          '$free ${free == 1 ? l10n.creneauLibre : l10n.creneauxLibres}';
      rows.add(
        _Hour(
          time: formatHour(detailEnd * 60),
          until: '– ${formatHour(last * 60)}',
          children: [
            _MoreRow(
              title: title,
              pending: pending == 0
                  ? null
                  : l10n.enAttente4(pending, pending == 1 ? 'paiement' : 'paiements'),
              onTap: () => context.go(Routes.ownerPlanning),
            ),
          ],
        ),
      );
    }

    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) ...[
              const SizedBox(height: MuSpace.s3),
              Divider(height: 1, thickness: 1, color: c.border),
              const SizedBox(height: MuSpace.s3),
            ],
            r,
          ],
        ],
      ),
    );
  }
}

class _Hour extends StatelessWidget {
  const _Hour({
    required this.time,
    required this.children,
    this.until,
    this.past = false,
    this.now = false,
  });

  final String time;
  final String? until;
  final bool past;
  final bool now;
  final List<Widget> children;

  // OWN-10 source: the time column is 52 wide.
  static const double _timeWidth = 52;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _timeWidth,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: MuSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: MuType.numS.copyWith(color: past ? c.textSecondary : c.text)),
                if (until != null)
                  Text(until!, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [if (now) const _NowMark(), ...children],
          ),
        ),
      ],
    );
  }
}

/// « Maintenant »: a red dot, the label and a rule across the column.
class _NowMark extends StatelessWidget {
  const _NowMark();

  // OWN-10 source: the now rule is 2 px.
  static const double _rule = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: MuSpace.s3, bottom: MuSpace.s1),
      child: Row(
        children: [
          _Dot(color: c.error),
          const SizedBox(width: MuSpace.s2),
          Text(l10n.maintenant, style: MuType.labelS.copyWith(color: c.errorText)),
          const SizedBox(width: MuSpace.s2),
          Expanded(
            child: Container(
              height: _rule,
              decoration: BoxDecoration(color: c.error, borderRadius: MuRadius.fullAll),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.day, required this.hour, required this.past});

  final _Line line;
  final DateTime day;
  final int hour;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final nameColor = past ? c.textSecondary : c.text;
    late final Widget name;
    late final Widget detail;
    Widget? badge;
    late final VoidCallback onTap;
    late final String semantics;
    switch (line.kind) {
      case _LineKind.booking:
        final b = line.booking!;
        final kind = b.kind == OwnerBookingKind.public ? l10n.publique2 : l10n.privee;
        final players = b.kind == OwnerBookingKind.public
            ? '${b.players}/${b.capacity} joueurs'
            : '${b.players} joueurs';
        final text = switch (b.status) {
          OwnerBookingStatus.done => l10n.termine6(kind),
          OwnerBookingStatus.noShow => l10n.personneAuCheckIn,
          _ => '$kind · $players',
        };
        final (MuStatus status, String? label) = switch (b.status) {
          OwnerBookingStatus.done => (MuStatus.paid, l10n.paye),
          OwnerBookingStatus.noShow => (MuStatus.failed, l10n.noShow),
          OwnerBookingStatus.inProgress => (MuStatus.live, l10n.enCours2),
          OwnerBookingStatus.pendingPayment => (MuStatus.pending, l10n.paiementEnAttente2),
          OwnerBookingStatus.cancelled => (MuStatus.cancelled, null),
          OwnerBookingStatus.confirmed => (MuStatus.confirmed, null),
        };
        name = Text(
          b.organiser,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MuType.label.copyWith(color: nameColor),
        );
        detail = Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: caption);
        badge = MuStatusBadge(status: status, label: label, size: MuBadgeSize.s);
        onTap = b.status == OwnerBookingStatus.noShow
            ? () => context.push(Routes.ownerNoShow(b.ref))
            : () => context.push(Routes.ownerBooking(b.ref));
        semantics = l10n.terrain7(b.court, b.organiser, text);
      case _LineKind.blocked:
        final block = line.block!;
        name = Row(
          children: [
            Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: nameColor),
            const SizedBox(width: MuSpace.s1),
            Text(l10n.bloque, style: MuType.label.copyWith(color: nameColor)),
          ],
        );
        detail = Text(
          block.note ?? l10n.creneauBloque,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: caption,
        );
        onTap = () => context.go(Routes.ownerPlanning);
        semantics = l10n.terrainBloque(block.court, block.note ?? '');
      case _LineKind.free:
        final price = slotPrice(hour);
        final perPlayer = formatDT(price / 10);
        name = Text(l10n.libre2, style: MuType.label.copyWith(color: c.textSecondary));
        detail = Row(
          children: [
            Icon(
              PhosphorIcons.lightning(PhosphorIconsStyle.fill),
              size: MuSize.iconXs,
              color: c.warningText,
            ),
            const SizedBox(width: MuSpace.s1),
            Flexible(child: Text(l10n.pers3(formatDT(price), perPlayer), style: caption)),
          ],
        );
        onTap = () => context.push(
          Routes.ownerBlock,
          extra: BlockPrefill(court: line.court, day: day, startHour: hour, endHour: hour + 1),
        );
        semantics = l10n.terrainLibre(line.court, formatDT(price));
    }
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: MuRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: MuSize.touchTarget),
          child: Row(
            children: [
              _CourtTag(number: line.courtNumber, free: line.kind == _LineKind.free),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [name, detail],
                ),
              ),
              if (badge != null) ...[const SizedBox(width: MuSpace.s2), badge],
            ],
          ),
        ),
      ),
    );
  }
}

/// « T1 »: the court tag; a free court has a dashed outline.
class _CourtTag extends StatelessWidget {
  const _CourtTag({required this.number, this.free = false});

  final int number;
  final bool free;

  // OWN-10 source (`own-tag`): min 28 × 22, 6 px side padding.
  static const double _minWidth = 28;
  static const double _height = 22;
  static const double _side = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final label = Text(
      'T$number',
      style: MuType.labelS.copyWith(color: free ? c.textSecondary : c.text),
    );
    final box = Container(
      constraints: const BoxConstraints(minWidth: _minWidth, minHeight: _height),
      padding: const EdgeInsets.symmetric(horizontal: _side),
      alignment: Alignment.center,
      decoration: free ? null : BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.xsAll),
      child: label,
    );
    if (!free) return box;
    return CustomPaint(
      painter: _DashedRect(color: c.borderStrong),
      child: box,
    );
  }
}

class _DashedRect extends CustomPainter {
  const _DashedRect({required this.color});

  final Color color;

  // A 1 px dashed outline, 3 on / 2 off.
  static const double _dash = 3;
  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          const Radius.circular(MuRadius.xs),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRect old) => old.color != color;
}

/// « 8 réservations · 1 créneau libre » — the rest of the evening.
class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.title, required this.onTap, this.pending});

  final String title;
  final String? pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: MuSpace.s1),
      child: Semantics(
        button: true,
        label: [title, ?pending].join(', '),
        excludeSemantics: true,
        child: Material(
          color: c.surfaceMuted,
          borderRadius: MuRadius.smAll,
          child: InkWell(
            onTap: onTap,
            borderRadius: MuRadius.smAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: MuSize.controlL),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s1),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: MuType.label.copyWith(color: c.text)),
                          if (pending != null)
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.clock(PhosphorIconsStyle.fill),
                                  size: MuSize.iconXs,
                                  color: c.warningText,
                                ),
                                const SizedBox(width: MuSpace.s1),
                                Flexible(
                                  child: Text(
                                    pending!,
                                    style: MuType.caption.copyWith(color: c.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    MuDirectionalIcon(
                      PhosphorIcons.caretRight(),
                      size: MuSize.iconS,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The AI's price insight. It only proposes: « Appliquer » opens OWN-16 with the promo filled
/// in, and nothing changes until the owner saves there; « Ignorer » hides it.
class _PromoInsight extends StatelessWidget {
  const _PromoInsight({required this.now, required this.courts});

  final DateTime now;
  final int courts;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    const promo = PromoDraft.thursdayAfternoon;
    final slots = courts * (promo.toHour - promo.fromHour);
    var next = DateTime(now.year, now.month, now.day + 1);
    while (next.weekday != promo.weekday) {
      next = DateTime(next.year, next.month, next.day + 1);
    }
    final secondary = MuType.caption.copyWith(color: c.textSecondary);
    return Semantics(
      label: l10n.suggestionDeLIa,
      container: true,
      explicitChildNodes: true,
      child: MuAiSuggestionCard(
        context: l10n.tarifs2(Story.arenaFive.name),
        title:
            l10n.jeudiHHDeCreneaux(promo.fromHour, promo.toHour, promo.percent),
        reason:
            l10n.surTesDerniersJeudisCreneaux(promo.fromHour, promo.toHour),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MuSpace.s2,
              children: [
                Text(
                  formatDT(promo.priceBefore),
                  semanticsLabel: l10n.avant(formatDT(promo.priceBefore)),
                  style: MuType.numM.copyWith(
                    color: c.textSecondary,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: c.textSecondary,
                  ),
                ),
                MuDirectionalIcon(
                  PhosphorIcons.arrowRight(),
                  size: MuSize.iconXs,
                  color: c.textSecondary,
                ),
                Text(
                  formatDT(promo.priceAfter),
                  semanticsLabel: l10n.apres(formatDT(promo.priceAfter)),
                  style: MuType.numM.copyWith(color: c.text),
                ),
                Text(l10n.soitPers(formatDT(promo.priceAfter / 10)), style: secondary),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            Text(
              l10n.terrainsCreneauxLesJoueursVoient(courts, slots, withFullStop(formatDay(next))),
              style: secondary,
            ),
          ],
        ),
        primary: MuAction(l10n.appliquer, () => context.push(Routes.ownerTariffs, extra: promo)),
        secondary: MuAction(l10n.ignorer, () {}),
        secondaryDismisses: true,
        onDismiss: () {},
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payouts});

  final OwnerPayouts payouts;

  // OWN-10 source: the bank tile is 40.
  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final next = formatDay(payouts.next.date);
    return MuCardSurface(
      semanticLabel: l10n.revenusProchainVersementVersLe(next),
      onTap: () => context.push(Routes.ownerRevenue),
      child: Row(
        children: [
          Container(
            width: _tile,
            height: _tile,
            decoration: BoxDecoration(color: c.successSoft, borderRadius: MuRadius.smAll),
            child: Icon(PhosphorIcons.bank(), size: MuSize.iconS, color: c.successText),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.versementPrevuVersLe(next), style: MuType.label.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s1 / 2),
                Text(
                  l10n.dernier(formatDT(payouts.last.amount), formatDay(payouts.last.date)),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          MuDirectionalIcon(PhosphorIcons.caretRight(), size: MuSize.iconS, color: c.textSecondary),
        ],
      ),
    );
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews({required this.reviews});

  final OwnerReviewHighlights reviews;

  // OWN-10 source: stars 16.
  static const double _star = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(formatLevel(reviews.average), style: MuType.numXl.copyWith(color: c.text)),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MuStarRating.display(value: reviews.average, size: _star, showValue: false),
                    const SizedBox(height: MuSpace.s1 / 2),
                    Text(
                      l10n.avisSansReponse3(formatInt(reviews.count), reviews.unanswered),
                      style: caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final r in reviews.latest) ...[
            const SizedBox(height: MuSpace.s4),
            Divider(height: 1, thickness: 1, color: c.border),
            const SizedBox(height: MuSpace.s4),
            _Review(review: r, star: _star),
          ],
        ],
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.review, required this.star});

  final OwnerReviewHighlight review;
  final double star;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = review;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return Semantics(
      container: true,
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
                    Text(l10n.terrain8(r.court, formatDay(r.date)), style: caption),
                  ],
                ),
              ),
              MuStarRating.display(value: r.stars.toDouble(), size: star, showValue: false),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Text('« ${r.text} »', style: MuType.body.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s2),
          if (r.answeredAt == null)
            Row(
              children: [
                MuStatusBadge(
                  status: MuStatus.pending,
                  label: l10n.sansReponse,
                  size: MuBadgeSize.s,
                ),
                const Spacer(),
                MuButton.secondary(
                  label: l10n.repondre,
                  size: MuButtonSize.s,
                  leading: PhosphorIcons.arrowBendUpLeft(),
                  onPressed: () => context.push(Routes.ownerReviews),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  size: MuSize.iconXs,
                  color: c.successText,
                ),
                const SizedBox(width: MuSpace.s1 + MuSpace.s1 / 2),
                Flexible(
                  child: Text(l10n.tuAsReponduLe(formatDay(r.answeredAt!)), style: caption),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
