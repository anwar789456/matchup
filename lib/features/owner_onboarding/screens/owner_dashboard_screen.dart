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

/// The owner's sidebar (Sidebar.md « Content »).
List<MuNavSection> ownerNav() => [
  MuNavSection(
    items: [
      MuNavItem(
        id: 'dashboard',
        label: 'Tableau de bord',
        icon: PhosphorIcons.squaresFour(),
        activeIcon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
      ),
    ],
  ),
  MuNavSection(
    heading: 'Activité',
    items: [
      MuNavItem(id: 'planning', label: 'Planning', icon: PhosphorIcons.calendarDots()),
      MuNavItem(id: 'reservations', label: 'Réservations', icon: PhosphorIcons.ticket()),
      const MuNavItem(id: 'terrains', label: 'Terrains', asset: MuGlyph.court),
      MuNavItem(id: 'tarifs', label: 'Tarifs', icon: PhosphorIcons.tag()),
    ],
  ),
  MuNavSection(
    heading: 'Clientèle',
    items: [
      MuNavItem(id: 'clients', label: 'Clients', icon: PhosphorIcons.users()),
      MuNavItem(id: 'avis', label: 'Avis', icon: PhosphorIcons.star()),
    ],
  ),
  MuNavSection(
    heading: 'Gestion',
    items: [
      MuNavItem(id: 'revenus', label: 'Revenus', icon: PhosphorIcons.coins()),
      MuNavItem(id: 'abonnement', label: 'Abonnement', icon: PhosphorIcons.crownSimple()),
      MuNavItem(id: 'parametres', label: 'Paramètres', icon: PhosphorIcons.gearSix()),
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
    final venue = d.venueName.trim().isEmpty ? 'ton terrain' : d.venueName.trim();
    final firstName = d.manager.split(' ').first;
    final email = d.email.isEmpty ? '' : d.email;

    void go(int step) => context.go(Routes.owner[step]);

    final bounds = OwnerSteps.priceBounds(d);
    final players = OwnerCatalog.playersOf(d.courts.firstOrNull?.sport ?? MuSport.football);
    String perHead(int v) => formatAmount((v / players * 2).round() / 2);

    final tasks = [
      _Task(
        title: 'Infos de l’entreprise',
        detail: d.reached >= 1
            ? '${d.legalName} · matricule fiscal ${d.taxId.isEmpty ? 'à ajouter' : 'ajouté'}'
            : 'Raison sociale, matricule fiscal et contact.',
        done: d.reached >= 1,
        action: d.reached >= 1 ? 'Modifier' : 'Reprendre',
        semanticAction: 'Modifier les infos de l’entreprise',
        onAction: () => go(0),
      ),
      _Task(
        title: 'Adresse et terrains',
        detail: d.reached >= 3
            ? '${d.street}, ${d.city} · ${OwnerSteps.courtsSummary(d).replaceFirst(' · ', ' ')}'
            : 'Où te trouver, et chaque terrain réservable.',
        done: d.reached >= 3,
        action: d.reached >= 3 ? 'Modifier' : 'Reprendre',
        semanticAction: 'Modifier l’adresse et les terrains',
        onAction: () => go(d.reached >= 3 ? 1 : d.reached.clamp(1, 2)),
      ),
      _Task(
        title: 'Horaires et tarifs',
        detail: d.reached >= 5 && bounds != null
            ? '${d.openDays}j/7 · de ${bounds.$1} à ${bounds.$2} DT /h, soit ${perHead(bounds.$1)} '
                  'à ${perHead(bounds.$2)} DT /pers.'
            : 'Quand on peut réserver, et à quel prix.',
        done: d.reached >= 5,
        action: d.reached >= 5 ? 'Modifier' : 'Reprendre',
        semanticAction: 'Modifier les horaires et les tarifs',
        onAction: () => go(d.reached >= 5 ? 3 : d.reached.clamp(3, 4)),
      ),
      _Task(
        title: 'Photos et versements',
        detail: d.reached >= 7
            ? '${d.photos.length} photos · ${OwnerCatalog.bankName(d.bank)} '
                  '${OwnerSteps.maskRib(d.rib)}'
            : 'Tes photos, et le compte où on verse tes revenus.',
        done: d.reached >= 7,
        badge: d.reached >= 7
            ? const MuStatusBadge(
                status: MuStatus.pending,
                label: 'RIB en vérification',
                size: MuBadgeSize.s,
              )
            : null,
        action: d.reached >= 7 ? 'Modifier' : 'Reprendre',
        semanticAction: 'Modifier les photos et les versements',
        onAction: () => go(d.reached >= 7 ? 5 : d.reached.clamp(5, 6)),
      ),
      if (d.trialStartedAt == null && d.reached >= 7)
        _Task(
          title: 'Choisis ton offre',
          detail: '${OwnerCatalog.trialDays} jours d’essai gratuit, sans paiement aujourd’hui.',
          done: false,
          action: 'Choisir',
          onAction: () => go(7),
        ),
      _Task(
        title: 'Ajoute ta politique d’annulation',
        detail: 'Les joueurs la lisent avant de payer. Par exemple : remboursé jusqu’à 24 h avant.',
        done: false,
        action: 'Ajouter',
        onAction: () => showComingSoon(context),
      ),
      _Task(
        title: 'Publie ton premier créneau',
        detail:
            'Tes terrains deviennent réservables et visibles à ${d.city.isEmpty ? 'ta ville' : d.city}.',
        done: false,
        action: 'Publier',
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
                  Text('MISE EN ROUTE', style: MuType.overline.copyWith(color: c.textSecondary)),
                  const SizedBox(height: MuSpace.s1),
                  Semantics(
                    header: true,
                    child: Text(
                      'Termine la configuration ${elideDe(venue)}',
                      style: MuType.h2.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    left == 0
                        ? 'Tout est prêt.'
                        : 'Encore $left étape${left > 1 ? 's' : ''} et les joueurs pourront '
                              'réserver.',
                    style: MuType.body.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: MuSpace.s1),
                child: SizedBox(
                  width: _progressWidth,
                  child: MuProgressBar(
                    label: 'Configuration',
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
                  child: Text('Réservations du jour', style: MuType.h3.copyWith(color: c.text)),
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
                title: 'Aucune réservation pour l’instant',
                description:
                    'Publie ton premier créneau : il apparaîtra aux joueurs '
                    '${elideDe(d.city.isEmpty ? 'ta ville' : d.city)}.',
                actions: [
                  MuButton.secondary(
                    label: 'Ouvrir le planning',
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
      role: MuSidebarRole(role: 'Propriétaire', name: venue),
      user: MuSidebarUser(name: d.manager, email: email),
      userRole: 'Propriétaire',
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
                    child: Text('Bonjour $firstName', style: MuType.h1.copyWith(color: c.text)),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    trialEnd != null
                        ? '${withFullStop('Ton essai $plan court jusqu’au ${formatDay(trialEnd)}')} Voici où en est '
                              '$venue.'
                        : 'Termine la configuration pour démarrer ton essai gratuit. Voici où en '
                              'est $venue.',
                    style: MuType.bodyL.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              const MuStatusBadge(status: MuStatus.draft, label: 'Pas encore visible des joueurs'),
            ],
          ),
          const SizedBox(height: MuSpace.s6),
          ProSplit(start: setup, end: bookings),
          const SizedBox(height: MuSpace.s6),
          ProCardRow(
            columns: width < ProSplit.stackBelow ? 2 : 4,
            children: const [
              MuKpiCard(
                label: 'Taux d’occupation',
                value: '—',
                note: 'Calculé dès ta première réservation',
              ),
              MuKpiCard(
                label: 'Revenus du jour',
                value: '0',
                unit: 'DT',
                note: 'Aucun paiement encaissé',
              ),
              MuKpiCard(label: 'Réservations', value: '0', note: 'Pas encore de comparaison'),
              MuKpiCard(
                label: 'Note moyenne',
                value: '—',
                note: 'Après les premiers avis des joueurs',
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
      label: t.done ? 'Fait' : 'À faire',
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
