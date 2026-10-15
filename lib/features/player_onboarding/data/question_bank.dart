import '../../../theme/theme.dart';

/// The names the player onboarding uses for each sport (PLY-01, 03, 04).
extension MuSportOnboarding on MuSport {
  /// « Football 5 », « Padel », « Basket ».
  String get onboardingName => switch (this) {
        MuSport.football => 'Football 5',
        MuSport.padel => 'Padel',
        MuSport.basketball => 'Basket',
      };

  /// PLY-01 card description.
  String get formatLine => switch (this) {
        MuSport.football => '5 contre 5 · terrains synthétiques',
        MuSport.padel => '2 contre 2 · courts vitrés',
        MuSport.basketball => '3 contre 3 · salles et playgrounds',
      };

  /// « au padel » in « Depuis quand joues-tu au padel ? ».
  String get withAu => switch (this) {
        MuSport.football => 'au foot',
        MuSport.padel => 'au padel',
        MuSport.basketball => 'au basket',
      };

  /// « de padel » in « Ton niveau de padel ».
  String get withDe => switch (this) {
        MuSport.football => 'de foot',
        MuSport.padel => 'de padel',
        MuSport.basketball => 'de basket',
      };

  /// Lower-case name in « Niveau padel ».
  String get lowerName => switch (this) {
        MuSport.football => 'football',
        MuSport.padel => 'padel',
        MuSport.basketball => 'basket',
      };
}

/// One answer of a choice question.
class QuestionOption {
  const QuestionOption(this.id, this.title, this.description, {required this.score, this.reason});

  final String id;
  final String title;
  final String description;

  /// 0 (beginner) to 1 (expert), used by the level estimator.
  final double score;

  /// Short form for « Pourquoi ce niveau ? » (« 2 à 5 ans de pratique »).
  final String? reason;
}

/// One step of the 1–5 self-rating question.
class ScaleStep {
  const ScaleStep(this.word, this.description, {required this.reason});

  /// Under the number (« À l’aise »).
  final String word;
  final String description;

  /// For « Pourquoi ce niveau ? » (« Volée à l’aise (3/5) »).
  final String reason;
}

enum QuestionKind { choice, scale }

/// A question of the AI level questionnaire (PLY-02).
class LevelQuestion {
  const LevelQuestion.choice(this.id, this.title, this.options)
      : kind = QuestionKind.choice,
        subtitle = null,
        scale = const [];

  const LevelQuestion.scale(this.id, this.title, this.scale, {this.subtitle})
      : kind = QuestionKind.scale,
        options = const [];

  final String id;
  final QuestionKind kind;
  final String title;
  final String? subtitle;
  final List<QuestionOption> options;

  /// Five steps, for 1 to 5.
  final List<ScaleStep> scale;

  /// The answer's score (0–1) and its « Pourquoi » line.
  (double score, String? reason)? evaluate(String? answer) {
    if (answer == null) return null;
    if (kind == QuestionKind.scale) {
      final n = int.tryParse(answer);
      if (n == null || n < 1 || n > scale.length) return null;
      return ((n - 1) / (scale.length - 1), scale[n - 1].reason);
    }
    for (final o in options) {
      if (o.id == answer) return (o.score, o.reason);
    }
    return null;
  }
}

/// Question ids, shared by every sport: q1 experience, q2 frequency, q3 tournaments, q4 the 1–5
/// self-rating, q5 and q6 two technique questions.
abstract final class Q {
  static const experience = 'q1';
  static const frequency = 'q2';
  static const tournaments = 'q3';
  static const rating = 'q4';
  static const technique1 = 'q5';
  static const technique2 = 'q6';
}

/// The six questions per sport.
///
/// Padel is the designed questionnaire (design/screens/source/PLY-02). The football and basketball
/// technique questions (q4–q6) and their option copy are drafts written to the same pattern,
/// waiting for design validation.
abstract final class QuestionBank {
  static const int length = 6;

  static List<LevelQuestion> forSport(MuSport sport) => [
        _experience(sport),
        _frequency(sport),
        _tournaments(sport),
        ...switch (sport) {
          MuSport.padel => _padelTechnique,
          MuSport.football => _footballTechnique,
          MuSport.basketball => _basketballTechnique,
        },
      ];

