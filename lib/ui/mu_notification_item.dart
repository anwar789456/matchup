import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_avatar_stack.dart';
import 'mu_sport_icon.dart';
import '../l10n/l10n.dart';

enum MuNotificationPriority { normal, important, urgent }

enum MuNotificationVariant { regular, compact }

/// NotificationItem (components/NotificationItem.md): one entry of the notification centre —
/// category circle (or avatar with a category badge), title, time, two-line body, unread dot,
/// grouped people, a thumbnail, up to two inline actions, three priorities and, on phones, a
/// swipe toward the start that reveals « Lu » and « Supprimer ».
class MuNotificationItem extends StatefulWidget {
  const MuNotificationItem({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    this.sport,
    this.icon,
    this.status,
    this.avatarName,
    this.titleTrailing,
    this.people = const [],
    this.thumbnail,
    this.actions = const [],
    this.priority = MuNotificationPriority.normal,
    this.variant = MuNotificationVariant.regular,
    this.unread = false,
    this.background,
    this.onTap,
    this.onMarkRead,
    this.onDelete,
    this.swiped = false,
  });

  final String title;
  final String body;

  /// « maintenant », « 12 min », « 1 h », « lun. ».
  final String time;

  /// Matchs category: the sport icon on `<sport>-soft`.
  final MuSport? sport;

  /// Another category icon (calendar-check, wallet…) on a neutral circle.
  final IconData? icon;

  /// A status the notification reports (success, info, error…): tints the circle.
  final MuTone? status;

  /// Shows the person's avatar with the category as a badge.
  final String? avatarName;

  /// After the title (the AI label of « Ton plan de la semaine »).
  final Widget? titleTrailing;

  /// Grouped notifications: an AvatarStack XS under the body.
  final List<MuPerson> people;

  /// A 48 thumbnail at the end (tournament poster, programme).
  final Widget? thumbnail;

  /// At most two Buttons S, primary first.
  final List<Widget> actions;
  final MuNotificationPriority priority;
  final MuNotificationVariant variant;
  final bool unread;

  /// Row ground; `surface` by default.
  final Color? background;
  final VoidCallback? onTap;

  /// Swipe actions (regular variant only, when set).
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;

  /// Starts with the swipe actions revealed (NOT-02).
  final bool swiped;

  @override
  State<MuNotificationItem> createState() => _MuNotificationItemState();
}

class _MuNotificationItemState extends State<MuNotificationItem> {
  late double _offset = widget.swiped ? _reveal : 0;

  // NotificationItem.md: lead 40 / icon 20 (compact 32 / 16); avatar badge 18 (16) with a 2 px
  // surface ring; urgent halo 4 px; unread dot 8; thumbnail 48 (40); swipe reveals 2 × 72.
  static const double _badge = 18;
  static const double _badgeCompact = 16;
  static const double _ring = 2;
  static const double _halo = 4;
  static const double _dot = 8;
  static const double _thumb = 48;
  static const double _thumbCompact = 40;
  static const double _action = 72;
  static const double _reveal = _action * 2;
  static const double _badgeGlyph = 0.62;

  bool get _swipeable =>
      widget.variant == MuNotificationVariant.regular &&
      (widget.onMarkRead != null || widget.onDelete != null);

  void _settle() {
    setState(() => _offset = _offset > _reveal / 2 ? _reveal : 0);
  }

  void _close() => setState(() => _offset = 0);

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final w = widget;
    final compact = w.variant == MuNotificationVariant.compact;
    final lead = compact ? MuSize.avatarS : MuSize.avatarM;
    final leadIcon = compact ? MuSize.iconXs : MuSize.iconS;
    final important = w.priority == MuNotificationPriority.important;
    final urgent = w.priority == MuNotificationPriority.urgent;

    Widget categoryGlyph(double size, Color? color) => w.sport != null && w.icon == null
        ? MuSportIcon(w.sport!, size: size, color: color)
        : Icon(w.icon ?? PhosphorIcons.bell(), size: size, color: color ?? c.text);

