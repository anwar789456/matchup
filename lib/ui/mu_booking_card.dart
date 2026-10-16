import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_avatar_stack.dart';
import 'mu_button.dart';
import 'mu_icon_button.dart';
import 'mu_skeleton.dart';
import 'mu_sport_icon.dart';
import 'mu_status_badge.dart';
import 'src/card_surface.dart';
import 'src/scoreboard_strip.dart';
import 'src/tone_badge.dart';

enum MuBookingStatus { upcoming, pendingPayment, past, cancelled }

/// A court booking as « Mes réservations » and the Home show it.
@immutable
class MuBooking {
  const MuBooking({
    required this.sport,
    required this.venue,
    required this.place,
    required this.start,
    required this.end,
    required this.share,
    this.id,
    this.court,
    this.status = MuBookingStatus.upcoming,
    this.payBefore,
    this.refund,
    this.players = const [],
  });

  /// The booking reference, « MU-48213 ».
  final String? id;
  final MuSport sport;
  final String venue;
  final String? court;
  final String place;
  final DateTime start;
  final DateTime end;

  /// The player's share, « 15 DT ».
  final num share;
  final MuBookingStatus status;

  /// Deadline of a pending payment (« À payer avant 17h00 »).
  final DateTime? payBefore;

  /// Refunded to the balance when cancelled.
  final num? refund;
  final List<MuPerson> players;

  String get title => court == null ? venue : '$venue · $court';

  /// « 20h00 – 21h30 ».
  String get timeRange => '${formatTime(start)} – ${formatTime(end)}';

  /// « 1 h », « 1 h 30 ».
  String get duration {
    final m = end.difference(start).inMinutes;
    final h = m ~/ 60;
    final rest = m % 60;
    if (h == 0) return '$rest min';
    return rest == 0 ? '$h h' : '$h h ${rest.toString().padLeft(2, '0')}';
  }
}

enum MuBookingCardVariant { standard, compact }

/// BookingCard (components/BookingCard.md): tear-off calendar tile, status, a strip with the time
/// range and your share, players, and the actions needed at the venue — the QR code last.
///
/// The status drives the badge, the second strip cell and the actions: upcoming (Confirmé, Payé,
/// QR), pending payment (« Payer ma part » replaces the QR), past (Terminé, « Noter les joueurs »),
/// cancelled (time struck through, REMBOURSÉ, « Réserver à nouveau »).
class MuBookingCard extends StatelessWidget {
  const MuBookingCard({
    super.key,
    required MuBooking this.booking,
    this.variant = MuBookingCardVariant.standard,
    this.onShowQr,
    this.onDirections,
    this.onMore,
    this.onPay,
    this.onRate,
    this.onRebook,
    this.onTap,
  }) : loading = false;

  /// The skeleton of a card in [variant] while bookings load.
  const MuBookingCard.loading({super.key, this.variant = MuBookingCardVariant.standard})
    : booking = null,
      loading = true,
      onShowQr = null,
      onDirections = null,
      onMore = null,
      onPay = null,
      onRate = null,
      onRebook = null,
      onTap = null;

  final MuBooking? booking;
  final MuBookingCardVariant variant;
  final VoidCallback? onShowQr;
  final VoidCallback? onDirections;
  final VoidCallback? onMore;
  final VoidCallback? onPay;
  final VoidCallback? onRate;
  final VoidCallback? onRebook;
  final VoidCallback? onTap;
  final bool loading;

  // BookingCard.md: tile 60 × 72 (compact 52 × 64); compact min-height 88.
  static const Size _tile = Size(60, 72);
  static const Size _tileCompact = Size(52, 64);
  static const double _minHeight = 88;

  // Skeleton block widths (HOM-02).
  static const double _skelStack = 80;
  static const double _skelAction = 104;

  bool get _compact => variant == MuBookingCardVariant.compact;

  String _semantics(MuBooking b) {
    final status = switch (b.status) {
      MuBookingStatus.upcoming => 'confirmé, payé',
      MuBookingStatus.pendingPayment => 'en attente de paiement',
      MuBookingStatus.past => 'terminé',
      MuBookingStatus.cancelled => 'annulé',
    };
    return '${b.title}, ${formatDay(b.start)}, ${b.timeRange}, ${b.sport.label}, ${b.place}, '
        '$status, ta part ${formatDT(b.share)}';
  }

