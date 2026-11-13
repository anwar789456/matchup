import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import 'training_models.dart';

/// The training catalogue of the story (ENT-01…09): four programs, three verified coaches, and
/// where Yassine stands on ven. 16 oct. — Bandeja en 4 semaines joined on lun. 5 oct., sessions 1
/// to 4 done, session 5 « Bandeja croisée » today, 6 weeks in a row.
///
/// Programs and coaches are content (they will come from the entrainement API); the player's
/// progress lives in the database (SqliteTrainingRepository).
abstract final class TrainingStory {
  static const karim = MuCoach(
    id: 'karim',
    name: 'Karim J.',
    sport: MuSport.padel,
    city: 'Lac 2',
    specialties: ['Bandeja', 'Service', 'Placement'],
    rating: 4.9,
    reviews: 64,
    students: 38,
    languages: ['FR', 'AR'],
    priceFrom: 40,
    certification: 'Certifié FTT niveau 2',
  );

  static const sonia = MuCoach(
    id: 'sonia',
    name: 'Sonia L.',
    sport: MuSport.football,
    city: 'La Marsa',
    specialties: ['Endurance', 'Préparation physique'],
    rating: 4.7,
    reviews: 41,
    students: 27,
    languages: ['FR', 'AR'],
    priceFrom: 35,
    certification: 'Licence STAPS · préparatrice physique',
  );

  static const mehdi = MuCoach(
    id: 'mehdi',
    name: 'Mehdi K.',
    sport: MuSport.basketball,
    city: 'Ennasr',
    specialties: ['Tir', 'Dribble'],
    rating: 4.6,
    reviews: 22,
    students: 19,
    languages: ['AR', 'FR'],
    priceFrom: 30,
    certification: 'Entraîneur FTBB 1er degré',
  );

  static const coaches = [karim, sonia, mehdi];

  static MuCoach coach(String id) => coaches.firstWhere((c) => c.id == id);

  // ── Bandeja en 4 semaines ─────────────────────────────────────────────────────────────────
  static const _throwSetup = 'avec un partenaire qui lance';

  /// Session 5, played in ENT-04: warm-up, the key drill, the moving drill, a themed game.
  static const _session5 = [
    Exercise(
      title: 'Échauffement des épaules',
      dose: '4 min',
      video: Duration(seconds: 45),
      steps: [
        'Fais 10 rotations d’épaules vers l’avant, puis 10 vers l’arrière.',
        'Armé lent face au grillage : 10 gestes sans balle, épaule de profil.',
        'Finis par 20 petits pas chassés le long du filet.',
      ],
    ),
    Exercise(
      title: 'Bandeja croisée sur lancer',
      dose: '3 × 12',
      video: Duration(seconds: 72),
      sets: 3,
      reps: 12,
      rest: Duration(seconds: 45),
      setup: _throwSetup,
      steps: [
        'Ton partenaire lance un lob à mi-court, sur ton côté gauche.',
        'Arme tôt, épaule de profil. Frappe devant l’épaule, poignet ferme.',
        'Vise la grille latérale opposée, puis remonte au filet en 2 pas.',
      ],
      tip: 'Finis ton geste vers la grille, pas vers le sol : c’est ce qui fait tourner la balle.',
      counterLabel: 'Bandejas réussies',
      counterNoun: 'une bandeja',
      counted: true,
    ),
    Exercise(
      title: 'Bandeja croisée en déplacement',
      dose: '3 × 8',
      video: Duration(seconds: 65),
      sets: 3,
      reps: 8,
      rest: Duration(seconds: 45),
      setup: _throwSetup,
      steps: [
        'Pars du centre du court, au niveau de la ligne de service.',
        'Recule en pas chassés pendant que le lob monte, épaule de profil.',
        'Frappe croisé vers la grille, puis reviens au filet en 2 pas.',
      ],
      tip: 'Ne recule jamais en marche arrière : les pas chassés gardent ton épaule de profil.',
      counterLabel: 'Bandejas réussies',
      counterNoun: 'une bandeja',
    ),
    Exercise(
      title: 'Jeu à thème',
      dose: '5 min',
      video: Duration(seconds: 50),
      setup: 'à deux',
      steps: [
        'Jouez des points à deux : l’un au filet, l’autre au fond.',
        'Celui du fond lobe ; au filet, tu ne réponds qu’en bandeja croisée.',
        'Changez de rôle toutes les 2 minutes.',
      ],
    ),
  ];

