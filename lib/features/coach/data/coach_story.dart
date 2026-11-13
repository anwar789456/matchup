import '../../../theme/theme.dart';
import '../../common/data/story_data.dart';
import 'coach_models.dart';

/// The coach space of the story (COA-04…12): Karim J., padel coach at Lac 2, on ven. 16 oct.
/// 18h00. The six students drawn on COA-09 are exact; the 32 others are generated so the counts
/// of the designs hold (38 students · 3 late · 24 active this week · 6 finished).
abstract final class CoachStory {
  static const coachName = 'Karim J.';
  static const firstName = 'Karim';
  static const zone = 'Lac 2';
  static const notifications = 3;

  // ── KPIs (COA-04) ─────────────────────────────────────────────────────────────────────────
  static const studentsDelta = 4;
  static const activeEnrollments = 52;
  static const enrollmentsDelta = 6;
  static const revenueDelta = 18.0;
  static const commission = 0.10;
  static const rating = 4.9;
  static const reviewCount = 64;

  // ── Earnings (COA-12) ─────────────────────────────────────────────────────────────────────
  /// Net per month, janv. → oct. 2026 (oct. until the 16th).
  static const monthlyNet = <num>[180, 260, 340, 450, 620, 980, 1240, 1510, 1980, 2340];

  /// Net this month by source: Bandeja, Service et retour, Premium share.
  static const sources = <(String, num)>[
    ('Bandeja en 4 semaines', 1620),
    ('Service et retour', 540),
    ('Part Premium', 180),
  ];
  static const nextPayout = 612;
  static final nextPayoutDate = Story.at(19, 0);
  static const lastPayout = 548;
  static final lastPayoutDate = Story.at(12, 0);
  static const lastPayoutRef = 'VR-2026-0418';
  static const bank = 'BIAT •••• 0457';
  static const coachPlan = 39;
  static final coachPlanRenewal = DateTime(2026, 11, 1);
  static const lastStatement = 'septembre 2026';

  /// The latest operations: (label, who · when, amount, kind).
  static final operations = <(String, String, DateTime, num, String)>[
    ('Vente · Bandeja', 'Ines M.', Story.at(16, 17, 20), 40.5, 'sale'),
    ('Vente · Service et retour', 'Hamza R.', Story.at(15, 21, 4), 27, 'sale'),
    ('Part Premium · Bandeja', '9 abonnés · semaine du 5 oct.', Story.at(12, 0), 45, 'premium'),
    ('Remboursement', 'Omar D. · Service et retour', Story.at(13, 0), -27, 'refund'),
    ('Vente · Bandeja', 'Salma G.', Story.at(12, 9, 12), 40.5, 'sale'),
  ];

  // ── Programs (COA-05) ─────────────────────────────────────────────────────────────────────
  static const programStats = [
    CoachProgramStats(programId: 'bandeja', activeStudents: 34, averageProgress: 46, monthNet: 1620),
    CoachProgramStats(programId: 'service-retour', activeStudents: 18, averageProgress: 61, monthNet: 540),
  ];

  // ── Students (COA-09, COA-10) ─────────────────────────────────────────────────────────────
  static final yassine = CoachStudent(
    id: 'yassine',
    name: 'Yassine B.',
    level: 3.5,
    programId: 'bandeja',
    programTitle: 'Bandeja en 4 semaines',
    done: 4,
    total: 12,
    lastActivity: Story.at(16, 17, 5),
    state: StudentState.active,
    handle: '@yassine.b',
    side: 'côté gauche',
    videoAt: Story.at(16, 17, 5),
    activeThisWeek: true,
  );

