import 'package:flutter/foundation.dart';

import '../../../theme/theme.dart';

/// Where a student stands in the coach's eyes (COA-09 filters).
enum StudentState { active, late, finished, idle }

/// A student of the coach: who, which program, how far, what happened last.
@immutable
class CoachStudent {
  const CoachStudent({
    required this.id,
    required this.name,
    required this.level,
    required this.programId,
    required this.programTitle,
    required this.done,
    required this.total,
    required this.lastActivity,
    required this.state,
    this.handle,
    this.zone = 'La Marsa',
    this.side,
    this.videoAt,
    this.activeThisWeek = false,
  });

  final String id;

  /// « Yassine B. ».
  final String name;
  final double level;
  final String programId;
  final String programTitle;
  final int done;
  final int total;

  /// The last thing they did (a session, a video).
  final DateTime lastActivity;
  final StudentState state;
  final String? handle;
  final String zone;

  /// « côté gauche ».
  final String? side;

  /// When they sent a video waiting for feedback.
  final DateTime? videoAt;
  final bool activeThisWeek;

  int get percent => total == 0 ? 0 : (done / total * 100).round();
  bool get late => state == StudentState.late;
  bool get finished => state == StudentState.finished;

  /// The session they do next (1-based).
  int get current => done >= total ? total : done + 1;
}

/// A published program as the coach follows it (COA-05).
@immutable
class CoachProgramStats {
  const CoachProgramStats({
    required this.programId,
    required this.activeStudents,
    required this.averageProgress,
    required this.monthNet,
  });

  final String programId;
  final int activeStudents;

  /// Average progress of its students, in %.
  final int averageProgress;

  /// Net earned this month, in DT.
  final num monthNet;
}

/// How an exercise is measured: a duration or repetitions.
enum DrillMode { time, reps }

/// Where an uploaded video stands.
enum VideoState { none, uploading, processing, ready }

/// An exercise of a draft session (COA-06, COA-07).
@immutable
class DraftExercise {
  const DraftExercise({
    required this.id,
    required this.name,
    required this.mode,
    required this.sets,
    this.seconds = 45,
    this.reps = 12,
    this.video = VideoState.none,
    this.videoLength,
    this.uploadProgress = 0,
    this.fileName,
    this.fileBytes,
  });

  final String id;
  final String name;
  final DrillMode mode;
  final int sets;
  final int seconds;
  final int reps;
  final VideoState video;
  final Duration? videoLength;

  /// 0–1 while uploading.
  final double uploadProgress;
  final String? fileName;
  final int? fileBytes;

  /// Minutes the exercise takes (rough: time × sets, or 4 s a rep, plus rest).
  int get minutes {
    final work = mode == DrillMode.time ? seconds * sets : reps * sets * 4;
    return ((work + 30 * (sets - 1)) / 60).ceil().clamp(1, 60);
  }

  DraftExercise copyWith({
    String? name,
    DrillMode? mode,
    int? sets,
    int? seconds,
    int? reps,
    VideoState? video,
    Duration? videoLength,
    double? uploadProgress,
    String? fileName,
    int? fileBytes,
  }) => DraftExercise(
    id: id,
    name: name ?? this.name,
    mode: mode ?? this.mode,
    sets: sets ?? this.sets,
    seconds: seconds ?? this.seconds,
    reps: reps ?? this.reps,
    video: video ?? this.video,
    videoLength: videoLength ?? this.videoLength,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    fileName: fileName ?? this.fileName,
    fileBytes: fileBytes ?? this.fileBytes,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'mode': mode.name,
    'sets': sets,
    'seconds': seconds,
    'reps': reps,
    'video': video.name,
    'videoLength': videoLength?.inSeconds,
    'fileName': fileName,
    'fileBytes': fileBytes,
  };

  static DraftExercise fromJson(Map<String, Object?> j) => DraftExercise(
    id: j['id']! as String,
    name: j['name']! as String,
    mode: DrillMode.values.byName(j['mode']! as String),
    sets: j['sets']! as int,
    seconds: j['seconds']! as int,
    reps: j['reps']! as int,
    // An upload cut by closing the app is processed on the server: it comes back processing.
    video: switch (VideoState.values.byName(j['video']! as String)) {
      VideoState.uploading => VideoState.processing,
      final v => v,
    },
    videoLength: j['videoLength'] == null ? null : Duration(seconds: j['videoLength']! as int),
    fileName: j['fileName'] as String?,
    fileBytes: j['fileBytes'] as int?,
  );
}

/// A session of a draft program.
@immutable
class DraftSession {
  const DraftSession({
    required this.id,
    required this.title,
    required this.exercises,
    this.video = VideoState.none,
    this.videoName,
    this.videoBytes,
    this.videoLength,
    this.instruction = '',
  });

