import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/owner_controller.dart';
import '../data/owner_draft.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_wizard.dart';

/// OWN-05 — court prices per hour, off-peak and peak, for each sport and type of court; the
/// weekend rule; and the live preview of what a player pays.
class PricesScreen extends ConsumerStatefulWidget {
  const PricesScreen({super.key});

  @override
  ConsumerState<PricesScreen> createState() => _PricesScreenState();
}

/// The courts sharing a price: same sport, same type.
class _Group {
  _Group(this.key, this.first);

  final String key;
  final Court first;
  final List<Court> courts = [];

  String get title =>
      '${OwnerCatalog.sportName(first.sport)} · ${first.indoor ? 'Intérieur' : 'Extérieur'}';

  /// « Terrains 1 et 2 », « Terrain 3 », « Central et Annexe ».
  String get names {
    String join(List<String> parts) => parts.length == 1
        ? parts.first
        : '${parts.sublist(0, parts.length - 1).join(', ')} et ${parts.last}';
    final numbered = RegExp(r'^Terrain (\S+)$');
    final numbers = [for (final c in courts) numbered.firstMatch(c.name)?.group(1)];
    if (numbers.every((n) => n != null)) {
      return courts.length == 1 ? courts.first.name : 'Terrains ${join(numbers.cast<String>())}';
    }
    return join([for (final c in courts) c.name]);
  }
}

List<_Group> _groups(List<Court> courts) {
  final groups = <String, _Group>{};
  for (final c in courts) {
    groups.putIfAbsent(c.priceKey, () => _Group(c.priceKey, c)).courts.add(c);
  }
  return groups.values.toList();
}

class _PricesScreenState extends ConsumerState<PricesScreen> {
  final Map<String, TextEditingController> _fields = {};
  final Set<String> _errors = {};

  OwnerController get _owner => ref.read(ownerProvider.notifier);

  TextEditingController _field(String key, int? value) =>
      _fields.putIfAbsent(key, () => TextEditingController(text: value?.toString() ?? ''));

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(String key, {required bool peak, required String text}) {
    final v = int.tryParse(text);
    if (v != null && v > 0) setState(() => _errors.remove('$key-${peak ? 'peak' : 'off'}'));
    _owner.edit((d) {
      final p = d.prices[key] ?? const CourtPrice(offPeak: null, peak: null);
      final next = peak
          ? p.copyWith(peak: v, clearPeak: v == null)
          : p.copyWith(offPeak: v, clearOffPeak: v == null);
      return d.copyWith(prices: {...d.prices, key: next});
    });
  }

