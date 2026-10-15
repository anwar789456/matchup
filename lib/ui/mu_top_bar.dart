import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_icon_button.dart';
import 'src/interaction.dart';

/// An entry of the [MuTopBar] account menu.
@immutable
class MuMenuEntry {
  const MuMenuEntry({
    required this.label,
    required this.icon,
    this.onPressed,
    this.separated = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Draws a separator above (« Se déconnecter »).
  final bool separated;
}

/// TopBar (components/TopBar.md): the 64 dashboard bar — page title, the search trigger (opens
/// the command palette, ⌘ K / Ctrl K), « Assistant », the bell with its count and the account
/// menu.
///
/// Breadcrumbs come with the second-level dashboard pages.
class MuTopBar extends StatefulWidget {
  const MuTopBar({
    super.key,
    required this.title,
    required this.userName,
    required this.userRole,
    this.userEmail,
    this.userImage,
    this.searchPlaceholder = 'Rechercher un joueur, un terrain, une réservation…',
    this.onSearch,
    this.onAssistant,
    this.notifications = 0,
    this.onNotifications,
    this.menuItems = const [],
    this.leading,
  });

  final String title;
  final String userName;
  final String userRole;
  final String? userEmail;
  final ImageProvider? userImage;
  final String searchPlaceholder;
  final VoidCallback? onSearch;

  /// Null hides « Assistant ».
  final VoidCallback? onAssistant;
  final int notifications;
  final VoidCallback? onNotifications;
  final List<MuMenuEntry> menuItems;

  /// Menu button opening the sidebar drawer below `bp-expanded`.
  final Widget? leading;

  @override
  State<MuTopBar> createState() => _MuTopBarState();
}

class _MuTopBarState extends State<MuTopBar> {
  final _menu = MenuController();
  bool _menuOpen = false;

  // TopBar.md: search 200–480 wide; 1,5 px AI edge; account 48 high; menu ≥ 280, items 40.
  static const double _searchMin = 200;
  static const double _searchMax = 480;
  static const double _aiEdge = 1.5;
  static const double _account = 48;
  static const double _menuMin = 280;
  static const double _menuItem = 40;

  // Below this bar width the search shrinks to its icon and the account to its avatar.
  static const double _compact = 760;

  bool get _apple =>
      defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final shortcut = _apple ? '⌘ K' : 'Ctrl K';

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyK, meta: _apple, control: !_apple): () =>
            widget.onSearch?.call(),
      },
      child: Container(
        height: MuSize.topBar,
        padding: EdgeInsetsDirectional.only(
          start: widget.leading == null ? MuSpace.s8 : MuSpace.s2,
          end: MediaQuery.sizeOf(context).width < MuLayout.bpMedium ? MuSpace.s2 : MuSpace.s8,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < _compact;
            final title = Semantics(
              header: true,
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MuType.h3.copyWith(color: c.text),
              ),
            );
            return Row(
              children: [
                if (widget.leading != null) ...[widget.leading!, const SizedBox(width: MuSpace.s2)],
                if (compact)
                  Expanded(child: title)
                else ...[
                  title,
                  const SizedBox(width: MuSpace.s8),
                  // The search takes the leftover width up to 480, never under 200.
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(minWidth: _searchMin, maxWidth: _searchMax),
                        child: _SearchTrigger(
                          placeholder: widget.searchPlaceholder,
                          shortcut: shortcut,
                          onTap: widget.onSearch,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s4),
                ],
                if (compact)
                  MuIconButton(
                    icon: PhosphorIcons.magnifyingGlass(),
                    label: 'Rechercher',
                    onPressed: widget.onSearch ?? () {},
                  ),
                if (widget.onAssistant != null && compact)
                  MuIconButton(
                    icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                    label: 'Assistant',
                    color: c.aiText,
                    onPressed: widget.onAssistant,
                  )
                else if (widget.onAssistant != null) ...[
                  _AssistantButton(onTap: widget.onAssistant!),
                  const SizedBox(width: MuSpace.s4),
                ],
                MuIconButton(
                  icon: PhosphorIcons.bell(),
                  label: widget.notifications > 0
                      ? 'Notifications, ${widget.notifications} non lues'
                      : 'Notifications',
                  badge: widget.notifications > 0 ? widget.notifications : null,
                  onPressed: widget.onNotifications ?? () {},
                ),
                const SizedBox(width: MuSpace.s2),
                _accountMenu(c, compact: compact),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _accountMenu(MuColors c, {required bool compact}) {
    final duration = MuMotion.durationOf(context, MuMotion.base);
    return MenuAnchor(
      controller: _menu,
      onOpen: () => setState(() => _menuOpen = true),
      onClose: () => setState(() => _menuOpen = false),
      alignmentOffset: const Offset(0, MuSpace.s1),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surfaceElevated),
        elevation: const WidgetStatePropertyAll(MuElevation.materialLevel2),
        shadowColor: WidgetStatePropertyAll(MuElevation.of(context).shadowColor),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: MuRadius.lgAll)),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(MuSpace.s2)),
        minimumSize: const WidgetStatePropertyAll(Size(_menuMin, 0)),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(MuSpace.s2),
          child: Row(
            children: [
              MuAvatar(name: widget.userName, image: widget.userImage),
              const SizedBox(width: MuSpace.s3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.userName, style: MuType.label.copyWith(color: c.text)),
                  if (widget.userEmail != null)
                    Text(widget.userEmail!, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        for (final e in widget.menuItems) ...[
          if (e.separated)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
              child: Container(height: 1, color: c.border),
            ),
          MenuItemButton(
            onPressed: e.onPressed ?? () {},
            leadingIcon: Icon(e.icon, size: MuSize.iconS, color: c.textSecondary),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(_menuMin, _menuItem)),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: MuRadius.smAll),
              ),
              textStyle: WidgetStatePropertyAll(MuType.body),
              foregroundColor: WidgetStatePropertyAll(c.text),
            ),
            child: Text(e.label),
          ),
        ],
      ],
      child: Semantics(
        button: true,
        expanded: _menuOpen,
        label: '${widget.userName}, ${widget.userRole}. Menu du compte',
        excludeSemantics: true,
        child: MuFocusRing(
          borderRadius: MuRadius.fullAll,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => _menuOpen ? _menu.close() : _menu.open(),
              customBorder: const StadiumBorder(),
              hoverColor: c.text.withValues(alpha: MuOpacity.hover),
              child: Container(
                height: _account,
                padding: const EdgeInsetsDirectional.only(start: MuSpace.s1, end: MuSpace.s2),
                decoration: BoxDecoration(
                  borderRadius: MuRadius.fullAll,
                  color: _menuOpen ? c.text.withValues(alpha: MuOpacity.pressed) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MuAvatar(name: widget.userName, image: widget.userImage, size: MuAvatarSize.s),
                    if (!compact) ...[
                      const SizedBox(width: MuSpace.s3),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userName, style: MuType.label.copyWith(color: c.text)),
                          Text(
                            widget.userRole,
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(width: MuSpace.s2),
                    AnimatedRotation(
                      turns: _menuOpen ? 0.5 : 0,
                      duration: duration,
                      curve: MuMotion.move,
                      child: Icon(
                        PhosphorIcons.caretDown(),
                        size: MuSize.iconXs,
                        color: c.textSecondary,
                      ),
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

class _SearchTrigger extends StatefulWidget {
  const _SearchTrigger({required this.placeholder, required this.shortcut, required this.onTap});

  final String placeholder;
  final String shortcut;
  final VoidCallback? onTap;

  @override
  State<_SearchTrigger> createState() => _SearchTriggerState();
}

class _SearchTriggerState extends State<_SearchTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: widget.placeholder,
      hint: 'Raccourci ${widget.shortcut}',
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: MuFocusRing(
          borderRadius: MuRadius.smAll,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap ?? () {},
              borderRadius: MuRadius.smAll,
              child: AnimatedContainer(
                duration: MuMotion.durationOf(context, MuMotion.fast),
                height: MuSize.controlM,
                padding: const EdgeInsetsDirectional.only(start: MuSpace.s3, end: MuSpace.s2),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: MuRadius.smAll,
                  border: Border.all(color: _hovered ? c.borderStrong : c.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.magnifyingGlass(),
                      size: MuSize.iconS,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        widget.placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.body.copyWith(color: c.textSecondary),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: MuRadius.xsAll,
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        widget.shortcut,
                        style: MuType.labelS.copyWith(color: c.textSecondary),
                      ),
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

class _AssistantButton extends StatefulWidget {
  const _AssistantButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AssistantButton> createState() => _AssistantButtonState();
}

class _AssistantButtonState extends State<_AssistantButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: MuFocusRing(
        borderRadius: MuRadius.fullAll,
        child: MuPressScale(
          child: Container(
            height: MuSize.controlM,
            padding: const EdgeInsets.all(_MuTopBarState._aiEdge),
            decoration: const BoxDecoration(
              gradient: MuGradients.ai,
              borderRadius: MuRadius.fullAll,
            ),
            child: Material(
              color: _hovered ? c.aiSoft : c.surface,
              shape: const StadiumBorder(),
              child: InkWell(
                onTap: widget.onTap,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                        size: MuSize.iconS,
                        color: c.aiText,
                      ),
                      const SizedBox(width: MuSpace.s2),
                      Text('Assistant', style: MuType.label.copyWith(color: c.aiText)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
