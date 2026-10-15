import 'package:flutter/foundation.dart';

import '../../../theme/theme.dart';
import '../../common/data/draft_file.dart';

/// A tournament the organiser ran before MatchUp (ORG-01, up to 3).
@immutable
class PastEvent {
  const PastEvent({
    required this.id,
    required this.name,
    this.sport = MuSport.padel,
    this.date = '',
    this.teams,
    this.venue = '',
  });

  final String id;
  final String name;
  final MuSport sport;

  /// « mars 2026 ».
  final String date;
  final int? teams;
  final String venue;

  /// « mars 2026 · 16 équipes · Smash Padel Club ».
  String get summary => [
        if (date.isNotEmpty) date,
        if (teams != null) '$teams équipe${teams! > 1 ? 's' : ''}',
        if (venue.isNotEmpty) venue,
      ].join(' · ');

  PastEvent copyWith({String? name, MuSport? sport, String? date, int? teams, String? venue}) =>
      PastEvent(
        id: id,
        name: name ?? this.name,
        sport: sport ?? this.sport,
        date: date ?? this.date,
        teams: teams ?? this.teams,
        venue: venue ?? this.venue,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'sport': sport.name,
        'date': date,
        'teams': teams,
        'venue': venue,
      };

  factory PastEvent.fromJson(Map<String, Object?> j) => PastEvent(
        id: j['id']! as String,
        name: j['name']! as String,
        sport: MuSport.values.byName(j['sport']! as String),
        date: j['date']! as String,
        teams: j['teams'] as int?,
        venue: j['venue']! as String,
      );
}

/// What the organiser wizard collects (ORG-01), saved after every change.
@immutable
class OrganizerDraft {
  const OrganizerDraft({
    this.logo,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.manager = '',
    this.managerRole = 'Organisateur',
    this.events = const [],
    this.reached = 0,
    this.savedAt,
  });

  final DraftFile? logo;
  final String name;
  final String email;

  /// 8 digits, without +216.
  final String phone;

  /// The account holder (« Ines M. ») and how the bar names their role (« Organisatrice »).
  final String manager;
  final String managerRole;
  final List<PastEvent> events;
  final int reached;
  final DateTime? savedAt;

  OrganizerDraft copyWith({
    DraftFile? logo,
    bool clearLogo = false,
    String? name,
    String? email,
    String? phone,
    List<PastEvent>? events,
    int? reached,
    DateTime? savedAt,
  }) =>
      OrganizerDraft(
        logo: clearLogo ? null : logo ?? this.logo,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        manager: manager,
        managerRole: managerRole,
        events: events ?? this.events,
        reached: reached ?? this.reached,
        savedAt: savedAt ?? this.savedAt,
      );

  Map<String, Object?> toJson() => {
        'logo': logo?.toJson(),
        'name': name,
        'email': email,
        'phone': phone,
        'manager': manager,
        'managerRole': managerRole,
        'events': [for (final e in events) e.toJson()],
        'reached': reached,
        'savedAt': savedAt?.toIso8601String(),
      };

  factory OrganizerDraft.fromJson(Map<String, Object?> j) => OrganizerDraft(
        logo: j['logo'] == null ? null : DraftFile.fromJson(j['logo']! as Map<String, Object?>),
        name: j['name']! as String,
        email: j['email']! as String,
        phone: j['phone']! as String,
        manager: j['manager']! as String,
        managerRole: j['managerRole']! as String,
        events: [
          for (final e in j['events']! as List<Object?>)
            PastEvent.fromJson(e! as Map<String, Object?>),
        ],
        reached: j['reached']! as int,
        savedAt: j['savedAt'] == null ? null : DateTime.parse(j['savedAt']! as String),
      );
}

/// The organiser side of the backend.
abstract interface class OrganizerRepository {
  /// What the account already knows when the wizard starts.
  Future<OrganizerDraft> start();
}

/// Tunis Padel Series, run by Ines M. — the organiser of the ORG screens.
class FakeOrganizerRepository implements OrganizerRepository {
  const FakeOrganizerRepository();

  @override
  Future<OrganizerDraft> start() async => const OrganizerDraft(
        name: 'Tunis Padel Series',
        email: 'contact@tunispadelseries.tn',
        phone: '22456789',
        manager: 'Ines M.',
        managerRole: 'Organisatrice',
        events: [
          PastEvent(
            id: 'e1',
            name: 'Padel Cup Lac 2',
            date: 'mars 2026',
            teams: 16,
            venue: 'Smash Padel Club',
          ),
        ],
      );
}

/// ORG-01: up to 3 past events.
const maxPastEvents = 3;
