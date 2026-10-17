import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';

/// Where an account stands for the admin (ADM-02 badge).
enum AdminUserStatus { flagged, toVerify, active, suspended, banned }

/// The roles an account holds (ADM-02 « Rôle » filter).
enum AdminRole { player, owner, coach, organizer }

/// One row of ADM-02.
@immutable
class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.roleLine,
    required this.meta,
    required this.status,
    required this.roles,
    required this.joined,
    required this.lastActive,
    this.email = '',
    this.phone = '',
    this.reliability,
    this.hasDetail = false,
    this.verificationId,
    this.suspendedUntil,
  });

  final String id;

  /// « Omar D. », « promo_crampons ».
  final String name;

  /// « Joueur · La Marsa ».
  final String roleLine;

  /// « 2 no-shows · 1 signalement ».
  final String meta;
  final AdminUserStatus status;
  final Set<AdminRole> roles;
  final DateTime joined;
  final DateTime lastActive;
  final String email;
  final String phone;
  final int? reliability;

  /// ADM-03 is designed for this account.
  final bool hasDetail;

  /// Opens ADM-05 when the account waits for a verification.
  final String? verificationId;

  /// Set once suspended (ADM-04); null and [AdminUserStatus.banned] = banned for good.
  final DateTime? suspendedUntil;

  AdminUser copyWith({AdminUserStatus? status, DateTime? suspendedUntil}) => AdminUser(
    id: id,
    name: name,
    roleLine: roleLine,
    meta: meta,
    status: status ?? this.status,
    roles: roles,
    joined: joined,
    lastActive: lastActive,
    email: email,
    phone: phone,
    reliability: reliability,
    hasDetail: hasDetail,
    verificationId: verificationId,
    suspendedUntil: suspendedUntil ?? this.suspendedUntil,
  );
}

enum AdminActivityKind { booking, review, joined, noShow }

@immutable
class AdminActivity {
  const AdminActivity(this.kind, this.title, this.meta);

  final AdminActivityKind kind;
  final String title;
  final String meta;
}

/// What ADM-04 needs to state the consequence and reach the player (STA-07).
@immutable
class AdminSanctionPlan {
  const AdminSanctionPlan({
    required this.reason,
    required this.message,
    required this.playerReason,
    this.freedGames = 0,
    this.refund = 0,
  });

  /// The « Raison » select's value.
  final AdminSanctionReason reason;

  /// « Message à Omar D. » prefilled.
  final String message;

  /// The reason the player reads on STA-07.
  final String playerReason;

  /// Upcoming games freed and their shares refunded to the balance.
  final int freedGames;
  final num refund;
}

enum AdminSanctionReason { noShow, aggressive, spam, fraud, other }

extension AdminSanctionReasonLabel on AdminSanctionReason {
  String get label => switch (this) {
    AdminSanctionReason.noShow => 'No-shows répétés',
    AdminSanctionReason.aggressive => 'Comportement agressif',
    AdminSanctionReason.spam => 'Spam ou publicité',
    AdminSanctionReason.fraud => 'Fraude au paiement',
    AdminSanctionReason.other => 'Autre raison',
  };
}

/// ADM-04 durations; [ban] has no end.
enum AdminSuspensionLength {
  day(Duration(hours: 24)),
  week(Duration(days: 7)),
  month(Duration(days: 30)),
  ban(null);

  const AdminSuspensionLength(this.duration);

  final Duration? duration;
}

/// ADM-03 · Fiche utilisateur.
@immutable
class AdminUserDetail {
  const AdminUserDetail({
    required this.user,
    required this.code,
    required this.handle,
    required this.sport,
    required this.level,
    required this.matches,
    required this.noShows,
    required this.reports,
    required this.paid,
    required this.joinedLine,
    required this.alertTitle,
    required this.alertDetail,
    required this.reporter,
    required this.reporterLine,
    required this.reportContext,
    required this.reportQuote,
    required this.activity,
    required this.paymentCard,
    required this.payments,
    required this.plan,
  });

  final AdminUser user;

  /// « U-20417 ».
  final String code;

  /// « @omar.d ».
  final String handle;
  final MuSport sport;
  final double level;
  final int matches;
  final int noShows;
  final int reports;
  final num paid;

  /// « mar. 10 mars 2026 · Google ».
  final String joinedLine;
  final String alertTitle;
  final String alertDetail;
  final String reporter;
  final String reporterLine;
  final String reportContext;
  final String reportQuote;
  final List<AdminActivity> activity;

  /// « Visa •••• 7310 ».
  final String paymentCard;
  final List<MuTransaction> payments;
  final AdminSanctionPlan plan;
}

enum AdminVerificationKind { coach, venue }

enum AdminVerificationStatus { pending, illegible, approved }

enum AdminDocKind { pdf, id, image }

@immutable
class AdminDoc {
  const AdminDoc(this.kind, this.title, this.meta, {this.bad = false});

  final AdminDocKind kind;
  final String title;
  final String meta;
  final bool bad;
}

