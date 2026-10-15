import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/owner_controller.dart';
import '../data/owner_draft.dart';
import '../widgets/owner_wizard.dart';

/// OWN-04 — opening hours per weekday (a switch, opening and closing selects, the length), « Appliquer
/// à tous les jours », and exceptional closures.
class HoursScreen extends ConsumerStatefulWidget {
  const HoursScreen({super.key});

  @override
  ConsumerState<HoursScreen> createState() => _HoursScreenState();
}

const _days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

/// 06h00 to 02h00 the next day, every half hour (OWN-04 source).
final _times = [for (var m = 6 * 60; m <= 26 * 60; m += 30) m];

/// « 16 h », « 16 h 30 ».
String _length(int minutes) =>
    minutes % 60 == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h ${minutes % 60}';

class _HoursScreenState extends ConsumerState<HoursScreen> {
  /// The day whose hours « Appliquer à tous les jours » copies.
  int? _lastEdited;
  final Set<int> _errors = {};

  OwnerController get _owner => ref.read(ownerProvider.notifier);

  void _setDay(int i, DayHours h) {
    setState(() {
      _lastEdited = i;
      if (h.close > h.from) _errors.remove(i);
    });
    _owner.edit((d) => d.copyWith(hours: [...d.hours]..[i] = h));
  }

  void _applyToAll() {
    final hours = ref.read(ownerProvider).requireValue.hours;
    final source = _lastEdited ?? hours.indexWhere((h) => h.open);
    if (source < 0) return;
    final h = hours[source];
    _owner.edit(
      (d) => d.copyWith(
        hours: [for (final x in d.hours) x.open ? x.copyWith(from: h.from, close: h.close) : x],
      ),
    );
    setState(_errors.clear);
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: 'Horaires du ${_days[source].toLowerCase()} appliqués à tous les jours ouverts',
    );
  }

  bool _validate() {
    final hours = ref.read(ownerProvider).requireValue.hours;
    setState(() {
      _errors
        ..clear()
        ..addAll([
          for (final (i, h) in hours.indexed)
            if (h.open && h.close <= h.from) i,
        ]);
    });
    if (hours.every((h) => !h.open)) {
      MuToast.show(context, tone: MuToastTone.error, title: 'Ouvre au moins un jour.');
      return false;
    }
    return _errors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final hours = ref.watch(ownerProvider.select((v) => v.requireValue.hours));

    return OwnerWizard(
      step: 3,
      title: 'Tes horaires d’ouverture',
      lead: 'Les joueurs ne peuvent réserver que pendant ces plages.',
      validate: _validate,
      body: ProFormCard(
        children: [
          ProFormSection(
            title: 'Horaires de la semaine',
            description: 'Les créneaux sont générés toutes les heures dans ces plages.',
            trailing: MuButton.tertiary(
              label: 'Appliquer à tous les jours',
              leading: PhosphorIcons.copy(),
              size: MuButtonSize.s,
              onPressed: _applyToAll,
            ),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < _DayRow.stackBelow;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!stacked)
                        ExcludeSemantics(
                          child: Container(
                            padding: const EdgeInsets.only(bottom: MuSpace.s2),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: c.border)),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _head(c, 'Jour')),
                                SizedBox(width: _DayRow.select, child: _head(c, 'Ouverture')),
                                const SizedBox(width: MuSpace.s3 * 2 + _DayRow.to),
                                SizedBox(width: _DayRow.select, child: _head(c, 'Fermeture')),
                                const SizedBox(width: MuSpace.s3),
                                SizedBox(
                                  width: _DayRow.length,
                                  child: _head(c, 'Durée', end: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      for (final (i, h) in hours.indexed)
                        _DayRow(
                          day: _days[i],
                          hours: h,
                          stacked: stacked,
                          last: i == hours.length - 1,
                          error: _errors.contains(i),
                          onChanged: (v) => _setDay(i, v),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          ProExtraRow(
            icon: PhosphorIcons.calendarX(),
            title: 'Fermetures exceptionnelles',
            caption: 'Aïd, jours fériés, travaux : les créneaux de ces dates disparaissent.',
            action: 'Ajouter une fermeture',
            onAction: () => showComingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _head(MuColors c, String text, {bool end = false}) => Text(
    text,
    textAlign: end ? TextAlign.end : TextAlign.start,
    style: MuType.labelS.copyWith(color: c.textSecondary),
  );
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.hours,
    required this.stacked,
    required this.last,
    required this.error,
    required this.onChanged,
  });

  final String day;
  final DayHours hours;
  final bool stacked;
  final bool last;
  final bool error;
  final ValueChanged<DayHours> onChanged;

  // OWN-04 source: rows ≥ 52; selects 128; « à » 14; length 40.
  static const double _minHeight = 52;
  static const double select = 128;
  static const double to = 14;
  static const double length = 40;
  static const double stackBelow = 520;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final lower = day.toLowerCase();

    List<MuSelectOption<int>> options(Iterable<int> values) => [
      for (final m in values) MuSelectOption(value: m, label: formatHour(m)),
    ];

    // On phones the two selects share the row.
    Widget slot(Widget child) =>
        stacked ? Expanded(child: child) : SizedBox(width: select, child: child);

    final range = hours.open
        ? Row(
            mainAxisSize: stacked ? MainAxisSize.max : MainAxisSize.min,
            children: [
              slot(
                MuSelect<int>(
                  label: 'Ouverture le $lower',
                  hideLabel: true,
                  size: MuFieldSize.m,
                  value: hours.from,
                  options: options(_times),
                  onChanged: (v) => onChanged(hours.copyWith(from: v)),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              SizedBox(
                width: to,
                child: Text(
                  'à',
                  textAlign: TextAlign.center,
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              slot(
                MuSelect<int>(
                  label: 'Fermeture le $lower',
                  hideLabel: true,
                  size: MuFieldSize.m,
                  value: hours.close,
                  options: options(_times),
                  onChanged: (v) => onChanged(hours.copyWith(close: v)),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              SizedBox(
                width: length,
                child: Text(
                  hours.minutes > 0 ? _length(hours.minutes) : '—',
                  textAlign: TextAlign.end,
                  style: MuType.numS.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.moon(), size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s2),
              Text('Fermé toute la journée', style: MuType.body.copyWith(color: c.textSecondary)),
            ],
          );

    final toggle = MuSwitch(
      value: hours.open,
      label: day,
      onChanged: (v) => onChanged(hours.copyWith(open: v)),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (stacked) ...[
            toggle,
            if (hours.open) ...[
              const SizedBox(height: MuSpace.s2),
              Align(alignment: AlignmentDirectional.centerStart, child: range),
            ],
            if (!hours.open) ...[const SizedBox(height: MuSpace.s1), range],
          ] else
            Row(
              children: [
                Expanded(
                  child: Align(alignment: AlignmentDirectional.centerStart, child: toggle),
                ),
                const SizedBox(width: MuSpace.s4),
                range,
              ],
            ),
          if (error)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: MuSpace.s1),
              child: MuFieldMessage.error('La fermeture doit venir après l’ouverture.'),
            ),
        ],
      ),
    );
  }
}
