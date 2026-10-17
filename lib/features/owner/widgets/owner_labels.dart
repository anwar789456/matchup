import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/owner_repository.dart';
import '../../../l10n/l10n.dart';

/// « 08h » on the planning's hour column.
String hourShort(int h) => '${(h % 24).toString().padLeft(2, '0')}h';

/// « 21h00 ».
String hourLong(int h) => formatHour((h % 24) * 60);

/// « Mer. 21 oct. ».
String capitalized(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String courtName(int n) => l10n.terrain4(n);

/// « Extérieur » / « Indoor ».
String courtKind(OwnerCourt c) => c.indoor ? l10n.indoor : l10n.exterieur;

/// Players who paid their share (« 9/10 payé »).
int paidShares(OwnerBooking b) =>
    b.capacity == 0 ? 0 : (b.paid / (b.price / b.capacity)).round().clamp(0, b.capacity);

/// The share of one player (« 15 DT »).
num shareOf(OwnerBooking b) => b.capacity == 0 ? b.price : b.price / b.capacity;

String blockReasonLabel(BlockReason r) => switch (r) {
  BlockReason.maintenance => l10n.entretien,
  BlockReason.privateEvent => l10n.evenementPrive,
  BlockReason.tournament => l10n.tournoi,
  BlockReason.weather => l10n.meteo,
  BlockReason.other => l10n.autre,
};

IconData? blockReasonIcon(BlockReason r) => switch (r) {
  BlockReason.maintenance => PhosphorIcons.plant(),
  BlockReason.privateEvent => PhosphorIcons.calendarStar(),
  BlockReason.tournament => PhosphorIcons.trophy(),
  BlockReason.weather => PhosphorIcons.cloudSun(),
  BlockReason.other => null,
};

/// The booking's status as a badge (OWN-12, OWN-14).
(MuStatus, String) bookingStatus(OwnerBooking b) => switch (b.status) {
  OwnerBookingStatus.confirmed => (MuStatus.confirmed, l10n.confirme2),
  OwnerBookingStatus.pendingPayment => (MuStatus.pending, l10n.paiementEnAttente2),
  OwnerBookingStatus.inProgress => (MuStatus.live, l10n.enCours2),
  OwnerBookingStatus.done => (MuStatus.neutral, l10n.termine),
  OwnerBookingStatus.noShow => (MuStatus.failed, l10n.noShow),
  OwnerBookingStatus.cancelled => (MuStatus.cancelled, l10n.annulee),
};

/// The planning cell of a booking (OWN-11). [hourIndex] is 0 for the first hour of a long booking.
MuPlanningCell bookingCell(
  BuildContext context,
  OwnerBooking b, {
  required int hourIndex,
  VoidCallback? onTap,
}) {
  final c = context.mu;
  final where = '${courtName(b.court)}, ${hourLong(b.start.hour + hourIndex)}';
  if (hourIndex > 0) {
    return MuPlanningCell(
      state: b.kind == OwnerBookingKind.public ? MuPlanningState.public : MuPlanningState.booked,
      title: b.organiser,
      meta: 'suite',
      semanticLabel: l10n.suite(where, b.organiser),
      onTap: onTap,
    );
  }
  switch (b.status) {
    case OwnerBookingStatus.done:
      return MuPlanningCell(
        state: MuPlanningState.done,
        title: b.organiser,
        meta: l10n.termine,
        metaIcon: PhosphorIcons.checkCircle(),
        semanticLabel: l10n.terminePaye(where, b.organiser),
        onTap: onTap,
      );
    case OwnerBookingStatus.noShow:
      return MuPlanningCell(
        state: MuPlanningState.noShow,
        title: b.organiser,
        meta: l10n.noShow,
        metaIcon: PhosphorIcons.prohibit(),
        semanticLabel: l10n.noShow4(where, b.organiser),
        onTap: onTap,
      );
    case OwnerBookingStatus.inProgress:
      return MuPlanningCell(
        state: b.kind == OwnerBookingKind.public ? MuPlanningState.public : MuPlanningState.booked,
        title: b.organiser,
        meta: l10n.enCours2,
        live: true,
        semanticLabel: l10n.enCours3(where, b.organiser),
        onTap: onTap,
      );
    case OwnerBookingStatus.cancelled:
    case OwnerBookingStatus.confirmed:
    case OwnerBookingStatus.pendingPayment:
      break;
  }
  if (b.mine) {
    return MuPlanningCell(
      state: MuPlanningState.mine,
      title: l10n.toi,
      meta: b.kind == OwnerBookingKind.public ? '${b.players}/${b.capacity} joueurs' : l10n.privee,
      metaIcon: b.kind == OwnerBookingKind.public ? PhosphorIcons.usersThree() : null,
      semanticLabel: l10n.taPartieSur(where, b.players, b.capacity),
      onTap: onTap,
    );
  }
  if (b.kind == OwnerBookingKind.public) {
    return MuPlanningCell(
      state: MuPlanningState.public,
      title: b.organiser,
      meta: '${b.players}/${b.capacity} joueurs',
      metaIcon: PhosphorIcons.usersThree(),
      semanticLabel: l10n.partiePubliqueDeSur(where, b.organiser, b.players, b.capacity),
      onTap: onTap,
    );
  }
  if (b.hours > 1) {
    return MuPlanningCell(
      state: MuPlanningState.booked,
      title: b.organiser,
      meta: '${hourShort(b.start.hour)} – ${hourShort(b.end.hour)}',
      semanticLabel: '$where, ${b.organiser}, ${hourLong(b.start.hour)} à ${hourLong(b.end.hour)}',
      onTap: onTap,
    );
  }
  if (!b.fullyPaid) {
    final n = paidShares(b);
    return MuPlanningCell(
      state: MuPlanningState.pendingPayment,
      title: b.organiser,
      meta: '$n/${b.capacity} payé',
      metaIcon: PhosphorIcons.clock(PhosphorIconsStyle.fill),
      metaIconColor: c.warningText,
      semanticLabel: l10n.surPaye(where, b.organiser, n, b.capacity),
      onTap: onTap,
    );
  }
  return MuPlanningCell(
    state: MuPlanningState.booked,
    title: b.organiser,
    meta: l10n.priveePaye,
    semanticLabel: '$where, ${b.organiser}',
    onTap: onTap,
  );
}
