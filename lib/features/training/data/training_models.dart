import 'package:flutter/foundation.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// One exercise of a session: its line in the curriculum (« Armé face au grillage, sans balle ·
/// 3 × 10 ») and, for the session player (ENT-04), the video, sets, rest and instructions.
@immutable
class Exercise {
  const Exercise({
    required this.title,
    required this.dose,
    this.video = Duration.zero,
    this.sets = 1,
    this.reps,
    this.rest = Duration.zero,
    this.setup,
    this.steps = const [],
    this.tip,
    this.counterLabel,
    this.counterNoun,
    this.counted = false,
  });

  final String title;

  /// « 3 min », « 3 × 10 ».
  final String dose;

  /// Length of the demonstration video.
  final Duration video;
  final int sets;

  /// Target per set (null: a timed exercise, no counter).
  final int? reps;
  final Duration rest;

  /// « avec un partenaire qui lance ».
  final String? setup;
  final List<String> steps;

  /// The coach's advice (« Le conseil de Karim »).
  final String? tip;

  /// « Bandejas réussies »: what the counter counts.
  final String? counterLabel;

  /// « une bandeja », for the stepper's « Ajouter une bandeja » (« une répétition » when null).
  final String? counterNoun;

  /// The session's key drill: its reps make the « Bandejas 29/36 » of ENT-05.
  final bool counted;

  int? get target => reps == null ? null : reps! * sets;
}

/// One session of a program.
@immutable
class TrainingLesson {
  const TrainingLesson({
    required this.index,
    required this.title,
    required this.minutes,
    required this.exercises,
    this.downloaded = false,
  });

  final int index;
  final String title;
  final int minutes;
  final List<Exercise> exercises;
  final bool downloaded;

  MuLesson toMu(MuSport sport) => MuLesson(
    index: index,
    title: title,
    minutes: minutes,
    drills: exercises.length,
    sport: sport,
    downloaded: downloaded,
  );
}

/// A week of the curriculum: « Bandeja croisée » · « Viser la grille · Croisée · Sous pression ».
@immutable
class TrainingWeek {
  const TrainingWeek({
    required this.index,
    required this.title,
    required this.topics,
    required this.lessons,
  });

  final int index;
  final String title;
  final String topics;
  final List<TrainingLesson> lessons;

  int get minutes => lessons.fold(0, (sum, l) => sum + l.minutes);
}

/// A student's review of a program.
@immutable
class ProgramReview {
  const ProgramReview({
    required this.author,
    required this.daysAgo,
    required this.stars,
    required this.text,
    this.finished = true,
  });

  final String author;
  final int daysAgo;
  final int stars;
  final String text;
  final bool finished;
}

/// A training program with everything its page (ENT-03) shows.
@immutable
class TrainingProgram {
  const TrainingProgram({
    required this.card,
    required this.coachId,
    required this.levelMin,
    required this.levelMax,
    required this.perWeek,
    required this.minutesMin,
    required this.minutesMax,
    required this.about,
    required this.outcomes,
    required this.equipment,
    required this.weeks,
    required this.ratingCounts,
    this.preview = const Duration(seconds: 90),
    this.reviews = const [],
    this.forYouReason,
    this.nickname,
  });

  final MuProgram card;

  /// « Bandeja » in « ton programme Bandeja ».
  final String? nickname;

  /// [nickname], or the title.
  String get shortTitle => nickname ?? card.title;
  final String coachId;
  final double levelMin;
  final double levelMax;
  final int perWeek;
  final int minutesMin;
  final int minutesMax;
  final Duration preview;
  final String about;
  final List<String> outcomes;

  /// « ta raquette, 10 balles et un court. Seul ou à deux. »
  final String equipment;
  final List<TrainingWeek> weeks;

  /// Reviews by stars, 5 down to 1.
  final List<int> ratingCounts;
  final List<ProgramReview> reviews;

  /// Why the AI suggests it (ENT-02 « Pour toi »).
  final String? forYouReason;

  String get id => card.id;
  String get title => card.title;
  MuSport get sport => card.sport;