/// One request of ADM-05.
@immutable
class AdminVerification {
  const AdminVerification({
    required this.id,
    required this.kind,
    required this.name,
    required this.line,
    required this.sent,
    required this.aiTitle,
    required this.aiBody,
    this.sport = MuSport.padel,
    this.status = AdminVerificationStatus.pending,
    this.docs = const [],
    this.checksTitle,
    this.checks = const [],
    this.aiNote,
    this.doneLine,
  });

  final String id;
  final AdminVerificationKind kind;
  final String name;

  /// « Coach padel · Lac 2 · badge « Certifié FTT » ».
  final String line;
  final DateTime sent;
  final MuSport sport;
  final AdminVerificationStatus status;
  final List<AdminDoc> docs;

  /// « 4 pièces sur 4 fournies ».
  final String? checksTitle;
  final List<String> checks;
  final String aiTitle;
  final String aiBody;
  final String? aiNote;

  /// Once handled: « Coach basket · mar. 13 oct. ».
  final String? doneLine;

  AdminVerification approved(String line) => AdminVerification(
    id: id,
    kind: kind,
    name: name,
    line: this.line,
    sent: sent,
    sport: sport,
    status: AdminVerificationStatus.approved,
    docs: docs,
    checksTitle: checksTitle,
    checks: checks,
    aiTitle: aiTitle,
    aiBody: aiBody,
    aiNote: aiNote,
    doneLine: line,
  );
}

/// ADM-01 numbers.
@immutable
class AdminOverview {
  const AdminOverview({
    required this.users,
    required this.usersDelta,
    required this.bookings,
    required this.bookingsDelta,
    required this.revenue,
    required this.revenueDelta,
    required this.venues,
    required this.venuesDelta,
    required this.days,
    required this.bySport,
    required this.premium,
    required this.premiumWeek,
    required this.trials,
  });

  final int users;
  final double usersDelta;
  final int bookings;
  final double bookingsDelta;
  final num revenue;
  final double revenueDelta;
  final int venues;
  final double venuesDelta;
  final List<DateTime> days;
  final Map<MuSport, List<double>> bySport;
  final int premium;
  final num premiumWeek;
  final int trials;
}

enum AdminTxFilter { all, bookings, subscriptions, refunds, payouts }

/// ADM-06 data.
@immutable
class AdminFinance {
  const AdminFinance({
    required this.cashed,
    required this.cashedDelta,
    required this.refunded,
    required this.refundedDelta,
    required this.revenue,
    required this.sources,
    required this.today,
    required this.week,
  });

  final num cashed;
  final double cashedDelta;
  final num refunded;
  final double refundedDelta;

  /// 30 days, ending today.
  final List<double> revenue;
  final List<(String, double)> sources;
  final List<MuTransaction> today;
  final List<MuTransaction> week;
}

/// One payout of ADM-07.
@immutable
class AdminPayout {
  const AdminPayout({
    required this.id,
    required this.name,
    required this.bank,
    required this.meta,
    required this.amount,
    this.validated = false,
  });

  final String id;
  final String name;

  /// « Terrain · Attijari bank •••• 12 34 ».
  final String bank;
  final String meta;
  final num amount;
  final bool validated;
}

enum AdminFactKind { photo, message, wallet, confirmed, card }

/// One refund request of ADM-07.
@immutable
class AdminRefund {
  const AdminRefund({
    required this.id,
    required this.name,
    required this.line,
    required this.amount,
    required this.quote,
    required this.facts,
    this.done = false,
  });

  final String id;
  final String name;
  final String line;
  final num amount;
  final String quote;
  final List<(AdminFactKind, String)> facts;
  final bool done;
}

enum ChurnLevel { high, medium }

/// One subscriber of ADM-08.
@immutable
class ChurnRisk {
  const ChurnRisk({
    required this.id,
    required this.name,
    required this.context,
    required this.title,
    required this.reason,
    required this.line,
    required this.level,
    required this.score,
    required this.trend,
    required this.trendLabel,
    required this.primary,
    required this.secondary,
    this.playerLevel,
    this.primaryMail = false,
    this.secondaryIgnores = false,
    this.ignored = false,
  });

  final String id;
  final String name;
  final String context;
  final String title;
  final String reason;

  /// « 19 DT/mois · La Marsa ».
  final String line;
  final ChurnLevel level;

  /// 0–100.
  final int score;
  final List<double> trend;
  final String trendLabel;
  final String primary;
  final String secondary;

  /// The player's level shown on the avatar.
  final double? playerLevel;
  final bool primaryMail;
  final bool secondaryIgnores;
  final bool ignored;

  ChurnRisk withIgnored(bool v) => ChurnRisk(
    id: id,
    name: name,
    context: context,
    title: title,
    reason: reason,
    line: line,
    level: level,
    score: score,
    trend: trend,
    trendLabel: trendLabel,
    primary: primary,
    secondary: secondary,
    playerLevel: playerLevel,
    primaryMail: primaryMail,
    secondaryIgnores: secondaryIgnores,
    ignored: v,
  );
}

enum ModerationKind { comment, post, review, profile }

