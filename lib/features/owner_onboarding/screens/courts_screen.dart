import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/owner_controller.dart';
import '../data/owner_draft.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_wizard.dart';
import '../../../l10n/l10n.dart';

/// OWN-03 — the bookable courts: one row each (lighting switch, edit, more), edited in place one
/// at a time.
class CourtsScreen extends ConsumerStatefulWidget {
  const CourtsScreen({super.key});

  @override
  ConsumerState<CourtsScreen> createState() => _CourtsScreenState();
}

class _CourtsScreenState extends ConsumerState<CourtsScreen> {
  /// The court open for editing, and its working copy.
  String? _editingId;
  Court? _working;

  /// The open court was just added (« Annuler » removes it).
  bool _isNew = false;
  String? _nameError;
  String? _listError;
  final _name = TextEditingController();

  OwnerController get _owner => ref.read(ownerProvider.notifier);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _open(Court court, {bool isNew = false}) {
    if (_editingId != null && !_save()) return;
    setState(() {
      _editingId = court.id;
      _working = court;
      _isNew = isNew;
      _nameError = null;
      _name.text = court.name;
    });
  }

  void _add() {
    final courts = ref.read(ownerProvider).requireValue.courts;
    var n = courts.length + 1;
    while (courts.any((c) => c.name == 'Terrain $n')) {
      n++;
    }
    final court = Court(
      id: 'c${DateTime.now().microsecondsSinceEpoch}',
      name: l10n.terrain4(n),
      sport: courts.lastOrNull?.sport ?? MuSport.football,
      surface: courts.lastOrNull?.surface ?? OwnerCatalog.surfaces.first,
    );
    if (_editingId != null && !_save()) return;
    _owner.edit((d) => d.copyWith(courts: [...d.courts, court]));
    setState(() => _listError = null);
    _open(court, isNew: true);
  }

