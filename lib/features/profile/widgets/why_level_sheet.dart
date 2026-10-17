import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/profile_repository.dart';
import '../../../l10n/l10n.dart';

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
    title: l10n.pourquoiEn(formatLevel(level.level), level.sport.label.toLowerCase()),
    height: MuSheetHeight.full,
    snapPoints: const [MuSheetHeight.full],
    footer: MuButton.primary(
      label: l10n.jAiCompris,
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
              MuAiLabel(size: MuAiLabelSize.s),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Text(
                  l10n.miseAJourApresTon(l.updatedOn ?? l10n.recemment),
                  style: caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          MuLevelIndicator(
            level: l.level,
            variant: MuLevelVariant.bar,
            label: l10n.tonNiveau2(l.sport.label),
            showValue: true,
            trend: l.trend,
            trendLabel: l10n.surJours2,
            confidence: l.confidence,
            reason: l.range == null
                ? null
                : l10n.tresProbablementEntreEt(formatLevel(l.range!.$1), formatLevel(l.range!.$2)),
          ),
          const SizedBox(height: MuSpace.s5),
          Text(
            l10n.ceQueLIaA,
            style: MuType.overline.copyWith(color: c.textSecondary),
          ),
          for (final (label, weight, detail) in explanation.factors) ...[
            const SizedBox(height: MuSpace.s3),
            MuProgressBar(
              value: weight * 100,
              label: label,
              valueLabel: ltr('${(weight * 100).round()} %'),
              size: MuProgressSize.s,
              tone: MuTone.ai,
              hint: detail.isEmpty ? null : detail,
            ),
          ],
          const SizedBox(height: MuSpace.s5),
          Text(
            l10n.lesMatchsQuiLOnt,
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
          Text(l10n.pasDAccordAvecCe, style: MuType.label.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s2),
          Row(
            children: [
              MuButton.secondary(
                label: l10n.ajuster,
                leading: PhosphorIcons.slidersHorizontal(),
                onPressed: () => _adjust(context, ref),
              ),
              const SizedBox(width: MuSpace.s3),
              Flexible(
                child: MuButton.tertiary(
                  label: l10n.ceNiveauMeSembleFaux,
                  onPressed: () async {
                    await ref.read(playerProfileRepositoryProvider).contestLevel(l.sport);
                    if (context.mounted) {
                      MuToast.show(
                        context,
                        title: l10n.contestationEnvoyee,
                        description: l10n.unHumainRelitTonNiveau,
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
                  l10n.lIaPeutSeTromper,
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
      title: l10n.ajusterMonNiveau,
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
                label: l10n.tonNiveau2(level.sport.label.toLowerCase()),
                aiEstimate: level.level,
                aiNote: l10n.dApresTesMatchs(level.matches),
                onChanged: (v) => setState(() => value = v),
              ),
              const SizedBox(height: MuSpace.s3),
              Text(
                l10n.tonChoixCompteCommeUne,
                style: MuType.caption.copyWith(color: context.mu.textSecondary),
              ),
              const SizedBox(height: MuSpace.s4),
              MuButton.primary(
                label: l10n.enregistrer,
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
        MuToast.show(context, title: l10n.niveauAjusteA(formatLevel(value)));
      }
    }
  }
}