  final String id;
  final String title;
  final List<DraftExercise> exercises;

  /// The session's main video (COA-07 « Vidéo de la séance »).
  final VideoState video;
  final String? videoName;
  final int? videoBytes;
  final Duration? videoLength;

  /// « Consigne pour tes élèves ».
  final String instruction;

  int get minutes => exercises.fold(0, (a, e) => a + e.minutes);

  bool get processing =>
      video == VideoState.processing ||
      video == VideoState.uploading ||
      exercises.any((e) => e.video == VideoState.uploading || e.video == VideoState.processing);

  DraftSession copyWith({
    String? title,
    List<DraftExercise>? exercises,
    VideoState? video,
    String? videoName,
    int? videoBytes,
    Duration? videoLength,
    String? instruction,
  }) => DraftSession(
    id: id,
    title: title ?? this.title,
    exercises: exercises ?? this.exercises,
    video: video ?? this.video,
    videoName: videoName ?? this.videoName,
    videoBytes: videoBytes ?? this.videoBytes,
    videoLength: videoLength ?? this.videoLength,
    instruction: instruction ?? this.instruction,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'exercises': [for (final e in exercises) e.toJson()],
    'video': video.name,
    'videoName': videoName,
    'videoBytes': videoBytes,
    'videoLength': videoLength?.inSeconds,
    'instruction': instruction,
  };

  static DraftSession fromJson(Map<String, Object?> j) => DraftSession(
    id: j['id']! as String,
    title: j['title']! as String,
    exercises: [
      for (final e in j['exercises']! as List) DraftExercise.fromJson((e as Map).cast()),
    ],
    video: switch (VideoState.values.byName(j['video']! as String)) {
      VideoState.uploading => VideoState.processing,
      final v => v,
    },
    videoName: j['videoName'] as String?,
    videoBytes: j['videoBytes'] as int?,
    videoLength: j['videoLength'] == null ? null : Duration(seconds: j['videoLength']! as int),
    instruction: (j['instruction'] as String?) ?? '',
  );
}

/// A week of a draft program.
@immutable
class DraftWeek {
  const DraftWeek({required this.id, required this.title, required this.sessions});

  final String id;
  final String title;
  final List<DraftSession> sessions;

  int get exercises => sessions.fold(0, (a, s) => a + s.exercises.length);
  int get minutes => sessions.fold(0, (a, s) => a + s.minutes);

  DraftWeek copyWith({String? title, List<DraftSession>? sessions}) =>
      DraftWeek(id: id, title: title ?? this.title, sessions: sessions ?? this.sessions);

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'sessions': [for (final s in sessions) s.toJson()],
  };

  static DraftWeek fromJson(Map<String, Object?> j) => DraftWeek(
    id: j['id']! as String,
    title: j['title']! as String,
    sessions: [for (final s in j['sessions']! as List) DraftSession.fromJson((s as Map).cast())],
  );
}

/// « Dès que tout est prêt » or a date.
enum PublishWhen { ready, date }

enum DraftStatus { draft, scheduled }

/// A program the coach is writing (COA-06 → COA-08).
@immutable
class ProgramDraft {
  const ProgramDraft({
    required this.id,
    required this.title,
    required this.sport,
    required this.levelMin,
    required this.levelMax,
    required this.weeks,
    required this.updatedAt,
    this.targetSessions = 12,
    this.sell = true,
    this.price = 35,
    this.premium = true,
    this.when = PublishWhen.ready,
    this.publishDate,
    this.status = DraftStatus.draft,
    this.priceSet = false,
  });

  final String id;
  final String title;
  final MuSport sport;
  final double levelMin;
  final double levelMax;
  final List<DraftWeek> weeks;
  final DateTime updatedAt;

  /// Sessions planned: 3 a week.
  final int targetSessions;
  final bool sell;
  final num price;
  final bool premium;
  final PublishWhen when;
  final DateTime? publishDate;
  final DraftStatus status;

  /// The coach went through « Prix et publication » and saved.
  final bool priceSet;

  List<DraftSession> get sessions => [for (final w in weeks) ...w.sessions];
  int get sessionCount => sessions.length;
  int get exerciseCount => sessions.fold(0, (a, s) => a + s.exercises.length);
  int get missingSessions => (targetSessions - sessionCount).clamp(0, 99);
  int get processingVideos => sessions.where((s) => s.processing).length;
  bool get readyToPublish => missingSessions == 0 && (sell || premium);

  /// The 1-based number of [session] in the whole program.
  int numberOf(DraftSession session) => sessions.indexWhere((s) => s.id == session.id) + 1;

