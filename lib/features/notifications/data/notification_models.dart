import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';

/// The centre's filter chips and the preference rows (NOT-01, NOT-10).
enum NotificationCategory {
  matches('Matchs'),
  bookings('Réservations'),
  tournaments('Tournois'),
  payments('Paiements'),
  training('Entraînement'),
  community('Communauté'),
  security('Sécurité');

  const NotificationCategory(this.label);
  final String label;

  /// Category icon when the notification has no sport or avatar (NotificationItem.md).
  IconData get icon => switch (this) {
    NotificationCategory.matches => PhosphorIcons.soccerBall(),
    NotificationCategory.bookings => PhosphorIcons.calendarCheck(),
    NotificationCategory.tournaments => PhosphorIcons.trophy(),
    NotificationCategory.payments => PhosphorIcons.wallet(),
    NotificationCategory.training => PhosphorIcons.barbell(),
    NotificationCategory.community => PhosphorIcons.chatsCircle(),
    NotificationCategory.security => PhosphorIcons.shieldCheck(),
  };

  /// Payments and security can't be turned off in the app (NOT-10).
  bool get locked => this == payments || this == security;
}

enum NotificationPriority { normal, important, urgent }

/// Where a notification or its action leads. Targets of later phases have no route yet: their
/// actions are hidden (Phase 11 brief).
enum NotificationTarget {
  claimSpot,
  game,
  upcoming,
  past,
  rate,
  booking,
  invite,
  checkout,
  paymentFailed,
  receipt,
  wallet,
  refundStatus,
  subscription,
  explore,
  directions,
  tournament,
  community,
  training,
  ownerSpace,
  organizerSpace,
}

/// An inline action (« Payer ma part · 15 DT », « Réclamer la place · 14:59 »).
@immutable
class NotificationAction {
  const NotificationAction(
    this.label, {
    this.target,
    this.secondary = false,
    this.price,
    this.icon,
    this.countdown = false,
    this.accept,
  });

  final String label;
  final NotificationTarget? target;
  final bool secondary;
  final String? price;
  final IconData? icon;

  /// Shows the time left before the notification's [AppNotification.expiresAt].
  final bool countdown;

  /// An invitation's « Accepter » (true) or « Refuser » (false).
  final bool? accept;
}

/// The 36 notification types of the catalog (NOT-04, NOT-05, NOT-06), numbered as there.
enum NotificationType {
  gameFull(1, NotificationCategory.matches),
  playerLeft(2, NotificationCategory.matches),
  matchReminder(3, NotificationCategory.matches),
  spotFreed(4, NotificationCategory.matches),
  invitation(5, NotificationCategory.matches),
  rateTeammates(6, NotificationCategory.matches),
  bookingConfirmed(7, NotificationCategory.bookings),
  bookingCancelledByVenue(8, NotificationCategory.bookings),
  bookingMoved(9, NotificationCategory.bookings),
  checkIn(10, NotificationCategory.bookings),
  paymentSucceeded(11, NotificationCategory.payments),
  paymentFailed(12, NotificationCategory.payments),
  shareDue(13, NotificationCategory.payments),
  refundDone(14, NotificationCategory.payments),
  subscriptionRenewed(15, NotificationCategory.payments),
  renewalFailed(16, NotificationCategory.payments),
  trialEnding(17, NotificationCategory.payments),
  tournamentRegistered(18, NotificationCategory.tournaments),
  drawPublished(19, NotificationCategory.tournaments),
  tournamentMatchSoon(20, NotificationCategory.tournaments),
  tournamentResult(21, NotificationCategory.tournaments),
  tournamentAnnouncement(22, NotificationCategory.tournaments),
  aiPlan(23, NotificationCategory.training),
  coachFeedback(24, NotificationCategory.training),
  newSession(25, NotificationCategory.training),
  streakAtRisk(26, NotificationCategory.training),
  postReply(27, NotificationCategory.community),
  mention(28, NotificationCategory.community),
  bestAnswer(29, NotificationCategory.community),
  contentHidden(30, NotificationCategory.community),
  ownerNewBooking(31, NotificationCategory.bookings),
  ownerCancellation(32, NotificationCategory.bookings),
  ownerNoShow(33, NotificationCategory.bookings),
  organizerRegistration(34, NotificationCategory.tournaments),
  newReview(35, NotificationCategory.bookings),
  payoutSent(36, NotificationCategory.payments),
  // Variants shown in the centre (NOT-01 / NOT-02) beside the catalog.
  registrationsOpen(0, NotificationCategory.tournaments),
  refundReviewing(0, NotificationCategory.payments),
  refundRequested(0, NotificationCategory.payments),
  topUpDone(0, NotificationCategory.payments),
  playersJoined(0, NotificationCategory.matches),
  playerJoinedLive(0, NotificationCategory.matches);

  const NotificationType(this.number, this.category);

  /// The catalog number (0 for the centre's variants).
  final int number;
  final NotificationCategory category;
}

/// One notification of the centre.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.at,
    this.priority = NotificationPriority.normal,
    this.sport,
    this.icon,
    this.status,
    this.avatar,
    this.people = const [],
    this.thumbnail,
    this.ai = false,
    this.actions = const [],
    this.target,
    this.targetId,
    this.expiresAt,
    this.unread = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime at;
  final NotificationPriority priority;
  final MuSport? sport;
  final IconData? icon;
  final MuTone? status;
  final String? avatar;
  final List<String> people;

  /// The sport of a poster thumbnail (tournaments, programmes).
  final MuSport? thumbnail;

  /// The title carries the AI label (« Ton plan de la semaine »).
  final bool ai;
  final List<NotificationAction> actions;
  final NotificationTarget? target;

  /// The game, booking or refund the notification is about.
  final String? targetId;

  /// When a time-limited action expires (the 15 min of a freed spot).
  final DateTime? expiresAt;
  final bool unread;

  NotificationCategory get category => type.category;

  AppNotification copyWith({bool? unread}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    at: at,
    priority: priority,
    sport: sport,
    icon: icon,
    status: status,
    avatar: avatar,
    people: people,
    thumbnail: thumbnail,
    ai: ai,
    actions: actions,
    target: target,
    targetId: targetId,
    expiresAt: expiresAt,
    unread: unread ?? this.unread,
  );
}
