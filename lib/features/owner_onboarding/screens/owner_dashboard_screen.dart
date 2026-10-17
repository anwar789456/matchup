import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../../common/widgets/pro_dashboard_scaffold.dart';
import '../../common/widgets/pro_wizard_scaffold.dart' show showComingSoon;
import '../controllers/owner_controller.dart';
import '../data/owner_repository.dart';
import 'plan_screen.dart' show OwnerPlans;
import '../../../l10n/l10n.dart';

/// The owner's sidebar (Sidebar.md « Content »).
List<MuNavSection> ownerNav() => [
  MuNavSection(
    items: [
      MuNavItem(
        id: 'dashboard',
        label: l10n.tableauDeBord,
        icon: PhosphorIcons.squaresFour(),
        activeIcon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
      ),
    ],
  ),
  MuNavSection(
    heading: l10n.activite,
    items: [
      MuNavItem(id: 'planning', label: l10n.planning, icon: PhosphorIcons.calendarDots()),
      MuNavItem(id: 'reservations', label: l10n.reservations, icon: PhosphorIcons.ticket()),
      MuNavItem(id: 'terrains', label: l10n.terrains, asset: MuGlyph.court),
      MuNavItem(id: 'tarifs', label: l10n.tarifs, icon: PhosphorIcons.tag()),
    ],
  ),
  MuNavSection(
    heading: l10n.clientele,
    items: [
      MuNavItem(id: 'clients', label: l10n.clients, icon: PhosphorIcons.users()),
      MuNavItem(id: 'avis', label: l10n.avis, icon: PhosphorIcons.star()),
    ],
  ),
  MuNavSection(
    heading: l10n.gestion,
    items: [
      MuNavItem(id: 'revenus', label: l10n.revenus, icon: PhosphorIcons.coins()),
      MuNavItem(id: 'abonnement', label: l10n.abonnement, icon: PhosphorIcons.crownSimple()),
      MuNavItem(id: 'parametres', label: l10n.parametres, icon: PhosphorIcons.gearSix()),
    ],
  ),
];

/// One line of « Mise en route ».
class _Task {
  const _Task({
    required this.title,
    required this.detail,
    required this.done,
    required this.action,
    required this.onAction,
    this.semanticAction,
    this.badge,
  });

  final String title;
  final String detail;
  final bool done;
  final String action;
  final String? semanticAction;
  final VoidCallback onAction;
  final Widget? badge;
}

