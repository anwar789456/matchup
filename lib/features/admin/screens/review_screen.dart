import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/admin_controller.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';
import '../../../l10n/l10n.dart';

/// ADM-10 · Revue du contenu: a full sheet over the queue — the thread, the AI's reading, the
/// reports, then « Ta décision » with its consequence. Removing, warning or suspending always
/// asks for confirmation first (« Suspendre l’auteur » goes through ADM-04).
class AdminReviewScreen extends ConsumerStatefulWidget {
  const AdminReviewScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends ConsumerState<AdminReviewScreen> {
  ModerationDecision _decision = ModerationDecision.warn;
  bool _busy = false;

  void _close() => goBack(context, Routes.adminModeration);

  static String _label(ModerationDecision d) => switch (d) {
    ModerationDecision.approve => l10n.approuverEtRepublier,
    ModerationDecision.delete => l10n.supprimerLeCommentaire,
    ModerationDecision.warn => l10n.supprimerEtAvertirLAuteur,
    ModerationDecision.suspend => l10n.suspendreLAuteur,
  };

  static String _cta(ModerationDecision d) => switch (d) {
    ModerationDecision.approve => l10n.approuverEtRepublier,
    ModerationDecision.delete => l10n.supprimerLeCommentaire,
    ModerationDecision.warn => l10n.supprimerEtAvertir,
    ModerationDecision.suspend => l10n.choisirLaDuree,
  };

  static String _consequence(ModerationDecision d, String author) => switch (d) {
    ModerationDecision.approve =>
      l10n.leCommentaireReapparaitPourTout,
    ModerationDecision.delete =>
      l10n.ilDisparaitPourToutLe(author),
    ModerationDecision.warn =>
      l10n.supprimePourToutLeMonde(author),
    ModerationDecision.suspend =>
      l10n.leCommentaireEstSupprimeTu,
  };

  Future<void> _go(ModerationReview r) async {
    final author = r.item.author ?? '';
    final d = _decision;
    if (d == ModerationDecision.suspend) {
      await context.push(Routes.adminSuspend(r.authorId, review: r.item.id));
      return;
    }
    if (d != ModerationDecision.approve) {
      final ok = await MuDialog.show<bool>(
        context,
        tone: MuDialogTone.destructive,
        icon: PhosphorIcons.trash(),
        title: d == ModerationDecision.warn
            ? l10n.supprimerEtAvertir2(author)
            : l10n.supprimerLeCommentaire2,
        description: l10n.tuNePourrasPasLe,
        consequence: _consequence(d, author),
        actions: [
          Builder(
            builder: (context) => MuButton.secondary(
              label: l10n.annuler,
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          Builder(
            builder: (context) => MuButton.destructive(
              label: _cta(d),
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    await ref.read(adminActionsProvider).decide(r.item.id, d);
    if (!mounted) return;
    context.go(Routes.adminModeration);
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: switch (d) {
        ModerationDecision.approve => l10n.commentaireRepublie,
        ModerationDecision.warn => l10n.commentaireSupprimeAverti(author),
        _ => l10n.commentaireSupprime,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = ref.watch(adminReviewProvider(widget.itemId)).value;
    final height = MediaQuery.sizeOf(context).height * MuSheetHeight.full.share;
    final author = r?.item.author ?? '';
    return Scaffold(
      backgroundColor: c.bg.withValues(alpha: 0),
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: height,
          child: MuBottomSheet(
            title: l10n.revoirLeCommentaire,
            onClose: _close,
            footer: r == null
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _consequence(_decision, author),
                          style: MuType.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s3),
                      MuButton(
                        label: _cta(_decision),
                        variant: _decision == ModerationDecision.approve
                            ? MuButtonVariant.primary
                            : MuButtonVariant.destructive,
                        size: MuButtonSize.xl,
                        fullWidth: true,
                        loading: _busy,
                        onPressed: _busy ? null : () => _go(r),
                      ),
                    ],
                  ),
            child: r == null
                ? const Padding(
                    padding: EdgeInsets.all(MuSpace.s8),
                    child: Center(child: MuSpinner()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(MuSpace.s3),
                        decoration: BoxDecoration(
                          color: c.bg,
                          borderRadius: MuRadius.mdAll,
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdminMuted(r.replyTo, maxLines: 1),
                            const SizedBox(height: MuSpace.s2),
                            Row(
                              children: [
                                MuAvatar(name: author, size: MuAvatarSize.xs),
                                const SizedBox(width: MuSpace.s2),
                                Text(author, style: MuType.label.copyWith(color: c.text)),
                                const SizedBox(width: MuSpace.s2),
                                AdminMuted(r.time),
                                const Spacer(),
                                MuStatusBadge(
                                  status: MuStatus.pending,
                                  label: l10n.masque,
                                  size: MuBadgeSize.s,
                                ),
                              ],
                            ),
                            const SizedBox(height: MuSpace.s2),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: r.before),
                                  TextSpan(
                                    text: r.flagged,
                                    style: TextStyle(backgroundColor: c.warningSoft),
                                    semanticsLabel: l10n.passageReleveParLIa(r.flagged),
                                  ),
                                  TextSpan(text: r.after),
                                ],
                              ),
                              style: MuType.bodyL.copyWith(color: c.text),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Container(
                        padding: const EdgeInsets.all(MuSpace.s3),
                        decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.smAll),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                MuAiLabel(size: MuAiLabelSize.s, onAiSurface: true),
                                const SizedBox(width: MuSpace.s2),
                                Expanded(
                                  child: Text(
                                    r.item.why,
                                    style: MuType.labelS.copyWith(color: c.aiText),
                                  ),
                                ),
                                Text(
                                  r.item.score.toStringAsFixed(2).replaceAll('.', ','),
                                  style: MuType.numM.copyWith(color: c.aiText),
                                ),
                              ],
                            ),
                            const SizedBox(height: MuSpace.s2),
                            Text(r.analysis, style: MuType.body.copyWith(color: c.aiText)),
                          ],
                        ),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Text(r.reportsTitle, style: MuType.label.copyWith(color: c.text)),
                      const SizedBox(height: 2),
                      AdminMuted(r.reportsDetail),
                      const SizedBox(height: MuSpace.s4),
                      MuRadioGroup<ModerationDecision>(
                        label: l10n.taDecision,
                        value: _decision,
                        onChanged: _busy ? null : (v) => setState(() => _decision = v),
                        options: [
                          for (final d in ModerationDecision.values)
                            MuRadioOption(value: d, label: _label(d)),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s4),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