  static final _designed = <CoachStudent>[
    yassine,
    CoachStudent(
      id: 'mariem',
      name: 'Mariem K.',
      level: 4.0,
      programId: 'bandeja',
      programTitle: 'Bandeja en 4 semaines',
      done: 9,
      total: 12,
      lastActivity: Story.at(15, 19),
      state: StudentState.active,
      activeThisWeek: true,
    ),
    CoachStudent(
      id: 'lina',
      name: 'Lina F.',
      level: 3.5,
      programId: 'service-retour',
      programTitle: 'Service et retour',
      done: 1,
      total: 9,
      lastActivity: Story.at(4, 18),
      state: StudentState.late,
    ),
    CoachStudent(
      id: 'ines',
      name: 'Ines M.',
      level: 4.0,
      programId: 'bandeja',
      programTitle: 'Bandeja en 4 semaines',
      done: 3,
      total: 12,
      lastActivity: Story.at(14, 19),
      state: StudentState.active,
      activeThisWeek: true,
    ),
    CoachStudent(
      id: 'nour',
      name: 'Nour A.',
      level: 3.0,
      programId: 'bandeja',
      programTitle: 'Bandeja en 4 semaines',
      done: 7,
      total: 12,
      lastActivity: Story.at(13, 20),
      state: StudentState.active,
      activeThisWeek: true,
    ),
    CoachStudent(
      id: 'rami',
      name: 'Rami S.',
      level: 3.5,
      programId: 'service-retour',
      programTitle: 'Service et retour',
      done: 9,
      total: 9,
      lastActivity: Story.at(11, 18),
      state: StudentState.finished,
    ),
  ];

  static const _names = [
    'Ahmed T.', 'Sami K.', 'Yosra B.', 'Malek H.', 'Fares Z.', 'Amira S.', 'Khalil M.', 'Rania J.',
    'Wassim N.', 'Hiba L.', 'Bilel C.', 'Sarra D.', 'Anis G.', 'Emna F.', 'Oussama R.', 'Dorra A.',
    'Mehdi B.', 'Nada T.', 'Zied M.', 'Asma K.', 'Hamdi S.', 'Ons B.', 'Chaima R.', 'Firas L.',
    'Meriem Z.', 'Youssef D.', 'Lamia N.', 'Aymen J.', 'Rim C.', 'Taha G.', 'Ilyes H.', 'Salma G.',
  ];

  /// The 32 others: 20 active this week, 2 late, 5 finished, 5 active earlier.
  static List<CoachStudent> _generated() => [
    for (final (i, name) in _names.indexed)
      () {
        final bandeja = i % 3 != 2;
        final total = bandeja ? 12 : 9;
        final state = i < 20
            ? StudentState.active
            : i < 22
            ? StudentState.late
            : i < 27
            ? StudentState.finished
            : StudentState.idle;
        final done = switch (state) {
          StudentState.finished => total,
          StudentState.late => 1 + i % 2,
          _ => 1 + (i * 5) % (total - 1),
        };
        final last = switch (state) {
          StudentState.active => Story.at(12 + i % 4, 9 + i % 9),
          StudentState.late => Story.at(2 + i % 3, 19),
          StudentState.finished => Story.at(1 + i % 10, 20),
          StudentState.idle => Story.at(6 + i % 4, 19),
        };
        return CoachStudent(
          id: 'student-$i',
          name: name,
          level: 2.5 + (i % 4) * 0.5,
          programId: bandeja ? 'bandeja' : 'service-retour',
          programTitle: bandeja ? 'Bandeja en 4 semaines' : 'Service et retour',
          done: done,
          total: total,
          lastActivity: last,
          state: state,
          activeThisWeek: state == StudentState.active,
        );
      }(),
  ];

  static final students = [..._designed, ..._generated()];

  /// Yassine's minutes of training, the 6 weeks from lun. 7 sept.
  static const yassineMinutes = <double>[40, 55, 45, 60, 75, 46];

  /// What the AI saw in Yassine's video (COA-10), to confirm or correct.
  static const yassineAi =
      'Frappe un peu tôt (0:18), balle au centre au lieu de la grille (0:31), bon replacement '
      '(0:39). À confirmer ou corriger dans ton retour.';

  static final yassineNotes = [
    StudentNote(
      fromCoach: false,
      session: 4,
      date: Story.at(15, 0),
      text: 'J’arrive à la placer, mais pas encore croisée. Elle part souvent au centre.',
    ),
    StudentNote(
      fromCoach: true,
      session: 2,
      date: Story.at(12, 0),
      text: 'Bonne trajectoire. Garde la raquette plus haute en préparation, tu gagneras du temps '
          'sur les lobs.',
    ),
  ];