/// OWN-09 — the owner dashboard on its first day: what is left to set up, today's bookings (none
/// yet) and the four KPIs, empty until the first booking.
class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final d = ref.watch(ownerProvider).requireValue;
    final now = ref.watch(clockProvider)();
    final width = MediaQuery.sizeOf(context).width;
    final venue = d.venueName.trim().isEmpty ? l10n.tonTerrain : d.venueName.trim();
    final firstName = d.manager.split(' ').first;
    final email = d.email.isEmpty ? '' : d.email;

    void go(int step) => context.go(Routes.owner[step]);

    final bounds = OwnerSteps.priceBounds(d);
    final players = OwnerCatalog.playersOf(d.courts.firstOrNull?.sport ?? MuSport.football);
    String perHead(int v) => formatAmount((v / players * 2).round() / 2);

    final tasks = [
      _Task(
        title: l10n.infosDeLEntreprise,
        detail: d.reached >= 1
            ? l10n.matriculeFiscal2(d.legalName, d.taxId.isEmpty ? l10n.aAjouter : l10n.ajoute)
            : l10n.raisonSocialeMatriculeFiscalEt,
        done: d.reached >= 1,
        action: d.reached >= 1 ? l10n.modifier : l10n.reprendre2,
        semanticAction: l10n.modifierLesInfosDeL,
        onAction: () => go(0),
      ),
      _Task(
        title: l10n.adresseEtTerrains,
        detail: d.reached >= 3
            ? '${d.street}, ${d.city} · ${OwnerSteps.courtsSummary(d).replaceFirst(' · ', ' ')}'
            : l10n.ouTeTrouverEtChaque,
        done: d.reached >= 3,
        action: d.reached >= 3 ? l10n.modifier : l10n.reprendre2,
        semanticAction: l10n.modifierLAdresseEtLes,
        onAction: () => go(d.reached >= 3 ? 1 : d.reached.clamp(1, 2)),
      ),
      _Task(
        title: l10n.horairesEtTarifs,
        detail: d.reached >= 5 && bounds != null
            ? l10n.jDeADtH(d.openDays, bounds.$1, bounds.$2, perHead(bounds.$1), perHead(bounds.$2))
            : l10n.quandOnPeutReserverEt,
        done: d.reached >= 5,
        action: d.reached >= 5 ? l10n.modifier : l10n.reprendre2,
        semanticAction: l10n.modifierLesHorairesEtLes,
        onAction: () => go(d.reached >= 5 ? 3 : d.reached.clamp(3, 4)),
      ),
      _Task(
        title: l10n.photosEtVersements,
        detail: d.reached >= 7
            ? l10n.photos2(d.photos.length, OwnerCatalog.bankName(d.bank), OwnerSteps.maskRib(d.rib))
            : l10n.tesPhotosEtLeCompte,
        done: d.reached >= 7,
        badge: d.reached >= 7
            ? MuStatusBadge(
                status: MuStatus.pending,
                label: l10n.ribEnVerification,
                size: MuBadgeSize.s,
              )
            : null,
        action: d.reached >= 7 ? l10n.modifier : l10n.reprendre2,
        semanticAction: l10n.modifierLesPhotosEtLes,
        onAction: () => go(d.reached >= 7 ? 5 : d.reached.clamp(5, 6)),
      ),
      if (d.trialStartedAt == null && d.reached >= 7)
        _Task(
          title: l10n.choisisTonOffre,
          detail: l10n.joursDEssaiGratuitSans(OwnerCatalog.trialDays),
          done: false,
          action: l10n.choisir,
          onAction: () => go(7),
        ),
      _Task(
        title: l10n.ajouteTaPolitiqueDAnnulation,
        detail: l10n.lesJoueursLaLisentAvant,
        done: false,
        action: l10n.ajouter,
        onAction: () => showComingSoon(context),
      ),
      _Task(
        title: l10n.publieTonPremierCreneau,
        detail:
            l10n.tesTerrainsDeviennentReservablesEt(d.city.isEmpty ? l10n.taVille : d.city),
        done: false,
        action: l10n.publier,
        onAction: () => showComingSoon(context),
      ),
    ];
    final done = tasks.where((t) => t.done).length;
    final left = tasks.length - done;
    final firstOpen = tasks.indexWhere((t) => !t.done);
    final percent = (done / tasks.length * 100).round();

    final trialEnd = d.trialStartedAt?.add(const Duration(days: OwnerCatalog.trialDays));
    final plan = OwnerPlans.of(d.plan).name;

    final setup = ProCard(
      padding: const EdgeInsets.fromLTRB(MuSpace.s6, MuSpace.s6, MuSpace.s6, MuSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: MuSpace.s6,
            runSpacing: MuSpace.s3,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.miseEnRoute, style: MuType.overline.copyWith(color: c.textSecondary)),
                  const SizedBox(height: MuSpace.s1),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.termineLaConfiguration(elideDe(venue)),
                      style: MuType.h2.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    left == 0
                        ? l10n.toutEstPret
                        : l10n.encoreEtapeEtLesJoueurs(left, left > 1 ? 's' : ''),
                    style: MuType.body.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: MuSpace.s1),
                child: SizedBox(
                  width: _progressWidth,
                  child: MuProgressBar(
                    label: l10n.configuration,
                    value: done.toDouble(),
                    max: tasks.length.toDouble(),
                    size: MuProgressSize.l,
                    valueLabel: '$done/${tasks.length} · $percent %',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          for (final (i, t) in tasks.indexed)
            _TaskRow(task: t, primary: i == firstOpen, last: i == tasks.length - 1),
        ],
      ),
    );

    final bookings = ProCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.reservationsDuJour, style: MuType.h3.copyWith(color: c.text)),
                ),
              ),
              Text(formatDay(now), style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          // Beside the setup card the empty state centres in the stretched card.
          _fill(
            width >= ProSplit.stackBelow,
            Center(
              child: MuEmptyState(
                compact: true,
                illustration: MuEmptyIllustration.bookings,
                title: l10n.aucuneReservationPourLInstant,
                description:
                    l10n.publieTonPremierCreneauIl(elideDe(d.city.isEmpty ? l10n.taVille : d.city)),
                actions: [
                  MuButton.secondary(
                    label: l10n.ouvrirLePlanning,
                    leading: PhosphorIcons.calendarDots(),
                    onPressed: () => showComingSoon(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return ProDashboardScaffold(
      sections: ownerNav(),
      role: MuSidebarRole(role: l10n.proprietaire, name: venue),
      user: MuSidebarUser(name: d.manager, email: email),
      userRole: l10n.proprietaire,
      notifications: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: MuSpace.s6,
            runSpacing: MuSpace.s3,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.bonjour(firstName), style: MuType.h1.copyWith(color: c.text)),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    trialEnd != null
                        ? l10n.voiciOuEnEst(withFullStop(l10n.tonEssaiCourtJusquAu(plan, formatDay(trialEnd))), venue)
                        : l10n.termineLaConfigurationPourDemarrer(venue),
                    style: MuType.bodyL.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              MuStatusBadge(status: MuStatus.draft, label: l10n.pasEncoreVisibleDesJoueurs),
            ],
          ),
          const SizedBox(height: MuSpace.s6),
          ProSplit(start: setup, end: bookings),
          const SizedBox(height: MuSpace.s6),
          ProCardRow(
            columns: width < ProSplit.stackBelow ? 2 : 4,
            children: [
              MuKpiCard(
                label: l10n.tauxDOccupation,
                value: '—',
                note: l10n.calculeDesTaPremiereReservation,
              ),
              MuKpiCard(
                label: l10n.revenusDuJour,
                value: '0',
                unit: 'DT',
                note: l10n.aucunPaiementEncaisse,
              ),
              MuKpiCard(label: l10n.reservations, value: '0', note: l10n.pasEncoreDeComparaison),
              MuKpiCard(
                label: l10n.noteMoyenne,
                value: '—',
                note: l10n.apresLesPremiersAvisDes,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // OWN-09 source: the progress block is 220 wide.
  static const double _progressWidth = 220;

  static Widget _fill(bool fill, Widget child) => fill ? Expanded(child: child) : child;
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.primary, required this.last});

  final _Task task;
  final bool primary;
  final bool last;

  // OWN-09 source: rows ≥ 52; 2 px between title and detail.
  static const double _minHeight = 52;
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final t = task;
    final Widget action;
    if (t.done) {
      action = Semantics(
        label: t.semanticAction,
        excludeSemantics: t.semanticAction != null,
        child: MuButton.tertiary(label: t.action, size: MuButtonSize.s, onPressed: t.onAction),
      );
    } else if (primary) {
      action = MuButton.primary(
        label: t.action,
        leading: t.action == 'Ajouter' ? PhosphorIcons.plus() : null,
        onPressed: t.onAction,
      );
    } else {
      action = MuButton.secondary(label: t.action, onPressed: t.onAction);
    }

    return Semantics(
      container: true,
      label: t.done ? l10n.fait : l10n.aFaire,
      child: Container(
        constraints: const BoxConstraints(minHeight: _minHeight),
        padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Icon(
              t.done
                  ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                  : PhosphorIcons.circleDashed(),
              size: MuSize.iconM,
              color: t.done ? c.successText : c.textSecondary,
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: t.done
                        ? MuType.body.copyWith(color: c.textSecondary)
                        : MuType.label.copyWith(color: c.text),
                  ),
                  const SizedBox(height: _lineGap),
                  Text(t.detail, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            if (t.badge != null) ...[const SizedBox(width: MuSpace.s3), t.badge!],
            const SizedBox(width: MuSpace.s3),
            action,
          ],
        ),
      ),
    );
  }
}
