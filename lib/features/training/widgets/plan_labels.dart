import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../data/training_models.dart';

/// Labels and icons of the AI plan's choices (ENT-06) and entries (ENT-07).

String planGoalLabel(PlanGoal g) => switch (g) {
  PlanGoal.placement => l10n.entGoalPlacement,
  PlanGoal.endurance => l10n.entGoalEndurance,
  PlanGoal.service => l10n.entGoalService,
  PlanGoal.retour => l10n.entGoalReturn,
  PlanGoal.volee => l10n.entGoalVolley,
  PlanGoal.bandeja => l10n.entGoalBandeja,
  PlanGoal.vitesse => l10n.entGoalSpeed,
};

/// ENT-06 draws an icon on « Placement » and « Endurance » only.
IconData? planGoalIcon(PlanGoal g) => switch (g) {
  PlanGoal.placement => PhosphorIcons.crosshair(),
  PlanGoal.endurance => PhosphorIcons.personSimpleRun(),
  _ => null,
};

String dayMomentLabel(DayMoment m) => switch (m) {
  DayMoment.morning => l10n.entMorning,
  DayMoment.noon => l10n.entNoon,
  DayMoment.evening => l10n.entEvening,
};

IconData dayMomentIcon(DayMoment m) => switch (m) {
  DayMoment.morning => PhosphorIcons.sunHorizon(),
  DayMoment.noon => PhosphorIcons.sun(),
  DayMoment.evening => PhosphorIcons.moon(),
};

String intensityLabel(PlanIntensity i) => switch (i) {
  PlanIntensity.soft => l10n.entIntensitySoft,
  PlanIntensity.moderate => l10n.entIntensityModerate,
  PlanIntensity.intense => l10n.entIntensityHigh,
};

String intensityCaption(PlanIntensity i) => switch (i) {
  PlanIntensity.soft => l10n.entIntensitySoftCaption,
  PlanIntensity.moderate => l10n.entIntensityModerateCaption,
  PlanIntensity.intense => l10n.entIntensityHighCaption,
};

/// The calendar colour of an entry: programme (info), AI (ai), match (success), tournament
/// (warning) — always with its icon and the legend's label.
MuTone planItemTone(PlanItemKind k) => switch (k) {
  PlanItemKind.program => MuTone.info,
  PlanItemKind.ai || PlanItemKind.recovery => MuTone.ai,
  PlanItemKind.match => MuTone.success,
  PlanItemKind.tournament => MuTone.warning,
};

IconData planItemIcon(PlanItem i) => switch (i.kind) {
  PlanItemKind.program => PhosphorIcons.barbell(),
  PlanItemKind.ai => i.goal == PlanGoal.endurance
      ? PhosphorIcons.personSimpleRun()
      : PhosphorIcons.crosshair(),
  PlanItemKind.recovery => PhosphorIcons.heart(),
  PlanItemKind.match => PhosphorIcons.soccerBall(),
  PlanItemKind.tournament => PhosphorIcons.trophy(),
};
