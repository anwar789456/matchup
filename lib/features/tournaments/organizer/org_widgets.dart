import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';

/// A page of the organiser space: compact bar with « Retour », the content in a list, and an
/// optional sticky bar at the bottom.
class OrgPage extends StatelessWidget {
  const OrgPage({
    super.key,
    required this.title,
    required this.children,
    required this.back,
    this.subtitle,
    this.bottom,
  });

  final String title;
  final String? subtitle;

  /// Where « Retour » goes when there is nothing to pop.
  final String back;
  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(title: title, subtitle: subtitle, onBack: () => goBack(context, back)),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s8),
              children: children,
            ),
          ),
          if (bottom != null)
            DecoratedBox(
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
              child: SafeArea(
                top: false,
                child: Padding(padding: const EdgeInsetsDirectional.all(MuSpace.s4), child: bottom),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loads [id]'s tournament, then builds; a spinner meanwhile, a message if it is gone.
class TournoiLoader extends ConsumerWidget {
  const TournoiLoader({super.key, required this.id, required this.builder});

  final String id;
  final Widget Function(BuildContext context, Tournoi t) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final t = ref.watch(tournoiProvider(id));
    return t.when(
      data: (t) => t == null
          ? OrgPage(
              title: l10n.trnIntrouvable,
              back: Routes.organizerTournois,
              children: [MuEmptyState(title: l10n.trnIntrouvable)],
            )
          : builder(context, t),
      loading: () => Scaffold(backgroundColor: c.bg, body: Center(child: MuSpinner(semanticLabel: l10n.chargement))),
      error: (e, _) => OrgPage(
        title: l10n.trnIntrouvable,
        back: Routes.organizerTournois,
        children: [MuEmptyState(title: '$e')],
      ),
    );
  }
}

/// Team names by id, for brackets and score sheets.
Map<String, String> teamNames(List<Equipe> teams) => {for (final e in teams) e.id: e.nom};

/// The status of a tournament as a badge.
MuStatusBadge statutBadge(TournoiStatut s) => switch (s) {
      TournoiStatut.brouillon => MuStatusBadge(status: MuStatus.draft, label: l10n.trnStatutBrouillon),
      TournoiStatut.inscriptionsOuvertes => MuStatusBadge(status: MuStatus.confirmed, label: l10n.trnStatutOuvert),
      TournoiStatut.inscriptionsFermees => MuStatusBadge(status: MuStatus.full, label: l10n.trnStatutFerme),
      TournoiStatut.enCours => MuStatusBadge(status: MuStatus.live, label: l10n.trnStatutEnCours),
      TournoiStatut.termine => MuStatusBadge(status: MuStatus.neutral, label: l10n.trnStatutTermine),
      TournoiStatut.annule => MuStatusBadge(status: MuStatus.cancelled, label: l10n.trnStatutAnnule),
    };

/// A refusal from the repository, as a toast.
void toastRefus(BuildContext context, Object e) {
  MuToast.show(
    context,
    tone: MuToastTone.error,
    title: e is TournoiRefus ? e.message : l10n.erreur,
  );
}
