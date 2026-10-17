import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/owner_drafts.dart';
import '../data/owner_repository.dart';
import '../data/tariffs_repository.dart';
import '../../../l10n/l10n.dart';

/// OWN-17 · Terrains: active courts, occupancy and hours, then a card per court (visible switch,
/// prices, occupancy, works) with Modifier (visibility, maintenance), Bloquer (OWN-13) and
/// Planning (OWN-11); « Ajouter un terrain » and the link to the prices (OWN-16).
class OwnerCourtsScreen extends ConsumerStatefulWidget {
  const OwnerCourtsScreen({super.key});

  @override
  ConsumerState<OwnerCourtsScreen> createState() => _OwnerCourtsScreenState();
}

class _OwnerCourtsScreenState extends ConsumerState<OwnerCourtsScreen> {
  /// Changes shown before the repository answers.
  final _pending = <String, OwnerCourt>{};

  Future<void> _update(OwnerCourt court) async {
    setState(() => _pending[court.id] = court);
    await ref.read(ownerRepositoryProvider).updateCourt(court);
    ref.invalidate(ownerCourtsProvider);
    await ref.read(ownerCourtsProvider.future);
    if (!mounted) return;
    setState(() => _pending.remove(court.id));
  }

  Future<void> _setVisible(OwnerCourt court, bool visible) async {
    await _update(court.copyWith(visible: visible));
    if (!mounted) return;
    MuSnackbar.show(
      context,
      icon: visible ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
      message: visible
          ? l10n.terrainVisibleLesJoueursPeuvent(court.number)
          : l10n.terrainMasquePlusReservable(court.number),
      action: MuAction(l10n.annuler, () => _update(court.copyWith(visible: !visible))),
    );
  }

  Future<void> _setMaintenance(OwnerCourt court, bool on) async {
    await _update(court.copyWith(maintenance: on));
    if (!mounted) return;
    MuSnackbar.show(
      context,
      icon: PhosphorIcons.wrench(),
      message: on
          ? l10n.terrainEnEntretienCreneauxFermes(court.number)
          : l10n.terrainRouvertALaReservation(court.number),
    );
  }

