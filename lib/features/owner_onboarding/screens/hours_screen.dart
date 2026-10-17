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
import '../../../l10n/l10n.dart';

/// OWN-04 — opening hours per weekday (a switch, opening and closing selects, the length), « Appliquer
/// à tous les jours », and exceptional closures.
class HoursScreen extends ConsumerStatefulWidget {
  const HoursScreen({super.key});

  @override
  ConsumerState<HoursScreen> createState() => _HoursScreenState();
}

final _days = [l10n.lundi, l10n.mardi, l10n.mercredi, l10n.jeudi, l10n.vendredi, l10n.samedi, l10n.dimanche];

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
      title: l10n.horairesDuAppliquesATous(_days[source].toLowerCase()),
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
      MuToast.show(context, tone: MuToastTone.error, title: l10n.ouvreAuMoinsUnJour);
      return false;
    }
    return _errors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final hours = ref.watch(ownerProvider.select((v) => v.requireValue.hours));

    return OwnerWizard(
      step: 3,
      title: l10n.tesHorairesDOuverture,
      lead: l10n.lesJoueursNePeuventReserver,
      validate: _validate,
      body: ProFormSections(
        children: [
          ProFormSection(
            title: l10n.horairesDeLaSemaine,
            description: l10n.lesCreneauxSontGeneresToutes,
            trailing: MuButton.tertiary(
              label: l10n.appliquerATousLesJours,
              leading: PhosphorIcons.copy(),
              size: MuButtonSize.s,
              onPressed: _applyToAll,
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, h) in hours.indexed)
                    _DayRow(
                      day: _days[i],
                      hours: h,
                      last: i == hours.length - 1,
                      error: _errors.contains(i),
                      onChanged: (v) => _setDay(i, v),
                    ),
                ],
              ),
            ],
          ),
          ProExtraRow(
            icon: PhosphorIcons.calendarX(),
            title: l10n.fermeturesExceptionnelles,
            caption: l10n.aidJoursFeriesTravauxLes,
            action: l10n.ajouterUneFermeture,
            onAction: () => showComingSoon(context),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.hours,
    required this.last,
    required this.error,
    required this.onChanged,
  });

  final String day;
  final DayHours hours;
  final bool last;
  final bool error;
  final ValueChanged<DayHours> onChanged;

  // OWN-04 source: rows ≥ 52; « à » 14; the length 40 wide.
  static const double _minHeight = 52;
  static const double _to = 14;
  static const double _lengthWidth = 40;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final lower = day.toLowerCase();

    List<MuSelectOption<int>> options(Iterable<int> values) => [
      for (final m in values) MuSelectOption(value: m, label: formatHour(m)),
    ];

    // The day's switch, then the two selects sharing the row under it.
    final range = hours.open
        ? Row(
            children: [
              Expanded(
                child: MuSelect<int>(
                  label: l10n.ouvertureLe(lower),
                  hideLabel: true,
                  value: hours.from,
                  options: options(_times),
                  onChanged: (v) => onChanged(hours.copyWith(from: v)),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              SizedBox(
                width: _to,
                child: Text(
                  l10n.horaireA,
                  textAlign: TextAlign.center,
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: MuSelect<int>(
                  label: l10n.fermetureLe(lower),
                  hideLabel: true,
                  value: hours.close,
                  options: options(_times),
                  onChanged: (v) => onChanged(hours.copyWith(close: v)),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              SizedBox(
                width: _lengthWidth,
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
              Text(l10n.fermeTouteLaJournee, style: MuType.body.copyWith(color: c.textSecondary)),
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
          toggle,
          const SizedBox(height: MuSpace.s2),
          range,
          const SizedBox(height: MuSpace.s1),
          if (error)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
              child: MuFieldMessage.error(l10n.laFermetureDoitVenirApres),
            ),
        ],
      ),
    );
  }
}
