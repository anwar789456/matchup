import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../booking/controllers/booking_controller.dart';
import '../data/venue_details.dart';
import '../widgets/venue_widgets.dart';

/// VEN-02 · Créneau choisi: the venue's days and slots; picking one raises the detail panel —
/// court and time, the court price and the price per person, the free cancellation date — with
/// « Continuer · 15 DT /pers. ».
class SlotScreen extends ConsumerStatefulWidget {
  const SlotScreen({super.key, required this.venueId});

  final String venueId;

  @override
  ConsumerState<SlotScreen> createState() => _SlotScreenState();
}

class _SlotScreenState extends ConsumerState<SlotScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(bookingProvider.notifier).openVenue(widget.venueId);
    });
  }

  Future<void> _continue(VenueDetails details, DayGrid grid) async {
    setState(() => _busy = true);
    await ref.read(bookingProvider.notifier).confirmSlot(details, grid);
    if (!mounted) return;
    setState(() => _busy = false);
    context.push(Routes.bookingType);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final details = ref.watch(venueDetailsProvider(widget.venueId)).value;
    final draft = ref.watch(bookingProvider);
    if (details == null) {
      return Scaffold(backgroundColor: c.surface, body: const SizedBox.shrink());
    }
    final v = details.venue;
    final schedule = ref.watch(dayScheduleProvider((v.id, draft.day))).value;
    final grid = schedule == null ? null : dayGrid(details, schedule, fullDay: draft.fullDay);
    final sel = draft.selection;

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: MuSpace.s16 * 5),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    MuSpace.s2,
                    MuSpace.s2,
                    MuSpace.s4,
                    MuSpace.s1,
                  ),
                  child: Row(
                    children: [
                      MuIconButton(
                        icon: PhosphorIcons.arrowLeft(),
                        label: 'Retour',
                        size: MuIconButtonSize.l,
                        onPressed: () =>
                            context.canPop() ? context.pop() : context.go(Routes.venue(v.id)),
                      ),
                      const SizedBox(width: MuSpace.s1),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(v.name, style: MuType.labelL.copyWith(color: c.text)),
                            ),
                            Text(
                              '${v.place} · ${countLabelFr(details.courts.length, 'terrain', 'terrains')}',
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (v.verified)
                        const MuStatusBadge(status: MuStatus.verified, size: MuBadgeSize.s),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                VenueSlotPicker(details: details, compact: true),
              ],
            ),
            if (sel != null && grid != null && sel.to <= grid.times.length)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _SlotSheet(
                  details: details,
                  grid: grid,
                  selection: sel,
                  busy: _busy,
                  onClose: () => ref.read(bookingProvider.notifier).select(null),
                  onContinue: () => _continue(details, grid),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// « 3 terrains », « 1 terrain ».
String countLabelFr(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// The non-modal detail panel of the picked slot (BottomSheet, auto height, no scrim).
class _SlotSheet extends StatelessWidget {
  const _SlotSheet({
    required this.details,
    required this.grid,
    required this.selection,
    required this.busy,
    required this.onClose,
    required this.onContinue,
  });

  final VenueDetails details;
  final DayGrid grid;
  final MuSlotRange selection;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final court = details.courts.firstWhere((x) => x.id == selection.courtId);
    final row = grid.courts.firstWhere((x) => x.id == selection.courtId);
    final runs = row.slots.sublist(selection.from, selection.to);
    final start = grid.times[selection.from];
    final end = grid.times[selection.to - 1].add(Duration(minutes: details.slotMinutes));
    final minutes = end.difference(start).inMinutes;
    final length = minutes % 60 == 0
        ? '${minutes ~/ 60} h'
        : '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
    final price = runs.fold<num>(0, (a, s) => a + (s.price ?? 0));
    final peak = runs.any((s) => s.peak);
    final share = price / details.players;
    final free = policyFor(start).freeUntil;
    final v = details.venue;

    return MuBottomSheet(
      title: '${capitalDay(start)} · ${formatTime(start)}',
      onClose: onClose,
      closeLabel: 'Fermer le détail du créneau',
      handleExpands: false,
      footer: MuButton.primary(
        label: 'Continuer',
        price: '${formatDT(share)} /pers.',
        size: MuButtonSize.xl,
        fullWidth: true,
        loading: busy,
        onPressed: busy ? null : onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${court.name} · ${formatTime(start)} – ${formatHour(end.hour * 60 + end.minute)} · '
            '$length · ${details.format}',
            style: MuType.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s2),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              if (court.lit)
                MuChip(label: 'Éclairé', icon: PhosphorIcons.lightbulb(), size: MuChipSize.s),
              MuChip(
                label: court.indoor ? 'Intérieur' : 'Extérieur',
                icon: court.indoor ? PhosphorIcons.umbrella() : PhosphorIcons.sun(),
                size: MuChipSize.s,
              ),
              if (v.amenities.contains(MuAmenity.changingRooms))
                MuChip(label: 'Vestiaires', icon: PhosphorIcons.coatHanger(), size: MuChipSize.s),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          VenuePriceBox(
            cells: [
              (
                'Terrain · $length',
                formatAmount(price),
                peak ? 'Heure de pointe' : 'Heure creuse',
                peak
                    ? Icon(
                        PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                        size: MuSize.iconXs,
                        color: c.warningText,
                      )
                    : null,
              ),
              ('Par personne', formatAmount(share), 'à ${details.players} joueurs', null),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIcons.checkCircle(), size: MuSize.iconXs, color: c.successText),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Annulation gratuite jusqu’au '),
                      TextSpan(
                        text: formatDateTime(free),
                        style: MuType.labelS.copyWith(color: c.text),
                      ),
                      const TextSpan(text: '. Ensuite 50 % remboursés jusqu’à 6 h avant.'),
                    ],
                  ),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