  bool _validate() {
    final d = ref.read(ownerProvider).requireValue;
    setState(() {
      _errors.clear();
      for (final g in _groups(d.courts)) {
        final p = d.prices[g.key];
        if ((p?.offPeak ?? 0) <= 0) _errors.add('${g.key}-off');
        if ((p?.peak ?? 0) <= 0) _errors.add('${g.key}-peak');
      }
    });
    return _errors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = ref.watch(ownerProvider).requireValue;
    final groups = _groups(d.courts);

    return OwnerWizard(
      step: 4,
      title: 'Fixe tes tarifs',
      lead:
          'Les joueurs comparent le prix par personne : MatchUp l’affiche à côté du prix du '
          'terrain.',
      validate: _validate,
      body: ProFormCard(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProFormSection(
                title: 'Prix du terrain à l’heure',
                description: 'Le prix par joueur est calculé pour 10 joueurs, comme sur MatchUp.',
                trailing: MuButton.tertiary(
                  label: 'Modifier les plages',
                  leading: PhosphorIcons.clock(),
                  size: MuButtonSize.s,
                  onPressed: () => showComingSoon(context),
                ),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < _PriceRow.stackBelow;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!stacked) _header(c),
                          for (final (i, g) in groups.indexed)
                            _PriceRow(
                              group: g,
                              stacked: stacked,
                              last: i == groups.length - 1,
                              off: _field('${g.key}-off', d.prices[g.key]?.offPeak),
                              peak: _field('${g.key}-peak', d.prices[g.key]?.peak),
                              offError: _errors.contains('${g.key}-off'),
                              peakError: _errors.contains('${g.key}-peak'),
                              onOff: (t) => _set(g.key, peak: false, text: t),
                              onPeak: (t) => _set(g.key, peak: true, text: t),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s5),
              MuSwitch(
                value: d.weekendPeak,
                labelAtStart: true,
                icon: PhosphorIcons.calendarStar(),
                label: 'Week-end en heures de pointe',
                description: 'Samedi et dimanche, de l’ouverture à la fermeture.',
                onChanged: (v) => _owner.edit((d) => d.copyWith(weekendPeak: v)),
              ),
              if (groups.isNotEmpty) ...[
                const SizedBox(height: MuSpace.s5),
                _Preview(draft: d, group: groups.first),
              ],
            ],
          ),
          ProExtraRow(
            icon: PhosphorIcons.calendarPlus(),
            title: 'Dates spéciales',
            caption: 'Ramadan, Aïd, soir de finale : un autre tarif pour un jour précis.',
            action: 'Ajouter une date',
            onAction: () => showComingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _header(MuColors c) {
    Widget band(IconData icon, String title, String hours) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: MuSize.iconXs, color: c.text),
            const SizedBox(width: MuSpace.s2),
            Text(title, style: MuType.label.copyWith(color: c.text)),
          ],
        ),
        const SizedBox(height: _PriceRow.lineGap),
        Text(hours, style: MuType.numXs.copyWith(color: c.textSecondary)),
      ],
    );
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.only(bottom: MuSpace.s3),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: _PriceRow.typeFlex,
              child: Text('Type de terrain', style: MuType.labelS.copyWith(color: c.textSecondary)),
            ),
            const SizedBox(width: MuSpace.s4),
            Expanded(
              flex: _PriceRow.fieldFlex,
              child: band(PhosphorIcons.sun(), 'Heures creuses', 'Lun.–ven. · 08h00–17h00'),
            ),
            const SizedBox(width: MuSpace.s4),
            Expanded(
              flex: _PriceRow.fieldFlex,
              child: band(
                PhosphorIcons.lightning(),
                'Heures de pointe',
                'Lun.–ven. · 17h00–fermeture',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.group,
    required this.stacked,
    required this.last,
    required this.off,
    required this.peak,
    required this.offError,
    required this.peakError,
    required this.onOff,
    required this.onPeak,
  });

  final _Group group;
  final bool stacked;
  final bool last;
  final TextEditingController off;
  final TextEditingController peak;
  final bool offError;
  final bool peakError;
  final ValueChanged<String> onOff;
  final ValueChanged<String> onPeak;

  // OWN-05 source: columns 1,15fr / 1fr / 1fr; sport tile 32; 2 px between lines.
  static const int typeFlex = 115;
  static const int fieldFlex = 100;
  static const double _tile = 32;
  static const double lineGap = 2;
  static const double stackBelow = 520;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final sport = group.first.sport;
    final players = OwnerCatalog.playersOf(sport);
    final fieldPrefix =
        '${OwnerCatalog.sportName(sport)} ${group.first.indoor ? 'intérieur' : 'extérieur'}';

    Widget price(
      TextEditingController ctl,
      String band,
      bool error,
      ValueChanged<String> onChanged,
    ) {
      final v = int.tryParse(ctl.text);
      return MuTextField(
        label: '$fieldPrefix, $band',
        hideLabel: !stacked,
        controller: ctl,
        size: MuFieldSize.m,
        suffixText: 'DT /h',
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        error: error ? 'Indique un prix.' : null,
        helper: v == null || v == 0 ? null : 'soit ${formatDT(v / players)} /pers.',
        onChanged: onChanged,
      );
    }

    final type = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _tile,
          height: _tile,
          decoration: BoxDecoration(color: sport.soft(c), borderRadius: MuRadius.smAll),
          child: Center(
            child: MuSportIcon(sport, size: MuSize.iconS, color: sport.text(c)),
          ),
        ),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.title, style: MuType.label.copyWith(color: c.text)),
              const SizedBox(height: lineGap),
              Text(group.names, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );

    final offField = price(off, 'heures creuses', offError, onOff);
    final peakField = price(peak, 'heures de pointe', peakError, onPeak);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                type,
                const SizedBox(height: MuSpace.s3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: offField),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(child: peakField),
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: typeFlex,
                  child: Padding(
                    padding: const EdgeInsets.only(top: MuSpace.s1),
                    child: type,
                  ),
                ),
                const SizedBox(width: MuSpace.s4),
                Expanded(flex: fieldFlex, child: offField),
                const SizedBox(width: MuSpace.s4),
                Expanded(flex: fieldFlex, child: peakField),
              ],
            ),
    );
  }
}

/// « Aperçu joueur · en direct »: the next Saturday 20h00 on the first court, at the peak price.
class _Preview extends ConsumerWidget {
  const _Preview({required this.draft, required this.group});

  final OwnerDraft draft;
  final _Group group;

  // OWN-05 source: 2 px pill padding and line gap.
  static const double _tight = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final saturday = DateTime(
      now.year,
      now.month,
      now.day + (DateTime.saturday - now.weekday) % 7,
      20,
    );
    final court = group.courts.first;
    final players = OwnerCatalog.playersOf(court.sport);
    final price = draft.prices[group.key]?.peak;
    final perPerson = price == null ? null : price / players;

    return Theme(
      data: MuTheme.dark(),
      child: Builder(
        builder: (context) {
          final c = context.mu;
          final when = '${court.name} · ${formatDateTime(saturday)}';
          return Semantics(
            container: true,
            liveRegion: true,
            label:
                'Aperçu joueur : $when, heure de pointe, '
                '${perPerson == null ? 'prix à définir' : '${formatDT(perPerson)} par personne'}',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s5, vertical: MuSpace.s4),
              decoration: BoxDecoration(color: c.surfaceElevated, borderRadius: MuRadius.mdAll),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: MuSpace.s6,
                runSpacing: MuSpace.s3,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'APERÇU JOUEUR · EN DIRECT',
                        style: MuType.overline.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: MuSpace.s2),
                      Text(when, style: MuType.labelL.copyWith(color: c.text)),
                      const SizedBox(height: MuSpace.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MuSpace.s2,
                          vertical: _tight,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: MuRadius.fullAll,
                          border: Border.all(color: c.borderStrong),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIcons.lightning(), size: MuSize.iconXs, color: c.text),
                            const SizedBox(width: MuSpace.s1),
                            Text(
                              'Heure de pointe · 1 h',
                              style: MuType.labelS.copyWith(color: c.text),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            perPerson == null ? '—' : formatDT(perPerson),
                            style: MuType.numXl.copyWith(color: c.text),
                          ),
                          const SizedBox(width: MuSpace.s2),
                          Text('/pers.', style: MuType.body.copyWith(color: c.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: _tight),
                      if (price != null)
                        Text(
                          '${formatDT(price)} le terrain · soit ${formatDT(perPerson!)} /pers. pour '
                          '$players joueurs',
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