  ProgramDraft copyWith({
    String? title,
    List<DraftWeek>? weeks,
    DateTime? updatedAt,
    bool? sell,
    num? price,
    bool? premium,
    PublishWhen? when,
    DraftStatus? status,
    bool? priceSet,
  }) => ProgramDraft(
    id: id,
    title: title ?? this.title,
    sport: sport,
    levelMin: levelMin,
    levelMax: levelMax,
    weeks: weeks ?? this.weeks,
    updatedAt: updatedAt ?? this.updatedAt,
    targetSessions: targetSessions,
    sell: sell ?? this.sell,
    price: price ?? this.price,
    premium: premium ?? this.premium,
    when: when ?? this.when,
    publishDate: publishDate,
    status: status ?? this.status,
    priceSet: priceSet ?? this.priceSet,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'sport': sport.name,
    'levelMin': levelMin,
    'levelMax': levelMax,
    'weeks': [for (final w in weeks) w.toJson()],
    'updatedAt': updatedAt.toIso8601String(),
    'targetSessions': targetSessions,
    'sell': sell,
    'price': price,
    'premium': premium,
    'when': when.name,
    'publishDate': publishDate?.toIso8601String(),
    'status': status.name,
    'priceSet': priceSet,
  };

  static ProgramDraft fromJson(Map<String, Object?> j) => ProgramDraft(
    id: j['id']! as String,
    title: j['title']! as String,
    sport: MuSport.values.byName(j['sport']! as String),
    levelMin: (j['levelMin']! as num).toDouble(),
    levelMax: (j['levelMax']! as num).toDouble(),
    weeks: [for (final w in j['weeks']! as List) DraftWeek.fromJson((w as Map).cast())],
    updatedAt: DateTime.parse(j['updatedAt']! as String),
    targetSessions: j['targetSessions']! as int,
    sell: j['sell']! as bool,
    price: j['price']! as num,
    premium: j['premium']! as bool,
    when: PublishWhen.values.byName(j['when']! as String),
    publishDate: j['publishDate'] == null ? null : DateTime.parse(j['publishDate']! as String),
    status: DraftStatus.values.byName(j['status']! as String),
    priceSet: j['priceSet'] == true,
  );
}

/// An exercise of the coach's library (« Ajouter un exercice »).
@immutable
class LibraryExercise {
  const LibraryExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.mode,
    required this.sets,
    this.seconds = 45,
    this.reps = 12,
    this.videoLength,
  });

  final String id;
  final String name;

  /// « Jeu au filet », « Déplacements », « Physique ».
  final String category;
  final DrillMode mode;
  final int sets;
  final int seconds;
  final int reps;
  final Duration? videoLength;

  DraftExercise toDraft(String newId) => DraftExercise(
    id: newId,
    name: name,
    mode: mode,
    sets: sets,
    seconds: seconds,
    reps: reps,
    video: videoLength == null ? VideoState.none : VideoState.ready,
    videoLength: videoLength,
  );
}

/// What waits on the dashboard (« À traiter »).
enum TodoKind { video, dropped, review }

@immutable
class CoachTodo {
  const CoachTodo({
    required this.id,
    required this.kind,
    required this.studentId,
    required this.who,
    required this.detail,
    this.level,
    this.stars,
  });

  final String id;
  final TodoKind kind;
  final String studentId;
  final String who;

  /// « Bandeja · 0:42 · il y a 55 min », « Service et retour · 1/10 · 12 jours ».
  final String detail;
  final double? level;
  final int? stars;
}

/// A timestamped comment on a student's video (COA-11).
@immutable
class VideoComment {
  const VideoComment({required this.at, required this.text, this.fromAi = false});

  final Duration at;
  final String text;
  final bool fromAi;

  Map<String, Object?> toJson() => {'at': at.inSeconds, 'text': text, 'ai': fromAi};

  static VideoComment fromJson(Map<String, Object?> j) => VideoComment(
    at: Duration(seconds: j['at']! as int),
    text: j['text']! as String,
    fromAi: j['ai'] == true,
  );
}

/// The coach's answer to a student's video.
@immutable
class CoachFeedback {
  const CoachFeedback({
    required this.studentId,
    required this.comments,
    required this.message,
    required this.askNewVideo,
    this.sentAt,
  });

  final String studentId;
  final List<VideoComment> comments;
  final String message;
  final bool askNewVideo;
  final DateTime? sentAt;
}

/// A student's review of one of the coach's programs.
@immutable
class CoachReview {
  const CoachReview({
    required this.author,
    required this.level,
    required this.stars,
    required this.program,
    required this.date,
    required this.text,
  });

  final String author;
  final double level;
  final int stars;
  final String program;
  final DateTime date;
  final String text;
}

/// A note in a student's file (COA-10 « Notes et retours »).
@immutable
class StudentNote {
  const StudentNote({
    required this.fromCoach,
    required this.session,
    required this.date,
    required this.text,
  });

  final bool fromCoach;
  final int session;
  final DateTime date;
  final String text;
}
