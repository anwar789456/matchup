import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_icon_button.dart';
import 'mu_logo.dart';
import 'src/interaction.dart';

/// A destination of the [MuSidebar]: a Phosphor icon (regular, Fill when active) or one of the
/// MatchUp glyph [asset]s (`MuGlyph.court`).
@immutable
class MuNavItem {
  const MuNavItem({
    required this.id,
    required this.label,
    this.icon,
    this.activeIcon,
    this.asset,
    this.count,
    this.countLabel,
  }) : assert(icon != null || asset != null);

  final String id;
  final String label;
  final IconData? icon;
  final IconData? activeIcon;
  final String? asset;

  /// Work waiting on this person only.
  final int? count;

  /// Spoken with the item: « 4 à confirmer ».
  final String? countLabel;
}

@immutable
class MuNavSection {
  const MuNavSection({this.heading, required this.items});

  final String? heading;
  final List<MuNavItem> items;
}

/// The role trigger at the top: « Propriétaire » over « Arena Five ».
@immutable
class MuSidebarRole {
  const MuSidebarRole({required this.role, required this.name, this.initials, this.image});

  final String role;
  final String name;

  /// The tile's letters (« AF », « ST »); the first letters of [name] by default.
  final String? initials;
  final ImageProvider? image;
}

@immutable
class MuSidebarUser {
  const MuSidebarUser({required this.name, required this.email, this.image});

  final String name;
  final String email;
  final ImageProvider? image;
}

/// Sidebar (components/Sidebar.md): the dark dashboard rail, 248 expanded or 72 collapsed — brand
/// row, role trigger, sections of items with the current one in a Volt pill, then help, the
/// collapse toggle and the user row. Same colours in both themes.
///
/// The role switcher menu comes with the multi-role milestone; [onRole] receives the tap.
class MuSidebar extends StatelessWidget {
  const MuSidebar({
    super.key,
    required this.sections,
    required this.activeId,
    required this.role,
    required this.user,
    this.onNavigate,
    this.collapsed = false,
    this.onCollapsedChanged,
    this.onRole,
    this.onHelp,
    this.onUserMenu,
  });

  final List<MuNavSection> sections;
  final String activeId;
  final MuSidebarRole role;
  final MuSidebarUser user;
  final ValueChanged<String>? onNavigate;
  final bool collapsed;
  final ValueChanged<bool>? onCollapsedChanged;
  final VoidCallback? onRole;
  final VoidCallback? onHelp;
  final VoidCallback? onUserMenu;

  // Sidebar.md: brand wordmark 24 (icon 32 collapsed); role trigger ≥ 48 with a 32 tile;
  // items 40 high and 2 apart, 48 wide when collapsed.
  static const double _wordmark = 24;
  static const double _roleMin = 48;
  static const double _roleTile = 32;
  static const double _item = 40;
  static const double _itemGap = 2;
  static const double _collapsedItem = 48;

