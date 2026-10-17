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
import '../controllers/owner_controllers.dart';
import '../data/owner_drafts.dart';
import '../data/owner_repository.dart';
import '../widgets/block_form.dart';
import '../widgets/booking_detail.dart';
import '../widgets/owner_header.dart';
import '../widgets/owner_labels.dart';
import '../../../l10n/l10n.dart';

/// OWN-11 · Planning: Jour / Semaine, the 14-day strip, the legend and the grid (courts in
/// columns, hours in rows). A booking opens its sheet (OWN-12), a free slot the block sheet
/// (OWN-13), a no-show its report (OWN-24); long-press a free slot to block it.
class OwnerPlanningScreen extends ConsumerStatefulWidget {
  const OwnerPlanningScreen({super.key});

  @override
  ConsumerState<OwnerPlanningScreen> createState() => _OwnerPlanningScreenState();
}

class _OwnerPlanningScreenState extends ConsumerState<OwnerPlanningScreen> {
  (int, int)? _selected;

  Future<void> _openBooking(OwnerBooking b) async {
    setState(() => _selected = (b.court - 1, b.start.hour));
    await showOwnerBookingSheet(context, b);
    if (mounted) setState(() => _selected = null);
  }

  Future<void> _block(BlockPrefill prefill) async {
    final block = await showBlockSheet(context, prefill: prefill);
    if (block == null || !mounted) return;
    final n = block.end.difference(block.start).inHours;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: n == 1 ? l10n.creneauBloque : l10n.creneauxBloques,
      description:
          '${courtName(block.court)} · ${formatDay(block.start)} · ${hourLong(block.start.hour)} – ${hourLong(block.end.hour)}',
    );
  }

  Future<void> _openBlock(OwnerBlock block) async {
    final nav = Navigator.of(context, rootNavigator: true);
    final ok = await MuDialog.show<bool>(
      context,
      icon: PhosphorIcons.lockSimpleOpen(),
      title: l10n.debloquerCeCreneau,
      description:
          '${courtName(block.court)} · ${formatDay(block.start)} · ${hourLong(block.start.hour)} – ${hourLong(block.end.hour)} · ${block.note ?? blockReasonLabel(block.reason)}',
      consequence: l10n.lesJoueursPourrontDeNouveau,
      actions: [
        MuButton.secondary(
          label: l10n.garderBloque,
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: () => nav.pop(false),
        ),
        MuButton.primary(
          label: l10n.debloquer,
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: () => nav.pop(true),
        ),
      ],
    );
    if (ok != true || !mounted) return;
    await ref.read(ownerActionsProvider).unblock(block.id);
    if (!mounted) return;
    MuToast.show(context, tone: MuToastTone.success, title: l10n.creneauDebloque);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final today = dayOf(now);
    final day = ref.watch(ownerPlanningDayProvider);
    final view = ref.watch(ownerPlanningViewProvider);
    final courts = ref.watch(ownerCourtsProvider).value;
    final bookings = ref.watch(ownerBookingsOnProvider(day)).value;
    final blocks = ref.watch(ownerBlocksOnProvider(day)).value;
    final visibleCourts = courts?.where((x) => x.visible).toList();
    final stats = bookings == null || visibleCourts == null
        ? ''
        : '${occupancy(bookings.length, visibleCourts.length)} %${blocks == null || blocks.isEmpty ? '' : ' · ${blocks.length} ${blocks.length == 1 ? l10n.bloque2 : l10n.bloques}'}';

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerHeader(
            title: l10n.planning,
            actions: [
              MuButton.secondary(
                label: l10n.bloquer2,
                leading: PhosphorIcons.lockSimple(),
                size: MuButtonSize.s,
                onPressed: () => _block(BlockPrefill(day: day)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              MuSpace.s4,
              MuSpace.s1,
              MuSpace.s4,
              MuSpace.s2 + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    MuSegmentedControl<PlanningView>(
                      semanticLabel: l10n.vueDuPlanning,
                      size: MuSegmentedSize.s,
                      segments: [
                        MuSegment(value: PlanningView.day, label: l10n.jour),
                        MuSegment(value: PlanningView.week, label: l10n.semaine),
                      ],
                      value: view,
                      onChanged: ref.read(ownerPlanningViewProvider.notifier).set,
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: bookings == null
                          ? const SizedBox.shrink()
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: bookings.length == 1
                                        ? l10n.reservation3
                                        : l10n.reservations2(bookings.length),
                                    style: MuType.labelS.copyWith(color: c.text),
                                  ),
                                  TextSpan(text: ' · $stats'),
                                ],
                              ),
                              textAlign: TextAlign.end,
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                    ),
                  ],
                ),
                if (view == PlanningView.day) ...[
                  const SizedBox(height: MuSpace.s2 + 2),
                  MuDateStrip(
                    start: today,
                    today: today,
                    value: day,
                    label: l10n.jourDuPlanning,
                    onChanged: ref.read(ownerPlanningDayProvider.notifier).set,
                  ),
                  const SizedBox(height: MuSpace.s2 + 2),
                  const _Legend(),
                ],
              ],
            ),
          ),
          Expanded(
            child: view == PlanningView.week
                ? _WeekView(from: today)
                : courts == null || bookings == null || blocks == null
                ? Center(child: MuSpinner(semanticLabel: l10n.chargementDuPlanning))
                : _grid(context, visibleCourts!, bookings, blocks, day, now),
          ),
        ],
      ),
    );
  }

  Widget _grid(
    BuildContext context,
    List<OwnerCourt> courts,
    List<OwnerBooking> bookings,
    List<OwnerBlock> blocks,
    DateTime day,
    DateTime now,
  ) {
    final hours = [for (var h = ownerOpens; h < ownerCloses; h++) h];
    OwnerBooking? bookingAt(int court, int hour) => bookings
        .where((b) => b.court == court && b.start.hour <= hour && b.end.hour > hour)
        .firstOrNull;
    OwnerBlock? blockAt(int court, int hour) => blocks
        .where(
          (b) =>
              b.court == court &&
              b.start.hour <= hour &&
              (b.end.hour > hour || (b.end.day != b.start.day && b.end.hour == 0)),
        )
        .firstOrNull;
    final busy = [
      for (final h in hours)
        if (courts.any((x) => bookingAt(x.number, h) != null || blockAt(x.number, h) != null)) h,
    ];
    final first = busy.isEmpty ? null : busy.first;
    final isToday = dayOf(now) == day;
    final dayLabel = formatDay(day);

    return MuPlanningGrid(
      label: l10n.planning2(Story.arenaFive.name, dayLabel),
      columns: [
        for (final x in courts)
          MuPlanningColumn(
            name: courtName(x.number),
            detail: courtKind(x),
            icon: x.indoor ? PhosphorIcons.umbrella() : null,
          ),
      ],
      hours: hours,
      hourLabel: hourShort,
      now: isToday ? now : null,
      foldBefore: first != null && first > ownerOpens ? first : null,
      foldLabel: first == null
          ? null
          : l10n.aucuneReservation(hourLong(ownerOpens), hourLong(first)),
      selected: _selected,
      cellAt: (i, h) {
        final court = courts[i].number;
        final where = '${courtName(court)}, ${hourLong(h)}';
        final b = bookingAt(court, h);
        if (b != null) {
          final noShow = b.status == OwnerBookingStatus.noShow;
          return bookingCell(
            context,
            b,
            hourIndex: h - b.start.hour,
            onTap: noShow ? () => context.push(Routes.ownerNoShow(b.ref)) : () => _openBooking(b),
          );
        }
        final block = blockAt(court, h);
        if (block != null) {
          return MuPlanningCell(
            state: MuPlanningState.blocked,
            title: l10n.bloque,
            meta: block.shortNote ?? blockReasonLabel(block.reason),
            semanticLabel:
                l10n.bloque3(where, (block.shortNote ?? blockReasonLabel(block.reason)).toLowerCase()),
            onTap: () => _openBlock(block),
          );
        }
        final past =
            day.add(Duration(hours: h + 1)).isBefore(now) || day.add(Duration(hours: h + 1)) == now;
        final price = slotPrice(h);
        if (past) {
          return MuPlanningCell(
            state: MuPlanningState.free,
            title: l10n.libre2,
            dimmed: true,
            semanticLabel: l10n.creneauPasseLibre(where),
          );
        }
        final prefill = BlockPrefill(court: court, day: day, startHour: h, endHour: h + 1);
        return MuPlanningCell(
          state: MuPlanningState.free,
          title: l10n.libre2,
          meta: formatDT(price),
          peak: isPeak(h),
          semanticLabel: l10n.libreAppuiLongPourBloquer(where, formatDT(price)),
          onTap: () => _block(prefill),
          onLongPress: () => _block(prefill),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  // OWN-11 legend keys: 14 × 10.
  static const Size _key = Size(14, 10);

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final style = MuType.caption.copyWith(color: c.textSecondary);
    Widget key(MuPlanningState s, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.fromSize(
          size: _key,
          child: MuPlanningKey(state: s),
        ),
        const SizedBox(width: MuSpace.s1 + 1),
        Text(label, style: style),
      ],
    );
    return Semantics(
      container: true,
      label: l10n.legende,
      child: Wrap(
        spacing: MuSpace.s3,
        runSpacing: MuSpace.s1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          key(MuPlanningState.booked, l10n.privee),
          key(MuPlanningState.public, l10n.publique2),
          key(MuPlanningState.free, l10n.libre2),
          key(MuPlanningState.blocked, l10n.bloque),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                size: 12,
                color: c.warningText,
              ),
              const SizedBox(width: MuSpace.s1 + 1),
              Text(l10n.pointe, style: style),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.handPointing(), size: 14, color: c.text),
              const SizedBox(width: MuSpace.s1 + 1),
              Text(l10n.appuiLongSurUnCreneau, style: style),
            ],
          ),
        ],
      ),
    );
  }
}

