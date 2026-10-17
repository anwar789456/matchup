import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';
import '../widgets/notification_tile.dart';
import '../../../l10n/l10n.dart';

/// NOT-01 · Centre de notifications, NOT-02 (a category filter) and NOT-03 (« Tout est calme »):
/// the filter chips, the unread count with « Tout marquer comme lu », then Aujourd’hui / Cette
/// semaine / Plus ancien. Rows swipe to « Lu » / « Supprimer ».
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  NotificationCategory? _filter;

  static const _filters = [
    NotificationCategory.matches,
    NotificationCategory.bookings,
    NotificationCategory.tournaments,
    NotificationCategory.payments,
    NotificationCategory.training,
    NotificationCategory.community,
  ];

  // NOT-01: the unread dot before the count is 6.
  static const double _dot = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final all = ref.watch(notificationsProvider).value;
    final now = ref.read(clockProvider)();
    final items = [
      for (final n in all ?? const <AppNotification>[])
        if (_filter == null || n.category == _filter) n,
    ];
    final unread = items.where((n) => n.unread).length;
    final today = DateTime(now.year, now.month, now.day);
    final week = today.subtract(const Duration(days: 6));
    final sections = <(String, List<AppNotification>)>[
      (
        l10n.aujourdHui2,
        [
          for (final n in items)
            if (!n.at.isBefore(today)) n,
        ],
      ),
      (
        l10n.cetteSemaine,
        [
          for (final n in items)
            if (n.at.isBefore(today) && !n.at.isBefore(week)) n,
        ],
      ),
      (
        l10n.plusAncien,
        [
          for (final n in items)
            if (n.at.isBefore(week)) n,
        ],
      ),
    ];
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    Widget chips() => SizedBox(
      height: MuSize.touchTarget,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
        children: [
          for (final (i, f) in [null, ..._filters].indexed) ...[
            if (i > 0) const SizedBox(width: MuSpace.s2),
            Center(
              child: MuChip(
                label: f?.label ?? l10n.tout,
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
            ),
          ],
        ],
      ),
    );

    final Widget body;
    if (all == null) {
      body = const Center(child: MuSpinner());
    } else if (items.isEmpty) {
      body = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MuSpace.s6),
          child: MuEmptyState(
            illustration: MuEmptyIllustration.notifications,
            title: l10n.toutEstCalme,
            description: l10n.tuVerrasIciTesInvitations,
            actions: [
              MuButton.secondary(
                label: l10n.gererMesNotifications,
                leading: PhosphorIcons.gearSix(),
                onPressed: () => context.push(Routes.notificationSettings),
              ),
            ],
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.only(bottom: MuSpace.s8),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, 0, MuSpace.s2, 0),
            child: Row(
              children: [
                if (unread > 0) ...[
                  Container(
                    width: _dot,
                    height: _dot,
                    decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: MuSpace.s2),
                ],
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$unread',
                          style: MuType.labelS.copyWith(color: c.text),
                        ),
                        TextSpan(text: unread == 1 ? l10n.nonLue : l10n.nonLues),
                      ],
                    ),
                    style: caption,
                  ),
                ),
                MuButton.tertiary(
                  label: l10n.toutMarquerCommeLu,
                  leading: PhosphorIcons.checks(),
                  size: MuButtonSize.s,
                  onPressed: unread == 0
                      ? null
                      : () => ref.read(notificationRepositoryProvider).markAllRead(),
                ),
              ],
            ),
          ),
          for (final (title, list) in sections)
            if (list.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  MuSpace.s4,
                  MuSpace.s4,
                  MuSpace.s4,
                  MuSpace.s2,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    title.toUpperCase(),
                    style: MuType.overline.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
              for (final (i, n) in list.indexed) ...[
                if (i > 0)
                  ColoredBox(
                    color: c.surface,
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: c.border,
                      indent: MuSpace.s4 + MuSize.avatarM + MuSpace.s3,
                    ),
                  ),
                NotificationTile(key: ValueKey(n.id), notification: n),
              ],
            ],
          if (_filter == null) ...[
            const SizedBox(height: MuSpace.s6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s8),
              child: Text(
                l10n.tuAsToutVuLes,
                textAlign: TextAlign.center,
                style: caption,
              ),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.notifications,
            onBack: () => goBack(context, Routes.home),
            actions: [
              MuBarAction(
                icon: PhosphorIcons.gearSix(),
                label: l10n.preferencesDeNotification,
                onPressed: () => context.push(Routes.notificationSettings),
              ),
            ],
          ),
          chips(),
          const SizedBox(height: MuSpace.s2),
          Expanded(child: body),
        ],
      ),
    );
  }
}