  // ── Video feedback (COA-11) ───────────────────────────────────────────────────────────────
  static const videoLength = Duration(seconds: 42);
  static const videoSession = 4;
  static const comments = [
    VideoComment(
      at: Duration(seconds: 8),
      text: 'Bonne préparation : raquette haute, derrière la tête. Garde-la comme ça.',
    ),
    VideoComment(
      at: Duration(seconds: 31),
      text: 'La balle part au centre. Ouvre un peu plus le tamis et vise la grille côté gauche '
          'pour la croiser.',
    ),
  ];
  static const commentDraftAt = Duration(seconds: 18);
  static const commentDraft =
      'Tu frappes trop tôt : laisse descendre la balle à hauteur d’épaule, puis accompagne vers la '
      'grille.';
  static const aiMoment = VideoComment(
    at: Duration(seconds: 39),
    text: 'Bon replacement au filet',
    fromAi: true,
  );
  static const message =
      'Belle progression, Yassine ! La trajectoire est là, il reste le timing.\n'
      '• Laisse descendre la balle avant de frapper.\n'
      '• Vise la grille latérale, pas le centre.\n'
      'Refais l’exercice 3 de la séance 5 au ralenti avant de passer à la vitesse match.';

  // ── Dashboard (COA-04) ────────────────────────────────────────────────────────────────────
  static const todos = [
    CoachTodo(
      id: 'video-yassine',
      kind: TodoKind.video,
      studentId: 'yassine',
      who: 'Yassine B.',
      detail: 'Bandeja · 0:42',
      level: 3.5,
    ),
    CoachTodo(
      id: 'dropped-lina',
      kind: TodoKind.dropped,
      studentId: 'lina',
      who: 'Lina F.',
      detail: 'Service et retour · 1/9 · 12 jours',
    ),
    CoachTodo(
      id: 'review-omar',
      kind: TodoKind.review,
      studentId: 'omar',
      who: 'Omar D.',
      detail: '« Les vidéos sont un peu longues »',
      stars: 3,
    ),
  ];

  static final latestReview = CoachReview(
    author: 'Mariem K.',
    level: 4.0,
    stars: 5,
    program: 'Bandeja en 4 semaines',
    date: Story.at(14, 0),
    text: 'Karim explique simplement et corrige vite. Ma bandeja croisée passe enfin, même sous '
        'pression.',
  );

  // ── The draft « Jeu au filet en 4 semaines » (COA-06…08) ──────────────────────────────────
  static DraftExercise _ex(
    String id,
    String name,
    DrillMode mode,
    int sets, {
    int seconds = 45,
    int reps = 12,
    int? video,
    VideoState state = VideoState.ready,
  }) => DraftExercise(
    id: id,
    name: name,
    mode: mode,
    sets: sets,
    seconds: seconds,
    reps: reps,
    video: video == null ? VideoState.none : state,
    videoLength: video == null ? null : Duration(seconds: video),
  );

  static DraftSession _session(String id, String title, List<DraftExercise> ex) =>
      DraftSession(id: id, title: title, exercises: ex, video: VideoState.ready);

  static List<DraftExercise> _three(String p, String a, String b, String c) => [
    _ex('$p-1', a, DrillMode.time, 1, seconds: 180, video: 40),
    _ex('$p-2', b, DrillMode.reps, 3, reps: 10, video: 50),
    _ex('$p-3', c, DrillMode.time, 4, seconds: 45, video: 55),
  ];