  Widget _badge(MuBooking b, {bool small = false}) {
    final size = small ? MuBadgeSize.s : MuBadgeSize.m;
    return switch (b.status) {
      MuBookingStatus.upcoming => MuStatusBadge(status: MuStatus.confirmed, size: size),
      MuBookingStatus.pendingPayment => MuStatusBadge(status: MuStatus.pending, size: size),
      MuBookingStatus.cancelled => MuStatusBadge(status: MuStatus.cancelled, size: size),
      MuBookingStatus.past => MuToneBadge(
        label: 'Terminé',
        tone: MuBadgeTone.neutral,
        icon: PhosphorIcons.flag(PhosphorIconsStyle.fill),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return _Loading(compact: _compact);
    return _compact ? _buildCompact(context, booking!) : _buildStandard(context, booking!);
  }

  Widget _struck(MuBooking b, Widget child) => b.status == MuBookingStatus.cancelled
      ? DefaultTextStyle.merge(
          style: const TextStyle(decoration: TextDecoration.lineThrough),
          child: child,
        )
      : child;

  Widget _buildStandard(BuildContext context, MuBooking b) {
    final c = context.mu;
    final cancelled = b.status == MuBookingStatus.cancelled;

    final MuStripCell second = switch (b.status) {
      MuBookingStatus.cancelled => MuStripCell(
        label: 'Remboursé',
        value: MuScoreboardStrip.valueM(context, formatAmount(b.refund ?? b.share), 'DT'),
        sub: MuScoreboardStrip.sub(
          context,
          'sur ton solde',
          color: c.infoText,
          icon: PhosphorIcons.arrowUUpLeft(),
        ),
      ),
      MuBookingStatus.pendingPayment => MuStripCell(
        label: 'Ta part',
        value: MuScoreboardStrip.valueM(context, formatAmount(b.share), 'DT'),
        sub: MuScoreboardStrip.sub(
          context,
          b.payBefore == null ? 'À payer' : 'À payer avant ${formatTime(b.payBefore!)}',
          color: c.warningText,
          icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
        ),
      ),
      _ => MuStripCell(
        label: 'Ta part',
        value: MuScoreboardStrip.valueM(context, formatAmount(b.share), 'DT'),
        sub: MuScoreboardStrip.sub(
          context,
          'Payé',
          color: c.successText,
          icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        ),
      ),
    };

    final Widget action = switch (b.status) {
      MuBookingStatus.upcoming => MuIconButton(
        icon: PhosphorIcons.qrCode(),
        label: 'Afficher le QR code',
        variant: MuIconButtonVariant.inverse,
        onPressed: onShowQr,
      ),
      MuBookingStatus.pendingPayment => MuButton.primary(
        label: 'Payer ma part',
        price: formatDT(b.share),
        size: MuButtonSize.s,
        onPressed: onPay,
      ),
      MuBookingStatus.past => MuButton.secondary(
        label: 'Noter les joueurs',
        leading: PhosphorIcons.star(),
        size: MuButtonSize.s,
        onPressed: onRate,
      ),
      MuBookingStatus.cancelled => MuButton.tertiary(
        label: 'Réserver à nouveau',
        size: MuButtonSize.s,
        onPressed: onRebook,
      ),
    };
    // « Itinéraire » once paid: before that, « Payer ma part » takes the room.
    final showsDirections = b.status == MuBookingStatus.upcoming;

    return MuCardSurface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticLabel: _semantics(b),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalendarTile(booking: b, size: _tile, compact: false),
                const SizedBox(width: MuSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.labelL.copyWith(color: c.text),
                      ),
                      const SizedBox(height: MuSpace.s1),
                      Row(
                        children: [
                          MuSportIcon(b.sport, size: MuSize.iconXs, color: b.sport.text(c)),
                          const SizedBox(width: MuSpace.s1),
                          Expanded(
                            child: Text(
                              '${b.sport.label} · ${b.place}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MuType.body.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s2),
                      _badge(b),
                    ],
                  ),
                ),
              ],
            ),
          ),
          MuScoreboardStrip(
            semanticLabel: '${formatDay(b.start)}, ${b.timeRange}, ${b.duration}',
            cells: [
              MuStripCell(
                label: 'Horaire',
                value: _struck(
                  b,
                  MuScoreboardStrip.valueM(
                    context,
                    b.timeRange,
                    null,
                    cancelled ? c.textSecondary : null,
                  ),
                ),
                sub: MuScoreboardStrip.sub(context, b.duration),
              ),
              second,
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Row(
              children: [
                if (b.players.isNotEmpty)
                  MuAvatarStack(
                    people: b.players,
                    size: MuAvatarSize.xs,
                    semanticLabel: '${b.players.length} joueurs',
                  ),
                const Spacer(),
                if (showsDirections)
                  MuButton.secondary(
                    label: 'Itinéraire',
                    leading: PhosphorIcons.navigationArrow(),
                    size: MuButtonSize.s,
                    onPressed: onDirections,
                  ),
                MuIconButton(
                  icon: PhosphorIcons.dotsThree(),
                  label: 'Plus d’actions',
                  onPressed: onMore,
                ),
                action,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context, MuBooking b) {
    final c = context.mu;
    final String? statusLine = switch (b.status) {
      MuBookingStatus.upcoming => '${formatDT(b.share)} payés',
      MuBookingStatus.pendingPayment =>
        b.payBefore == null ? null : 'Avant ${formatTime(b.payBefore!)}',
      MuBookingStatus.cancelled when b.refund != null => '+${formatDT(b.refund!)} sur ton solde',
      _ => null,
    };
    final Widget? end = switch (b.status) {
      MuBookingStatus.upcoming => MuIconButton(
        icon: PhosphorIcons.qrCode(),
        label: 'Afficher le QR code',
        variant: MuIconButtonVariant.inverse,
        onPressed: onShowQr,
      ),
      MuBookingStatus.pendingPayment => MuButton.primary(
        label: 'Payer',
        price: formatDT(b.share),
        size: MuButtonSize.s,
        onPressed: onPay,
      ),
      _ => null,
    };

    return MuCardSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel: _semantics(b),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight - MuSpace.s3 * 2),
        child: Row(
          children: [
            _CalendarTile(booking: b, size: _tileCompact, compact: true),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MuType.label.copyWith(color: c.text),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  _struck(
                    b,
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: b.timeRange,
                            style: MuType.numXs.copyWith(color: c.text),
                          ),
                          TextSpan(
                            text: ' · ${b.place}',
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Wrap(
                    spacing: MuSpace.s2,
                    runSpacing: MuSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _badge(b, small: true),
                      if (statusLine != null)
                        Text(statusLine, style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            if (end != null) ...[const SizedBox(width: MuSpace.s3), end],
          ],
        ),
      ),
    );
  }
}

/// The tear-off calendar tile: weekday and month `overline` in `<sport>-text`, the day in `num-l`
/// (`num-m` compact) on `<sport>-soft`; muted when past or cancelled. Decorative: the date is read
/// with the card.
class _CalendarTile extends StatelessWidget {
  const _CalendarTile({required this.booking, required this.size, required this.compact});

  final MuBooking booking;
  final Size size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final b = booking;
    final muted = b.status == MuBookingStatus.past || b.status == MuBookingStatus.cancelled;
    final ink = muted ? c.textSecondary : b.sport.text(c);
    return ExcludeSemantics(
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: muted ? c.surfaceMuted : b.sport.soft(c),
          borderRadius: MuRadius.smAll,
          border: muted ? Border.all(color: c.border) : null,
        ),
        padding: const EdgeInsets.all(MuSpace.s1),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatWeekday(b.start).toUpperCase(),
                style: MuType.overline.copyWith(color: ink),
              ),
              Text(
                '${b.start.day}',
                style: (compact ? MuType.numM : MuType.numL).copyWith(color: c.text),
              ),
              Text(formatMonth(b.start).toUpperCase(), style: MuType.overline.copyWith(color: ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return MuCardSurface(
        padding: const EdgeInsets.all(MuSpace.s3),
        child: Row(
          children: [
            MuSkeleton(
              width: MuBookingCard._tileCompact.width,
              height: MuBookingCard._tileCompact.height,
            ),
            const SizedBox(width: MuSpace.s3),
            const Expanded(child: MuSkeleton.text(lines: 3)),
            const SizedBox(width: MuSpace.s3),
            const MuSkeleton.circle(size: MuSize.controlM),
          ],
        ),
      );
    }
    return MuCardSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Row(
              children: [
                MuSkeleton(width: MuBookingCard._tile.width, height: MuBookingCard._tile.height),
                const SizedBox(width: MuSpace.s4),
                const Expanded(child: MuSkeleton.text(lines: 3)),
              ],
            ),
          ),
          const MuScoreboardStrip(
            loading: true,
            cells: [
              MuStripCell(label: '', value: SizedBox.shrink()),
              MuStripCell(label: '', value: SizedBox.shrink()),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(MuSpace.s4),
            child: Row(
              children: [
                MuSkeleton.pill(width: MuBookingCard._skelStack, height: MuSize.iconM),
                Spacer(),
                MuSkeleton.pill(width: MuBookingCard._skelAction, height: MuSize.controlS),
                SizedBox(width: MuSpace.s2),
                MuSkeleton.circle(size: MuSize.controlM),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