  static Exercise _ex(
    String title,
    String dose, {
    int sets = 1,
    int? reps,
    String? label,
  }) => Exercise(
    title: title,
    dose: dose,
    video: const Duration(seconds: 55),
    sets: sets,
    reps: reps,
    rest: reps == null ? Duration.zero : const Duration(seconds: 45),
    counterLabel: label,
    counted: label != null,
  );

  static final bandeja = TrainingProgram(
    card: const MuProgram(
      id: 'bandeja',
      title: 'Bandeja en 4 semaines',
      coach: MuCoachRef('Karim J.'),
      sport: MuSport.padel,
      level: 3.5,
      weeks: 4,
      sessions: 12,
      minutesPerDay: 25,
      rating: 4.9,
      reviews: 64,
      price: 45,
      premium: true,
    ),
    coachId: 'karim',
    nickname: 'Bandeja',
    levelMin: 3.0,
    levelMax: 4.5,
    perWeek: 3,
    minutesMin: 20,
    minutesMax: 30,
    about:
        'La bandeja, c’est le coup qui te garde au filet quand l’adversaire te lobe. En 4 '
        'semaines, Karim t’apprend à la placer croisée, à la jouer en déplacement et à la '
        'choisir au bon moment.',
    outcomes: const [
      'Armer tôt, épaule de profil',
      'Frapper devant l’épaule, poignet ferme',
      'Placer croisé vers la grille ou le long de la ligne',
      'Enchaîner vers le filet sans perdre ta place',
    ],
    equipment: 'ta raquette, 10 balles et un court. Seul ou à deux.',
    ratingCounts: const [57, 6, 1, 0, 0],
    reviews: const [
      ProgramReview(
        author: 'Rami S.',
        daysAgo: 5,
        stars: 5,
        text:
            'Fini en 4 semaines pile. La semaine 3 sur les déplacements change tout : je ne '
            'recule plus en marche arrière.',
      ),
    ],
    weeks: [
      const TrainingWeek(
        index: 1,
        title: 'Les bases du geste',
        topics: 'Prise · Armé · Contact',
        lessons: [
          TrainingLesson(
            index: 1,
            title: 'Prise et armé',
            minutes: 20,
            downloaded: true,
            exercises: [
              Exercise(
                title: 'Prise continentale et armé',
                dose: '3 min',
                video: Duration(seconds: 40),
              ),
              Exercise(
                title: 'Armé face au grillage, sans balle',
                dose: '3 × 10',
                video: Duration(seconds: 50),
                sets: 3,
                reps: 10,
                rest: Duration(seconds: 30),
                counterLabel: 'Gestes propres',
              ),
              Exercise(
                title: 'Bandeja sur balle lancée',
                dose: '3 × 12',
                video: Duration(seconds: 62),
                sets: 3,
                reps: 12,
                rest: Duration(seconds: 45),
                setup: _throwSetup,
                counterLabel: 'Bandejas réussies',
                counterNoun: 'une bandeja',
                counted: true,
              ),
            ],
          ),
          TrainingLesson(
            index: 2,
            title: 'Le contact devant l’épaule',
            minutes: 22,
            downloaded: true,
            exercises: [
              Exercise(
                title: 'Échauffement des épaules',
                dose: '4 min',
                video: Duration(seconds: 45),
              ),
              Exercise(
                title: 'Armé face au grillage',
                dose: '3 × 10',
                video: Duration(seconds: 50),
                sets: 3,
                reps: 10,
                rest: Duration(seconds: 30),
                counterLabel: 'Gestes propres',
              ),
              Exercise(
                title: 'Contact devant l’épaule sur lancer',
                dose: '3 × 12',
                video: Duration(seconds: 70),
                sets: 3,
                reps: 12,
                rest: Duration(seconds: 45),
                setup: _throwSetup,
                counterLabel: 'Bandejas réussies',
                counterNoun: 'une bandeja',
                counted: true,
              ),
              Exercise(
                title: 'Jeu à thème',
                dose: '5 min',
                video: Duration(seconds: 50),
              ),
            ],
          ),
          TrainingLesson(
            index: 3,
            title: 'Bandeja long de ligne',
            minutes: 23,
            downloaded: true,
            exercises: [
              Exercise(
                title: 'Échauffement des épaules',
                dose: '4 min',
                video: Duration(seconds: 45),
              ),
              Exercise(
                title: 'Bandeja long de ligne sur lancer',
                dose: '3 × 12',
                video: Duration(seconds: 68),
                sets: 3,
                reps: 12,
                rest: Duration(seconds: 45),
                setup: _throwSetup,
                counterLabel: 'Bandejas réussies',
                counterNoun: 'une bandeja',
                counted: true,
              ),
              Exercise(
                title: 'Viser la ligne de côté',
                dose: '3 × 8',
                video: Duration(seconds: 58),
                sets: 3,
                reps: 8,
                rest: Duration(seconds: 45),
                counterLabel: 'Balles sur la ligne',
              ),
              Exercise(
                title: 'Jeu à thème',
                dose: '5 min',
                video: Duration(seconds: 50),
              ),
            ],
          ),
        ],
      ),
      TrainingWeek(
        index: 2,
        title: 'Bandeja croisée',
        topics: 'Viser la grille · Croisée · Sous pression',
        lessons: [
          TrainingLesson(
            index: 4,
            title: 'Viser la grille',
            minutes: 20,
            downloaded: true,
            exercises: [
              _ex('Échauffement des épaules', '4 min'),
              _ex(
                'Bandeja vers la grille',
                '3 × 10',
                sets: 3,
                reps: 10,
                label: 'Bandejas réussies',
              ),
              _ex('Jeu à thème', '5 min'),
            ],
          ),
          const TrainingLesson(
            index: 5,
            title: 'Bandeja croisée',
            minutes: 22,
            downloaded: true,
            exercises: _session5,
          ),
          TrainingLesson(
            index: 6,
            title: 'Bandeja sous pression',
            minutes: 20,
            exercises: [
              _ex('Échauffement des épaules', '4 min'),
              _ex(
                'Bandeja sur lob rapide',
                '3 × 10',
                sets: 3,
                reps: 10,
                label: 'Bandejas réussies',
              ),
              _ex('Bandeja puis volée', '3 × 8', sets: 3, reps: 8),
              _ex('Jeu à thème', '5 min'),
            ],
          ),
        ],
      ),
      TrainingWeek(
        index: 3,
        title: 'En déplacement',
        topics: 'Pas chassés · Lob court · Montée au filet',
        lessons: [
          TrainingLesson(
            index: 7,
            title: 'Pas chassés et bandeja',
            minutes: 22,
            exercises: [
              _ex('Échauffement des jambes', '4 min'),
              _ex('Pas chassés sans balle', '3 × 10', sets: 3, reps: 10),
              _ex(
                'Bandeja en reculant',
                '3 × 10',
                sets: 3,
                reps: 10,
                label: 'Bandejas réussies',
              ),
            ],
          ),
          TrainingLesson(
            index: 8,
            title: 'Le lob court',
            minutes: 20,
            exercises: [
              _ex('Échauffement des épaules', '4 min'),
              _ex(
                'Bandeja sur lob court',
                '3 × 10',
                sets: 3,
                reps: 10,
                label: 'Bandejas réussies',
              ),
              _ex('Jeu à thème', '5 min'),
            ],
          ),
          TrainingLesson(
            index: 9,
            title: 'Monter au filet',
            minutes: 23,
            exercises: [
              _ex('Échauffement des jambes', '4 min'),
              _ex(
                'Bandeja et 2 pas en avant',
                '3 × 10',
                sets: 3,
                reps: 10,
                label: 'Bandejas réussies',
              ),
              _ex('Volée après la bandeja', '3 × 8', sets: 3, reps: 8),
              _ex('Jeu à thème', '5 min'),
            ],
          ),
        ],
      ),
      TrainingWeek(
        index: 4,
        title: 'Le bon coup au bon moment',
        topics: 'Bandeja ou víbora · Jeu à deux · Test filmé',
        lessons: [
          TrainingLesson(
            index: 10,
            title: 'Bandeja ou víbora',
            minutes: 22,
            exercises: [
              _ex('Échauffement des épaules', '4 min'),
              _ex('Lire la hauteur du lob', '3 × 8', sets: 3, reps: 8),
              _ex(
                'Bandeja ou víbora sur lancer',
                '3 × 10',
                sets: 3,
                reps: 10,
                label: 'Bons choix',
              ),
              _ex('Jeu à thème', '5 min'),
            ],
          ),
          TrainingLesson(
            index: 11,
            title: 'Jeu à deux',
            minutes: 25,
            exercises: [
              _ex('Échauffement complet', '5 min'),
              _ex('Points à thème', '3 × 5 min', sets: 3),
              _ex('Retour au calme', '3 min'),
            ],
          ),
          TrainingLesson(
            index: 12,
            title: 'Test filmé',
            minutes: 20,
            exercises: [
              _ex('Échauffement des épaules', '4 min'),
              _ex(
                '10 bandejas filmées',
                '1 × 10',
                reps: 10,
                label: 'Bandejas réussies',
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // ── The other programs ────────────────────────────────────────────────────────────────────

  /// A week of [titles], each session with a warm-up, a counted drill and a themed game.
  static TrainingWeek _week(
    int index,
    String title,
    String topics,
    int firstLesson,
    List<String> titles,
    int minutes, {
    required String drill,
    required String counter,
  }) => TrainingWeek(
    index: index,
    title: title,
    topics: topics,
    lessons: [
      for (final (i, t) in titles.indexed)
        TrainingLesson(
          index: firstLesson + i,
          title: t,
          minutes: minutes,
          exercises: [
            _ex('Échauffement', '5 min'),
            _ex(drill, '3 × 10', sets: 3, reps: 10, label: counter),
            _ex('Jeu à thème', '5 min'),
          ],
        ),
    ],
  );

  static final service = TrainingProgram(
    card: const MuProgram(
      id: 'service-retour',
      title: 'Service et retour',
      coach: MuCoachRef('Karim J.'),
      sport: MuSport.padel,
      level: 3.5,
      weeks: 3,
      sessions: 9,
      minutesPerDay: 20,
      rating: 4.8,
      reviews: 29,
      price: 30,
    ),
    coachId: 'karim',
    levelMin: 3.0,
    levelMax: 4.5,
    perWeek: 3,
    minutesMin: 15,
    minutesMax: 25,
    forYouReason: 'tu joues côté gauche : c’est toi qui retournes la plupart des services adverses.',
    about:
        'Le premier coup de chaque point. En 3 semaines, Karim t’aide à servir toujours à la '
        'vitre et à retourner bas, dans les pieds du joueur au filet.',
    outcomes: const [
      'Servir à la vitre, sans faute',
      'Retourner bas, dans les pieds',
      'Choisir le lob de retour au bon moment',
    ],
    equipment: 'ta raquette, 20 balles et un court. Seul ou à deux.',
    ratingCounts: const [24, 4, 1, 0, 0],
    reviews: const [
      ProgramReview(
        author: 'Ines M.',
        daysAgo: 12,
        stars: 5,
        text: 'Mon service ne fait plus de cadeaux. Les retours dans les pieds marchent vraiment.',
      ),
    ],
    weeks: [
      _week(
        1,
        'Le service',
        'Lancer · Vitre · Régularité',
        1,
        ['Le lancer de balle', 'Servir à la vitre', 'Service sous pression'],
        20,
        drill: 'Services à la vitre',
        counter: 'Services réussis',
      ),
      _week(
        2,
        'Le retour',
        'Bas · Dans les pieds · Croisé',
        4,
        ['Retour bas', 'Retour dans les pieds', 'Retour croisé'],
        20,
        drill: 'Retours sur service',
        counter: 'Retours réussis',
      ),
      _week(
        3,
        'En match',
        'Lob de retour · Enchaîner · Test',
        7,
        ['Le lob de retour', 'Service et montée', 'Test en jeu'],
        20,
        drill: 'Points à thème',
        counter: 'Points gagnés',
      ),
    ],
  );

  static final endurance = TrainingProgram(
    card: const MuProgram(
      id: 'endurance-foot',
      title: 'Endurance foot 5v5',
      coach: MuCoachRef('Sonia L.'),
      sport: MuSport.football,
      level: 3.0,
      weeks: 6,
      sessions: 18,
      minutesPerDay: 30,
      rating: 4.7,
      reviews: 41,
      price: 60,
    ),
    coachId: 'sonia',
    levelMin: 2.5,
    levelMax: 4.0,
    perWeek: 3,
    minutesMin: 25,
    minutesMax: 35,
    about:
        'Tenir 60 minutes à 5 contre 5 sans finir à bout de souffle. Sonia alterne fractionné, '
        'changements de direction et récupération active, semaine après semaine.',
    outcomes: const [
      'Tenir le rythme jusqu’à la fin du match',
      'Répéter les sprints courts',
      'Récupérer plus vite entre deux actions',
    ],
    equipment: 'des baskets, 6 plots et un terrain ou un parc. Seul.',
    ratingCounts: const [33, 6, 2, 0, 0],
    reviews: const [
      ProgramReview(
        author: 'Omar D.',
        daysAgo: 9,
        stars: 5,
        text: 'Au bout de 3 semaines, je ne demande plus de changement à la mi-temps.',
      ),
    ],
    weeks: [
      for (var w = 0; w < 6; w++)
        _week(
          w + 1,
          [
            'Les bases',
            'Fractionné',
            'Changements de direction',
            'Sprints répétés',
            'Intensité match',
            'Test final',
          ][w],
          [
            'Footing · Gainage · Mobilité',
            'Courts · Longs · Récupération',
            'Appuis · Plots · Réaction',
            'Départs · Relances · Repos',
            'Jeu réduit · Pressing · Repli',
            'Test navette · Bilan · Suite',
          ][w],
          w * 3 + 1,
          [
            ['Footing et gainage', 'Mobilité', 'Premier fractionné'],
            ['Fractionné 30/30', 'Fractionné long', 'Récupération active'],
            ['Appuis rapides', 'Slalom entre les plots', 'Réaction au signal'],
            ['Départs arrêtés', 'Sprints répétés', 'Relances'],
            ['Jeu réduit', 'Pressing et repli', 'Séance match'],
            ['Test navette', 'Séance bilan', 'La suite'],
          ][w],
          30,
          drill: 'Sprints de 20 m',
          counter: 'Sprints faits',
        ),
    ],
  );

  static final basket = TrainingProgram(
    card: const MuProgram(
      id: 'basket-3x3',
      title: 'Bases du basket 3×3',
      coach: MuCoachRef('Mehdi K.'),
      sport: MuSport.basketball,
      level: 2.5,
      weeks: 4,
      sessions: 8,
      minutesPerDay: 20,
      rating: 4.6,
      reviews: 22,
    ),
    coachId: 'mehdi',
    levelMin: 1.5,
    levelMax: 3.5,
    perWeek: 2,
    minutesMin: 15,
    minutesMax: 25,
    about:
        'Dribbler des deux mains, tirer avec le bon geste et jouer le 3×3 sur un demi-terrain. '
        'Mehdi reprend tout depuis le début, à ton rythme.',
    outcomes: const [
      'Dribbler main gauche et main droite',
      'Tirer avec le coude sous la balle',
      'Jouer le pick and roll à 3',
    ],
    equipment: 'un ballon et un panier. Seul ou à deux.',
    ratingCounts: const [16, 4, 2, 0, 0],
    reviews: const [
      ProgramReview(
        author: 'Salma G.',
        daysAgo: 20,
        stars: 4,
        text: 'Parfait pour reprendre. Les séances de tir sont courtes et efficaces.',
      ),
    ],
    weeks: [
      _week(
        1,
        'Le dribble',
        'Deux mains · Tête haute',
        1,
        ['Dribble main faible', 'Dribble tête haute'],
        20,
        drill: 'Dribbles en slalom',
        counter: 'Passages sans perte',
      ),
      _week(
        2,
        'Le tir',
        'Geste · Lancers francs',
        3,
        ['Le geste du tir', 'Lancers francs'],
        20,
        drill: 'Tirs près du panier',
        counter: 'Paniers réussis',
      ),
      _week(
        3,
        'Le jeu à 3',
        'Écran · Pick and roll',
        5,
        ['L’écran', 'Le pick and roll'],
        20,
        drill: 'Pick and roll à 3',
        counter: 'Actions réussies',
      ),
      _week(
        4,
        'En match',
        'Demi-terrain · Test',
        7,
        ['Match à 3', 'Test final'],
        20,
        drill: 'Tirs en mouvement',
        counter: 'Paniers réussis',
      ),
    ],
  );

  static final programs = [bandeja, service, endurance, basket];

  // ── Reviews (« Voir les 64 avis ») ─────────────────────────────────────────────────────────

  static const _reviewers = [
    'Mariem K.', 'Ines M.', 'Omar D.', 'Salma G.', 'Hamza R.', 'Nour A.', 'Aziz H.', 'Lina F.',
    'Skander T.', 'Amira S.', 'Fares Z.', 'Hiba L.',
  ];

  static const _texts = {
    5: [
      'Clair, progressif, et les vidéos vont droit au but. Je referais un programme du même coach.',
      'Les séances tiennent en 20 minutes : parfait avant le travail.',
      'J’ai senti la différence dès la deuxième semaine en match.',
    ],
    4: [
      'Très bien construit. Une ou deux séances un peu longues à mon goût.',
      'Bons exercices, il faut juste un partenaire pour la plupart.',
    ],
    3: ['Utile, mais j’aurais aimé plus de variantes pour mon niveau.'],
    2: ['Trop rapide pour moi, j’ai dû refaire plusieurs séances.'],
    1: ['Pas adapté à ce que je cherchais.'],
  };

  /// The program's reviews: the designed one first, then up to 11 more whose stars follow its
  /// split ([TrainingProgram.ratingCounts]).
  static List<ProgramReview> reviewsOf(TrainingProgram p) {
    final total = p.ratingCounts.fold(0, (a, b) => a + b);
    final shown = total < 12 ? total : 12;
    final stars = <int>[
      for (final (i, n) in p.ratingCounts.indexed)
        for (var k = 0; k < (n * shown / (total == 0 ? 1 : total)).round(); k++) 5 - i,
    ];
    return [
      ...p.reviews,
      for (final (i, st) in stars.skip(p.reviews.length).indexed)
        ProgramReview(
          author: _reviewers[(i + p.id.length) % _reviewers.length],
          daysAgo: 7 + i * 4,
          stars: st,
          text: _texts[st]![i % _texts[st]!.length],
          finished: i.isEven,
        ),
    ];
  }

  // ── Yassine's progress on ven. 16 oct. ────────────────────────────────────────────────────

  static final bandejaJoined = DateTime(2026, 10, 5, 19);

  /// Sessions 1 to 4: lun. 5, mer. 7, lun. 12 and mer. 14 oct., in the evening.
  static final doneSessions = [
    for (final (index, day) in [(1, 5), (2, 7), (3, 12), (4, 14)])
      LessonResult(
        programId: 'bandeja',
        index: index,
        doneAt: Story.at(day, 19, 30),
        minutes: bandeja.lesson(index).minutes + 2,
        drillsDone: bandeja.lesson(index).exercises.length,
        drillsTotal: bandeja.lesson(index).exercises.length,
        reps: 30,
        target: 36,
        feeling: LessonFeeling.right,
      ),
  ];

  /// Weeks validated in a row before the week of 12 oct.
  static const streakBefore = 6;
  static const weeklyGoal = 3;
}
