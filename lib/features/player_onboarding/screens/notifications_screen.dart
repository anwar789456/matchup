import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/onboarding_controller.dart';
import '../data/location_services.dart';
import '../widgets/onboarding_step_scaffold.dart';
import '../../../l10n/l10n.dart';

/// PLY-09 · Notifications: concrete examples before the system prompt; « Plus tard » is as visible.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _asking = false;

  void _next() => context.push(Routes.playerProfile);

  Future<void> _activate() async {
    setState(() => _asking = true);
    final outcome = await ref.read(devicePermissionsProvider).requestNotifications();
    await ref.onboarding.setNotifications(granted: outcome == PermissionOutcome.granted);
    if (!mounted) return;
    setState(() => _asking = false);
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final state = ref.watchOnboarding();
    Widget card(Widget item) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: MuRadius.mdAll,
            boxShadow: MuElevation.of(context).level2,
          ),
          child: ClipRRect(borderRadius: MuRadius.mdAll, child: item),
        );

    return OnboardingStepScaffold(
      route: Routes.playerNotifications,
      step: 6,
      stepTitle: l10n.notifications,
      onBack: () => goBack(
        context,
        state.locationGranted == false ? Routes.playerLocationDenied : Routes.playerZones,
      ),
      onSkip: _next,
      body: [
        Semantics(
          image: true,
          label: l10n.exemplesDeNotificationsMatchupUne,
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: MuRadius.lgAll,
            child: Stack(
              children: [
                const Positioned.fill(child: MuCourtArt(sport: MuSport.padel)),
                Positioned.fill(child: ColoredBox(color: c.scrim)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s4),
                  child: Column(
                    children: [
                      card(MuNotificationItem(
                        priority: MuNotificationPriority.urgent,
                        sport: MuSport.padel,
                        title: l10n.unePlaceSEstLiberee,
                        body: l10n.padelCeSoirASmash,
                        time: 'maintenant',
                        background: c.surfaceElevated,
                      )),
                      const SizedBox(height: MuSpace.s2),
                      card(MuNotificationItem(
                        avatarName: l10n.mariemK,
                        sport: MuSport.padel,
                        title: l10n.mariemKTInviteA,
                        body: l10n.padelVsDimOct18h30,
                        time: l10n.min2,
                        background: c.surfaceElevated,
                      )),
                      const SizedBox(height: MuSpace.s2),
                      card(MuNotificationItem(
                        sport: MuSport.football,
                        title: l10n.rappelMatchCeSoir20h00,
                        body: l10n.arenaFiveTerrainLaMarsa,
                        time: '1 h',
                        background: c.surfaceElevated,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        FlowTitle(
          l10n.neRateAucunePartie,
          lead: l10n.placesLibereesInvitationsRappelsOn,
        ),
      ],
      bottomBar: [
        ProgressSavedNote(
          icon: PhosphorIcons.deviceMobile(),
          text: l10n.tonTelephoneVaTeDemander2,
        ),
        MuButton.primary(
          label: l10n.activerLesNotifications,
          leading: PhosphorIcons.bellRinging(),
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _asking,
          onPressed: _activate,
        ),
        MuButton.tertiary(
          label: l10n.plusTard,
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: _next,
        ),
      ],
    );
  }
}