  static LevelQuestion _experience(MuSport sport) => LevelQuestion.choice(
        Q.experience,
        'Depuis quand joues-tu ${sport.withAu} ?',
        [
          const QuestionOption('lt6m', 'Moins de 6 mois', 'Je découvre encore les règles.',
              score: 0, reason: 'Moins de 6 mois de pratique'),
          const QuestionOption('6m2y', '6 mois à 2 ans', 'Je joue entre amis, sans trop de tactique.',
              score: 1 / 3, reason: '6 mois à 2 ans de pratique'),
          const QuestionOption('2y5y', '2 à 5 ans', 'J’ai mes coups et je lis le jeu.',
              score: 2 / 3, reason: '2 à 5 ans de pratique'),
          const QuestionOption('gt5y', 'Plus de 5 ans', 'Je joue en club ou en compétition.',
              score: 1, reason: 'Plus de 5 ans de pratique'),
        ],
      );

  static LevelQuestion _frequency(MuSport sport) => LevelQuestion.choice(
        Q.frequency,
        'À quelle fréquence joues-tu ?',
        [
          const QuestionOption('rare', 'Moins d’une fois par mois', 'Quand l’occasion se présente.',
              score: 0, reason: 'Moins d’une fois par mois'),
          const QuestionOption('month', '2 à 3 fois par mois', 'Un match de temps en temps.',
              score: 1 / 3, reason: '2 à 3 fois par mois'),
          const QuestionOption(
              'week', '1 fois par semaine', 'Mon créneau fixe avec les mêmes partenaires.',
              score: 2 / 3, reason: '1 fois par semaine'),
          QuestionOption(
            '2week',
            '2 fois par semaine ou plus',
            switch (sport) {
              MuSport.padel => 'Le padel fait partie de ma semaine.',
              MuSport.football => 'Le foot fait partie de ma semaine.',
              MuSport.basketball => 'Le basket fait partie de ma semaine.',
            },
            score: 1,
            reason: '2 fois par semaine',
          ),
        ],
      );

  static LevelQuestion _tournaments(MuSport sport) => LevelQuestion.choice(
        Q.tournaments,
        'As-tu déjà joué des tournois ?',
        [
          const QuestionOption('never', 'Jamais', 'Je joue seulement des matchs entre amis.',
              score: 0, reason: 'Pas encore de tournoi'),
          const QuestionOption(
              'friendly', '1 ou 2 tournois amicaux', 'Organisés par un club ou des amis.',
              score: 1 / 3, reason: 'Tournois amicaux'),
          const QuestionOption('club', 'Des tournois de club', 'Plusieurs fois par saison.',
              score: 2 / 3, reason: 'Tournois de club'),
          QuestionOption(
            'ranked',
            'Des tournois classés',
            sport == MuSport.padel
                ? 'J’ai un classement fédéral.'
                : 'Je joue en ligue ou en championnat.',
            score: 1,
            reason: 'Tournois classés',
          ),
        ],
      );

  // Padel (designed).
  static const _padelTechnique = [
    LevelQuestion.scale(
      Q.rating,
      'Ton jeu au filet : comment est ta volée ?',
      subtitle: 'Note-toi de 1 à 5. Pas besoin d’être parfait, le niveau s’ajuste après tes matchs.',
      [
        ScaleStep('Je l’évite', 'Je reste au fond dès que je peux.',
            reason: 'Volée évitée (1/5)'),
        ScaleStep('Hésitant', 'Je monte au filet, mais je rate encore beaucoup de volées.',
            reason: 'Volée hésitante (2/5)'),
        ScaleStep('À l’aise', 'Je tiens la volée sur les balles faciles et je la place parfois.',
            reason: 'Volée à l’aise (3/5)'),
        ScaleStep('Solide', 'Je place mes volées et je finis souvent le point.',
            reason: 'Volée solide (4/5)'),
        ScaleStep('Mon arme', 'Volée, bandeja, víbora : je gagne mes points au filet.',
            reason: 'Volée, ton arme (5/5)'),
      ],
    ),
    LevelQuestion.choice(Q.technique1, 'Et tes sorties de vitre ?', [
      QuestionOption('skip', 'Je laisse passer la balle',
          'Je ne joue pas encore le rebond sur la vitre.', score: 0),
      QuestionOption('some', 'Je la remets en jeu', 'Surtout quand la balle revient lentement.',
          score: 1 / 3),
      QuestionOption('often', 'Je la sors régulièrement',
          'Je contrôle la vitre du fond et la latérale.', score: 2 / 3),
      QuestionOption('attack', 'J’attaque en sortie de vitre',
          'Double vitre et contre-vitre comprises.', score: 1),
    ]),
    LevelQuestion.choice(Q.technique2, 'Et ton service ?', [
      QuestionOption('basic', 'Je le mets en jeu', 'L’important, c’est qu’il passe.', score: 0),
      QuestionOption('steady', 'Régulier', 'Peu de fautes, toujours sous la ceinture.',
          score: 1 / 3),
      QuestionOption('placed', 'Placé', 'Je vise la vitre ou le T pour gêner.', score: 2 / 3),
      QuestionOption('varied', 'Varié', 'Je change d’effet et de zone selon l’adversaire.',
          score: 1),
    ]),
  ];