  void _edit(OwnerCourt court) {
    MuBottomSheet.show<void>(
      context,
      title: l10n.terrain4(court.number),
      height: MuSheetHeight.auto,
      child: Consumer(
        builder: (context, ref, _) {
          final now =
              _pending[court.id] ??
              ref.watch(ownerCourtsProvider).value?.firstWhere((c) => c.id == court.id) ??
              court;
          return Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MuSwitch(
                  value: now.visible,
                  labelAtStart: true,
                  icon: PhosphorIcons.eye(),
                  label: l10n.visibleEtReservable,
                  description: l10n.masqueIlNApparaitPlus,
                  onChanged: (v) => _setVisible(now, v),
                ),
                const SizedBox(height: MuSpace.s4),
                MuSwitch(
                  value: now.maintenance,
                  labelAtStart: true,
                  icon: PhosphorIcons.wrench(),
                  label: l10n.enEntretien,
                  description: l10n.fermeTousSesCreneauxJusqu,
                  onChanged: (v) => _setMaintenance(now, v),
                ),
                const SizedBox(height: MuSpace.s5),
                MuButton.secondary(
                  label: l10n.modifierLeSportLaSurface,
                  fullWidth: true,
                  onPressed: () => showComingSoon(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final loaded = ref.watch(ownerCourtsProvider).value;
    final tariffs = ref.watch(tariffsProvider).value;
    final courts = [
      for (final court in loaded ?? const <OwnerCourt>[]) _pending[court.id] ?? court,
    ];
    final active = courts.where((x) => x.visible && !x.maintenance).length;
    final occupancy = courtOccupancy.isEmpty
        ? 0
        : (courtOccupancy.values.reduce((a, b) => a + b) / courtOccupancy.length).round();
    final secondary = MuType.caption.copyWith(color: c.textSecondary);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.terrains,
            subtitle: l10n.espaceProprietaire2(Story.arenaFive.name),
            backLabel: l10n.retourAPlus,
            onBack: () => goBack(context, Routes.ownerMore),
            actions: [
              MuBarAction(
                icon: PhosphorIcons.plus(),
                label: l10n.ajouterUnTerrain,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          Expanded(
            child: loaded == null
                ? const Center(child: MuSpinner())
                : ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      MuSpace.s4,
                      MuSpace.s2,
                      MuSpace.s4,
                      MuSpace.s8,
                    ),
                    children: [
                      MuCardSurface(
                        padding: EdgeInsets.zero,
                        child: _StatRow(
                          cells: [
                            ('$active', active == 1 ? l10n.terrainActif : l10n.terrainsActifs),
                            ('$occupancy %', l10n.occupesJ),
                            (
                              '${ownerOpens}h–${(ownerCloses % 24).toString().padLeft(2, '0')}h',
                              l10n.tousLesJours2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MuSpace.s5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  l10n.tesTerrains2,
                                  style: MuType.overline.copyWith(color: c.textSecondary),
                                ),
                              ),
                            ),
                            Text(l10n.masquePlusReservable, style: secondary),
                          ],
                        ),
                      ),
                      for (final court in courts) ...[
                        const SizedBox(height: MuSpace.s3),
                        _CourtCard(
                          court: court,
                          prices: tariffs?.priceOf(court.number),
                          peakLabel: tariffs == null
                              ? null
                              : '${tariffs.peakFrom}h–${tariffs.peakTo}h',
                          onVisible: (v) => _setVisible(court, v),
                          onEdit: () => _edit(court),
                        ),
                      ],
                      const SizedBox(height: MuSpace.s5),
                      _AddCourt(onTap: () => showComingSoon(context)),
                      const SizedBox(height: MuSpace.s5),
                      MuCardSurface(
                        onTap: () => context.push(Routes.ownerTariffs),
                        semanticLabel: l10n.tarifsEtHeuresDePointe,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          MuSpace.s4,
                          MuSpace.s3 + MuSpace.s1 / 2,
                          MuSpace.s3,
                          MuSpace.s3 + MuSpace.s1 / 2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: MuSize.controlS + MuSpace.s1,
                              height: MuSize.controlS + MuSpace.s1,
                              decoration: BoxDecoration(
                                color: c.surfaceMuted,
                                borderRadius: MuRadius.smAll,
                              ),
                              child: Icon(PhosphorIcons.tag(), size: MuSize.iconS, color: c.text),
                            ),
                            const SizedBox(width: MuSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.tarifsEtHeuresDePointe,
                                    style: MuType.label.copyWith(color: c.text),
                                  ),
                                  const SizedBox(height: MuSpace.s1 / 2),
                                  Text(
                                    tariffs == null
                                        ? l10n.prixParTerrainDatesSpeciales
                                        : l10n.prixParTerrainDatesSpeciales2(formatDT(tariffs.maxPrice / 10)),
                                    style: secondary,
                                  ),
                                ],
                              ),
                            ),
                            MuDirectionalIcon(
                              PhosphorIcons.caretRight(),
                              size: MuSize.iconS,
                              color: c.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Three figures side by side, ruled apart (« 3 terrains actifs », « Creuses 120 DT /h »).
class _StatRow extends StatelessWidget {
  const _StatRow({required this.cells, this.labelFirst = false, this.muted = false});

  /// (value, label).
  final List<(String, String)> cells;
  final bool labelFirst;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final value = (muted ? MuType.numS : MuType.numL).copyWith(color: c.text);
    final label = MuType.caption.copyWith(color: c.textSecondary);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (v, l)) in cells.indexed) ...[
            if (i > 0) VerticalDivider(width: 1, thickness: 1, color: c.border),
            Expanded(
              child: Semantics(
                label: '$l : $v',
                excludeSemantics: true,
                child: Padding(
                  padding: muted
                      ? const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2)
                      : const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: labelFirst
                        ? [
                            Text(l, style: label),
                            const SizedBox(height: MuSpace.s1 / 2),
                            _valueText(v, value, label),
                          ]
                        : [
                            Text(v, style: value),
                            const SizedBox(height: MuSpace.s1 / 2),
                            Text(l, style: label),
                          ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// « 120 DT /h »: the unit after the figure in caption.
  static Widget _valueText(String v, TextStyle value, TextStyle unit) {
    final i = v.indexOf(' /');
    if (i < 0) return Text(v, style: value);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: v.substring(0, i), style: value),
          TextSpan(text: v.substring(i), style: unit),
        ],
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.court,
    required this.prices,
    required this.peakLabel,
    required this.onVisible,
    required this.onEdit,
  });

  final OwnerCourt court;
  final CourtPrice? prices;
  final String? peakLabel;
  final ValueChanged<bool> onVisible;
  final VoidCallback onEdit;

  // OWN-17: the court art is 72 square.
  static const double _art = 72;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final n = court.number;
    final works = courtWorks[n];
    final note = court.maintenance
        ? l10n.enEntretienTousSesCreneaux
        : works == null
        ? null
        : l10n.hHCreneauxBloques(works.what, formatDay(works.day), works.from, works.to);
    return Semantics(
      container: true,
      label: l10n.terrain4(n),
      child: MuCardSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: MuRadius.smAll,
                    child: SizedBox.square(
                      dimension: _art,
                      child: MuCourtArt(
                        variant: court.indoor ? MuCourtArtVariant.pattern : MuCourtArtVariant.photo,
                        semanticLabel: court.indoor
                            ? l10n.terrainSalleCouverte(n)
                            : l10n.terrainGazonSynthetiqueEclaire(n),
                      ),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(l10n.terrain4(n), style: MuType.h3.copyWith(color: c.text)),
                        ),
                        const SizedBox(height: MuSpace.s1 + MuSpace.s1 / 2),
                        MuChip(
                          kind: MuChipKind.sport,
                          sport: MuSport.football,
                          label: l10n.football5v52,
                          size: MuChipSize.s,
                        ),
                        const SizedBox(height: MuSpace.s1 + MuSpace.s1 / 2),
                        Text(
                          court.indoor
                              ? l10n.synthetiqueInterieur
                              : l10n.synthetiqueExterieurEclaire,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      MuSwitch(
                        value: court.visible,
                        size: MuSwitchSize.s,
                        semanticLabel: l10n.terrainVisibleEtReservable(n),
                        onChanged: onVisible,
                      ),
                      const SizedBox(height: MuSpace.s1),
                      ExcludeSemantics(
                        child: Text(
                          court.visible ? l10n.visible : l10n.masque,
                          style: MuType.labelS.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                child: _StatRow(
                  labelFirst: true,
                  muted: true,
                  cells: [
                    (prices == null ? '–' : '${formatDT(prices!.offPeak)} /h', l10n.creuses),
                    (prices == null ? '–' : '${formatDT(prices!.peak)} /h', peakLabel ?? l10n.pointe),
                    ('${courtOccupancy[n] ?? 0} %', l10n.occupeJ),
                  ],
                ),
              ),
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
                  decoration: BoxDecoration(color: c.warningSoft, borderRadius: MuRadius.smAll),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.warning(), size: MuSize.iconXs, color: c.warningText),
                      const SizedBox(width: MuSpace.s2),
                      Expanded(
                        child: Text(note, style: MuType.caption.copyWith(color: c.warningText)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: MuSpace.s3),
            Divider(height: 1, thickness: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.all(MuSpace.s2),
              child: Row(
                children: [
                  Expanded(
                    child: MuButton.tertiary(
                      label: l10n.modifier,
                      size: MuButtonSize.s,
                      leading: PhosphorIcons.pencilSimple(),
                      onPressed: onEdit,
                    ),
                  ),
                  const SizedBox(width: MuSpace.s1),
                  Expanded(
                    child: MuButton.tertiary(
                      label: l10n.bloquer2,
                      size: MuButtonSize.s,
                      leading: PhosphorIcons.calendarX(),
                      onPressed: () =>
                          context.push(Routes.ownerBlock, extra: BlockPrefill(court: n)),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s1),
                  Expanded(
                    child: MuButton.tertiary(
                      label: l10n.planning,
                      size: MuButtonSize.s,
                      leading: PhosphorIcons.calendarBlank(),
                      onPressed: () => context.go(Routes.ownerPlanning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Ajouter un terrain »: a dashed card with the Volt plus.
class _AddCourt extends StatelessWidget {
  const _AddCourt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: l10n.ajouterUnTerrain,
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: MuRadius.mdAll,
          child: CustomPaint(
            painter: _DashedBorder(color: c.borderStrong),
            child: Padding(
              padding: const EdgeInsets.all(MuSpace.s4),
              child: Row(
                children: [
                  Container(
                    width: MuSize.touchTarget,
                    height: MuSize.touchTarget,
                    decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.smAll),
                    child: Icon(PhosphorIcons.plus(), size: MuSize.iconM, color: c.onAccent),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.ajouterUnTerrain, style: MuType.labelL.copyWith(color: c.text)),
                        const SizedBox(height: MuSpace.s1 / 2),
                        Text(
                          l10n.sportSurfaceEclairagePuisSes,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 1,5 px dashed outline of « Ajouter un terrain » (`border-strong`, `radius-md`).
class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});

  final Color color;

  static const double _stroke = 1.5;
  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()..addRRect(MuRadius.mdAll.toRRect(rect.deflate(_stroke / 2)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
