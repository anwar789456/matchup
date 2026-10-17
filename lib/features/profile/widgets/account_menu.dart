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
    title: 'Mon compte',
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
                label: 'Mon profil, ${me?.displayName ?? Story.myName}',
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
                title: 'Mon profil',
                onTap: () => go(Routes.profile),
              ),
              _Item(
                icon: PhosphorIcons.wallet(),
                title: 'Portefeuille',
                detail: 'Remboursements et parts payées',
                end: Text(
                  formatDT(me?.balance ?? Story.myBalance),
                  style: MuType.numM.copyWith(color: c.text),
                ),
                semanticLabel: 'Portefeuille, solde ${formatDT(me?.balance ?? Story.myBalance)}',
                onTap: () => go(Routes.wallet),
              ),
              _Item(
                icon: PhosphorIcons.crownSimple(),
                title: 'MatchUp Premium',
                detail: switch (ref.watch(subscriptionProvider).value?.status) {
                  PremiumStatus.trial => 'Essai gratuit en cours',
                  PremiumStatus.cancelled => 'Résilié · actif jusqu’au 30 oct.',
                  _ => '14 jours gratuits, sans engagement',
                },
                onTap: () => go(
                  ref.read(subscriptionProvider).value?.premium ?? false
                      ? Routes.subscription
                      : Routes.subscriptionOffers,
                ),
              ),
              _Item(
                icon: PhosphorIcons.gearSix(),
                title: 'Paramètres',
                onTap: () => go(Routes.settings),
              ),
              _Item(
                icon: PhosphorIcons.arrowsLeftRight(),
                title: 'Changer de rôle',
                detail: 'Joueur · Propriétaire de terrain à terminer',
                end: Semantics(
                  label: 'Une configuration à terminer',
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
                title: 'Aide',
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
                title: 'Se déconnecter',
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
Future<void> showRoleSwitcher(BuildContext context) => MuRoleSwitcher.show(
  context,
  current: 'player',
  roles: [
    MuRole(
      id: 'player',
      name: 'Joueur',
      icon: PhosphorIcons.personSimpleRun(),
      detail: 'Padel ${formatLevel(Story.myLevels[MuSport.padel]!)} · ${Story.zone}',
    ),
    MuRole(
      id: 'owner',
      name: 'Propriétaire de terrain',
      icon: PhosphorIcons.storefront(),
      detail: 'Configuration à terminer · 3 étapes',
      pending: 1,
      semanticLabel: 'Passer en Propriétaire de terrain et terminer la configuration',
    ),
  ],
  onChanged: (r) => context.push(Routes.ownerCompany),
  onAddRole: () => context.push(Routes.roleChoice),
);

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