/// « Semaine »: the next seven days, their bookings and occupancy; a day opens its grid.
class _WeekView extends ConsumerWidget {
  const _WeekView({required this.from});

  final DateTime from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final all = ref.watch(ownerUpcomingProvider(from)).value;
    final courts = ref.watch(ownerCourtsProvider).value?.where((x) => x.visible).length ?? 0;
    if (all == null) {
      return Center(child: MuSpinner(semanticLabel: l10n.chargementDeLaSemaine));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 120),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: MuSpace.s2),
      itemBuilder: (context, i) {
        final d = DateTime(from.year, from.month, from.day + i);
        final n = all
            .where((b) => dayOf(b.start) == d && b.status != OwnerBookingStatus.cancelled)
            .length;
        final pct = occupancy(n, courts);
        return MuCardSurface(
          semanticLabel: l10n.reservations3(formatDay(d), n, pct),
          onTap: () {
            ref.read(ownerPlanningDayProvider.notifier).set(d);
            ref.read(ownerPlanningViewProvider.notifier).set(PlanningView.day);
          },
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  i == 0 ? l10n.auj : capitalized(formatDay(d)),
                  style: MuType.label.copyWith(color: c.text),
                ),
              ),
              Expanded(
                child: MuProgressBar(value: pct.toDouble(), showValue: false),
              ),
              const SizedBox(width: MuSpace.s3),
              SizedBox(
                width: 96,
                child: Text(
                  l10n.resa(n, pct),
                  textAlign: TextAlign.end,
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
