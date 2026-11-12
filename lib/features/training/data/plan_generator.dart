import '../../common/data/story_data.dart';
import 'training_models.dart';
import 'training_story.dart';

/// The AI weekly plan, faked until the assistant exists (phase 18): whatever the request, the
/// week of lun. 19 oct. as designed (ENT-07) — session 6 of Bandeja on Monday, light placement
/// on Wednesday before the 21h00 match, 10 min of recovery after Saturday's tournament — with
/// the request's duration, and the program session swapped for an AI one when it is left out.
abstract final class PlanGenerator {
  static TrainingPlan generate(PlanRequest r, DateTime now) {
    final monday = DateTime(2026, 10, 19);
    DateTime at(int day, int hour, [int minute = 0]) => DateTime(2026, 10, day, hour, minute);
    final match = Story.myBooking;
    final next = TrainingStory.bandeja.lesson(6);
    final second = r.goals.length > 1 ? r.goals.elementAt(1) : PlanGoal.endurance;
    final items = <PlanItem>[
      if (r.includeProgram)
        PlanItem(
          kind: PlanItemKind.program,
          start: at(19, 19),
          minutes: next.minutes,
          title: 'Séance ${next.index} · ${next.title}',
          calendarLabel: TrainingStory.bandeja.shortTitle,
          details: '${next.minutes} min · ${next.exercises.length} exercices · Coach Karim J.',
        )
      else
        PlanItem(
          kind: PlanItemKind.ai,
          start: at(19, 19),
          minutes: r.minutes,
          goal: second,
          tag: '${_names[second]} · légère',
          title: _titles[second]!,
          details: '${r.minutes} min · 3 exercices',
        ),
      PlanItem(
        kind: PlanItemKind.ai,
        start: at(21, 18, 30),
        minutes: r.minutes,
        goal: r.goals.firstOrNull ?? PlanGoal.placement,
        tag: '${_names[r.goals.firstOrNull ?? PlanGoal.placement]} · légère',
        title: _titles[r.goals.firstOrNull ?? PlanGoal.placement]!,
        details:
            '${r.minutes} min · 3 exercices · avancée à 18h30 car tu joues à ${match.venue} à 21h00',
      ),
      PlanItem(
        kind: PlanItemKind.match,
        start: match.start,
        minutes: 60,
        title: '${match.venue} · Foot 5 vs 5',
      ),
      PlanItem(
        kind: PlanItemKind.tournament,
        start: at(24, 10),
        minutes: 330,
        title: 'Padel Masters Lac 2 · matchs à 10h00 et 15h30',
      ),
      PlanItem(
        kind: PlanItemKind.recovery,
        start: at(24, 19),
        minutes: 10,
        tag: 'Récupération · 10 min',
        title: 'Étirements après le tournoi',
        details: '10 min · jambes et épaules, après tes matchs de 10h00 et 15h30',
      ),
      PlanItem(
        kind: PlanItemKind.tournament,
        start: at(25, 11),
        minutes: 90,
        title: 'Padel Masters Lac 2 · match à 11h00',
      ),
    ];
    return TrainingPlan(
      request: r,
      weekStart: monday,
      generatedAt: now,
      items: items,
      reason:
          'ton placement au filet revient dans 3 de tes 9 avis de coéquipiers : 2 séances '
          'dessus, dont la séance 6 de ton programme, et allégé avant ton tournoi du week-end : '
          'samedi, 10 min de récupération seulement. L’endurance revient la semaine prochaine.',
    );
  }

  /// How the AI names a goal in a session's tag.
  static const _names = {
    PlanGoal.placement: 'Placement',
    PlanGoal.endurance: 'Endurance',
    PlanGoal.service: 'Service',
    PlanGoal.retour: 'Retour',
    PlanGoal.volee: 'Volée',
    PlanGoal.bandeja: 'Bandeja',
    PlanGoal.vitesse: 'Vitesse',
  };

  /// The AI session proposed for each goal.
  static const _titles = {
    PlanGoal.placement: 'Placement au filet, sans sauter',
    PlanGoal.endurance: 'Fractionné court, 30/30',
    PlanGoal.service: 'Service à la vitre',
    PlanGoal.retour: 'Retours dans les pieds',
    PlanGoal.volee: 'Volées croisées',
    PlanGoal.bandeja: 'Bandeja croisée sur lancer',
    PlanGoal.vitesse: 'Appuis et départs rapides',
  };
}
