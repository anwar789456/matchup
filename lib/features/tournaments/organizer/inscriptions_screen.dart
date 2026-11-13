import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import 'org_widgets.dart';

enum _Filtre { toutes, aValider, validees, refusees }

/// ORG-10 · Inscriptions: filter the teams, validate or refuse (with a reason) each one.
class InscriptionsScreen extends ConsumerStatefulWidget {
  const InscriptionsScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<InscriptionsScreen> createState() => _InscriptionsScreenState();
}

class _InscriptionsScreenState extends ConsumerState<InscriptionsScreen> {
  _Filtre _filtre = _Filtre.aValider;
  String? _busy;

  Future<void> _act(Equipe e, Future<void> Function() action) async {
    setState(() => _busy = e.id);
    try {
      await action();
    } on TournoiRefus catch (err) {
      if (mounted) toastRefus(context, err);
    } finally {
      refreshTournoi(ref, widget.id);
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _refuser(Tournoi t, Equipe e) async {
    final motifs = [l10n.trnMotifComplet, l10n.trnMotifNiveau, l10n.trnMotifAutre];
    var motif = motifs.first;
    final ok = await MuDialog.show<bool>(
      context,
      title: l10n.trnRefuserEquipe(e.nom),
      description: l10n.trnRefusDescription,
      consequence: l10n.trnRefusRembourse(formatDT(t.draft.fraisEquipe)),
      tone: MuDialogTone.destructive,
      content: StatefulBuilder(
        builder: (context, set) => MuSelect<String>(
          label: l10n.trnMotifDuRefus,
          value: motif,
          options: [for (final m in motifs) MuSelectOption(value: m, label: m)],
          onChanged: (v) => set(() => motif = v),
        ),
      ),
      actions: [
        MuButton.tertiary(label: l10n.annuler, onPressed: () => Navigator.of(context, rootNavigator: true).pop(false)),
        MuButton.destructive(label: l10n.refuser, onPressed: () => Navigator.of(context, rootNavigator: true).pop(true)),
      ],
    );
    if (ok == true) await _act(e, () => ref.read(tournoiRepositoryProvider).refuser(e.id, motif: motif));
  }

  @override
  Widget build(BuildContext context) => TournoiLoader(
        id: widget.id,
        builder: (context, t) {
          final c = context.mu;
          final teams = ref.watch(equipesProvider(widget.id)).value ?? const <Equipe>[];
          int count(EquipeStatut s) => teams.where((e) => e.statut == s).length;
          final shown = [
            for (final e in teams)
              if (switch (_filtre) {
                _Filtre.toutes => e.statut != EquipeStatut.annulee,
                _Filtre.aValider => e.statut == EquipeStatut.enAttente,
                _Filtre.validees => e.statut == EquipeStatut.confirmee,
                _Filtre.refusees => e.statut == EquipeStatut.refusee,
              })
                e,
          ];
          return OrgPage(
            title: l10n.trnInscriptions,
            subtitle: '${t.draft.nom} · ${formatDateRange(t.draft.debut, t.draft.fin)}',
            back: Routes.organizerTournoi(widget.id),
            children: [
              MuSegmentedControl<_Filtre>(
                semanticLabel: l10n.trnFiltrerEquipes,
                expand: true,
                value: _filtre,
                onChanged: (v) => setState(() => _filtre = v),
                segments: [
                  MuSegment(value: _Filtre.toutes, label: l10n.toutes),
                  MuSegment(value: _Filtre.aValider, label: l10n.trnAValider, badge: count(EquipeStatut.enAttente) == 0 ? null : "${count(EquipeStatut.enAttente)}"),
                  MuSegment(value: _Filtre.validees, label: l10n.trnValidees),
                  MuSegment(value: _Filtre.refusees, label: l10n.trnRefusees),
                ],
              ),
              const SizedBox(height: MuSpace.s4),
              if (shown.isEmpty) MuEmptyState(title: l10n.trnAucuneEquipe, compact: true),
              for (final e in shown) _team(context, t, e),
              const SizedBox(height: MuSpace.s3),
              Text(l10n.trnRefusRembourse(formatDT(t.draft.fraisEquipe)),
                  style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          );
        },
      );

  Widget _team(BuildContext context, Tournoi t, Equipe e) {
    final c = context.mu;
    final busy = _busy == e.id;
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: MuSpace.s3),
      padding: const EdgeInsetsDirectional.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MuRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(e.nom, style: MuType.labelL.copyWith(color: c.text))),
              MuStatusBadge(
                status: e.paye ? MuStatus.paid : MuStatus.pending,
                label: e.paye ? l10n.trnPaye : l10n.trnNonPaye,
                size: MuBadgeSize.s,
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          for (final (i, (_, nom)) in e.membres.indexed)
            Text(i == 0 ? '$nom · ${l10n.trnCapitaine}' : nom, style: MuType.body.copyWith(color: c.textSecondary)),
          if (e.membres.length < t.draft.joueursParEquipe)
            Text(l10n.trnJoueursManquants(t.draft.joueursParEquipe - e.membres.length),
                style: MuType.caption.copyWith(color: c.warningText)),
          if (e.statut == EquipeStatut.refusee && e.motif != null)
            Text(e.motif!, style: MuType.caption.copyWith(color: c.textSecondary)),
          if (e.statut == EquipeStatut.enAttente) ...[
            const SizedBox(height: MuSpace.s3),
            Row(
              children: [
                Expanded(
                  child: MuButton.secondary(
                    label: l10n.refuser,
                    fullWidth: true,
                    onPressed: busy ? null : () => _refuser(t, e),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: MuButton.primary(
                    label: l10n.valider,
                    fullWidth: true,
                    loading: busy,
                    onPressed: busy ? null : () => _act(e, () => ref.read(tournoiRepositoryProvider).valider(e.id)),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: MuSpace.s2),
            Row(children: [
              MuStatusBadge(
                status: switch (e.statut) {
                  EquipeStatut.confirmee => MuStatus.confirmed,
                  EquipeStatut.refusee => MuStatus.failed,
                  _ => MuStatus.cancelled,
                },
                label: switch (e.statut) {
                  EquipeStatut.confirmee => l10n.trnValidee,
                  EquipeStatut.refusee => l10n.trnRefusee,
                  _ => l10n.trnAnnulee,
                },
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
