import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../controllers/admin_controller.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';
import '../../../l10n/l10n.dart';

enum _Level { all, high, medium, ignored }

/// ADM-08 · Risque de churn IA: subscribers who might leave, each with the AI's reason and a
/// suggested action. The AI proposes; nothing is sent without the admin.
class AdminChurnScreen extends ConsumerStatefulWidget {
  const AdminChurnScreen({super.key});

  @override
  ConsumerState<AdminChurnScreen> createState() => _AdminChurnScreenState();
}

class _AdminChurnScreenState extends ConsumerState<AdminChurnScreen> {
  _Level _level = _Level.all;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.read(clockProvider)();
    final all = ref.watch(adminChurnProvider).value;
    final active = [
      for (final r in all ?? const <ChurnRisk>[])
        if (!r.ignored) r,
    ];
    final ignored = [
      for (final r in all ?? const <ChurnRisk>[])
        if (r.ignored) r,
    ];
    final high = active.where((r) => r.level == ChurnLevel.high).length;
    final shown = switch (_level) {
      _Level.all => active,
      _Level.high => [
        for (final r in active)
          if (r.level == ChurnLevel.high) r,
      ],
      _Level.medium => [
        for (final r in active)
          if (r.level == ChurnLevel.medium) r,
      ],
      _Level.ignored => ignored,
    };
    final premium = ref.watch(adminOverviewProvider).value?.premium ?? 180;
    final updated = DateTime(now.year, now.month, now.day, 4);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          AdminBar(
            title: l10n.risqueDeChurn,
            caption: l10n.adminFinanceAbonnesPremium,
            backLabel: l10n.retourAFinance,
            fallback: Routes.adminFinance,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, MuSpace.s2, 0, MuSpace.s12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: MuCardSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            MuAiLabel(),
                            const SizedBox(width: MuSpace.s2),
                            AdminMuted(l10n.misAJour(formatDateTime(updated))),
                          ],
                        ),
                        const SizedBox(height: MuSpace.s2),
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.abonnesPourraientPartir(active.length),
                            style: MuType.h2.copyWith(color: c.text),
                          ),
                        ),
                        const SizedBox(height: MuSpace.s2),
                        Text(
                          l10n.calculeChaqueNuitSurJours,
                          style: MuType.body.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: MuSpace.s3),
                        Row(
                          children: [
                            _Figure(value: formatDT(active.length * 19), label: l10n.parMoisEnJeu),
                            const SizedBox(width: MuSpace.s6),
                            _Figure(value: formatInt(premium), label: l10n.abonnesPremium),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MuSpace.s5),
                Semantics(
                  container: true,
                  label: l10n.niveauDeRisque,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                    child: Row(
                      children: [
                        for (final (k, label, count) in [
                          (_Level.all, l10n.tous, active.length),
                          (_Level.high, l10n.eleve, high),
                          (_Level.medium, l10n.moyen, active.length - high),
                          (_Level.ignored, l10n.ignores, ignored.length),
                        ]) ...[
                          MuChip(
                            kind: MuChipKind.choice,
                            label: label,
                            count: count == 0 || k == _Level.ignored ? null : count,
                            selected: _level == k,
                            onSelected: (_) => setState(() => _level = k),
                          ),
                          const SizedBox(width: MuSpace.s2),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MuSpace.s5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (all == null)
                        const MuSkeleton(height: 320)
                      else if (shown.isEmpty)
                        MuEmptyState(compact: true, title: l10n.personneDansCetteCategorie)
                      else
                        for (final r in shown) ...[
                          _ChurnCard(
                            key: ValueKey(r.id),
                            r: r,
                            onIgnore: (v) =>
                                ref.read(adminActionsProvider).ignoreChurn(r.id, ignored: v),
                          ),
                          const SizedBox(height: MuSpace.s4),
                        ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                        child: AdminMuted(
                          l10n.lIaPeutSeTromper2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: MuType.numL.copyWith(color: context.mu.text)),
      AdminMuted(label),
    ],
  );
}

class _ChurnCard extends StatelessWidget {
  const _ChurnCard({super.key, required this.r, required this.onIgnore});

  final ChurnRisk r;
  final ValueChanged<bool> onIgnore;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final high = r.level == ChurnLevel.high;
    return MuAiSuggestionCard(
      context: r.context,
      title: r.title,
      reason: r.reason,
      primary: MuAction(r.primary, () => showComingSoon(context)),
      primaryIcon: r.primaryMail ? PhosphorIcons.envelopeSimple() : null,
      secondary: MuAction(
        r.secondary,
        r.secondaryIgnores ? () => onIgnore(true) : () => showComingSoon(context),
      ),
      secondaryDismisses: r.secondaryIgnores,
      onDismiss: () => onIgnore(!r.ignored),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuAvatar(name: r.name, level: r.playerLevel),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: AdminTexts(title: r.name, lines: [r.line]),
              ),
              AdminScore(
                value: '${r.score} %',
                fraction: r.score / 100,
                level: high ? AdminScoreLevel.high : AdminScoreLevel.mid,
                levelLabel: high ? l10n.risqueEleve : l10n.risqueMoyen,
                width: 100,
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
            decoration: BoxDecoration(color: c.bg, borderRadius: MuRadius.smAll),
            child: Row(
              children: [
                Expanded(child: AdminMuted(l10n.matchsParSemaineSem)),
                MuSparkline(values: r.trend, size: const Size(96, 28), semanticLabel: r.trendLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
