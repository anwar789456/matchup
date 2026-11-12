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

// ── AI weekly plan (ENT-06, ENT-07) ───────────────────────────────────────────────────────────

/// « Ton objectif » (2 max).
enum PlanGoal { placement, endurance, service, retour, volee, bandeja, vitesse }

/// « Matin », « Midi », « Soir ».
enum DayMoment { morning, noon, evening }

/// « Douce », « Modérée », « Intense ».
enum PlanIntensity { soft, moderate, intense }

/// What the player asks the AI for (ENT-06).
@immutable
class PlanRequest {
  const PlanRequest({
    required this.goals,
    required this.days,
    required this.moment,
    required this.minutes,
    required this.intensity,
    required this.includeProgram,
  });

  /// Placement + endurance, lun. mer. sam. soir, 20 min, modérée, with the program.
  static const story = PlanRequest(
    goals: {PlanGoal.placement, PlanGoal.endurance},
    days: {DateTime.monday, DateTime.wednesday, DateTime.saturday},
    moment: DayMoment.evening,
    minutes: 20,
    intensity: PlanIntensity.moderate,
    includeProgram: true,
  );

  static const maxGoals = 2;
  static const durations = [15, 20, 30, 45];

  final Set<PlanGoal> goals;

  /// Weekdays (1 = Monday).
  final Set<int> days;
  final DayMoment moment;
  final int minutes;
  final PlanIntensity intensity;
  final bool includeProgram;

  bool get complete => goals.isNotEmpty && days.isNotEmpty;

  PlanRequest copyWith({
    Set<PlanGoal>? goals,
    Set<int>? days,
    DayMoment? moment,
    int? minutes,
    PlanIntensity? intensity,
    bool? includeProgram,
  }) => PlanRequest(
    goals: goals ?? this.goals,
    days: days ?? this.days,
    moment: moment ?? this.moment,
    minutes: minutes ?? this.minutes,
    intensity: intensity ?? this.intensity,
    includeProgram: includeProgram ?? this.includeProgram,
  );
}

/// What a calendar entry is: a session of the program, one the AI proposes, a recovery, or
/// something already in the agenda (a match, a tournament).
enum PlanItemKind { program, ai, recovery, match, tournament }

/// One entry of the week (ENT-07): a session to accept, or a fixed event it works around.
@immutable
class PlanItem {
  const PlanItem({
    required this.kind,
    required this.start,
    required this.minutes,
    required this.title,
    this.tag,
    this.details,
    this.goal,
    this.calendarLabel,
  });

  final PlanItemKind kind;
  final DateTime start;
  final int minutes;

  /// « Séance 6 · Bandeja sous pression », « Placement au filet, sans sauter ».
  final String title;

  /// « Placement · légère », « Récupération · 10 min » (sessions only).
  final String? tag;

  /// « 20 min · 3 exercices · avancée à 18h30 car tu joues à Arena Five à 21h00 ».
  final String? details;
  final PlanGoal? goal;

  /// Under the time in the week's calendar: « Bandeja » for the program's session.
  final String? calendarLabel;

  bool get isSession =>
      kind == PlanItemKind.program || kind == PlanItemKind.ai || kind == PlanItemKind.recovery;
}

/// A week proposed by the AI: shown, editable, applied only on « Accepter le plan ».
@immutable
class TrainingPlan {
  const TrainingPlan({
    required this.request,
    required this.weekStart,
    required this.generatedAt,
    required this.items,
    required this.reason,
  });

  final PlanRequest request;

  /// Monday of the planned week.
  final DateTime weekStart;
  final DateTime generatedAt;
  final List<PlanItem> items;

  /// « Recommandé car … » (the end of the sentence).
  final String reason;

  List<PlanItem> get sessions => [for (final i in items) if (i.isSession) i];
}

// ── AI video analysis (ENT-08, ENT-09) ─────────────────────────────────────────────────────────

/// « Quel geste ? ».
enum VideoMove { bandeja, vibora, service, volee, smash }

/// What a tip points to: an exercise of the program, or the next session.
enum TipLinkKind { exercise, nextSession }

/// One of « 3 conseils, par priorité »: the moment in the video and what to change.
@immutable
class AnalysisTip {
  const AnalysisTip({
    required this.priority,
    required this.at,
    required this.title,
    required this.text,
    required this.link,
    required this.linkKind,
    this.programId,
  });

  final int priority;

  /// The moment in the video (« 0:21 »).
  final Duration at;
  final String title;
  final String text;

  /// « Séance 2 · Le contact devant l’épaule », « Armé face au grillage · 3 × 10 ».
  final String link;
  final TipLinkKind linkKind;

  /// The program the link opens (ENT-03).
  final String? programId;
}

/// What the AI found in the player's video.
@immutable
class VideoAnalysis {
  const VideoAnalysis({
    required this.id,
    required this.move,
    required this.fileName,
    required this.sizeBytes,
    required this.duration,
    required this.filmedAt,
    required this.venue,
    required this.analysedAt,
    required this.summary,
    required this.tips,
    required this.confidenceNote,
    this.sharedWithCoach = false,
  });

  /// A UUID made on the phone (synced: unique across the user's phones).
  final String id;
  final VideoMove move;
  final String fileName;
  final int sizeBytes;
  final Duration duration;
  final DateTime filmedAt;
  final String venue;
  final DateTime analysedAt;

  /// « Ce que l’IA a vu »: paragraphs split by a blank line.
  final String summary;
  final List<AnalysisTip> tips;

  /// « Confiance moyenne : la vidéo est filmée de trois quarts… ».
  final String confidenceNote;
  final bool sharedWithCoach;

  VideoAnalysis copyWith({String? summary, bool? sharedWithCoach}) => VideoAnalysis(
    id: id,
    move: move,
    fileName: fileName,
    sizeBytes: sizeBytes,
    duration: duration,
    filmedAt: filmedAt,
    venue: venue,
    analysedAt: analysedAt,
    summary: summary ?? this.summary,
    tips: tips,
    confidenceNote: confidenceNote,
    sharedWithCoach: sharedWithCoach ?? this.sharedWithCoach,
  );
}
