import 'package:flutter/foundation.dart';

import '../../../theme/theme.dart';
import '../../common/data/draft_file.dart';

/// Everything the coach wizard collects (COA-01, COA-02), saved after every change.
@immutable
class CoachDraft {
  const CoachDraft({
    this.name = '',
    this.email = '',
    this.photo,
    this.city = 'Lac 2, Tunis',
    this.bio = '',
    this.specialties = const [],
    this.sports = const [],
    this.levels = const [],
    this.diploma,
    this.diplomaSentAt,
    this.reached = 0,
    this.savedAt,
  });

  /// From the account.
  final String name;
  final String email;
  final DraftFile? photo;
  final String city;
  final String bio;
  final List<String> specialties;
  final List<MuSport> sports;
  final List<String> levels;
  final DraftFile? diploma;
  final DateTime? diplomaSentAt;

  /// Furthest step reached, 0-based.
  final int reached;
  final DateTime? savedAt;

  /// « Lac 2 » from « Lac 2, Tunis ».
  String get district => city.split(',').first.trim();

  CoachDraft copyWith({
    String? name,
    String? email,
    DraftFile? photo,
    bool clearPhoto = false,
    String? city,
    String? bio,
    List<String>? specialties,
    List<MuSport>? sports,
    List<String>? levels,
    DraftFile? diploma,
    DateTime? diplomaSentAt,
    bool clearDiploma = false,
    int? reached,
    DateTime? savedAt,
  }) => CoachDraft(
    name: name ?? this.name,
    email: email ?? this.email,
    photo: clearPhoto ? null : photo ?? this.photo,
    city: city ?? this.city,
    bio: bio ?? this.bio,
    specialties: specialties ?? this.specialties,
    sports: sports ?? this.sports,
    levels: levels ?? this.levels,
    diploma: clearDiploma ? null : diploma ?? this.diploma,
    diplomaSentAt: clearDiploma ? null : diplomaSentAt ?? this.diplomaSentAt,
    reached: reached ?? this.reached,
    savedAt: savedAt ?? this.savedAt,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'photo': photo?.toJson(),
    'city': city,
    'bio': bio,
    'specialties': specialties,
    'sports': [for (final s in sports) s.name],
    'levels': levels,
    'diploma': diploma?.toJson(),
    'diplomaSentAt': diplomaSentAt?.toIso8601String(),
    'reached': reached,
    'savedAt': savedAt?.toIso8601String(),
  };

  factory CoachDraft.fromJson(Map<String, Object?> j) {
    List<String> strings(String k) => [for (final e in j[k]! as List<Object?>) e! as String];
    DraftFile? file(String k) =>
        j[k] == null ? null : DraftFile.fromJson(j[k]! as Map<String, Object?>);
    DateTime? date(String k) => j[k] == null ? null : DateTime.parse(j[k]! as String);
    return CoachDraft(
      name: j['name']! as String,
      email: j['email']! as String,
      photo: file('photo'),
      city: j['city']! as String,
      bio: j['bio']! as String,
      specialties: strings('specialties'),
      sports: [for (final s in strings('sports')) MuSport.values.byName(s)],
      levels: strings('levels'),
      diploma: file('diploma'),
      diplomaSentAt: date('diplomaSentAt'),
      reached: j['reached']! as int,
      savedAt: date('savedAt'),
    );
  }
}

/// The coach side of the backend.
abstract interface class CoachRepository {
  /// What the account already knows when the wizard starts.
  Future<CoachDraft> start();

  /// Sends the diploma to the federation check (answer within 48 h).
  Future<void> submitDiploma(DraftFile file);
}

/// Skander T., padel coach at Lac 2 — the coach of the COA screens, diploma sent this morning.
class FakeCoachRepository implements CoachRepository {
  FakeCoachRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  Future<CoachDraft> start() async {
    final today = _now();
    return CoachDraft(
      name: 'Skander T.',
      email: 'skander.t@email.tn',
      bio:
          'Coach de padel diplômé d’État, j’entraîne à Smash Padel Club (Lac 2) depuis 6 ans. '
          'J’aide les joueurs débutants et intermédiaires à fiabiliser leur service et à mieux '
          'se placer. Séances en français, en arabe ou en anglais.',
      specialties: const ['Padel', 'Préparation physique', 'Service', 'Débutants'],
      sports: const [MuSport.padel],
      levels: const ['Débutant', 'Intermédiaire', 'Avancé'],
      diploma: const DraftFile(
        id: 'dip',
        name: 'Diplôme d’État padel – Skander T.pdf',
        sizeBytes: 1887437,
      ),
      diplomaSentAt: DateTime(today.year, today.month, today.day, 10, 12),
    );
  }

  @override
  Future<void> submitDiploma(DraftFile file) async {}
}

/// The lists of the coach wizard.
abstract final class CoachCatalog {
  static const cities = [
    'Lac 2, Tunis',
    'La Marsa',
    'Ennasr, Ariana',
    'Menzah 6',
    'Sousse',
    'Sfax',
  ];

  static const specialties = [
    'Padel',
    'Préparation physique',
    'Service',
    'Débutants',
    'Jeu au filet',
    'Tactique',
    'Juniors',
    'Compétition',
  ];

  static const maxSpecialties = 6;

  static const sports = [
    (MuSport.padel, 'Padel'),
    (MuSport.football, 'Football'),
    (MuSport.basketball, 'Basketball'),
  ];

  static String sportName(MuSport s) =>
      sports.where((e) => e.$1 == s).map((e) => e.$2).firstOrNull ?? s.label;

  static const levels = ['Débutant', 'Intermédiaire', 'Avancé', 'Expert'];

  static const bioMax = 400;

  /// The federation answers within this delay.
  static const review = Duration(hours: 48);
}