/// One reported content of ADM-09.
@immutable
class ModerationItem {
  const ModerationItem({
    required this.id,
    required this.kind,
    required this.type,
    required this.quote,
    required this.meta,
    required this.why,
    required this.score,
    required this.reported,
    this.author,
    this.reviewable = false,
  });

  final String id;
  final ModerationKind kind;

  /// « Commentaire · Équipement ».
  final String type;
  final String quote;
  final String meta;

  /// The AI's reading (« Toxicité · insulte légère »).
  final String why;

  /// AI score 0–1: it only sorts the queue.
  final double score;
  final DateTime reported;
  final String? author;

  /// ADM-10 is designed for it.
  final bool reviewable;
}

/// ADM-10 · Revue du contenu.
@immutable
class ModerationReview {
  const ModerationReview({
    required this.item,
    required this.authorId,
    required this.replyTo,
    required this.time,
    required this.before,
    required this.flagged,
    required this.after,
    required this.analysis,
    required this.reportsTitle,
    required this.reportsDetail,
  });

  final ModerationItem item;

  /// The author's account, for « Suspendre l’auteur » (ADM-04).
  final String authorId;
  final String replyTo;
  final String time;

  /// The text around the passage the AI flagged.
  final String before;
  final String flagged;
  final String after;
  final String analysis;
  final String reportsTitle;
  final String reportsDetail;
}

enum ModerationDecision { approve, delete, warn, suspend }

/// The admin space (ADM-01 to ADM-10). Swap [FakeAdminRepository] for the API later.
abstract interface class AdminRepository {
  Future<AdminOverview> overview();
  Future<List<AdminUser>> users();
  Future<AdminUserDetail?> userDetail(String id);
  Future<AdminSanctionPlan> sanctionPlan(String id);

  /// [until] is null for a definitive ban.
  Future<void> suspend(String id, {required DateTime? until});
  Future<List<AdminVerification>> verifications();
  Future<void> approve(String id, String doneLine);
  Future<AdminFinance> finance();
  Future<List<AdminPayout>> payouts();
  Future<void> validatePayouts(Set<String> ids);
  Future<List<AdminRefund>> refunds();
  Future<void> refund(String id);
  Future<List<ChurnRisk>> churn();
  Future<void> ignoreChurn(String id, {required bool ignored});
  Future<List<ModerationItem>> moderation();
  Future<ModerationReview?> review(String id);
  Future<void> decide(String id, ModerationDecision decision);
}

