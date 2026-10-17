import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../theme/theme.dart';
import 'notification_models.dart';

/// The notification centre's data. Until a backend exists [FakeNotificationRepository] serves
/// the story's notifications (NOT-01 / NOT-02) and the debug menu pushes new ones.
abstract interface class NotificationRepository {
  /// The centre, newest first; emits on every change.
  Stream<List<AppNotification>> watch();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);

  /// A new notification arrives (real time, debug menu).
  Future<void> push(AppNotification n);
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({required DateTime now, bool empty = false})
    : _items = empty ? [] : storyNotifications(now);

  final List<AppNotification> _items;
  final _changes = StreamController<List<AppNotification>>.broadcast();

  List<AppNotification> get _sorted => [..._items]..sort((a, b) => b.at.compareTo(a.at));

  void _emit() => _changes.add(_sorted);

  @override
  Stream<List<AppNotification>> watch() async* {
    yield _sorted;
    yield* _changes.stream;
  }

  @override
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i >= 0) _items[i] = _items[i].copyWith(unread: false);
    _emit();
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(unread: false);
    }
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((n) => n.id == id);
    _emit();
  }

  @override
  Future<void> push(AppNotification n) async {
    _items.removeWhere((x) => x.id == n.id);
    _items.add(n);
    _emit();
  }
}