  static final draft = ProgramDraft(
    id: 'jeu-au-filet',
    title: 'Jeu au filet en 4 semaines',
    sport: MuSport.padel,
    levelMin: 2.5,
    levelMax: 4.0,
    updatedAt: Story.at(15, 22, 10),
    publishDate: DateTime(2026, 10, 26, 8),
    weeks: [
      DraftWeek(
        id: 'w1',
        title: 'Les bases au filet',
        sessions: [
          _session('s1', 'Position d’attente au filet',
              _three('s1', 'Échauffement au filet', 'Position d’attente', 'Volée sur lancer')),
          _session('s2', 'Volée de coup droit',
              _three('s2', 'Échauffement au filet', 'Volée de coup droit à l’arrêt', 'Volée en avançant')),
          _session('s3', 'Volée de revers',
              _three('s3', 'Échauffement au filet', 'Volée de revers à l’arrêt', 'Revers croisé')),
        ],
      ),
      DraftWeek(
        id: 'w2',
        title: 'Placement',
        sessions: [
          _session('s4', 'Fermer l’angle',
              _three('s4', 'Échauffement au filet', 'Couvrir la ligne', 'Fermer l’angle sur lancer')),
          DraftSession(
            id: 's5',
            title: 'Volée croisée profonde',
            video: VideoState.processing,
            videoName: 'volee-croisee-demo.mp4',
            videoBytes: 86200000,
            videoLength: const Duration(minutes: 2, seconds: 14),
            instruction:
                'Vise la grille latérale, pas le centre. Après chaque volée, reviens en position '
                'd’attente avant la balle suivante.',
            exercises: [
              _ex('s5-1', 'Échauffement au filet', DrillMode.time, 1, seconds: 180, video: 40),
              _ex('s5-2', 'Ouverture de raquette', DrillMode.reps, 3, reps: 12, video: 52),
              const DraftExercise(
                id: 's5-3',
                name: 'Volée croisée sur panier de balles',
                mode: DrillMode.time,
                sets: 6,
                seconds: 45,
                video: VideoState.uploading,
                uploadProgress: 0.64,
                fileName: 'panier-croise.mov',
                fileBytes: 29000000,
              ),
            ],
          ),
          DraftSession(
            id: 's6',
            title: 'Volée amortie',
            video: VideoState.ready,
            exercises: [
              ..._three('s6', 'Échauffement au filet', 'Toucher de balle', 'Amortie sur lancer'),
              _ex('s6-4', 'Jeu à thème', DrillMode.time, 2, seconds: 240),
            ],
          ),
        ],
      ),
      DraftWeek(
        id: 'w3',
        title: 'Sous pression',
        sessions: [
          DraftSession(
            id: 's7',
            title: 'Défendre le lob depuis le filet',
            exercises: _three('s7', 'Échauffement', 'Recul en pas chassés', 'Lob sur lancer'),
          ),
          DraftSession(
            id: 's8',
            title: 'Enchaînement volée – smash',
            exercises: [
              ..._three('s8', 'Échauffement', 'Volée puis smash', 'Smash par 3'),
              _ex('s8-4', 'Jeu à thème', DrillMode.time, 2, seconds: 240),
            ],
          ),
          DraftSession(
            id: 's9',
            title: 'Bandeja de dépannage',
            exercises: _three('s9', 'Échauffement', 'Bandeja haute', 'Bandeja en recul'),
          ),
        ],
      ),
      DraftWeek(
        id: 'w4',
        title: 'En match',
        sessions: [
          DraftSession(
            id: 's10',
            title: 'Monter au filet à deux',
            exercises: _three('s10', 'Échauffement', 'Monter ensemble', 'Points à thème'),
          ),
        ],
      ),
    ],
  );

  /// The coach's exercise library.
  static const library = [
    LibraryExercise(
      id: 'split',
      name: 'Split-step avant la volée',
      category: 'Déplacements',
      mode: DrillMode.time,
      sets: 4,
      seconds: 45,
      videoLength: Duration(seconds: 35),
    ),
    LibraryExercise(
      id: 'jeu-dirige',
      name: 'Jeu dirigé 2 contre 1 au filet',
      category: 'Jeu au filet',
      mode: DrillMode.time,
      sets: 3,
      seconds: 240,
      videoLength: Duration(seconds: 70),
    ),
    LibraryExercise(
      id: 'volee-basse',
      name: 'Volée basse sous la bande',
      category: 'Jeu au filet',
      mode: DrillMode.reps,
      sets: 3,
      reps: 10,
    ),
    LibraryExercise(
      id: 'gainage',
      name: 'Gainage latéral',
      category: 'Physique',
      mode: DrillMode.time,
      sets: 3,
      seconds: 30,
      videoLength: Duration(seconds: 28),
    ),
    LibraryExercise(
      id: 'pas-chasses',
      name: 'Pas chassés le long du filet',
      category: 'Déplacements',
      mode: DrillMode.time,
      sets: 4,
      seconds: 30,
      videoLength: Duration(seconds: 25),
    ),
    LibraryExercise(
      id: 'volee-haute',
      name: 'Volée haute croisée',
      category: 'Jeu au filet',
      mode: DrillMode.reps,
      sets: 3,
      reps: 12,
      videoLength: Duration(seconds: 48),
    ),
    LibraryExercise(
      id: 'gainage-face',
      name: 'Gainage face',
      category: 'Physique',
      mode: DrillMode.time,
      sets: 3,
      seconds: 40,
    ),
  ];

  static const categories = ['Jeu au filet', 'Déplacements', 'Physique'];
}
