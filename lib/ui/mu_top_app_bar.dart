import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_chip.dart';
import 'mu_icon_button.dart';
import 'src/interaction.dart';

/// TopAppBar (components/TopAppBar.md), Home form: location chip, notifications bell with its
/// count, account avatar, then the greeting as the screen's `h1`. Paints behind the status bar.
///
/// The compact, large and media forms (and the collapse on scroll) come with the screens that use
/// them.
class MuTopAppBar extends StatelessWidget {
  const MuTopAppBar.home({
    super.key,
    required this.greeting,
    required this.location,
    required this.userName,
    this.notifications = 0,
    this.onLocation,
    this.onNotifications,
    this.onAccount,
    this.userImage,
  });

  final String greeting;

  /// The district (« La Marsa »), never an address.
  final String location;
  final String userName;
  final ImageProvider? userImage;
  final int notifications;
  final VoidCallback? onLocation;
  final VoidCallback? onNotifications;
  final VoidCallback? onAccount;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: MuSize.appBar,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s1),
              child: Row(
                children: [
                  Semantics(
                    hint: 'Choisir le quartier',
                    child: MuChip(
                      label: location,
                      icon: PhosphorIcons.mapPin(),
                      trailingIcon: PhosphorIcons.caretDown(),
                      onSelected: (_) => onLocation?.call(),
                    ),
                  ),
                  const Spacer(),
                  MuIconButton(
                    icon: PhosphorIcons.bell(),
                    label: notifications > 0
                        ? 'Notifications, $notifications non lues'
                        : 'Notifications',
                    size: MuIconButtonSize.l,
                    badge: notifications,
                    onPressed: onNotifications,
                  ),
                  Semantics(
                    button: true,
                    label: 'Mon compte, $userName',
                    excludeSemantics: true,
                    child: MuFocusRing(
                      shape: BoxShape.circle,
                      borderRadius: MuRadius.fullAll,
                      child: InkResponse(
                        onTap: onAccount,
                        radius: MuSize.controlL / 2,
                        child: SizedBox.square(
                          dimension: MuSize.controlL,
                          child: Center(
                            child: MuAvatar(
                              name: userName,
                              image: userImage,
                              size: MuAvatarSize.s,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s2),
            child: Semantics(
              header: true,
              child: Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MuType.h1.copyWith(color: c.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