/// The centre on ven. 16 oct. 18h00 (NOT-01, plus the payment lines of NOT-02).
List<AppNotification> storyNotifications(DateTime now) {
  DateTime ago(Duration d) => now.subtract(d);
  DateTime day(int d, [int h = 9]) => DateTime(2026, 10, d, h);
  return [
    AppNotification(
      id: 'n-place',
      type: NotificationType.spotFreed,
      title: 'Une place s’est libérée',
      body: 'Foot 5v5 · Arena Five · dim. 18 oct. · 20h00. Réclame-la avant qu’elle passe au suivant.',
      at: ago(const Duration(minutes: 1)),
      priority: NotificationPriority.urgent,
      sport: MuSport.football,
      target: NotificationTarget.claimSpot,
      targetId: 'g1',
      expiresAt: ago(const Duration(minutes: 1)).add(const Duration(minutes: 15)),
      unread: true,
      actions: const [
        NotificationAction(
          'Réclamer la place',
          countdown: true,
          target: NotificationTarget.claimSpot,
        ),
      ],
    ),
    AppNotification(
      id: 'n-invite',
      type: NotificationType.invitation,
      title: 'Mariem K. t’invite au padel',
      body: 'Padel mixte · Smash Padel Club · ven. 23 oct. · 19h30 · 25 DT par personne · 2/4 joueurs.',
      at: ago(const Duration(minutes: 12)),
      sport: MuSport.padel,
      avatar: 'Mariem K.',
      target: NotificationTarget.upcoming,
      unread: true,
      actions: const [
        NotificationAction('Accepter', target: NotificationTarget.upcoming, accept: true),
        NotificationAction(
          'Refuser',
          secondary: true,
          target: NotificationTarget.upcoming,
          accept: false,
        ),
      ],
    ),
    AppNotification(
      id: 'n-part',
      type: NotificationType.shareDue,
      title: 'Ta part de 15 DT est en attente',
      body:
          'Ta réservation à Arena Five, mer. 21 oct. · 21h00. À régler avant mer. 21 oct. · 18h00.',
      at: ago(const Duration(hours: 2)),
      priority: NotificationPriority.important,
      target: NotificationTarget.checkout,
      targetId: 'MU-48213',
      unread: true,
      actions: const [
        NotificationAction('Payer ma part', price: '15 DT', target: NotificationTarget.checkout),
      ],
    ),
    AppNotification(
      id: 'n-joined',
      type: NotificationType.playersJoined,
      title: 'Nour A. et 2 autres ont rejoint ta partie',
      body: 'Arena Five · Terrain 1 · mer. 21 oct. · 21h00 · 6/10 joueurs, encore 4 places.',
      at: ago(const Duration(hours: 3)),
      sport: MuSport.football,
      people: const ['Nour A.', 'Omar D.', 'Aziz H.'],
      target: NotificationTarget.booking,
      targetId: 'MU-48213',
    ),
    AppNotification(
      id: 'n-cup',
      type: NotificationType.registrationsOpen,
      title: 'Inscriptions ouvertes : Padel Masters Lac 2',
      body: 'Smash Padel Club · 24–26 oct. · 120 DT par équipe. Plus que 4 places.',
      at: day(15),
      icon: PhosphorIcons.trophy(),
      thumbnail: MuSport.padel,
    ),
    AppNotification(
      id: 'n-reply',
      type: NotificationType.postReply,
      title: 'Hamza R. a répondu à ton post',
      body: '« Compte sur moi, on vient à deux. » — sur ton post « 5v5 dimanche soir à La Marsa ».',
      at: day(14),
      avatar: 'Hamza R.',
      icon: PhosphorIcons.chatsCircle(),
    ),
    AppNotification(
      id: 'n-review',
      type: NotificationType.refundReviewing,
      title: 'Remboursement en cours d’examen',
      body: 'Part · Hoop Zone · dim. 27 sept. · 9 DT. Réponse sous 5 jours ouvrés.',
      at: day(13),
      status: MuTone.info,
      icon: PhosphorIcons.hourglass(),
      target: NotificationTarget.refundStatus,
      targetId: 'rf-hoop',
    ),
    AppNotification(
      id: 'n-sent',
      type: NotificationType.refundRequested,
      title: 'Demande de remboursement envoyée',
      body: '9 DT · « Le terrain était fermé à notre arrivée ». On revient vers toi sous 5 jours ouvrés.',
      at: day(12, 8),
      icon: PhosphorIcons.wallet(),
      target: NotificationTarget.refundStatus,
      targetId: 'rf-hoop',
    ),
    AppNotification(
      id: 'n-rate',
      type: NotificationType.rateTeammates,
      title: 'Note tes coéquipiers du ven. 9 oct.',
      body: 'Padel · Smash Padel Club avec Mariem K., Ines M. et Nour A. 1 min suffit.',
      at: day(12),
      sport: MuSport.padel,
      target: NotificationTarget.rate,
      actions: [
        NotificationAction(
          'Noter les joueurs',
          secondary: true,
          icon: PhosphorIcons.star(),
          target: NotificationTarget.rate,
        ),
      ],
    ),
    AppNotification(
      id: 'n-refund',
      type: NotificationType.refundDone,
      title: 'Remboursement de 15 DT effectué',
      body: 'Foot du sam. 10 oct. annulé par Skander T. 15 DT crédités sur ton solde MatchUp.',
      at: day(9, 12),
      status: MuTone.success,
      icon: PhosphorIcons.wallet(),
      target: NotificationTarget.wallet,
    ),
    AppNotification(
      id: 'n-padel',
      type: NotificationType.paymentSucceeded,
      title: 'Paiement réussi · 20 DT',
      body: 'Ta part · Smash Padel Club, ven. 9 oct. Payée avec ton solde MatchUp.',
      at: day(9, 10),
      status: MuTone.success,
      icon: PhosphorIcons.checkCircle(),
      target: NotificationTarget.wallet,
    ),
    AppNotification(
      id: 'n-topup',
      type: NotificationType.topUpDone,
      title: 'Recharge de 50 DT effectuée',
      body: 'Visa •••• 4242. Ton solde MatchUp est prêt pour tes prochaines parties.',
      at: day(5),
      status: MuTone.success,
      icon: PhosphorIcons.plusCircle(),
      target: NotificationTarget.wallet,
    ),
    AppNotification(
      id: 'n-reminder',
      type: NotificationType.matchReminder,
      title: 'Rappel : Foot 5v5 à Arena Five dans 2 h',
      body: 'Sam. 3 oct. · Terrain 2. Arrive 10 min avant, chasubles fournies.',
      at: day(3, 16),
      sport: MuSport.football,
      icon: PhosphorIcons.clock(),
      target: NotificationTarget.past,
    ),
  ];
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => FakeNotificationRepository(now: ref.read(clockProvider)()),
);

final notificationsProvider = StreamProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).watch(),
);

/// The bell's count on Home.
final unreadNotificationsProvider = Provider<int>(
  (ref) => (ref.watch(notificationsProvider).value ?? const []).where((n) => n.unread).length,
);
