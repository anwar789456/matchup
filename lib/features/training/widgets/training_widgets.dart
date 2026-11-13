import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// A section title (`h3`) with its optional caption and end action (« Catalogue », « Voir tout »).
class TrainingSectionHeader extends StatelessWidget {
  const TrainingSectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.action,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? caption;
  final String? action;
  final VoidCallback? onAction;

  /// Instead of [action]: « 4 semaines · 12 séances ».
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: MuSpace.s4,
        end: action == null ? MuSpace.s4 : MuSpace.s1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: MuSize.controlS),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: MuType.h3.copyWith(color: c.text)),
                  ),
                ),
                if (action != null)
                  MuButton.tertiary(label: action!, size: MuButtonSize.s, onPressed: onAction)
                else
                  ?trailing,
              ],
            ),
          ),
          if (caption != null)
            Text(caption!, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

/// An emphasis card that stays dark in both themes (CLAUDE.md rule 13): `surface-inverse` in
/// light, `night-700` + 1px `border` in Night match; its content reads the Night colours.
class TrainingDarkCard extends StatelessWidget {
  const TrainingDarkCard({
    super.key,
    required this.child,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(MuSpace.s4),
  });

  final Widget child;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: dark ? c.night700 : c.surfaceInverse,
          borderRadius: MuRadius.lgAll,
          border: dark ? Border.all(color: c.border) : null,
          boxShadow: dark ? null : MuElevation.of(context).level2,
        ),
        child: MuNightTheme(child: child),
      ),
    );
  }
}

/// A day of the week card: « lun. » over a check (done), the dashed session number (today) or
/// nothing (rest), then the date.
class WeekDayCell extends StatelessWidget {
  const WeekDayCell({
    super.key,
    required this.day,
    required this.today,
    required this.done,
    this.lesson,
  });

  final DateTime day;
  final bool today;
  final bool done;

  /// Today's session number, drawn in the dashed circle.
  final int? lesson;

  static const double _dot = 28;
  static const double _todayRing = 1.5;
  static const double _check = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final state = done
        ? l10n.entDayDone
        : lesson != null
        ? l10n.entDayToDo(lesson!)
        : l10n.entDayRest;
    final date = '${formatWeekdayLong(day)} ${day.day} ${formatMonth(day)}';
    final name = today ? l10n.entTodayDay(date) : date;
    final Widget dot = done
        ? Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: _check, color: c.onAccent),
          )
        : lesson != null
        ? CustomPaint(
            painter: DashedCirclePainter(color: c.accent),
            child: SizedBox.square(
              dimension: _dot,
              child: Center(
                child: Text('$lesson', style: MuType.numXs.copyWith(color: c.accent)),
              ),
            ),
          )
        : const SizedBox.square(dimension: _dot);
    return Semantics(
      label: l10n.entDaySemantics(name, state),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, MuSpace.s2, 0, MuSpace.s2 + MuSpace.s1 / 2),
        decoration: today
            ? BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: MuRadius.smAll,
                border: Border.all(color: c.accent, width: _todayRing),
              )
            : null,
        child: Column(
          children: [
            Text(
              today ? l10n.entTodayAbbr : formatWeekday(day),
              style: MuType.caption.copyWith(color: today ? c.text : c.textSecondary),
            ),
            const SizedBox(height: MuSpace.s1 + MuSpace.s1 / 2),
            dot,
            const SizedBox(height: MuSpace.s1 + MuSpace.s1 / 2),
            Text('${day.day}', style: MuType.numXs.copyWith(color: c.text)),
          ],
        ),
      ),
    );
  }
}

/// A 2px dashed circle (today's session to do).
class DashedCirclePainter extends CustomPainter {
  const DashedCirclePainter({required this.color, this.stroke = 2, this.dashes = 10});

  final Color color;
  final double stroke;
  final int dashes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep - math.pi / 2, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter old) => old.color != color || old.stroke != stroke;
}

/// « Impossible de charger ton entraînement » with « Réessayer ».
class TrainingRetry extends StatelessWidget {
  const TrainingRetry({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MuBanner(
    title: l10n.impossibleDeCharger2(l10n.entYourTraining),
    detail: l10n.verifieTaConnexionPuisReessaie,
    tone: MuBannerTone.warning,
    icon: PhosphorIcons.wifiSlash(),
    action: MuAction(l10n.reessayer, onRetry),
  );
}
