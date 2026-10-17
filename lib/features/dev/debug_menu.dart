import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/connectivity.dart';
import '../../core/platform.dart';
import '../../router.dart';
import '../../theme/theme.dart';
import '../../ui/ui.dart';
import '../common/data/story_data.dart';
import '../games/widgets/claim_takeover.dart';
import '../home/controllers/home_providers.dart';
import '../notifications/controllers/live_events.dart';
import '../owner/data/camera.dart';
import '../notifications/data/push_service.dart';
import '../payments/data/payment_repository.dart';
import '../states/data/account_status.dart';
import '../states/widgets/state_widgets.dart';

/// Whether the floating debug button shows: debug builds, not in widget tests.
final debugMenuEnabledProvider = Provider<bool>((ref) => kDebugMode && !isWidgetTest);

/// The debug menu (CLAUDE.md rules 10–11): the next payment's outcome, real-time events and
/// simulated pushes, reachable from any screen through a small floating button.
class DebugMenuButton extends ConsumerWidget {
  const DebugMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Opacity(
          opacity: MuOpacity.disabled,
          child: Material(
            color: c.surfaceInverse,
            shape: const CircleBorder(),
            // No tooltip: this button sits above the navigator, outside its overlay.
            child: Semantics(
              button: true,
              label: 'Menu debug',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  final nav = ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;
                  if (nav != null) showDebugMenu(nav, ref);
                },
                child: SizedBox.square(
                  dimension: MuSize.touchTarget,
                  child: Icon(PhosphorIcons.bug(), size: MuSize.iconS, color: c.textInverse),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showDebugMenu(BuildContext context, WidgetRef ref) => MuBottomSheet.show<void>(
  context,
  title: 'Menu debug',
  height: MuSheetHeight.full,
  child: Consumer(
    builder: (context, ref, _) {
      final c = context.mu;
      Widget section(String title) => Padding(
        padding: const EdgeInsets.only(top: MuSpace.s5, bottom: MuSpace.s2),
        child: Text(title.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
      );
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s8),
        children: [
          section('Paiement'),
          MuSelect<PaymentOutcome>(
            label: 'Issue du prochain paiement',
            value: ref.watch(paymentOutcomeProvider),
            options: [
              for (final o in PaymentOutcome.values) MuSelectOption(value: o, label: o.label),
            ],
            onChanged: (o) => ref.read(paymentOutcomeProvider.notifier).select(o),
          ),
          section('États (STA-01 à STA-09)'),
          MuSwitch(
            value: ref.watch(simulatedOfflineProvider),
            label: 'Hors ligne (STA-01)',
            onChanged: (v) => ref.read(simulatedOfflineProvider.notifier).set(v),
          ),
          MuSwitch(
            value: ref.watch(simulatedServerErrorProvider),
            label: 'Erreur serveur 503 (STA-02, STA-09)',
            onChanged: (v) {
              ref.read(simulatedServerErrorProvider.notifier).set(v);
              ref.invalidate(upcomingMatchesProvider);
            },
          ),
          MuSwitch(
            value: !ref.watch(accountFlagsProvider).emailVerified,
            label: 'Email non vérifié (STA-06)',
            onChanged: (v) => ref.read(accountFlagsProvider.notifier).setEmailVerified(!v),
          ),
          MuSwitch(
            value: ref.watch(cameraDeniedProvider),
            label: 'Caméra refusée (STA-05)',
            onChanged: (v) => ref.read(cameraDeniedProvider.notifier).set(v),
          ),
          MuSelect<String>(
            label: 'Code lu par le scan simulé (OWN-20)',
            options: [for (final code in simulatedCodes) MuSelectOption(value: code, label: code)],
            value: ref.watch(simulatedScanProvider),
            onChanged: (v) => ref.read(simulatedScanProvider.notifier).set(v),
          ),
          MuButton.tertiary(
            label: 'Session expirée (STA-04)',
            leading: PhosphorIcons.lockKey(),
            fullWidth: true,
            onPressed: () {
              final root = Navigator.of(context, rootNavigator: true).context;
              Navigator.of(context).pop();
              showSessionExpired(
                root,
                name: Story.myName,
                email: Story.myEmail,
                balance: Story.myBalance,
                onReconnect: () => ref.read(routerProvider).push(Routes.login),
              );
            },
          ),
          MuButton.tertiary(
            label: 'Partie introuvable (STA-03)',
            leading: PhosphorIcons.linkBreak(),
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(routerProvider).push(Routes.game('7Q2K9'));
            },
          ),
          section('Temps réel (NOT-07)'),
          MuButton.secondary(
            label: 'Rami S. rejoint G1',
            leading: PhosphorIcons.userPlus(),
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(liveEventsProvider).playerJoined(Story.g1.id!);
            },
          ),
          const SizedBox(height: MuSpace.s2),
          MuButton.secondary(
            label: 'Simuler une place libérée (GAM-04)',
            leading: PhosphorIcons.hourglassMedium(),
            fullWidth: true,
            onPressed: () {
              final root = Navigator.of(context, rootNavigator: true).context;
              Navigator.of(context).pop();
              showClaimTakeover(root, ref, Story.g1.id!);
            },
          ),
          section('Push simulés (NOT-08 / NOT-09)'),
          for (final m in PushSamples.all) ...[
            MuButton.tertiary(
              label: m.title,
              leading: PhosphorIcons.bellRinging(),
              fullWidth: true,
              onPressed: () => ref.read(pushServiceProvider).show(m),
            ),
          ],
          section('Écrans'),
          MuButton.tertiary(
            label: 'Galerie des widgets',
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(routerProvider).push(Routes.gallery);
            },
          ),
        ],
      );
    },
  ),
);