    final Widget leading;
    if (w.avatarName != null) {
      final badge = compact ? _badgeCompact : _badge;
      leading = SizedBox.square(
        dimension: lead,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            MuAvatar(name: w.avatarName!, size: compact ? MuAvatarSize.s : MuAvatarSize.m),
            PositionedDirectional(
              end: -_ring * 2,
              bottom: -_ring * 2,
              child: Container(
                width: badge + _ring * 2,
                height: badge + _ring * 2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: w.sport?.soft(c) ?? c.surfaceMuted,
                  border: Border.all(color: c.surface, width: _ring),
                ),
                child: categoryGlyph(badge * _badgeGlyph, null),
              ),
            ),
          ],
        ),
      );
    } else if (urgent) {
      leading = Container(
        width: lead + _halo * 2,
        height: lead + _halo * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.errorSoft),
        child: Container(
          width: lead,
          height: lead,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.error),
          child: categoryGlyph(leadIcon, MuPalette.white),
        ),
      );
    } else if (important) {
      leading = Container(
        width: lead,
        height: lead,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface),
        child: Icon(
          PhosphorIcons.warning(PhosphorIconsStyle.fill),
          size: leadIcon,
          color: c.warningText,
        ),
      );
    } else if (w.status != null) {
      leading = Container(
        width: lead,
        height: lead,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: w.status!.soft(c)),
        child: categoryGlyph(leadIcon, w.status!.text(c)),
      );
    } else {
      leading = Container(
        width: lead,
        height: lead,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: w.sport != null && w.icon == null ? w.sport!.soft(c) : c.surfaceMuted,
          border: w.sport != null && w.icon == null ? null : Border.all(color: c.border),
        ),
        child: categoryGlyph(leadIcon, null),
      );
    }

    final titleStyle = (w.unread ? MuType.label : MuType.body).copyWith(
      color: urgent ? c.errorText : c.text,
    );
    final thumb = compact ? _thumbCompact : _thumb;

    final row = Padding(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3)
          : const EdgeInsets.all(MuSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: w.title),
                            if (w.titleTrailing != null) ...[
                              const TextSpan(text: ' '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: w.titleTrailing!,
                              ),
                            ],
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Text(w.time, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
                const SizedBox(height: MuSpace.s1),
                Text(
                  w.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.body.copyWith(color: important ? c.text : c.textSecondary),
                ),
                if (w.people.isNotEmpty) ...[
                  const SizedBox(height: MuSpace.s2),
                  MuAvatarStack(people: w.people, size: MuAvatarSize.xs),
                ],
                if (w.actions.isNotEmpty) ...[
                  SizedBox(height: compact ? MuSpace.s2 : MuSpace.s3),
                  Wrap(spacing: MuSpace.s2, runSpacing: MuSpace.s2, children: w.actions),
                ],
              ],
            ),
          ),
          if (w.thumbnail != null) ...[
            const SizedBox(width: MuSpace.s3),
            ClipRRect(
              borderRadius: MuRadius.smAll,
              child: SizedBox.square(dimension: thumb, child: w.thumbnail),
            ),
          ],
        ],
      ),
    );

    final ground = important ? c.warningSoft : (w.background ?? c.surface);
    final content = Material(
      color: ground,
      child: InkWell(
        onTap: _offset > 0 ? _close : w.onTap,
        child: Stack(
          children: [
            row,
            if (w.unread)
              PositionedDirectional(
                start: (MuSpace.s4 - _dot) / 2,
                top: MuSpace.s4 + MuSpace.s2,
                child: Container(
                  width: _dot,
                  height: _dot,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary),
                ),
              ),
          ],
        ),
      ),
    );

    final label = [
      if (w.unread) l10n.nonLu,
      if (urgent) l10n.urgent,
      if (important) l10n.important,
    ].join(' · ');
    if (!_swipeable) return Semantics(container: true, label: label, child: content);

    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget swipeAction(String text, IconData icon, Color bg, Color fg, VoidCallback? onTap) =>
        SizedBox(
          width: _action,
          child: Material(
            color: bg,
            child: InkWell(
              onTap: onTap == null
                  ? null
                  : () {
                      _close();
                      onTap();
                    },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: MuSize.iconS, color: fg),
                  const SizedBox(height: MuSpace.s1),
                  Text(text, style: MuType.labelS.copyWith(color: fg)),
                ],
              ),
            ),
          ),
        );

    return Semantics(
      container: true,
      label: label,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Focus(
                  // Focusing a swipe button opens the row (NotificationItem.md).
                  onFocusChange: (f) {
                    if (f) setState(() => _offset = _reveal);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      swipeAction(
                        l10n.lu,
                        PhosphorIcons.envelopeOpen(),
                        c.primary,
                        c.onPrimary,
                        w.onMarkRead,
                      ),
                      swipeAction(
                        l10n.supprimer,
                        PhosphorIcons.trash(),
                        c.destructive,
                        c.onDestructive,
                        w.onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onHorizontalDragUpdate: (d) => setState(
                () => _offset = (_offset - d.delta.dx * (rtl ? -1 : 1)).clamp(0, _reveal),
              ),
              onHorizontalDragEnd: (_) => _settle(),
              child: AnimatedContainer(
                duration: MuMotion.durationOf(context, MuMotion.base),
                curve: MuMotion.move,
                transform: Matrix4.translationValues(_offset * (rtl ? 1 : -1), 0, 0),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
