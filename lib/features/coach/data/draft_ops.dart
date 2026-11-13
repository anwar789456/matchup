import '../../../l10n/l10n.dart';
import 'coach_models.dart';

/// The builder's edits on a draft (COA-06, COA-07): pure functions the controller applies.
abstract final class DraftOps {
  static int _seq = 0;

  /// A new id, unique on this phone and between phones (time + counter).
  static String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  /// Moves the item at [from] to [to] (indexes as ReorderableListView.onReorderItem gives them,
  /// already adjusted for the removed item).
  static List<T> _move<T>(List<T> list, int from, int to) {
    final l = [...list];
    final item = l.removeAt(from);
    l.insert(to.clamp(0, l.length), item);
    return l;
  }

  static ProgramDraft addWeek(ProgramDraft d) => d.copyWith(
    weeks: [
      ...d.weeks,
      DraftWeek(id: newId('w'), title: l10n.coaNewWeek, sessions: const []),
    ],
  );

  /// Adds an empty session at the end of [weekId]; returns the draft and the new session's id.
  static (ProgramDraft, String) addSession(ProgramDraft d, String weekId) {
    final id = newId('s');
    final draft = d.copyWith(
      weeks: [
        for (final w in d.weeks)
          w.id == weekId
              ? w.copyWith(
                  sessions: [
                    ...w.sessions,
                    DraftSession(id: id, title: l10n.coaNewSession, exercises: const []),
                  ],
                )
              : w,
      ],
    );
    return (draft, id);
  }

  static ProgramDraft reorderWeeks(ProgramDraft d, int from, int to) =>
      d.copyWith(weeks: _move(d.weeks, from, to));

  static ProgramDraft reorderSessions(ProgramDraft d, String weekId, int from, int to) =>
      d.copyWith(
        weeks: [
          for (final w in d.weeks)
            w.id == weekId ? w.copyWith(sessions: _move(w.sessions, from, to)) : w,
        ],
      );

  static DraftSession reorderExercises(DraftSession s, int from, int to) =>
      s.copyWith(exercises: _move(s.exercises, from, to));

  static DraftSession addExercises(DraftSession s, List<LibraryExercise> picked) => s.copyWith(
    exercises: [...s.exercises, for (final e in picked) e.toDraft(newId('e'))],
  );

  /// A blank exercise (« Créer un nouvel exercice »).
  static DraftSession addBlankExercise(DraftSession s) => s.copyWith(
    exercises: [
      ...s.exercises,
      DraftExercise(id: newId('e'), name: l10n.coaNewExercise, mode: DrillMode.time, sets: 3),
    ],
  );

  static DraftSession removeExercise(DraftSession s, String id) =>
      s.copyWith(exercises: [for (final e in s.exercises) if (e.id != id) e]);

  static DraftSession editExercise(
    DraftSession s,
    String id,
    DraftExercise Function(DraftExercise e) change,
  ) => s.copyWith(exercises: [for (final e in s.exercises) e.id == id ? change(e) : e]);

  static ProgramDraft removeSession(ProgramDraft d, String sessionId) => d.copyWith(
    weeks: [
      for (final w in d.weeks)
        w.copyWith(sessions: [for (final s in w.sessions) if (s.id != sessionId) s]),
    ],
  );

  /// The week holding [sessionId] (1-based) and the session.
  static (int, DraftSession)? find(ProgramDraft d, String sessionId) {
    for (final (i, w) in d.weeks.indexed) {
      for (final s in w.sessions) {
        if (s.id == sessionId) return (i + 1, s);
      }
    }
    return null;
  }
}
