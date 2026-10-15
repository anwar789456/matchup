import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../widgets/auth_widgets.dart';

/// AUTH-09 · Mot de passe modifié: confirmation; every other session was closed.
class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return FlowScaffold(
      centerBody: true,
      gap: MuSpace.s8,
      body: [
        Column(
          children: [
            StatusHeroTile(
              icon: PhosphorIcons.lockKey(),
              ground: c.successSoft,
              ink: c.successText,
              badgeIcon: PhosphorIcons.check(),
              badgeFill: c.success,
              badgeInk: MuPalette.white,
            ),
            const SizedBox(height: MuSpace.s6),
            const FlowTitle(
              'Mot de passe modifié',
              centered: true,
              lead: 'Tu peux maintenant te connecter avec ton nouveau mot de passe.',
            ),
          ],
        ),
        MuBanner(
          tone: MuBannerTone.neutral,
          icon: PhosphorIcons.signOut(PhosphorIconsStyle.fill),
          title: 'Tes autres sessions ont été fermées',
          detail: 'Par sécurité, on t’a déconnecté de tes autres appareils. Reconnecte-toi avec '
              'ton nouveau mot de passe.',
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: 'Se connecter',
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.go(Routes.login),
        ),
      ],
    );
  }
}
