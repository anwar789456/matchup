import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/owner_controllers.dart';
import '../data/owner_drafts.dart';
import '../data/owner_repository.dart';
import 'owner_labels.dart';
import '../../../l10n/l10n.dart';

/// OWN-13 as a sheet over the planning. Returns the block when one was saved.
Future<OwnerBlock?> showBlockSheet(BuildContext context, {BlockPrefill? prefill}) {
  final key = GlobalKey<BlockFormState>();
  return MuBottomSheet.show<OwnerBlock>(
    context,
    title: l10n.bloquerUnCreneau,
    height: MuSheetHeight.full,
    snapPoints: const [MuSheetHeight.full],
    child: BlockForm(key: key, prefill: prefill),
    footer: BlockFormFooter(formKey: key),
  );
}

/// The form of OWN-13: courts, day, time range (or all day), reason, note, weekly repeat.
class BlockForm extends ConsumerStatefulWidget {
  const BlockForm({super.key, this.prefill, this.onSaved});

  final BlockPrefill? prefill;

  /// Called after saving; defaults to closing the sheet with the block.
  final ValueChanged<OwnerBlock>? onSaved;

  @override
  ConsumerState<BlockForm> createState() => BlockFormState();
}

class BlockFormState extends ConsumerState<BlockForm> {
  late Set<int> _courts;
  late DateTime _day;
  late int _from;
  late int _to;
  bool _allDay = false;
  BlockReason _reason = BlockReason.maintenance;
  final _note = TextEditingController();
  bool _weekly = false;
  bool _saving = false;