/// Story data of the admin space (STORY-DATA « Admin »), « now » = ven. 16 oct. 18h00.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  Future<void> _wait() => Future<void>.delayed(latency);

  static DateTime _d(int month, int day, [int hour = 12]) => DateTime(2026, month, day, hour);

  final List<AdminUser> _users = [
    AdminUser(
      id: 'bons',
      name: 'bons.plans.tn',
      roleLine: 'Joueur · inscrit jeu. 15 oct.',
      meta: '4 posts signalés · spam',
      status: AdminUserStatus.flagged,
      roles: const {AdminRole.player},
      joined: _d(10, 15),
      lastActive: _d(10, 16, 9),
      email: 'bons.plans.tn@email.tn',
    ),
    AdminUser(
      id: 'promo',
      name: 'promo_crampons',
      roleLine: 'Joueur · inscrit mer. 14 oct.',
      meta: '6 posts signalés · spam',
      status: AdminUserStatus.flagged,
      roles: const {AdminRole.player},
      joined: _d(10, 14),
      lastActive: _d(10, 16, 17),
      email: 'promo.crampons@email.tn',
    ),
    AdminUser(
      id: 'omar',
      name: 'Omar D.',
      roleLine: 'Joueur · La Marsa',
      meta: '2 no-shows · 1 signalement',
      status: AdminUserStatus.flagged,
      roles: const {AdminRole.player},
      joined: _d(3, 10),
      lastActive: _d(10, 16, 18),
      email: 'omar.d@email.tn',
      phone: '22456789',
      reliability: 92,
      hasDetail: true,
    ),
    AdminUser(
      id: 'karim',
      name: 'Karim J.',
      roleLine: 'Coach padel · Lac 2',
      meta: 'Badge « Certifié FTT » à vérifier',
      status: AdminUserStatus.toVerify,
      roles: const {AdminRole.coach},
      joined: _d(9, 2),
      lastActive: _d(10, 16, 11),
      email: 'karim.j@email.tn',
      reliability: 100,
      verificationId: 'karim',
    ),
    AdminUser(
      id: 'sonia',
      name: 'Sonia L.',
      roleLine: 'Coach football · Ariana',
      meta: 'Document illisible',
      status: AdminUserStatus.toVerify,
      roles: const {AdminRole.coach},
      joined: _d(10, 1),
      lastActive: _d(10, 15, 20),
      email: 'sonia.l@email.tn',
      reliability: 100,
      verificationId: 'sonia',
    ),
    AdminUser(
      id: 'yassine',
      name: Story.myName,
      roleLine: 'Joueur · Propriétaire · La Marsa',
      meta: '1 commentaire masqué',
      status: AdminUserStatus.active,
      roles: const {AdminRole.player, AdminRole.owner},
      joined: _d(1, 8),
      lastActive: _d(10, 16, 18),
      email: 'yassine.b@email.tn',
      reliability: 96,
    ),
    AdminUser(
      id: 'mariem',
      name: 'Mariem K.',
      roleLine: 'Joueur · La Marsa',
      meta: 'Fiable 98 % · 74 matchs',
      status: AdminUserStatus.active,
      roles: const {AdminRole.player},
      joined: _d(2, 21),
      lastActive: _d(10, 16, 17),
      email: 'mariem.k@email.tn',
      reliability: 98,
    ),
    AdminUser(
      id: 'sami',
      name: 'Sami C.',
      roleLine: 'Organisateur · Tunis Padel Series',
      meta: '2 tournois actifs',
      status: AdminUserStatus.active,
      roles: const {AdminRole.organizer},
      joined: _d(4, 3),
      lastActive: _d(10, 16, 10),
      email: 'sami.c@email.tn',
      reliability: 99,
    ),
    AdminUser(
      id: 'skander',
      name: Story.ownerName,
      roleLine: 'Joueur · Propriétaire · Arena Five',
      meta: 'Fiable 96 % · terrain vérifié',
      status: AdminUserStatus.active,
      roles: const {AdminRole.player, AdminRole.owner},
      joined: _d(1, 5),
      lastActive: _d(10, 16, 18),
      email: 'skander.t@email.tn',
      reliability: 96,
    ),
  ];

  final Map<String, AdminSanctionPlan> _plans = const {
    'omar': AdminSanctionPlan(
      reason: AdminSanctionReason.noShow,
      message: '2 matchs manqués sans prévenir : sam. 26 sept. et jeu. 8 oct.',
      playerReason: '2 matchs manqués sans prévenir, le sam. 26 sept. et le jeu. 8 oct.',
      freedGames: 2,
      refund: 30,
    ),
    'yassine': AdminSanctionPlan(
      reason: AdminSanctionReason.aggressive,
      message: 'Commentaire insultant dans « Crampons pour synthétique ? ».',
      playerReason: 'commentaire insultant dans « Crampons pour synthétique ? ».',
    ),
  };

  late final List<AdminVerification> _verifications = [
    AdminVerification(
      id: 'karim',
      kind: AdminVerificationKind.coach,
      name: 'Karim J.',
      line: 'Coach padel · Lac 2 · badge « Certifié FTT »',
      sent: _d(10, 14),
      docs: const [
        AdminDoc(AdminDocKind.pdf, 'Certificat FTT niveau 2', 'PDF · 2 pages · 1,2 Mo'),
        AdminDoc(AdminDocKind.id, 'Carte d’identité', '2 photos · recto et verso'),
      ],
      aiTitle: 'Lecture du certificat',
      aiBody: 'Nom, niveau 2 et validité (juin 2028) lus sur le document, identiques au profil.',
      aiNote: 'L’IA ne valide jamais seule : vérifie le tampon de la fédération.',
    ),
    AdminVerification(
      id: 'phm',
      kind: AdminVerificationKind.venue,
      name: 'Padel House Menzah',
      line: 'Padel · Menzah 6 · Walid B.',
      sent: _d(10, 12),
      checksTitle: '4 pièces sur 4 fournies',
      checks: const ['Registre de commerce', 'CIN du gérant', 'RIB · BIAT •••• 88 02', '6 photos'],
      aiTitle: 'Contrôle des pièces',
      aiBody: 'Adresse du registre identique à celle de la carte. Les photos montrent 3 courts de padel.',
      aiNote: 'À confirmer : l’IA ne peut pas savoir si le club est ouvert au public.',
    ),
    AdminVerification(
      id: 'sonia',
      kind: AdminVerificationKind.coach,
      name: 'Sonia L.',
      line: 'Coach football · Ariana',
      sent: _d(10, 15),
      sport: MuSport.football,
      status: AdminVerificationStatus.illegible,
      docs: const [
        AdminDoc(AdminDocKind.image, 'Diplôme d’entraîneur', 'Photo floue · 0,4 Mo', bad: true),
      ],
      aiTitle: 'Lecture du diplôme',
      aiBody: 'Nom et date de délivrance illisibles : la photo est floue et coupée en bas.',
    ),
    AdminVerification(
      id: 'mehdi',
      kind: AdminVerificationKind.coach,
      name: 'Mehdi K.',
      line: 'Coach basket',
      sent: _d(10, 10),
      sport: MuSport.basketball,
      status: AdminVerificationStatus.approved,
      aiTitle: '',
      aiBody: '',
      doneLine: 'Coach basket · mar. 13 oct.',
    ),
    AdminVerification(
      id: 'arena',
      kind: AdminVerificationKind.venue,
      name: Story.arenaFive.name,
      line: 'Football · La Marsa',
      sent: _d(10, 9),
      sport: MuSport.football,
      status: AdminVerificationStatus.approved,
      aiTitle: '',
      aiBody: '',
      doneLine: 'RIB vérifié · lun. 12 oct.',
    ),
  ];

  final List<AdminPayout> _payouts = [
    const AdminPayout(
      id: 'arena',
      name: 'Arena Five',
      bank: 'Terrain · Attijari bank •••• 12 34',
      meta: '52 réservations · commission déduite',
      amount: 1410,
    ),
    const AdminPayout(
      id: 'smash',
      name: 'Smash Padel Club',
      bank: 'Terrain · STB •••• 40 17',
      meta: '38 réservations · commission déduite',
      amount: 3320,
    ),
    const AdminPayout(
      id: 'karim',
      name: 'Karim J.',
      bank: 'Coach · Amen Bank •••• 77 05',
      meta: 'Octobre · après commission 10 %',
      amount: 612,
    ),
  ];

  final List<AdminRefund> _refunds = [
    const AdminRefund(
      id: 'yassine',
      name: 'Yassine B.',
      line: 'Part · Hoop Zone · dim. 27 sept.',
      amount: 9,
      quote: '« Le terrain était fermé à notre arrivée. »',
      facts: [
        (AdminFactKind.photo, '1 photo jointe · portail fermé, 19h04'),
        (AdminFactKind.message, 'Hoop Zone n’a pas répondu (relancé mar. 13 oct.)'),
        (AdminFactKind.wallet, 'Vers son solde · en examen depuis mar. 13 oct.'),
      ],
    ),
    const AdminRefund(
      id: 'salma',
      name: 'Salma G.',
      line: 'Part · Arena Five · mer. 14 oct.',
      amount: 15,
      quote: '« J’ai été débitée deux fois pour la même partie. »',
      facts: [
        (AdminFactKind.confirmed, 'Doublon confirmé : 2 paiements Visa •••• 0921 à 18h31 et 18h32'),
        (AdminFactKind.card, 'Vers sa carte · 5 à 10 jours ouvrés'),
      ],
    ),
  ];

  final List<ChurnRisk> _churn = [
    const ChurnRisk(
      id: 'ines',
      name: 'Ines M.',
      playerLevel: 4.0,
      context: 'Premium mensuel · depuis mai',
      title: 'Proposer −30 % pendant 2 mois à Ines M.',
      reason: 'elle n’a joué aucun match depuis le jeu. 24 sept. (6 par mois avant) et n’ouvre plus son plan IA.',
      line: '19 DT/mois · La Marsa',
      level: ChurnLevel.high,
      score: 78,
      trend: [2, 1, 2, 1, 1, 1, 0, 1, 0, 0, 0, 0],
      trendLabel: 'Matchs par semaine sur 12 semaines : de 2 à 0',
      primary: 'Préparer l’offre',
      secondary: 'Contacter',
    ),
    const ChurnRisk(
      id: 'hamza',
      name: 'Hamza R.',
      playerLevel: 3.5,
      context: 'Premium mensuel · depuis mars',
      title: 'Demander à Hamza R. de mettre à jour sa carte',
      reason: '2 prélèvements refusés ce mois-ci et sa carte expire fin octobre. Il joue toujours 2 fois par semaine.',
      line: '19 DT/mois · Ennasr',
      level: ChurnLevel.medium,
      score: 64,
      trend: [2, 2, 3, 2, 2, 2, 3, 2, 2, 2, 2, 2],
      trendLabel: 'Matchs par semaine sur 12 semaines : stable, environ 2',
      primary: 'Contacter',
      secondary: 'Ignorer',
      primaryMail: true,
      secondaryIgnores: true,
    ),
    const ChurnRisk(
      id: 'aziz',
      name: 'Aziz H.',
      playerLevel: 4.5,
      context: 'Premium mensuel · depuis août',
      title: 'Proposer −30 % pendant 2 mois à Aziz H.',
      reason: 'il a ouvert « Résilier » 2 fois cette semaine et n’a utilisé aucun avantage Premium en octobre.',
      line: '19 DT/mois · Lac 2',
      level: ChurnLevel.medium,
      score: 55,
      trend: [3, 3, 2, 3, 2, 2, 2, 1, 2, 1, 1, 1],
      trendLabel: 'Matchs par semaine sur 12 semaines : de 3 à 1',
      primary: 'Préparer l’offre',
      secondary: 'Contacter',
    ),
  ];

  final List<ModerationItem> _moderation = [
    ModerationItem(
      id: 'promo',
      kind: ModerationKind.post,
      type: 'Post · Équipement',
      quote: '« Vends crampons pas cher, livraison partout, lien en bio »',
      meta: 'promo_crampons · 5 signalements · 1 h',
      why: 'Spam · même lien posté 6 fois',
      score: 0.91,
      reported: _d(10, 16, 17),
      author: 'promo_crampons',
    ),
    ModerationItem(
      id: 'yassine',
      kind: ModerationKind.comment,
      type: 'Commentaire · Équipement',
      quote: '« T’as jamais mis les pieds sur un synthétique, franchement t’es nul. »',
      meta: 'Yassine B. · 3 signalements · masqué',
      why: 'Toxicité · insulte légère',
      score: 0.62,
      reported: _d(10, 16, 18),
      author: Story.myName,
      reviewable: true,
    ),
    ModerationItem(
      id: 'bilel',
      kind: ModerationKind.post,
      type: 'Post · Conseils & technique',
      quote: '« Cours de padel à 30 DT, appelle-moi au 98 ••• 214 »',
      meta: 'coach.bilel · 2 signalements · hier',
      why: 'Coordonnées publiées',
      score: 0.55,
      reported: _d(10, 15, 16),
      author: 'coach.bilel',
    ),
    ModerationItem(
      id: 'rami',
      kind: ModerationKind.comment,
      type: 'Commentaire · Tournois',
      quote: '« Les arbitres de ce tournoi sont achetés, c’est une blague. »',
      meta: 'Rami S. · 1 signalement · hier',
      why: 'Accusation sans preuve',
      score: 0.47,
      reported: _d(10, 15, 21),
      author: 'Rami S.',
    ),
    ModerationItem(
      id: 'aziz',
      kind: ModerationKind.comment,
      type: 'Commentaire · Équipement',
      quote: '« Encore un qui achète des crampons à 300 DT pour jouer comme ça. »',
      meta: 'Aziz H. · 1 signalement · jeu. 15 oct.',
      why: 'Moquerie',
      score: 0.34,
      reported: _d(10, 15, 9),
      author: 'Aziz H.',
    ),
    ModerationItem(
      id: 'lina',
      kind: ModerationKind.profile,
      type: 'Profil · photo',
      quote: 'Photo de profil de Lina F. · « Ce n’est pas elle sur la photo »',
      meta: 'Signalé par 1 joueur · jeu. 15 oct.',
      why: 'Aucun contenu sensible détecté',
      score: 0.12,
      reported: _d(10, 15, 8),
      author: 'Lina F.',
    ),
    ModerationItem(
      id: 'hoop',
      kind: ModerationKind.review,
      type: 'Avis contesté · Hoop Zone',
      quote: '« Panier cassé depuis des semaines » · 2/5 par Hamza R.',
      meta: 'Contesté par Hoop Zone · mer. 14 oct.',
      why: 'Aucune toxicité · fait à vérifier',
      score: 0.08,
      reported: _d(10, 14, 10),
      author: 'Hamza R.',
    ),
  ];

  @override
  Future<AdminOverview> overview() async {
    await _wait();
    return AdminOverview(
      users: 12480,
      usersDelta: 312,
      bookings: 1945,
      bookingsDelta: 8,
      revenue: 48600,
      revenueDelta: 6,
      venues: 64,
      venuesDelta: 2,
      days: [for (var d = 10; d <= 16; d++) Story.at(d, 12)],
      bySport: const {
        MuSport.football: [200, 182, 120, 133, 145, 152, 196],
        MuSport.padel: [105, 98, 68, 74, 80, 86, 110],
        MuSport.basketball: [35, 30, 22, 23, 25, 27, 34],
      },
      premium: 180,
      premiumWeek: 3420,
      trials: 24,
    );
  }

  @override
  Future<List<AdminUser>> users() async {
    await _wait();
    return List.unmodifiable(_users);
  }

  @override
  Future<AdminUserDetail?> userDetail(String id) async {
    await _wait();
    final user = _users.where((u) => u.id == id).firstOrNull;
    if (user == null || id != 'omar') return null;
    return AdminUserDetail(
      user: user,
      code: 'U-20417',
      handle: '@omar.d',
      sport: MuSport.football,
      level: 3.5,
      matches: 25,
      noShows: 2,
      reports: 1,
      paid: 345,
      joinedLine: 'mar. 10 mars 2026 · Google',
      alertTitle: '2 no-shows en 3 semaines',
      alertDetail:
          'Sa fiabilité est passée de 100 % à 92 %. Aucun avertissement envoyé pour l’instant.',
      reporter: Story.ownerName,
      reporterLine: 'Organisateur · ven. 9 oct. · 10h14',
      reportContext: 'No-show répété · Foot 5v5 · Arena Five · jeu. 8 oct. · 21h00',
      reportQuote: '« Deuxième fois qu’il ne vient pas sans prévenir. On a joué à 9. »',
      activity: const [
        AdminActivity(
          AdminActivityKind.booking,
          'Réservation privée · Arena Five, Terrain 2',
          'ven. 16 oct. · 18h00 · en cours',
        ),
        AdminActivity(
          AdminActivityKind.review,
          'Avis 3/5 sur Arena Five',
          'jeu. 15 oct. · « Vestiaires à rafraîchir »',
        ),
        AdminActivity(
          AdminActivityKind.joined,
          'A rejoint la partie de Yassine B.',
          'mar. 13 oct. · pour mer. 21 oct. · 21h00 · payé',
        ),
        AdminActivity(
          AdminActivityKind.joined,
          'A rejoint le Foot 5v5 de Skander T.',
          'lun. 12 oct. · pour dim. 18 oct. · 20h00 · payé',
        ),
        AdminActivity(
          AdminActivityKind.noShow,
          'No-show · Foot 5v5, Arena Five',
          'jeu. 8 oct. · 21h00 · Terrain 1 · signalé',
        ),
        AdminActivity(
          AdminActivityKind.noShow,
          'No-show · Foot 5v5, Arena Five',
          'sam. 26 sept. · 20h00 · Terrain 2',
        ),
      ],
      paymentCard: 'Visa •••• 7310',
      payments: [
        MuTransaction(
          id: 'o1',
          kind: MuTransactionKind.booking,
          sport: MuSport.football,
          label: 'Réservation · Arena Five, T2',
          meta: 'ven. 16 oct. · 18h00 · Carte •••• 7310',
          amount: -150,
          date: _d(10, 16, 18),
        ),
        MuTransaction(
          id: 'o2',
          kind: MuTransactionKind.booking,
          sport: MuSport.football,
          label: 'Part · Arena Five, mer. 21 oct.',
          meta: 'mar. 13 oct. · Portefeuille',
          amount: -15,
          date: _d(10, 13),
        ),
        MuTransaction(
          id: 'o3',
          kind: MuTransactionKind.booking,
          sport: MuSport.football,
          label: 'Part · Arena Five, dim. 18 oct.',
          meta: 'lun. 12 oct. · Carte •••• 7310',
          amount: -15,
          date: _d(10, 12),
        ),
        MuTransaction(
          id: 'o4',
          kind: MuTransactionKind.booking,
          sport: MuSport.football,
          label: 'Part · Arena Five, jeu. 8 oct.',
          meta: 'No-show · non remboursée',
          amount: -15,
          date: _d(10, 8),
        ),
        MuTransaction(
          id: 'o5',
          kind: MuTransactionKind.topup,
          label: 'Recharge du solde',
          meta: 'sam. 3 oct. · Carte •••• 7310',
          amount: 50,
          date: _d(10, 3),
        ),
      ],
      plan: _plans['omar']!,
    );
  }

  @override
  Future<AdminSanctionPlan> sanctionPlan(String id) async {
    await _wait();
    final user = _users.where((u) => u.id == id).firstOrNull;
    return _plans[id] ??
        AdminSanctionPlan(
          reason: user?.meta.contains('spam') ?? false
              ? AdminSanctionReason.spam
              : AdminSanctionReason.other,
          message: user?.meta ?? '',
          playerReason: user?.meta ?? '',
        );
  }

  @override
  Future<void> suspend(String id, {required DateTime? until}) async {
    await _wait();
    final i = _users.indexWhere((u) => u.id == id);
    if (i < 0) return;
    _users[i] = _users[i].copyWith(
      status: until == null ? AdminUserStatus.banned : AdminUserStatus.suspended,
      suspendedUntil: until,
    );
  }

  @override
  Future<List<AdminVerification>> verifications() async {
    await _wait();
    return List.unmodifiable(_verifications);
  }

  @override
  Future<void> approve(String id, String doneLine) async {
    await _wait();
    final i = _verifications.indexWhere((v) => v.id == id);
    if (i < 0) return;
    final v = _verifications.removeAt(i).approved(doneLine);
    final at = _verifications.indexWhere((x) => x.status == AdminVerificationStatus.approved);
    _verifications.insert(at < 0 ? _verifications.length : at, v);
    final u = _users.indexWhere((x) => x.verificationId == id);
    if (u >= 0) _users[u] = _users[u].copyWith(status: AdminUserStatus.active);
  }

  @override
  Future<AdminFinance> finance() async {
    await _wait();
    return AdminFinance(
      cashed: 48600,
      cashedDelta: 6,
      refunded: 1140,
      refundedDelta: -12,
      revenue: const [
        5600, 7800, 7900, 6800, 4500, 4900, 5300, 5600, 7900, 8100, 7000, 4700, 5100, 5400, //
        5800, 8200, 8300, 7200, 4900, 5300, 5700, 6050, 8400, 8900, 7600, 5200, 5600, 6100,
        6400, 8800,
      ],
      sources: const [
        ('Réservations', 39200),
        ('Tournois et événements', 4680),
        ('Abonnements', 3420),
        ('Programmes', 1300),
      ],
      today: [
        MuTransaction(
          id: 'f1',
          kind: MuTransactionKind.booking,
          sport: MuSport.football,
          label: 'Yassine B. · Arena Five',
          meta: '18h02 · Visa •••• 4242 · MU-48213',
          amount: 15,
          date: _d(10, 16, 18),
        ),
        MuTransaction(
          id: 'f2',
          kind: MuTransactionKind.booking,
          sport: MuSport.padel,
          label: 'Mariem K. · Smash Padel Club',
          meta: '17h41 · Portefeuille · ce soir 20h00',
          amount: 25,
          date: _d(10, 16, 17),
        ),
        MuTransaction(
          id: 'f3',
          kind: MuTransactionKind.subscription,
          label: 'Rami S. · Premium mensuel',
          meta: '17h20 · Carte •••• 1907',
          amount: 19,
          date: _d(10, 16, 17),
        ),
        MuTransaction(
          id: 'f4',
          kind: MuTransactionKind.booking,
          sport: MuSport.basketball,
          label: 'Hamza R. · Hoop Zone',
          meta: '16h05 · Carte refusée',
          amount: 9,
          date: _d(10, 16, 16),
          status: MuTransactionStatus.failed,
        ),
      ],
      week: [
        MuTransaction(
          id: 'f5',
          kind: MuTransactionKind.refund,
          label: 'Yassine B. · Hoop Zone',
          meta: 'Remboursement · en examen',
          amount: -9,
          date: _d(10, 13),
          status: MuTransactionStatus.pending,
        ),
        MuTransaction(
          id: 'f6',
          kind: MuTransactionKind.payout,
          label: 'Versement · Arena Five',
          meta: 'lun. 12 oct. · VR-2026-0412 · Attijari',
          amount: -1250,
          date: _d(10, 12),
        ),
      ],
    );
  }

  @override
  Future<List<AdminPayout>> payouts() async {
    await _wait();
    return List.unmodifiable(_payouts);
  }

  @override
  Future<void> validatePayouts(Set<String> ids) async {
    await _wait();
    for (var i = 0; i < _payouts.length; i++) {
      final p = _payouts[i];
      if (!ids.contains(p.id)) continue;
      _payouts[i] = AdminPayout(
        id: p.id,
        name: p.name,
        bank: p.bank,
        meta: p.meta,
        amount: p.amount,
        validated: true,
      );
    }
  }

  @override
  Future<List<AdminRefund>> refunds() async {
    await _wait();
    return List.unmodifiable(_refunds);
  }

  @override
  Future<void> refund(String id) async {
    await _wait();
    final i = _refunds.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final r = _refunds[i];
    _refunds[i] = AdminRefund(
      id: r.id,
      name: r.name,
      line: r.line,
      amount: r.amount,
      quote: r.quote,
      facts: r.facts,
      done: true,
    );
  }

  @override
  Future<List<ChurnRisk>> churn() async {
    await _wait();
    return List.unmodifiable(_churn);
  }

  @override
  Future<void> ignoreChurn(String id, {required bool ignored}) async {
    await _wait();
    final i = _churn.indexWhere((r) => r.id == id);
    if (i >= 0) _churn[i] = _churn[i].withIgnored(ignored);
  }

  @override
  Future<List<ModerationItem>> moderation() async {
    await _wait();
    return List.unmodifiable(_moderation);
  }

  @override
  Future<ModerationReview?> review(String id) async {
    await _wait();
    final item = _moderation.where((m) => m.id == id).firstOrNull;
    if (item == null || id != 'yassine') return null;
    return ModerationReview(
      item: item,
      authorId: 'yassine',
      replyTo: 'En réponse à Omar D. : « Les vissés c’est mieux, tout le monde sait ça… »',
      time: '18h14',
      before: '« T’as jamais mis les pieds sur un synthétique, ',
      flagged: 'franchement t’es nul',
      after: '. Arrête de raconter n’importe quoi. »',
      analysis: 'Moquerie entre joueurs, sans menace ni haine. L’IA peut se tromper sur le ton entre amis.',
      reportsTitle: '3 signalements · masqué au 3e',
      reportsDetail: 'Propos insultants (2) · harcèlement (1) · auteur Fiable 96 %, jamais averti',
    );
  }

  @override
  Future<void> decide(String id, ModerationDecision decision) async {
    await _wait();
    _moderation.removeWhere((m) => m.id == id);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) => FakeAdminRepository());

