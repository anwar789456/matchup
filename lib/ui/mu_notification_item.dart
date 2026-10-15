import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_sport_icon.dart';

enum MuNotificationPriority { normal, important, urgent }

enum MuNotificationVariant { regular, compact }

/// NotificationItem (components/NotificationItem.md): one entry of the notification centre —
/// category circle (or avatar with a category badge), title, time, two-line body, unread dot.
///
/// Swipe actions (« Lu », « Supprimer »), inline actions and the grouped AvatarStack come with the
/// Notifications milestone.
class MuNotificationItem extends StatelessWidget {
  const MuNotificationItem({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    this.sport,
    this.icon,
    this.avatarName,
    this.priority = MuNotificationPriority.normal,
    this.variant = MuNotificationVariant.regular,
    this.unread = false,
    this.background,
    this.onTap,
  });

  final String title;
  final String body;

  /// « maintenant », « 12 min », « 1 h », « lun. ».
  final String time;

  /// Matchs category: the sport icon on `<sport>-soft`.
  final MuSport? sport;

  /// Another category icon (calendar-check, wallet…) on a neutral circle.
  final IconData? icon;

  /// Shows the person's avatar with the category as a badge.
  final String? avatarName;
  final MuNotificationPriority priority;
  final MuNotificationVariant variant;
  final bool unread;

  /// Row ground; `surface` by default.
  final Color? background;
  final VoidCallback? onTap;

  // NotificationItem.md: lead 40 / icon 20 (compact 32 / 16); avatar badge 18 (16) with a 2 px
  // surface ring; urgent halo 4 px; unread dot 8; 2 lines of title and body.
  static const double _badge = 18;
  static const double _badgeCompact = 16;
  static const double _ring = 2;
  static const double _halo = 4;
  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final compact = variant == MuNotificationVariant.compact;
    final lead = compact ? MuSize.avatarS : MuSize.avatarM;
    final leadIcon = compact ? MuSize.iconXs : MuSize.iconS;
    final important = priority == MuNotificationPriority.important;
    final urgent = priority == MuNotificationPriority.urgent;

    Widget categoryGlyph(double size, Color? color) => sport != null
        ? MuSportIcon(sport!, size: size, color: color)
        : Icon(icon ?? PhosphorIcons.bell(), size: size, color: color ?? c.text);

    final Widget leading;
    if (avatarName != null) {
      final badge = compact ? _badgeCompact : _badge;
      leading = SizedBox.square(
        dimension: lead,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            MuAvatar(name: avatarName!, size: compact ? MuAvatarSize.s : MuAvatarSize.m),
            PositionedDirectional(
              end: -_ring * 2,
              bottom: -_ring * 2,
              child: Container(
                width: badge + _ring * 2,
                height: badge + _ring * 2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sport?.soft(c) ?? c.surfaceMuted,
                  border: Border.all(color: c.surface, width: _ring),
                ),
                child: categoryGlyph(badge * 0.62, null),
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
        child: Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
            size: leadIcon, color: c.warningText),
      );
    } else {
      leading = Container(
        width: lead,
        height: lead,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: sport?.soft(c) ?? c.surfaceMuted,
          border: sport == null ? Border.all(color: c.border) : null,
        ),
        child: categoryGlyph(leadIcon, null),
      );
    }

    final titleStyle = (unread ? MuType.label : MuType.body)
        .copyWith(color: urgent ? c.errorText : c.text);

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
                      child: Text(title,
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle),
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Text(time, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
                const SizedBox(height: MuSpace.s1),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.body.copyWith(color: important ? c.text : c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: [if (unread) 'Non lu', if (urgent) 'Urgent', if (important) 'Important'].join(' · '),
      child: Material(
        color: important ? c.warningSoft : (background ?? c.surface),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              row,
              if (unread)
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
      ),
    );
  }
}
