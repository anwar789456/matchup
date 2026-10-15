import 'package:flutter/foundation.dart';

import '../../../theme/theme.dart';
import 'level_estimator.dart';

/// Everything the player onboarding collects (PLY-01 to PLY-10), saved after every change so the
/// player resumes where they left.
@immutable
class PlayerOnboardingState {
  const PlayerOnboardingState({
    this.sports = const [],
    this.answers = const {},
    this.estimates = const {},
    this.levels = const {},
    this.positions = const {},
    this.availability = const {},
    this.locationGranted,
    this.area,
    this.zones = const [],
    this.radiusKm = 10,
    this.notificationsGranted,
    this.pseudo,
    this.fullName,
    this.lastRoute,
    this.completed = false,
    this.tourSeen = false,
  });

  /// In the order the player picked them; the questionnaire follows this order.
  final List<MuSport> sports;

  /// Questionnaire answers per sport: question id → option id (or « 1 »–« 5 »).
  final Map<MuSport, Map<String, String>> answers;

  /// The AI estimate per sport.
  final Map<MuSport, LevelEstimate> estimates;

  /// The level the player confirmed per sport (the estimate, or their adjustment).
  final Map<MuSport, double> levels;

  /// Preferred position per sport (« milieu », « gauche »…).
  final Map<MuSport, String> positions;

  /// Free slots, « lun-soir », « sam-aprem »…
  final Set<String> availability;

  /// Null until asked; false when refused (PLY-08).
  final bool? locationGranted;

  /// District found from the position (« La Marsa »).
  final String? area;
  final List<String> zones;
  final int radiusKm;
  final bool? notificationsGranted;
  final String? pseudo;
  final String? fullName;

  /// Where to resume.
  final String? lastRoute;
  final bool completed;
  final bool tourSeen;

  /// The first selected sport without an estimate yet.
  MuSport? get nextSportToEstimate {
    for (final s in sports) {
      if (!estimates.containsKey(s)) return s;
    }
    return null;
  }

  PlayerOnboardingState copyWith({
    List<MuSport>? sports,
    Map<MuSport, Map<String, String>>? answers,
    Map<MuSport, LevelEstimate>? estimates,
    Map<MuSport, double>? levels,
    Map<MuSport, String>? positions,
    Set<String>? availability,
    bool? locationGranted,
    String? area,
    List<String>? zones,
    int? radiusKm,
    bool? notificationsGranted,
    String? pseudo,
    String? fullName,
    String? lastRoute,
    bool? completed,
    bool? tourSeen,
  }) =>
      PlayerOnboardingState(
        sports: sports ?? this.sports,
        answers: answers ?? this.answers,
        estimates: estimates ?? this.estimates,
        levels: levels ?? this.levels,
        positions: positions ?? this.positions,
        availability: availability ?? this.availability,
        locationGranted: locationGranted ?? this.locationGranted,
        area: area ?? this.area,
        zones: zones ?? this.zones,
        radiusKm: radiusKm ?? this.radiusKm,
        notificationsGranted: notificationsGranted ?? this.notificationsGranted,
        pseudo: pseudo ?? this.pseudo,
        fullName: fullName ?? this.fullName,
        lastRoute: lastRoute ?? this.lastRoute,
        completed: completed ?? this.completed,
        tourSeen: tourSeen ?? this.tourSeen,
      );

  Map<String, Object?> toJson() => {
        'sports': [for (final s in sports) s.name],
        'answers': {
          for (final e in answers.entries) e.key.name: e.value,
        },
        'estimates': {
          for (final e in estimates.entries)
            e.key.name: {
              'level': e.value.level,
              'confidence': e.value.confidence.name,
              'reasons': [
                for (final r in e.value.reasons) {'q': r.questionId, 'text': r.text},
              ],
            },
        },
        'levels': {for (final e in levels.entries) e.key.name: e.value},
        'positions': {for (final e in positions.entries) e.key.name: e.value},
        'availability': availability.toList(),
        'locationGranted': locationGranted,
        'area': area,
        'zones': zones,
        'radiusKm': radiusKm,
        'notificationsGranted': notificationsGranted,
        'pseudo': pseudo,
        'fullName': fullName,
        'lastRoute': lastRoute,
        'completed': completed,
        'tourSeen': tourSeen,
      };

  static MuSport? _sport(Object? name) =>
      MuSport.values.where((s) => s.name == name).firstOrNull;

  static Map<MuSport, V> _bySport<V>(Object? json, V Function(Object? v) read) {
    final out = <MuSport, V>{};
    if (json is Map) {
      for (final e in json.entries) {
        final s = _sport(e.key);
        if (s != null) out[s] = read(e.value);
      }
    }
    return out;
  }

  /// Tolerates missing or unknown fields (older saves): they fall back to the defaults.
  factory PlayerOnboardingState.fromJson(Map<String, Object?> json) {
    List<String> strings(Object? v) => v is List ? v.whereType<String>().toList() : const [];
    return PlayerOnboardingState(
      sports: [for (final n in strings(json['sports'])) ?_sport(n)],
      answers: _bySport(json['answers'], (v) => v is Map ? v.cast<String, String>() : {}),
      estimates: _bySport(json['estimates'], (v) {
        final m = v is Map ? v : const {};
        return LevelEstimate(
          level: (m['level'] as num?)?.toDouble() ?? 1,
          confidence: EstimateConfidence.values
                  .where((c) => c.name == m['confidence'])
                  .firstOrNull ??
              EstimateConfidence.low,
          reasons: [
            for (final r in (m['reasons'] as List? ?? const []))
              if (r is Map) EstimateReason('${r['q']}', '${r['text']}'),
          ],
        );
      }),
      levels: _bySport(json['levels'], (v) => (v as num?)?.toDouble() ?? 1),
      positions: _bySport(json['positions'], (v) => '$v'),
      availability: strings(json['availability']).toSet(),
      locationGranted: json['locationGranted'] as bool?,
      area: json['area'] as String?,
      zones: strings(json['zones']),
      radiusKm: (json['radiusKm'] as num?)?.toInt() ?? 10,
      notificationsGranted: json['notificationsGranted'] as bool?,
      pseudo: json['pseudo'] as String?,
      fullName: json['fullName'] as String?,
      lastRoute: json['lastRoute'] as String?,
      completed: json['completed'] as bool? ?? false,
      tourSeen: json['tourSeen'] as bool? ?? false,
    );
  }
}
