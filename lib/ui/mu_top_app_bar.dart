import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_chip.dart';
import 'mu_icon_button.dart';
import 'src/interaction.dart';
import '../l10n/l10n.dart';

/// An action at the end of the bar: an icon with its name.
@immutable
class MuBarAction {
  const MuBarAction({required this.icon, required this.label, this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
}

enum _Variant { home, large, media, compact }

/// TopAppBar (components/TopAppBar.md): the mobile top bar in its forms.
///
/// - `.home` (Accueil): the location chip, the bell with its count, the avatar, then the greeting.
/// - `.large`: the tab root's `h1` with up to two actions (« Mes matchs » + Réserver un terrain).
/// - `.media`: over a photo — on-media back and actions, a flipped scrim under the status bar.
/// - `.compact`: back + `h3` title (+ subtitle) + actions on detail and flow screens.
class MuTopAppBar extends StatelessWidget {
  MuTopAppBar.home({
    super.key,
    required this.greeting,
    required this.location,
    required this.userName,
    this.notifications = 0,
    this.onLocation,
    this.onNotifications,
    this.onAccount,
    this.userImage,
  }) : _variant = _Variant.home,
       title = null,
       subtitle = null,
       onBack = null,
       backLabel = l10n.retour,
       actions = const [];

  MuTopAppBar.large({super.key, required String this.title, this.actions = const []})
    : _variant = _Variant.large,
      greeting = '',
      location = '',
      userName = '',
      userImage = null,
      notifications = 0,
      onLocation = null,
      onNotifications = null,
      onAccount = null,
      subtitle = null,
      onBack = null,
      backLabel = l10n.retour;

  MuTopAppBar.media({
    super.key,
    this.title,
    required this.onBack,
    String? backLabel,
    this.actions = const [],
  }) : backLabel = backLabel ?? l10n.retour, _variant = _Variant.media,
       greeting = '',
       location = '',
       userName = '',
       userImage = null,
       notifications = 0,
       onLocation = null,
       onNotifications = null,
       onAccount = null,
       subtitle = null;

  MuTopAppBar.compact({
    super.key,
    required String this.title,
    this.subtitle,
    this.onBack,
    String? backLabel,
    this.actions = const [],
  }) : backLabel = backLabel ?? l10n.retour, _variant = _Variant.compact,
       greeting = '',
       location = '',
       userName = '',
       userImage = null,
       notifications = 0,
       onLocation = null,
       onNotifications = null,
       onAccount = null;

  final _Variant _variant;
  final String greeting;

  /// The district (« La Marsa »), never an address.
  final String location;
  final String userName;
  final ImageProvider? userImage;
  final int notifications;
  final VoidCallback? onLocation;
  final VoidCallback? onNotifications;
  final VoidCallback? onAccount;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final String backLabel;
  final List<MuBarAction> actions;

  // TopAppBar.md: the media scrim is the photo scrim flipped, at 70 %.
  static const double _mediaScrim = 0.7;

  @override
  Widget build(BuildContext context) => switch (_variant) {
    _Variant.home => _home(context),
    _Variant.large => _large(context),
    _Variant.media => _media(context),
    _Variant.compact => _compact(context),
  };

  List<Widget> _actionButtons({MuIconButtonVariant variant = MuIconButtonVariant.ghost}) => [
    for (final a in actions.take(2))
      MuIconButton(
        icon: a.icon,
        label: a.label,
        size: variant == MuIconButtonVariant.onMedia ? MuIconButtonSize.m : MuIconButtonSize.l,
        variant: variant,
        onPressed: a.onPressed,
      ),
  ];

  Widget _large(BuildContext context) {
    final c = context.mu;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s1),
        child: SizedBox(
          height: MuSize.appBar,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MuType.h1.copyWith(color: c.text),
                  ),
                ),
              ),
              ..._actionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compact(BuildContext context) {
    final c = context.mu;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
        child: SizedBox(
          height: MuSize.appBar,
          child: Row(
            children: [
              if (onBack != null)
                MuIconButton(
                  icon: PhosphorIcons.arrowLeft(),
                  label: backLabel,
                  size: MuIconButtonSize.l,
                  onPressed: onBack,
                )
              else
                const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (subtitle == null ? MuType.h3 : MuType.labelL).copyWith(
                          color: c.text,
                        ),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                  ],
                ),
              ),
              ..._actionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _media(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            for (final color in MuGradients.photoScrim.colors)
              color.withValues(alpha: color.a * _mediaScrim),
          ],
          stops: MuGradients.photoScrim.stops,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
          child: SizedBox(
            height: MuSize.appBar,
            child: Row(
              children: [
                MuIconButton(
                  icon: PhosphorIcons.arrowLeft(),
                  label: backLabel,
                  variant: MuIconButtonVariant.onMedia,
                  onPressed: onBack,
                ),
                const Spacer(),
                for (final (i, b) in _actionButtons(
                  variant: MuIconButtonVariant.onMedia,
                ).indexed) ...[if (i > 0) const SizedBox(width: MuSpace.s2), b],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _home(BuildContext context) {
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
                    hint: l10n.choisirLeQuartier,
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
                        ? l10n.notificationsNonLues(notifications)
                        : l10n.notifications,
                    size: MuIconButtonSize.l,
                    badge: notifications,
                    onPressed: onNotifications,
                  ),
                  Semantics(
                    button: true,
                    label: l10n.monCompte2(userName),
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
                            child: MuAvatar(name: userName, image: userImage, size: MuAvatarSize.s),
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
