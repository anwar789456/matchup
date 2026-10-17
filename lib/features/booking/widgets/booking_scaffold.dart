import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/booking_controller.dart';
import '../../../l10n/l10n.dart';

/// The booking flow's steps (BKG-01 to BKG-04).
const int bookingSteps = 3;

/// A booking step: back with « Étape n sur 3 · title » beside it, the scrolling body and the sticky
/// bar. Without a picked slot (a reload, a stale link) it goes back to the venues.
class BookingStepScaffold extends ConsumerWidget {
  const BookingStepScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.body,
    required this.bottomBar,
    this.gap = MuSpace.s5,
  });

  final int step;
  final String title;
  final List<Widget> Function(BuildContext context, BookingDraft draft, PickedSlot slot) body;
  final List<Widget> bottomBar;
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final draft = ref.watch(bookingProvider);
    final slot = draft.slot;
    if (slot == null) return const BookingLost();
    final children = body(context, draft, slot);
    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s2, MuSpace.s2, MuSpace.s4, 0),
              child: Row(
                children: [
                  MuIconButton(
                    icon: PhosphorIcons.arrowLeft(),
                    label: l10n.retour,
                    size: MuIconButtonSize.l,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.venueSlots(slot.venue.venue.id)),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: MuStepIndicator(step: step, total: bookingSteps, title: title),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s6),
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) SizedBox(height: gap),
                  child,
                ],
              ],
            ),
          ),
          StickyActionBar(children: bottomBar),
        ],
      ),
    );
  }
}

/// No booking in progress: back to the venues.
class BookingLost extends StatelessWidget {
  const BookingLost({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MuSpace.s4),
          child: MuEmptyState(
            title: l10n.aucuneReservationEnCours,
            description: l10n.choisisUnTerrainEtUn,
            actions: [
              MuButton.primary(
                label: l10n.voirLesTerrains,
                onPressed: () => context.go(Routes.exploreVenues),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The slot being booked: court art, « Arena Five · Terrain 1 », date and time, court price and
/// the share per person.
class BookingSlotCard extends StatelessWidget {
  const BookingSlotCard({super.key, required this.slot, required this.share});

  final PickedSlot slot;
  final num share;

  // BKG-01: a 48 thumbnail.
  static const double _thumb = 48;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s3),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
      child: Row(
        children: [
          SizedBox.square(
            dimension: _thumb,
            child: ClipRRect(
              borderRadius: MuRadius.smAll,
              child: MuCourtArt(sport: slot.venue.venue.sport, variant: MuCourtArtVariant.pattern),
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.title, style: MuType.label.copyWith(color: c.text)),
                Text(
                  '${formatDay(slot.start)} · ${slot.timeRange}',
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatDT(slot.price), style: MuType.numM.copyWith(color: c.text)),
              Text(
                '${formatDT(share)} /pers.',
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A 40 icon tile for choice cards.
class BookingIconTile extends StatelessWidget {
  const BookingIconTile(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      width: MuSize.controlM,
      height: MuSize.controlM,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
      child: Icon(icon, size: MuSize.iconS, color: c.text),
    );
  }
}

/// A `space-4`-tall hairline between form groups.
class BookingRule extends StatelessWidget {
  const BookingRule({super.key});

  @override
  Widget build(BuildContext context) => Divider(height: 1, thickness: 1, color: context.mu.border);
}

/// « foot », « padel », « basket ».
String sportShort(MuSport s) => switch (s) {
  MuSport.football => 'foot',
  MuSport.padel => 'padel',
  MuSport.basketball => 'basket',
};
