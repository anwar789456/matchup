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
import '../../profile/widgets/account_menu.dart';
import '../data/owner_repository.dart';
import '../data/reviews_repository.dart';
import '../data/tariffs_repository.dart';
import '../widgets/owner_header.dart';
import '../../../l10n/l10n.dart';

/// OWN-15 · Plus: the owner's account card and Pro plan, then the venue (Terrains, Tarifs,
/// Clients, Avis), the money (Revenus, Abonnement) and the account (Paramètres, Changer de rôle,
/// Aide), and « Se déconnecter ».
class OwnerMoreScreen extends ConsumerWidget {
  const OwnerMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final courts = ref.watch(ownerCourtsProvider).value;
    final tariffs = ref.watch(tariffsProvider).value;
    final reviews = ref.watch(ownerReviewsProvider).value;
    final unanswered = reviews?.unanswered ?? 0;

    Widget chevron() =>
        Icon(PhosphorIcons.caretRight(), size: MuSize.iconS, color: c.textSecondary);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          OwnerHeader(
            title: l10n.plus,
            actions: [
              MuIconButton(
                icon: PhosphorIcons.bell(),
                label: l10n.notificationsNonLues2,
                size: MuIconButtonSize.l,
                badge: 2,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MuSpace.s4,
                MuSpace.s2,
                MuSpace.s4,
                MuSpace.s16 + MuSpace.s10,
              ),
              children: [
                const _AccountCard(),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.monComplexe,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.squareSplitVertical(),
                      title: l10n.terrains,
                      value: courts == null ? null : '${courts.length} terrains',
                      onTap: () => context.push(Routes.ownerCourtList),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.tag(),
                      title: l10n.tarifs,
                      value: tariffs == null
                          ? null
                          : '${formatAmount(tariffs.minPrice)} – ${formatDT(tariffs.maxPrice)} /h',
                      onTap: () => context.push(Routes.ownerTariffs),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.users(),
                      title: l10n.clients,
                      value: l10n.habituesNoShows,
                      onTap: () => context.push(Routes.ownerClients),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.star(),
                      title: l10n.avis,
                      semanticValue: [
                        if (unanswered > 0)
                          unanswered == 1 ? l10n.avisSansReponse : l10n.avisSansReponse2(unanswered),
                        if (reviews != null) _rating(reviews),
                      ].join(', '),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unanswered > 0) ...[
                            Container(
                              width: MuSpace.s2,
                              height: MuSpace.s2,
                              decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: MuSpace.s2),
                          ],
                          if (reviews != null)
                            Text(
                              _rating(reviews),
                              style: MuType.body.copyWith(color: c.textSecondary),
                            ),
                          const SizedBox(width: MuSpace.s2),
                          chevron(),
                        ],
                      ),
                      onTap: () => context.push(Routes.ownerReviews),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.argent,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.coins(),
                      title: l10n.revenus,
                      value: l10n.versementLunOct,
                      onTap: () => context.push(Routes.ownerRevenue),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.crownSimple(),
                      title: l10n.abonnement,
                      value: l10n.proEssai,
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.compte,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.gearSix(),
                      title: l10n.parametres,
                      value: l10n.compteSecurite,
                      onTap: () => context.push(Routes.settings),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.userSwitch(),
                      title: l10n.changerDeRole,
                      value: l10n.roles,
                      onTap: () => showRoleSwitcher(context, current: 'owner'),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.lifebuoy(),
                      title: l10n.aideEtSupport,
                      value: ltr('+216 71 234 567'),
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.signOut(),
                      title: l10n.seDeconnecter,
                      chevron: false,
                      onTap: () => signOutToLogin(context, ref),
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

  static String _rating(ReviewsSummary r) =>
      l10n.avis6(r.average.toStringAsFixed(1).replaceAll('.', ','), r.total);
}

/// Skander, Arena Five, « Terrain vérifié », and the Pro plan trial.
class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return MuCardSurface(
      semanticLabel: l10n.monCompteProprietaire,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const MuAvatar(name: Story.ownerName, size: MuAvatarSize.l),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Story.ownerName, style: MuType.labelL.copyWith(color: c.text)),
                    const SizedBox(height: MuSpace.s1 / 2),
                    Text(
                      '${Story.arenaFive.name} · ${Story.streetOf(Story.arenaFive)}',
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: MuSpace.s1),
                    MuStatusBadge(
                      status: MuStatus.verified,
                      label: l10n.terrainVerifie,
                      size: MuBadgeSize.s,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          Container(
            padding: const EdgeInsets.all(MuSpace.s3),
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
            child: Row(
              children: [
                Container(
                  width: MuSize.controlS + MuSpace.s1,
                  height: MuSize.controlS + MuSpace.s1,
                  decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.smAll),
                  child: Icon(
                    PhosphorIcons.crownSimple(PhosphorIconsStyle.fill),
                    size: MuSize.iconS,
                    color: c.onAccent,
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.planProEssaiGratuit, style: MuType.label.copyWith(color: c.text)),
                      const SizedBox(height: MuSpace.s1 / 2),
                      Text(
                        l10n.jusquAuMerOctPuis,
                        style: MuType.caption.copyWith(color: c.textSecondary),
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