  List<TrainingLesson> get lessons => [for (final w in weeks) ...w.lessons];

  TrainingLesson lesson(int index) => lessons.firstWhere((l) => l.index == index);

  /// The week (1-based) a session belongs to.
  int weekOf(int lessonIndex) =>
      weeks.firstWhere((w) => w.lessons.any((l) => l.index == lessonIndex)).index;
}

/// « Trop facile », « Juste bien », « Trop dur » (ENT-05).
enum LessonFeeling { easy, right, hard }

/// A finished session.
@immutable
class LessonResult {
  const LessonResult({
    required this.programId,
    required this.index,
    required this.doneAt,
    required this.minutes,
    required this.drillsDone,
    required this.drillsTotal,
    this.reps,
    this.target,
    this.feeling,
    this.notes,
  });

  final String programId;
  final int index;
  final DateTime doneAt;
  final int minutes;
  final int drillsDone;
  final int drillsTotal;

  /// Successful reps of the key drill, and its target (« 29/36 »).
  final int? reps;
  final int? target;
  final LessonFeeling? feeling;
  final String? notes;

  LessonResult copyWith({LessonFeeling? feeling}) => LessonResult(
    programId: programId,
    index: index,
    doneAt: doneAt,
    minutes: minutes,
    drillsDone: drillsDone,
    drillsTotal: drillsTotal,
    reps: reps,
    target: target,
    feeling: feeling ?? this.feeling,
    notes: notes,
  );
}

/// Where the player stands: programs joined, sessions done, weekly streak.
@immutable
class TrainingProgress {
  const TrainingProgress({
    required this.enrolled,
    required this.results,
    required this.streakBefore,
    required this.weeklyGoal,
    this.planCardHidden = false,
  });

  /// Program id → date joined.
  final Map<String, DateTime> enrolled;
  final List<LessonResult> results;

  /// Weeks validated in a row before the current one.
  final int streakBefore;

  /// Sessions a week to validate it (3).
  final int weeklyGoal;

  /// « Plus tard » on the AI plan card (ENT-01).
  final bool planCardHidden;

  bool isEnrolled(String programId) => enrolled.containsKey(programId);

  Iterable<LessonResult> resultsOf(String programId) =>
      results.where((r) => r.programId == programId);

  bool isDone(String programId, int index) =>
      resultsOf(programId).any((r) => r.index == index);

  int doneCount(String programId) => resultsOf(programId).length;

  /// The first session not done yet (null once the program is finished).
  TrainingLesson? nextLesson(TrainingProgram p) =>
      p.lessons.where((l) => !isDone(p.id, l.index)).firstOrNull;

  LessonResult? result(String programId, int index) =>
      resultsOf(programId).where((r) => r.index == index).firstOrNull;

  /// Monday 00:00 of [now]'s week.
  static DateTime weekStart(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Sessions done in [now]'s week, by weekday (1 = Monday).
  Set<int> daysDone(DateTime now) {
    final start = weekStart(now);
    final end = start.add(const Duration(days: 7));
    return {
      for (final r in results)
        if (!r.doneAt.isBefore(start) && r.doneAt.isBefore(end)) r.doneAt.weekday,
    };
  }

  int doneThisWeek(DateTime now) {
    final start = weekStart(now);
    final end = start.add(const Duration(days: 7));
    return results.where((r) => !r.doneAt.isBefore(start) && r.doneAt.isBefore(end)).length;
  }

  bool weekValidated(DateTime now) => doneThisWeek(now) >= weeklyGoal;

  /// « 6 semaines de suite », 7 once this week is validated.
  int streak(DateTime now) => streakBefore + (weekValidated(now) ? 1 : 0);

  TrainingProgress copyWith({
    Map<String, DateTime>? enrolled,
    List<LessonResult>? results,
    bool? planCardHidden,
  }) => TrainingProgress(
    enrolled: enrolled ?? this.enrolled,
    results: results ?? this.results,
    streakBefore: streakBefore,
    weeklyGoal: weeklyGoal,
    planCardHidden: planCardHidden ?? this.planCardHidden,
  );
}
