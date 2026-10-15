import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/features/player_onboarding/data/level_estimator.dart';
import 'package:matchup/features/player_onboarding/data/location_services.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/profile_repository.dart';
import 'package:matchup/features/player_onboarding/data/question_bank.dart';
import 'package:matchup/theme/theme.dart';

void main() {
  const estimator = FakeLevelEstimator(latency: Duration.zero);

  group('FakeLevelEstimator', () {
    test('the designed PLY-02 answers give 3,5 with a medium confidence', () {
      final e = estimator.estimateNow(MuSport.padel, {
        Q.experience: '2y5y',
        Q.frequency: '2week',
        Q.tournaments: 'friendly',
        Q.rating: '3',
        Q.technique1: 'often',
        Q.technique2: 'steady',
      });
      expect(e.level, 3.5);
      expect(e.confidence, EstimateConfidence.medium);
      expect(e.reasons.map((r) => r.text), [
        '2 à 5 ans de pratique',
        '2 fois par semaine',
        'Volée à l’aise (3/5)',
        'Tournois amicaux',
      ]);
    });

    test('the lowest and highest answers give 1,0 and 7,0', () {
      Map<String, String> all(int i) => {
            for (final q in QuestionBank.forSport(MuSport.football))
              q.id: q.kind == QuestionKind.scale ? '${i == 0 ? 1 : 5}' : q.options[i].id,
          };
      expect(estimator.estimateNow(MuSport.football, all(0)).level, 1);
      expect(estimator.estimateNow(MuSport.football, all(3)).level, 7);
      expect(estimator.estimateNow(MuSport.football, all(3)).confidence, EstimateConfidence.high);
    });

    test('every sport has six questions with valid answers', () {
      for (final sport in MuSport.values) {
        final questions = QuestionBank.forSport(sport);
        expect(questions, hasLength(QuestionBank.length));
        expect(questions.map((q) => q.id).toSet(), hasLength(QuestionBank.length));
      }
    });
  });

  test('onboarding state survives a save and a load', () {
    const state = PlayerOnboardingState(
      sports: [MuSport.padel, MuSport.football],
      answers: {
        MuSport.padel: {Q.experience: '2y5y'},
      },
      estimates: {
        MuSport.padel: LevelEstimate(
          level: 3.5,
          confidence: EstimateConfidence.medium,
          reasons: [EstimateReason(Q.experience, '2 à 5 ans de pratique')],
        ),
      },
      levels: {MuSport.padel: 4},
      positions: {MuSport.football: 'milieu'},
      availability: {'lun-soir', 'sam-aprem'},
      locationGranted: true,
      area: 'La Marsa',
      zones: ['La Marsa', 'Lac 2'],
      radiusKm: 20,
      pseudo: 'yassine.b',
      lastRoute: '/ply/zones',
    );
    final back = PlayerOnboardingState.fromJson(state.toJson());
    expect(back.sports, state.sports);
    expect(back.answers[MuSport.padel], {Q.experience: '2y5y'});
    expect(back.estimates[MuSport.padel]!.level, 3.5);
    expect(back.estimates[MuSport.padel]!.reasons.single.text, '2 à 5 ans de pratique');
    expect(back.levels[MuSport.padel], 4);
    expect(back.positions[MuSport.football], 'milieu');
    expect(back.availability, {'lun-soir', 'sam-aprem'});
    expect(back.zones, ['La Marsa', 'Lac 2']);
    expect(back.radiusKm, 20);
    expect(back.lastRoute, '/ply/zones');
    expect(back.nextSportToEstimate, MuSport.football);
  });

  test('an old or broken save falls back to the defaults', () {
    final back = PlayerOnboardingState.fromJson({'sports': ['tennis', 'padel'], 'radiusKm': null});
    expect(back.sports, [MuSport.padel]);
    expect(back.radiusKm, 10);
  });

  test('zone search ignores case and accents', () async {
    const zones = FakeZoneDirectory();
    expect(await zones.search('sidi bou said'), ['Sidi Bou Saïd']);
    expect((await zones.search('ENN')).first, 'Ennasr');
    expect(await zones.search(''), isEmpty);
  });

  test('pseudo rules and public name', () {
    expect(pseudoError('yassine.b'), isNull);
    expect(pseudoError('ya'), isNotNull);
    expect(pseudoError('yassine b'), isNotNull);
    expect(publicName('Yassine Belhadj'), 'Yassine B.');
    expect(publicName('Yassine'), 'Yassine');
  });
}