  @override
  Widget build(BuildContext context) {
    // The rail is dark in both themes; its children (avatars, focus ring) follow.
    return Theme(
      data: MuTheme.dark(),
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final c = context.mu;
    final duration = MuMotion.durationOf(context, MuMotion.base);
    final width = collapsed ? MuSize.sidebarCollapsed : MuSize.sidebar;

    Widget item(MuNavItem it, {bool muted = false, VoidCallback? onTap, bool? expanded}) =>
        _SidebarItem(
          item: it,
          active: it.id == activeId,
          collapsed: collapsed,
          muted: muted,
          expanded: expanded,
          onTap: onTap ?? (onNavigate == null ? null : () => onNavigate!(it.id)),
        );

    final nav = <Widget>[];
    for (final (i, s) in sections.indexed) {
      if (s.heading != null) {
        nav.add(
          collapsed
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
                  child: Container(height: 1, color: c.navHover),
                )
              : Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: MuSpace.s4,
                    top: MuSpace.s4,
                    bottom: MuSpace.s1,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      s.heading!.toUpperCase(),
                      style: MuType.overline.copyWith(color: c.navTextMuted),
                    ),
                  ),
                ),
        );
      } else if (i > 0) {
        nav.add(const SizedBox(height: MuSpace.s3));
      }
      for (final (j, it) in s.items.indexed) {
        if (j > 0) nav.add(const SizedBox(height: _itemGap));
        nav.add(item(it));
      }
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Navigation du tableau de bord',
      child: AnimatedContainer(
        duration: duration,
        curve: MuMotion.move,
        width: width,
        color: c.navBg,
        child: ClipRect(
          child: OverflowBox(
            alignment: AlignmentDirectional.topStart,
            minWidth: width,
            maxWidth: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: MuSize.topBar,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: collapsed ? 0 : MuSpace.s6),
                    child: Align(
                      alignment: collapsed ? Alignment.center : AlignmentDirectional.centerStart,
                      child: collapsed
                          ? const MuLogo(variant: MuLogoVariant.icon, height: MuSize.iconL)
                          : const MuLogo(tone: MuLogoTone.dark, height: _wordmark),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3),
                  child: _RoleTrigger(role: role, collapsed: collapsed, onTap: onRole),
                ),
                const SizedBox(height: MuSpace.s3),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3),
                    children: nav,
                  ),
                ),
                Container(height: 1, color: c.navHover),
                Padding(
                  padding: const EdgeInsets.all(MuSpace.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      item(
                        MuNavItem(
                          id: '_help',
                          label: 'Aide et support',
                          icon: PhosphorIcons.lifebuoy(),
                        ),
                        muted: true,
                        onTap: onHelp ?? () {},
                      ),
                      const SizedBox(height: _itemGap),
                      item(
                        MuNavItem(
                          id: '_collapse',
                          label: collapsed ? 'Agrandir le menu' : 'Réduire le menu',
                          icon: collapsed
                              ? PhosphorIcons.caretDoubleRight()
                              : PhosphorIcons.caretDoubleLeft(),
                        ),
                        muted: true,
                        expanded: !collapsed,
                        onTap: onCollapsedChanged == null
                            ? null
                            : () => onCollapsedChanged!(!collapsed),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: c.navHover),
                SizedBox(
                  height: MuSize.topBar,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: collapsed ? 0 : MuSpace.s5,
                      end: collapsed ? 0 : MuSpace.s2,
                    ),
                    child: collapsed
                        ? Center(
                            child: MuAvatar(
                              name: user.name,
                              image: user.image,
                              size: MuAvatarSize.s,
                            ),
                          )
                        : Row(
                            children: [
                              MuAvatar(name: user.name, image: user.image, size: MuAvatarSize.s),
                              const SizedBox(width: MuSpace.s3),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: MuType.label.copyWith(color: c.navText),
                                    ),
                                    Text(
                                      user.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: MuType.caption.copyWith(color: c.navTextMuted),
                                    ),
                                  ],
                                ),
                              ),
                              MuIconButton(
                                icon: PhosphorIcons.dotsThreeVertical(),
                                label: 'Options du compte',
                                size: MuIconButtonSize.s,
                                color: c.navTextMuted,
                                onPressed: onUserMenu ?? () {},
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleTrigger extends StatelessWidget {
  const _RoleTrigger({required this.role, required this.collapsed, required this.onTap});

  final MuSidebarRole role;
  final bool collapsed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final tile = Container(
      width: MuSidebar._roleTile,
      height: MuSidebar._roleTile,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.navHover,
        borderRadius: MuRadius.smAll,
        image: role.image == null ? null : DecorationImage(image: role.image!, fit: BoxFit.cover),
      ),
      child: role.image == null
          ? Text(role.initials ?? initialsOf(role.name), style: MuType.labelS.copyWith(color: c.navText))
          : null,
    );

    return Semantics(
      button: true,
      label: '${role.role}, ${role.name}. Changer de rôle',
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.mdAll,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: MuRadius.mdAll,
            side: BorderSide(color: c.navHover),
          ),
          child: InkWell(
            onTap: onTap ?? () {},
            borderRadius: MuRadius.mdAll,
            hoverColor: c.navHover,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: MuSidebar._roleMin),
              child: Padding(
                padding: EdgeInsets.all(collapsed ? MuSpace.s1 : MuSpace.s2),
                child: collapsed
                    ? Center(child: tile)
                    : Row(
                        children: [
                          tile,
                          const SizedBox(width: MuSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.role,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: MuType.caption.copyWith(color: c.navTextMuted),
                                ),
                                Text(
                                  role.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: MuType.label.copyWith(color: c.navText),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            PhosphorIcons.caretUpDown(),
                            size: MuSize.iconXs,
                            color: c.navTextMuted,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.muted,
    required this.onTap,
    this.expanded,
  });

  final MuNavItem item;
  final bool active;
  final bool collapsed;
  final bool muted;
  final bool? expanded;
  final VoidCallback? onTap;

  // Sidebar.md: count on a 14 % `nav-text` fill.
  static const double _countAlpha = 0.14;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final fg = active ? c.onAccent : (muted ? c.navTextMuted : c.navText);
    final iconData = active ? (item.activeIcon ?? item.icon) : item.icon;
    final Widget icon = item.asset != null
        ? SvgPicture.asset(
            item.asset!,
            width: MuSize.iconS,
            height: MuSize.iconS,
            colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
          )
        : Icon(iconData, size: MuSize.iconS, color: fg);

    final count = item.count;
    final Widget? countBadge = count == null || count == 0
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
            decoration: BoxDecoration(
              color: active
                  ? c.onAccent.withValues(alpha: _countAlpha)
                  : c.navText.withValues(alpha: _countAlpha),
              borderRadius: MuRadius.fullAll,
            ),
            child: Text(count > 99 ? '99+' : '$count', style: MuType.numXs.copyWith(color: fg)),
          );

    final body = SizedBox(
      height: MuSidebar._item,
      width: collapsed ? MuSidebar._collapsedItem : null,
      child: collapsed
          ? Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                icon,
                if (countBadge != null) PositionedDirectional(top: 0, end: 0, child: countBadge),
              ],
            )
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s3),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (active ? MuType.label : MuType.body).copyWith(color: fg),
                    ),
                  ),
                  ?countBadge,
                ],
              ),
            ),
    );

    Widget row = MuFocusRing(
      borderRadius: MuRadius.fullAll,
      child: MuPressScale(
        enabled: onTap != null,
        child: Material(
          color: active ? c.navActive : Colors.transparent,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            hoverColor: active ? Colors.transparent : c.navHover,
            child: body,
          ),
        ),
      ),
    );
    if (collapsed) {
      row = Center(
        child: Tooltip(
          message: item.label,
          preferBelow: false,
          excludeFromSemantics: true,
          child: row,
        ),
      );
    }

    return Semantics(
      button: true,
      selected: active,
      expanded: expanded,
      label: [item.label, ?item.countLabel].join(', '),
      excludeSemantics: true,
      child: row,
    );
  }
}
