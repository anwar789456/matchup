import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../ui/ui.dart';
import '../controllers/notification_actions.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';

/// « 1 min », « 2 h » today, the weekday this week (« jeu. »), then the date (« 9 oct. »).
String notificationTime(DateTime at, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final d = now.difference(at);
  if (!at.isBefore(today)) {
    if (d.inMinutes < 1) return 'maintenant';
    if (d.inHours < 1) return '${d.inMinutes} min';
    return '${d.inHours} h';
  }
  if (today.difference(DateTime(at.year, at.month, at.day)).inDays < 7) return formatWeekday(at);
  return '${at.day} ${formatMonth(at)}';
}

/// An [AppNotification] as a [MuNotificationItem]: its actions (hidden when their screen comes in
/// a later phase), a ticking countdown, and the swipe to « Lu » / « Supprimer ».
class NotificationTile extends ConsumerStatefulWidget {
  const NotificationTile({super.key, required this.notification});

  final AppNotification notification;

  @override
  ConsumerState<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<NotificationTile> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (widget.notification.expiresAt != null &&
        widget.notification.actions.any((a) => a.countdown)) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final now = ref.read(clockProvider)();
    final left = n.expiresAt?.difference(now);
    final repo = ref.read(notificationRepositoryProvider);
    final actions = [
      for (final a in n.actions)
        if (targetAvailable(a.target) && !(a.countdown && left != null && left.isNegative))
          a.secondary
              ? MuButton.secondary(
                  label: a.label,
                  leading: a.icon,
                  price: a.price,
                  size: MuButtonSize.s,
                  onPressed: () => openNotification(context, ref, n, action: a),
                )
              : MuButton.primary(
                  label: a.label,
                  leading: a.icon,
                  price: a.price,
                  countdown: a.countdown && left != null ? formatClock(left) : null,
                  size: MuButtonSize.s,
                  onPressed: () => openNotification(context, ref, n, action: a),
                ),
    ];
    return MuNotificationItem(
      title: n.title,
      body: n.body,
      time: notificationTime(n.at, now),
      sport: n.sport,
      icon: n.icon ?? (n.sport == null && n.avatar == null ? n.category.icon : null),
      status: n.status,
      avatarName: n.avatar,
      titleTrailing: n.ai ? MuAiLabel(size: MuAiLabelSize.s) : null,
      people: [for (final p in n.people) MuPerson(p)],
      thumbnail: n.thumbnail == null
          ? null
          : MuCourtArt(sport: n.thumbnail!, variant: MuCourtArtVariant.poster),
      actions: actions,
      priority: switch (n.priority) {
        NotificationPriority.normal => MuNotificationPriority.normal,
        NotificationPriority.important => MuNotificationPriority.important,
        NotificationPriority.urgent => MuNotificationPriority.urgent,
      },
      unread: n.unread,
      onTap: () => openNotification(context, ref, n),
      onMarkRead: () => repo.markRead(n.id),
      onDelete: () => repo.delete(n.id),
    );
  }
}