final adminOverviewProvider = FutureProvider<AdminOverview>(
  (ref) => ref.watch(adminRepositoryProvider).overview(),
);

final adminUsersProvider = FutureProvider<List<AdminUser>>(
  (ref) => ref.watch(adminRepositoryProvider).users(),
);

final adminUserDetailProvider = FutureProvider.family<AdminUserDetail?, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).userDetail(id),
);

final adminSanctionPlanProvider = FutureProvider.family<AdminSanctionPlan, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).sanctionPlan(id),
);

final adminVerificationsProvider = FutureProvider<List<AdminVerification>>(
  (ref) => ref.watch(adminRepositoryProvider).verifications(),
);

final adminFinanceProvider = FutureProvider<AdminFinance>(
  (ref) => ref.watch(adminRepositoryProvider).finance(),
);

final adminPayoutsProvider = FutureProvider<List<AdminPayout>>(
  (ref) => ref.watch(adminRepositoryProvider).payouts(),
);

final adminRefundsProvider = FutureProvider<List<AdminRefund>>(
  (ref) => ref.watch(adminRepositoryProvider).refunds(),
);

final adminChurnProvider = FutureProvider<List<ChurnRisk>>(
  (ref) => ref.watch(adminRepositoryProvider).churn(),
);

final adminModerationProvider = FutureProvider<List<ModerationItem>>(
  (ref) => ref.watch(adminRepositoryProvider).moderation(),
);

final adminReviewProvider = FutureProvider.family<ModerationReview?, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).review(id),
);
