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
      stepTitle: 'Notifications',
      onBack: () => goBack(
        context,
        state.locationGranted == false ? Routes.playerLocationDenied : Routes.playerZones,
      ),
      onSkip: _next,
      body: [
        Semantics(
          image: true,
          label: 'Exemples de notifications MatchUp : une place libérée, une invitation de '
              'Mariem K., un rappel de match',
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
                        title: 'Une place s’est libérée',
                        body: 'Padel ce soir à Smash Padel Club. Tu as 14:59 pour la réclamer.',
                        time: 'maintenant',
                        background: c.surfaceElevated,
                      )),
                      const SizedBox(height: MuSpace.s2),
                      card(MuNotificationItem(
                        avatarName: 'Mariem K.',
                        sport: MuSport.padel,
                        title: 'Mariem K. t’invite à jouer',
                        body: 'Padel 2 vs 2 · dim. 19 oct. · 18h30 · 15 DT par personne.',
                        time: '12 min',
                        background: c.surfaceElevated,
                      )),
                      const SizedBox(height: MuSpace.s2),
                      card(MuNotificationItem(
                        sport: MuSport.football,
                        title: 'Rappel : match ce soir 20h00',
                        body: 'Arena Five · Terrain 2 · La Marsa. Pars vers 19h35.',
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
        const FlowTitle(
          'Ne rate aucune partie',
          lead: 'Places libérées, invitations, rappels : on te prévient seulement pour ce qui '
              'compte. Tu règles tout dans Paramètres.',
        ),
      ],
      bottomBar: [
        ProgressSavedNote(
          icon: PhosphorIcons.deviceMobile(),
          text: 'Ton téléphone va te demander l’autorisation juste après.',
        ),
        MuButton.primary(
          label: 'Activer les notifications',
          leading: PhosphorIcons.bellRinging(),
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _asking,
          onPressed: _activate,
        ),
        MuButton.tertiary(
          label: 'Plus tard',
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: _next,
        ),
      ],
    );
  }
}
