import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/session.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../../home/controllers/home_providers.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../subscription/data/subscription_repository.dart';
import '../data/profile_repository.dart';
import '../../../l10n/l10n.dart';

/// PRF-05 · Menu du compte: the sheet from the Home avatar — profile, wallet, Premium, settings,
/// role switch (PRF-06), help, sign out.
Future<void> showAccountMenu(BuildContext context, WidgetRef ref) {
  final nav = Navigator.of(context, rootNavigator: true);
  void go(String route) {
    nav.pop();
    context.push(route);
  }

  return MuBottomSheet.show<void>(
    context,
    title: l10n.monCompte,
    height: MuSheetHeight.auto,
    child: Consumer(
      builder: (context, ref, _) {
        final c = context.mu;
        final me = ref.watch(meProvider).value;
        final profile = ref.watch(myProfileProvider).value;
        final padel = me?.levels[MuSport.padel] ?? Story.myLevels[MuSport.padel]!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s2, 0, MuSpace.s2, MuSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                label: l10n.monProfil2(me?.displayName ?? Story.myName),
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: MuRadius.smAll,
                  onTap: () => go(Routes.profile),
                  child: Padding(
                    padding: const EdgeInsets.all(MuSpace.s2),
                    child: Row(
                      children: [
                        MuAvatar(name: me?.displayName ?? Story.myName, size: MuAvatarSize.l),
                        const SizedBox(width: MuSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                me?.displayName ?? Story.myName,
                                style: MuType.h3.copyWith(color: c.text),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  MuSportIcon(
                                    MuSport.padel,
                                    size: MuSize.iconXs,
                                    color: c.textSecondary,
                                  ),
                                  const SizedBox(width: MuSpace.s1),
                                  MuLevelIndicator(level: padel, size: MuLevelSize.s),
                                  const SizedBox(width: MuSpace.s2),
                                  MuReliabilityBadge(
                                    score: profile?.reliability.score ?? 96,
                                    size: MuBadgeSize.s,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          PhosphorIcons.caretRight(),
                          size: MuSize.iconS,
                          color: c.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MuSpace.s2),
              Divider(height: 1, thickness: 1, color: c.border),
              const SizedBox(height: MuSpace.s2),
              _Item(
                icon: PhosphorIcons.userCircle(),
                title: l10n.monProfil,
                onTap: () => go(Routes.profile),
              ),
              _Item(
                icon: PhosphorIcons.wallet(),
                title: l10n.portefeuille,
                detail: l10n.remboursementsEtPartsPayees,
                end: Text(
                  formatDT(me?.balance ?? Story.myBalance),
                  style: MuType.numM.copyWith(color: c.text),
                ),
                semanticLabel: l10n.portefeuilleSolde(formatDT(me?.balance ?? Story.myBalance)),
                onTap: () => go(Routes.wallet),
              ),
              _Item(
                icon: PhosphorIcons.crownSimple(),
                title: l10n.matchupPremium,
                detail: switch (ref.watch(subscriptionProvider).value?.status) {
                  PremiumStatus.trial => l10n.essaiGratuitEnCours,
                  PremiumStatus.cancelled => l10n.resilieActifJusquAuOct,
                  _ => l10n.joursGratuitsSansEngagement,
                },
                onTap: () => go(
                  ref.read(subscriptionProvider).value?.premium ?? false
                      ? Routes.subscription
                      : Routes.subscriptionOffers,
                ),
              ),
              _Item(
                icon: PhosphorIcons.gearSix(),
                title: l10n.parametres,
                onTap: () => go(Routes.settings),
              ),
              _Item(
                icon: PhosphorIcons.arrowsLeftRight(),
                title: l10n.changerDeRole,
                detail: l10n.joueurProprietaireDeTerrainA,
                end: Semantics(
                  label: l10n.uneConfigurationATerminer,
                  child: Container(
                    width: MuSpace.s2,
                    height: MuSpace.s2,
                    decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
                  ),
                ),
                onTap: () {
                  nav.pop();
                  showRoleSwitcher(context);
                },
              ),
              _Item(
                icon: PhosphorIcons.lifebuoy(),
                title: l10n.aide,
                onTap: () {
                  nav.pop();
                  showComingSoon(context);
                },
              ),
              const SizedBox(height: MuSpace.s2),
              Divider(height: 1, thickness: 1, color: c.border),
              const SizedBox(height: MuSpace.s2),
              _Item(
                icon: PhosphorIcons.signOut(),
                title: l10n.seDeconnecter,
                onTap: () async {
                  nav.pop();
                  await signOutToLogin(context, ref);
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// PRF-06 · Changer de rôle.
/// [current] is the space on screen (`player`, `owner`); picking another one opens it.
Future<void> showRoleSwitcher(BuildContext context, {String current = 'player'}) {
  final router = GoRouter.of(context);
  return MuRoleSwitcher.show(
  context,
  current: current,
  roles: [
    MuRole(
      id: 'player',
      name: l10n.joueur,
      icon: PhosphorIcons.personSimpleRun(),
      detail: l10n.padel2(formatLevel(Story.myLevels[MuSport.padel]!), Story.zone),
    ),
    MuRole(
      id: 'owner',
      name: l10n.proprietaireDeTerrain,
      icon: PhosphorIcons.storefront(),
      detail: l10n.configurationATerminerEtapes,
      pending: 1,
      semanticLabel: l10n.passerEnProprietaireDeTerrain,
    ),
    MuRole(id: 'admin', name: l10n.adminMatchup, icon: PhosphorIcons.shieldCheck()),
  ],
  onChanged: (r) {
    if (r.id == current) return;
    router.go(switch (r.id) {
      'owner' => Routes.ownerToday,
      'admin' => Routes.adminOverview,
      _ => Routes.home,
    });
  },
  onAddRole: () => router.push(Routes.roleChoice),
);
}

/// Signs out and lands on the login (AUTH-05).
Future<void> signOutToLogin(BuildContext context, WidgetRef ref) async {
  await ref.read(sessionProvider.notifier).signOut();
  if (context.mounted) context.go(Routes.login);
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.title,
    required this.onTap,
    this.detail,
    this.end,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? end;
  final String? semanticLabel;
  final VoidCallback onTap;

  // prf-item: min 56 high, gap 16, padding 0 8.
  static const double _minHeight = 56;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: MuRadius.smAll,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s2),
            child: Row(
              children: [
                Icon(icon, size: MuSize.iconM, color: c.text),
                const SizedBox(width: MuSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: MuType.label.copyWith(color: c.text)),
                      if (detail != null)
                        Text(detail!, style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                ?end,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
