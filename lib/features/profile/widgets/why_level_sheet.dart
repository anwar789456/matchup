import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/profile_repository.dart';

/// PRF-03 · Pourquoi ce niveau ?: what the AI weighed, the matches that moved the level,
/// « Ajuster » (a self-assessment) and « Ce niveau me semble faux ».
Future<void> showWhyLevelSheet(
  BuildContext context,
  WidgetRef ref,
  PlayerProfile profile,
  SportLevel level,
) async {
  final explanation = await ref.read(playerProfileRepositoryProvider).explain(level.sport);
  if (!context.mounted) return;
  await MuBottomSheet.show<void>(
    context,
    title: 'Pourquoi ${formatLevel(level.level)} en ${level.sport.label.toLowerCase()} ?',
    height: MuSheetHeight.full,
    snapPoints: const [MuSheetHeight.full],
    footer: MuButton.primary(
      label: 'J’ai compris',
      size: MuButtonSize.xl,
      fullWidth: true,
      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
    ),
    child: _WhyLevel(profile: profile, level: level, explanation: explanation),
  );
}

class _WhyLevel extends ConsumerWidget {
  const _WhyLevel({required this.profile, required this.level, required this.explanation});

  final PlayerProfile profile;
  final SportLevel level;
  final LevelExplanation explanation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final l = level;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const MuAiLabel(size: MuAiLabelSize.s),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Text(
                  'Mise à jour ${l.updatedOn ?? 'récemment'}, après ton dernier match',
                  style: caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          MuLevelIndicator(
            level: l.level,
            variant: MuLevelVariant.bar,
            label: 'Ton niveau ${l.sport.label}',
            showValue: true,
            trend: l.trend,
            trendLabel: 'sur 30 jours',
            confidence: l.confidence,
            reason: l.range == null
                ? null
                : 'Très probablement entre ${formatLevel(l.range!.$1)} et '
                      '${formatLevel(l.range!.$2)}.',
          ),
          const SizedBox(height: MuSpace.s5),
          Text(
            'CE QUE L’IA A PRIS EN COMPTE',
            style: MuType.overline.copyWith(color: c.textSecondary),
          ),
          for (final (label, weight, detail) in explanation.factors) ...[
            const SizedBox(height: MuSpace.s3),
            MuProgressBar(
              value: weight * 100,
              label: label,
              valueLabel: '${(weight * 100).round()} %',
              size: MuProgressSize.s,
              tone: MuTone.ai,
              hint: detail.isEmpty ? null : detail,
            ),
          ],
          const SizedBox(height: MuSpace.s5),
          Text(
            'LES MATCHS QUI L’ONT FAIT BOUGER',
            style: MuType.overline.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s2),
          for (final (result, date, detail, delta) in explanation.matches)
            Container(
              padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: MuSize.controlS,
                    height: MuSize.controlS,
                    decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                    child: MuSportIcon(l.sport, size: MuSize.iconXs),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$result · $date', style: MuType.label.copyWith(color: c.text)),
                        Text(detail, style: caption),
                      ],
                    ),
                  ),
                  Text(
                    delta == 0 ? '0,0' : '+${formatLevel(delta)}',
                    style: MuType.numS.copyWith(color: delta > 0 ? c.successText : c.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: MuSpace.s4),
          Text('Pas d’accord avec ce niveau ?', style: MuType.label.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s2),
          Row(
            children: [
              MuButton.secondary(
                label: 'Ajuster',
                leading: PhosphorIcons.slidersHorizontal(),
                onPressed: () => _adjust(context, ref),
              ),
              const SizedBox(width: MuSpace.s3),
              Flexible(
                child: MuButton.tertiary(
                  label: 'Ce niveau me semble faux',
                  onPressed: () async {
                    await ref.read(playerProfileRepositoryProvider).contestLevel(l.sport);
                    if (context.mounted) {
                      MuToast.show(
                        context,
                        title: 'Contestation envoyée',
                        description: 'Un humain relit ton niveau sous 48 h.',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Row(
            children: [
              Icon(PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s1),
              Expanded(
                child: Text(
                  'L’IA peut se tromper. Un humain relit chaque contestation.',
                  style: caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _adjust(BuildContext context, WidgetRef ref) async {
    var value = level.level;
    final saved = await MuBottomSheet.show<bool>(
      context,
      title: 'Ajuster mon niveau',
      height: MuSheetHeight.auto,
      child: StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuLevelSlider(
                value: value,
                label: 'Ton niveau ${level.sport.label.toLowerCase()}',
                aiEstimate: level.level,
                aiNote: 'd’après tes ${level.matches} matchs',
                onChanged: (v) => setState(() => value = v),
              ),
              const SizedBox(height: MuSpace.s3),
              Text(
                'Ton choix compte comme une auto-évaluation : tes 3 prochains matchs le '
                'confirmeront.',
                style: MuType.caption.copyWith(color: context.mu.textSecondary),
              ),
              const SizedBox(height: MuSpace.s4),
              MuButton.primary(
                label: 'Enregistrer',
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      await ref.read(playerProfileRepositoryProvider).adjustLevel(level.sport, value);
      if (context.mounted) {
        MuToast.show(context, title: 'Niveau ajusté à ${formatLevel(value)}');
      }
    }
  }
}
