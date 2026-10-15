import 'dart:math' as math;

import '../../../theme/theme.dart';
import 'question_bank.dart';

enum EstimateConfidence { low, medium, high }

/// One line of « Pourquoi ce niveau ? ».
class EstimateReason {
  const EstimateReason(this.questionId, this.text);

  final String questionId;
  final String text;
}

/// An AI level estimate on the 1,0–7,0 scale, with how sure it is and why.
class LevelEstimate {
  const LevelEstimate({required this.level, required this.confidence, required this.reasons});

  final double level;
  final EstimateConfidence confidence;
  final List<EstimateReason> reasons;
}

/// Estimates a level from the questionnaire. The real one is the AI service; screens only see
/// this interface.
abstract interface class LevelEstimator {
  Future<LevelEstimate> estimate(MuSport sport, Map<String, String> answers);
}

/// Local stand-in for the AI estimator.
///
/// Each answer scores 0–1. Technique counts more than experience (weights below); the weighted mean
/// is curved (^1,5) so high levels need consistently high answers, mapped to 1,0–7,0 and rounded to
/// 0,5. The spread of the answers gives the confidence. The designed answers of PLY-02 (2 à 5 ans,
/// 2 fois par semaine, tournois amicaux, volée 3/5, sorties de vitre régulières, service régulier)
/// give 3,5 with a medium confidence, as on PLY-03.
class FakeLevelEstimator implements LevelEstimator {
  const FakeLevelEstimator({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  static const _weights = {
    Q.experience: 0.15,
    Q.frequency: 0.10,
    Q.tournaments: 0.20,
    Q.rating: 0.20,
    Q.technique1: 0.20,
    Q.technique2: 0.15,
  };
  static const double _curve = 1.5;
  static const double _highSpread = 0.2;
  static const double _mediumSpread = 0.35;

  /// The « Pourquoi » lines shown, in the PLY-03 order.
  static const _reasonOrder = [Q.experience, Q.frequency, Q.rating, Q.tournaments];

  @override
  Future<LevelEstimate> estimate(MuSport sport, Map<String, String> answers) async {
    await Future<void>.delayed(latency);
    return estimateNow(sport, answers);
  }

  LevelEstimate estimateNow(MuSport sport, Map<String, String> answers) {
    final questions = {for (final q in QuestionBank.forSport(sport)) q.id: q};
    final scores = <String, double>{};
    final reasons = <String, String>{};
    for (final entry in questions.entries) {
      final result = entry.value.evaluate(answers[entry.key]);
      if (result == null) continue;
      scores[entry.key] = result.$1;
      if (result.$2 != null) reasons[entry.key] = result.$2!;
    }

    if (scores.isEmpty) {
      return const LevelEstimate(level: 1, confidence: EstimateConfidence.low, reasons: []);
    }
    var weightSum = 0.0;
    var mean = 0.0;
    for (final e in scores.entries) {
      final w = _weights[e.key] ?? 0;
      mean += w * e.value;
      weightSum += w;
    }
    mean /= weightSum;
    final raw = 1 + 6 * math.pow(mean, _curve);
    final level = ((raw * 2).round() / 2).clamp(1.0, 7.0);

    final avg = scores.values.reduce((a, b) => a + b) / scores.length;
    final spread = math.sqrt(
      scores.values.map((s) => (s - avg) * (s - avg)).reduce((a, b) => a + b) / scores.length,
    );
    final confidence = scores.length < QuestionBank.length || spread >= _mediumSpread
        ? EstimateConfidence.low
        : spread >= _highSpread
            ? EstimateConfidence.medium
            : EstimateConfidence.high;

    return LevelEstimate(
      level: level.toDouble(),
      confidence: confidence,
      reasons: [
        for (final id in _reasonOrder)
          if (reasons[id] != null) EstimateReason(id, reasons[id]!),
      ],
    );
  }
}