  /// Rebuilds the footer when the slot count changes.
  final changes = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    final today = dayOf(ref.read(clockProvider)());
    _courts = {p?.court ?? 1};
    _day = p?.day == null ? today : dayOf(p!.day!);
    _from = p?.startHour ?? 9;
    _to = p?.endHour ?? (p?.startHour == null ? 12 : p!.startHour! + 1);
  }

  @override
  void dispose() {
    _note.dispose();
    changes.dispose();
    super.dispose();
  }

  int get from => _allDay ? ownerOpens : _from;
  int get to => _allDay ? ownerCloses : _to;
  int get hours => (to - from).clamp(0, 24);
  int get slots => hours * _courts.length;
  bool get saving => _saving;
  bool get valid => _courts.isNotEmpty && hours > 0;

  void _changed(VoidCallback f) {
    setState(f);
    changes.value++;
  }

  Future<void> save() async {
    if (!valid || _saving) return;
    _changed(() => _saving = true);
    final block = await ref
        .read(ownerActionsProvider)
        .block(
          courts: _courts.toList()..sort(),
          start: _day.add(Duration(hours: from)),
          end: _day.add(Duration(hours: to)),
          reason: _reason,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          weekly: _weekly,
        );
    if (!mounted) return;
    _changed(() => _saving = false);
    if (widget.onSaved != null) {
      widget.onSaved!(block);
    } else {
      Navigator.of(context).pop(block);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final courts = ref.watch(ownerCourtsProvider).value ?? const <OwnerCourt>[];
    final bookings = ref.watch(ownerBookingsOnProvider(_day)).value ?? const <OwnerBooking>[];
    final today = dayOf(ref.read(clockProvider)());
    final touched = [
      for (final b in bookings)
        if (_courts.contains(b.court) &&
            b.start.hour < to &&
            b.end.hour > from &&
            b.status != OwnerBookingStatus.cancelled)
          b,
    ];
    Widget group(Widget child, {bool last = false}) => Container(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s4),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
      child: child,
    );
    Widget heading(String t) => Semantics(
      header: true,
      child: Text(t, style: MuType.label.copyWith(color: c.text)),
    );
    List<MuSelectOption<int>> options(int first, int last) => [
      for (var h = first; h <= last; h++) MuSelectOption(value: h, label: hourLong(h)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        group(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading(l10n.terrains),
              const SizedBox(height: MuSpace.s3),
              Wrap(
                spacing: MuSpace.s2,
                runSpacing: MuSpace.s2,
                children: [
                  for (final court in courts)
                    MuChip(
                      label: courtName(court.number),
                      icon: court.indoor ? PhosphorIcons.umbrella() : null,
                      selected: _courts.contains(court.number),
                      onSelected: (v) => _changed(
                        () => v ? _courts.add(court.number) : _courts.remove(court.number),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        group(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading(l10n.jour),
              const SizedBox(height: MuSpace.s3),
              MuDateStrip(
                start: today,
                today: today,
                value: _day,
                label: l10n.jourABloquer,
                bleed: 0,
                onChanged: (d) => _changed(() => _day = dayOf(d)),
              ),
            ],
          ),
        ),
        group(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: heading(l10n.plageHoraire)),
                  MuSwitch(
                    value: _allDay,
                    size: MuSwitchSize.s,
                    label: l10n.touteLaJournee,
                    onChanged: (v) => _changed(() => _allDay = v),
                  ),
                ],
              ),
              if (!_allDay) ...[
                const SizedBox(height: MuSpace.s3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MuSelect<int>(
                        label: l10n.de,
                        options: options(ownerOpens, ownerCloses - 1),
                        value: _from,
                        onChanged: (v) => _changed(() {
                          _from = v;
                          if (_to <= _from) _to = _from + 1;
                        }),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: MuSelect<int>(
                        label: 'À',
                        options: options(ownerOpens + 1, ownerCloses),
                        value: _to,
                        onChanged: (v) => _changed(() {
                          _to = v;
                          if (_from >= _to) _from = _to - 1;
                        }),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: MuSpace.s3),
              _Summary(hours: hours, slots: slots, touched: touched),
            ],
          ),
        ),
        group(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading(l10n.raison),
              const SizedBox(height: MuSpace.s3),
              Semantics(
                container: true,
                label: l10n.raison,
                child: Wrap(
                  spacing: MuSpace.s2,
                  runSpacing: MuSpace.s2,
                  children: [
                    for (final r in BlockReason.values)
                      MuChip(
                        label: blockReasonLabel(r),
                        kind: MuChipKind.choice,
                        icon: blockReasonIcon(r),
                        selected: _reason == r,
                        onSelected: (_) => _changed(() => _reason = r),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: MuSpace.s4),
              MuTextField(
                label: l10n.noteInterne,
                controller: _note,
                optional: true,
                helper: l10n.visibleParTonEquipeSeulement,
              ),
            ],
          ),
        ),
        group(
          last: true,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuSwitch(
                value: _weekly,
                labelAtStart: true,
                icon: PhosphorIcons.repeat(),
                label: l10n.repeterChaqueSemaine,
                description: _allDay
                    ? l10n.tousLesSTouteLa(formatWeekdayLong(_day))
                    : l10n.tousLesSDeA(formatWeekdayLong(_day), hourLong(from), hourLong(to)),
                onChanged: (v) => _changed(() => _weekly = v),
              ),
              const SizedBox(height: MuSpace.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.lesJoueursVoientIndisponibleSur,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// « 3 h · 3 créneaux · aucune réservation touchée », or the bookings in the way.
class _Summary extends StatelessWidget {
  const _Summary({required this.hours, required this.slots, required this.touched});

  final int hours;
  final int slots;
  final List<OwnerBooking> touched;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final ok = touched.isEmpty;
    final text = ok
        ? l10n.hAucuneReservationTouchee(hours, slots, slots == 1 ? l10n.creneau2 : l10n.creneaux3)
        : '$hours h · $slots ${slots == 1 ? l10n.creneau2 : l10n.creneaux3} · ${touched.length == 1 ? l10n.reservationADeplacer : l10n.reservationsADeplacer(touched.length)} (${touched.map((b) => b.organiser).join(', ')})';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok
              ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
              : PhosphorIcons.warning(PhosphorIconsStyle.fill),
          size: MuSize.iconXs,
          color: ok ? c.successText : c.warningText,
        ),
        const SizedBox(width: MuSpace.s1 + 2),
        Expanded(
          child: Text(
            text,
            style: MuType.caption.copyWith(color: ok ? c.successText : c.warningText),
          ),
        ),
      ],
    );
  }
}

/// « Annuler » · « Bloquer 3 créneaux ».
class BlockFormFooter extends StatelessWidget {
  const BlockFormFooter({super.key, required this.formKey, this.onCancel});

  final GlobalKey<BlockFormState> formKey;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return _FooterBinding(
      formKey: formKey,
      builder: (form) {
        final n = form?.slots ?? 0;
        return Row(
          children: [
            MuButton.secondary(
              label: l10n.annuler,
              size: MuButtonSize.xl,
              onPressed: onCancel ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: MuButton.primary(
                label: n == 1 ? l10n.bloquerCreneau : l10n.bloquerCreneaux(n),
                leading: PhosphorIcons.lockSimple(),
                size: MuButtonSize.xl,
                fullWidth: true,
                loading: form?.saving ?? false,
                onPressed: form != null && form.valid ? form.save : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Listens to the form's [BlockFormState.changes] once the form is mounted.
class _FooterBinding extends StatefulWidget {
  const _FooterBinding({required this.formKey, required this.builder});

  final GlobalKey<BlockFormState> formKey;
  final Widget Function(BlockFormState? form) builder;

  @override
  State<_FooterBinding> createState() => _FooterBindingState();
}

class _FooterBindingState extends State<_FooterBinding> {
  ValueNotifier<int>? _listening;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
  }

  void _bind() {
    if (!mounted) return;
    final n = widget.formKey.currentState?.changes;
    if (n == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
      return;
    }
    _listening = n..addListener(_rebuild);
    setState(() {});
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _listening?.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(widget.formKey.currentState);
}