  /// Saves the open court; false (with the error shown) when its name is missing.
  bool _save() {
    final w = _working;
    if (w == null) return true;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.donneUnNomAuTerrain);
      return false;
    }
    final saved = w.copyWith(name: name);
    _owner.edit(
      (d) => d.copyWith(courts: [for (final c in d.courts) c.id == saved.id ? saved : c]),
    );
    setState(() {
      _editingId = null;
      _working = null;
      _isNew = false;
    });
    return true;
  }

  void _cancel() {
    final id = _editingId;
    if (_isNew && id != null) {
      _owner.edit((d) => d.copyWith(courts: d.courts.where((c) => c.id != id).toList()));
    }
    setState(() {
      _editingId = null;
      _working = null;
      _isNew = false;
    });
  }

  void _duplicate(Court court) {
    final copy = Court(
      id: 'c${DateTime.now().microsecondsSinceEpoch}',
      name: l10n.copie(court.name),
      sport: court.sport,
      surface: court.surface,
      indoor: court.indoor,
      lights: court.lights,
    );
    _owner.edit((d) {
      final i = d.courts.indexWhere((c) => c.id == court.id);
      return d.copyWith(courts: [...d.courts]..insert(i + 1, copy));
    });
  }

  void _delete(Court court) {
    _owner.edit((d) => d.copyWith(courts: d.courts.where((c) => c.id != court.id).toList()));
    MuToast.show(
      context,
      title: l10n.supprime(court.name),
      action: MuAction(l10n.annuler, () {
        _owner.edit((d) {
          final courts = [...d.courts];
          courts.add(court);
          return d.copyWith(courts: courts);
        });
      }),
    );
  }

  bool _validate() {
    if (!_save()) return false;
    final empty = ref.read(ownerProvider).requireValue.courts.isEmpty;
    setState(() => _listError = empty ? l10n.ajouteAuMoinsUnTerrain : null);
    return !empty;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final courts = ref.watch(ownerProvider.select((v) => v.requireValue.courts));
    final n = courts.length;

    return OwnerWizard(
      step: 2,
      title: l10n.tesTerrains,
      lead:
          l10n.ajouteChaqueTerrainReservableLes,
      validate: _validate,
      body: ProFormCard(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: MuSpace.s4,
                runSpacing: MuSpace.s3,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          '$n terrain${n > 1 ? 's' : ''}',
                          style: MuType.h3.copyWith(color: c.text),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s1),
                      Text(
                        l10n.chaqueTerrainASonPlanning,
                        style: MuType.body.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                  MuButton.secondary(
                    label: l10n.ajouterUnTerrain,
                    leading: PhosphorIcons.plus(),
                    onPressed: _add,
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s6),
              for (final (i, court) in courts.indexed) ...[
                if (i > 0) const SizedBox(height: MuSpace.s3),
                if (court.id == _editingId)
                  _editor(c)
                else
                  _CourtRow(
                    court: court,
                    onLights: (v) => _owner.edit(
                      (d) => d.copyWith(
                        courts: [
                          for (final x in d.courts) x.id == court.id ? x.copyWith(lights: v) : x,
                        ],
                      ),
                    ),
                    onEdit: () => _open(court),
                    onDuplicate: () => _duplicate(court),
                    onDelete: () => _delete(court),
                  ),
              ],
              if (_listError != null) ...[
                const SizedBox(height: MuSpace.s3),
                MuFieldMessage.error(_listError!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _editor(MuColors c) {
    final w = _working!;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s3, MuSpace.s3, MuSpace.s4, MuSpace.s5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.primary, width: _CourtRow.editEdge),
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CourtRow.art(w.sport),
              const SizedBox(width: MuSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name.text.trim().isEmpty ? w.name : _name.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    const SizedBox(height: MuSpace.s1),
                    Text(
                      _isNew ? l10n.nouveauTerrain : l10n.modificationEnCours,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              MuButton.tertiary(label: l10n.annuler, onPressed: _cancel),
              const SizedBox(width: MuSpace.s2),
              MuButton.secondary(
                label: l10n.enregistrer,
                leading: PhosphorIcons.check(),
                onPressed: _save,
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s5),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: MuSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ThreeColumns(
                  children: [
                    MuTextField(
                      label: l10n.nom,
                      controller: _name,
                      size: MuFieldSize.m,
                      error: _nameError,
                      autofocus: _isNew,
                      onChanged: (_) => setState(() => _nameError = null),
                      onSubmitted: (_) => _save(),
                    ),
                    MuSelect<MuSport>(
                      label: l10n.sport,
                      size: MuFieldSize.m,
                      value: w.sport,
                      options: [
                        for (final (sport, label, players, _) in OwnerCatalog.sports)
                          MuSelectOption(
                            value: sport,
                            label: label,
                            description: players,
                            icon: MuSportIcon(sport, size: MuSize.iconS, color: sport.text(c)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _working = w.copyWith(sport: v)),
                    ),
                    MuSelect<String>(
                      label: l10n.surface,
                      size: MuFieldSize.m,
                      value: w.surface,
                      options: [
                        for (final s in OwnerCatalog.surfaces) MuSelectOption(value: s, label: s),
                      ],
                      onChanged: (v) => setState(() => _working = w.copyWith(surface: v)),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: MuSpace.s6,
                  runSpacing: MuSpace.s5,
                  children: [
                    MuRadioGroup<bool>(
                      label: l10n.type,
                      horizontal: true,
                      value: w.indoor,
                      options: [
                        MuRadioOption(value: false, label: l10n.exterieur),
                        MuRadioOption(value: true, label: l10n.interieur),
                      ],
                      onChanged: (v) => setState(() => _working = w.copyWith(indoor: v)),
                    ),
                    MuSwitch(
                      value: w.lights,
                      label: l10n.eclairage,
                      description: l10n.projecteursLedPourLesMatchs,
                      onChanged: (v) => setState(() => _working = w.copyWith(lights: v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three columns (Nom, Sport, Surface), stacked below 720.
class _ThreeColumns extends StatelessWidget {
  const _ThreeColumns({required this.children});

  final List<Widget> children;

  static const double _stackBelow = 720;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < _stackBelow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, w) in children.indexed) ...[
            if (i > 0) const SizedBox(height: MuSpace.s5),
            w,
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, w) in children.indexed) ...[
          if (i > 0) const SizedBox(width: MuSpace.s4),
          Expanded(child: w),
        ],
      ],
    );
  }
}

class _CourtRow extends StatelessWidget {
  const _CourtRow({
    required this.court,
    required this.onLights,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Court court;
  final ValueChanged<bool> onLights;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  // OWN-03 source: CourtArt 72 × 48; the open row has a 2 px primary edge; 24 high divider.
  static const Size _art = Size(72, 48);
  static const double editEdge = 2;
  static const double _divider = 24;
  static const double _compact = 560;

  static Widget art(MuSport sport) => ClipRRect(
    borderRadius: MuRadius.smAll,
    child: SizedBox.fromSize(
      size: _art,
      child: MuCourtArt(sport: sport),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final more = MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(PhosphorIcons.copy(), size: MuSize.iconS, color: c.textSecondary),
          onPressed: onDuplicate,
          child: Text(l10n.dupliquer, style: MuType.body.copyWith(color: c.text)),
        ),
        MenuItemButton(
          leadingIcon: Icon(PhosphorIcons.trash(), size: MuSize.iconS, color: c.errorText),
          onPressed: onDelete,
          child: Text(l10n.supprimer, style: MuType.body.copyWith(color: c.errorText)),
        ),
      ],
      builder: (context, controller, _) => MuIconButton(
        icon: PhosphorIcons.dotsThreeVertical(),
        label: l10n.plusDActionsPour(court.name),
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < _compact;
        return Container(
          padding: const EdgeInsets.all(MuSpace.s3),
          decoration: BoxDecoration(
            borderRadius: MuRadius.mdAll,
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              if (!compact) ...[art(court.sport), const SizedBox(width: MuSpace.s4)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    const SizedBox(height: MuSpace.s1),
                    Row(
                      children: [
                        MuSportIcon(court.sport, size: MuSize.iconXs, color: court.sport.text(c)),
                        const SizedBox(width: MuSpace.s1),
                        Text(
                          OwnerCatalog.sportName(court.sport),
                          style: MuType.labelS.copyWith(color: court.sport.text(c)),
                        ),
                        const SizedBox(width: MuSpace.s2),
                        Flexible(
                          child: Text(
                            '${court.surface} · ${court.indoor ? l10n.interieur : l10n.exterieur}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MuSpace.s4),
              MuSwitch(
                value: court.lights,
                size: MuSwitchSize.s,
                label: compact ? null : l10n.eclairage,
                semanticLabel: l10n.eclairage2(court.name),
                onChanged: onLights,
              ),
              const SizedBox(width: MuSpace.s2),
              Container(width: 1, height: _divider, color: c.border),
              const SizedBox(width: MuSpace.s1),
              MuIconButton(
                icon: PhosphorIcons.pencilSimple(),
                label: l10n.modifier2(court.name),
                onPressed: onEdit,
              ),
              more,
            ],
          ),
        );
      },
    );
  }
}
