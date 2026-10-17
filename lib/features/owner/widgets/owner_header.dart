import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../profile/widgets/account_menu.dart';
import '../../../l10n/l10n.dart';

/// The header of the owner tabs (OWN-10, OWN-11, OWN-14, OWN-15, OWN-20): « Espace propriétaire
/// · Arena Five » over the tab's h1, optional [actions], then Skander's avatar, which opens the
/// role switcher (PRF-06).
class OwnerHeader extends StatelessWidget {
  const OwnerHeader({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          MuSpace.s4,
          MuSpace.s2,
          MuSpace.s2,
          MuSpace.s2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.storefront(), size: MuSize.iconXs, color: c.text),
                      const SizedBox(width: MuSpace.s1),
                      Flexible(
                        child: Text(
                          l10n.espaceProprietaire2(Story.arenaFive.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s1 / 2),
                  Semantics(
                    header: true,
                    child: Text(title, style: MuType.h1.copyWith(color: c.text)),
                  ),
                ],
              ),
            ),
            for (final a in actions) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: MuSpace.s2),
                child: a,
              ),
              const SizedBox(width: MuSpace.s1),
            ],
            Semantics(
              button: true,
              label: l10n.changerDeRoleProprietaire(Story.ownerName),
              excludeSemantics: true,
              child: InkResponse(
                onTap: () => showRoleSwitcher(context, current: 'owner'),
                radius: MuSize.touchTarget / 2,
                child: const SizedBox.square(
                  dimension: MuSize.touchTarget + MuSpace.s1,
                  child: Center(
                    child: MuAvatar(name: Story.ownerName, size: MuAvatarSize.s),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