  // Football 5 (draft copy, to validate with design).
  static const _footballTechnique = [
    LevelQuestion.scale(
      Q.rating,
      'Ton contrôle de balle : il est comment ?',
      subtitle: 'Note-toi de 1 à 5. Pas besoin d’être parfait, le niveau s’ajuste après tes matchs.',
      [
        ScaleStep('Fragile', 'La balle m’échappe souvent à la réception.',
            reason: 'Contrôle fragile (1/5)'),
        ScaleStep('Hésitant', 'Je contrôle les passes simples, moins sous pression.',
            reason: 'Contrôle hésitant (2/5)'),
        ScaleStep('À l’aise', 'Je contrôle la plupart des ballons et je lève la tête.',
            reason: 'Contrôle à l’aise (3/5)'),
        ScaleStep('Solide', 'Contrôle orienté, même pressé par un adversaire.',
            reason: 'Contrôle solide (4/5)'),
        ScaleStep('Mon arme', 'Premier contrôle qui élimine : je fais la différence.',
            reason: 'Contrôle, ton arme (5/5)'),
      ],
    ),
    LevelQuestion.choice(Q.technique1, 'Et tes passes ?', [
      QuestionOption('near', 'Je cherche le plus proche', 'Je me débarrasse vite du ballon.',
          score: 0),
      QuestionOption('safe', 'Courtes et sûres', 'Je garde le ballon dans l’équipe.', score: 1 / 3),
      QuestionOption('switch', 'Je change le jeu', 'Je trouve le joueur libre de l’autre côté.',
          score: 2 / 3),
      QuestionOption('key', 'Je fais la dernière passe', 'Je crée les occasions de but.', score: 1),
    ]),
    LevelQuestion.choice(Q.technique2, 'Et devant le but ?', [
      QuestionOption('rare', 'Je laisse tirer les autres', 'Je tire rarement.', score: 0),
      QuestionOption('frame', 'Je cadre mes tirs', 'Pas toujours fort, mais souvent cadré.',
          score: 1 / 3),
      QuestionOption('score', 'Je marque régulièrement', 'Au moins un but par match ou presque.',
          score: 2 / 3),
      QuestionOption('finish', 'Je finis les actions', 'Pied faible compris, en une touche.',
          score: 1),
    ]),
  ];

  // Basket 3×3 (draft copy, to validate with design).
  static const _basketballTechnique = [
    LevelQuestion.scale(
      Q.rating,
      'Ton dribble : il est comment ?',
      subtitle: 'Note-toi de 1 à 5. Pas besoin d’être parfait, le niveau s’ajuste après tes matchs.',
      [
        ScaleStep('Fragile', 'Je perds souvent la balle en dribble.',
            reason: 'Dribble fragile (1/5)'),
        ScaleStep('Hésitant', 'Je dribble surtout de ma bonne main.',
            reason: 'Dribble hésitant (2/5)'),
        ScaleStep('À l’aise', 'Je change de main et je protège la balle.',
            reason: 'Dribble à l’aise (3/5)'),
        ScaleStep('Solide', 'Je crée le décalage face à mon défenseur.',
            reason: 'Dribble solide (4/5)'),
        ScaleStep('Mon arme', 'Crossover, retournement : je passe quand je veux.',
            reason: 'Dribble, ton arme (5/5)'),
      ],
    ),
    LevelQuestion.choice(Q.technique1, 'Et ton tir ?', [
      QuestionOption('close', 'Près du panier', 'Je marque surtout en lay-up.', score: 0),
      QuestionOption('mid', 'À mi-distance', 'Je mets mes tirs ouverts.', score: 1 / 3),
      QuestionOption('two', 'Au-delà de l’arc', 'Je tente des tirs à 2 points (3×3).',
          score: 2 / 3),
      QuestionOption('any', 'De partout', 'Même en sortie de dribble et sous pression.', score: 1),
    ]),
    LevelQuestion.choice(Q.technique2, 'Et en défense ?', [
      QuestionOption('watch', 'Je suis le jeu', 'Je défends quand la balle arrive vers moi.',
          score: 0),
      QuestionOption('man', 'Je tiens mon joueur', 'Je reste entre lui et le panier.',
          score: 1 / 3),
      QuestionOption('help', 'J’aide mes partenaires', 'Je change et je prends les rebonds.',
          score: 2 / 3),
      QuestionOption('lead', 'J’organise la défense', 'J’anticipe et je provoque les pertes.',
          score: 1),
    ]),
  ];
}
