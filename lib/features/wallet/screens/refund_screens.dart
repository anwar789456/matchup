import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../home/controllers/home_providers.dart';
import '../data/wallet_repository.dart';
import '../../../l10n/l10n.dart';

/// WAL-04 · Demander un remboursement: which payment, what happened, where to be refunded.
class RefundRequestScreen extends ConsumerStatefulWidget {
  const RefundRequestScreen({super.key});

  @override
  ConsumerState<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends ConsumerState<RefundRequestScreen> {
  String? _txId;
  RefundReason? _reason;
  RefundTarget _target = RefundTarget.balance;
  final _note = TextEditingController();
  int _photos = 0;
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send(MuTransaction tx) async {
    setState(() => _sending = true);
    final r = await ref.read(walletRepositoryProvider).requestRefund(
      transaction: tx,
      reason: _reason!,
      note: _note.text.trim(),
      target: _target,
      photos: _photos,
    );
    ref.invalidate(refundRequestsProvider);
    if (!mounted) return;
    MuToast.show(context, tone: MuToastTone.success, title: l10n.demandeEnvoyee, description: l10n.onRevientVersToiSous);
    context.pushReplacement(Routes.walletRefundStatus(r.id));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final history = ref.watch(walletHistoryProvider).value ?? const <MuTransaction>[];
    final candidates = [for (final t in history) if (t.kind == MuTransactionKind.booking && t.status == MuTransactionStatus.done) t].take(3).toList();
    final tx = candidates.where((t) => t.id == _txId).firstOrNull;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget step(int n, String title) => Row(
      children: [
        Container(width: MuSize.iconM, height: MuSize.iconM, alignment: Alignment.center, decoration: BoxDecoration(color: c.surfaceInverse, shape: BoxShape.circle), child: Text('$n', style: MuType.labelS.copyWith(color: c.textInverse))),
        const SizedBox(width: MuSpace.s2),
        Semantics(header: true, child: Text(title, style: MuType.h3.copyWith(color: c.text))),
      ],
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(title: l10n.demanderUnRemboursement, backLabel: l10n.retourAuPortefeuille, onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                Text(l10n.unSouciAvecUnPaiement, style: MuType.body.copyWith(color: c.textSecondary)),
                const SizedBox(height: MuSpace.s5),
                step(1, l10n.quelPaiement),
                const SizedBox(height: MuSpace.s3),
                MuCardSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, t) in candidates.indexed) ...[
                        if (i > 0) Divider(height: 1, thickness: 1, color: c.border, indent: MuSpace.s4),
                        Semantics(
                          button: true,
                          selected: _txId == t.id,
                          label: '${t.label}, ${t.meta}, ${formatDT(t.amount.abs())}',
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: () => setState(() => _txId = t.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
                              child: Row(
                                children: [
                                  Icon(_txId == t.id ? PhosphorIcons.radioButton(PhosphorIconsStyle.fill) : PhosphorIcons.circle(), size: MuSize.iconS, color: _txId == t.id ? c.primary : c.borderStrong),
                                  const SizedBox(width: MuSpace.s3),
                                  if (t.sport != null) MuSportIcon(t.sport!, size: MuSize.iconS),
                                  const SizedBox(width: MuSpace.s3),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.label, style: MuType.label.copyWith(color: c.text)), Text(t.meta, style: caption)])),
                                  Text(formatDT(t.amount.abs()), style: MuType.numS.copyWith(color: c.text)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s1),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: l10n.unePartieAVenirAnnule),
                          WidgetSpan(alignment: PlaceholderAlignment.middle, child: MuButton.link(label: l10n.mesMatchs, inline: true, onPressed: () => context.go(Routes.matches))),
                          TextSpan(text: l10n.leRemboursementEstAutomatique),
                        ]),
                        style: caption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s6),
                step(2, l10n.queSEstIlPasse),
                const SizedBox(height: MuSpace.s3),
                Wrap(
                  spacing: MuSpace.s2,
                  runSpacing: MuSpace.s2,
                  children: [
                    for (final r in RefundReason.values)
                      MuChip(label: r.label, kind: MuChipKind.choice, selected: _reason == r, onSelected: (_) => setState(() => _reason = r)),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                MuTextField(label: l10n.expliqueEnQuelquesMots, controller: _note, multiline: true, minLines: 2, maxLength: 240),
                const SizedBox(height: MuSpace.s4),
                MuFileUpload.dropzone(
                  label: l10n.photo,
                  title: l10n.ajouteUnePhoto,
                  linkPart: l10n.ajouteUnePhoto,
                  hint: l10n.jpgPngMoMax,
                  files: [for (var i = 0; i < _photos; i++) MuUploadFile(id: 'p$i', name: 'photo_${i + 1}.jpg', sizeBytes: 1200000)],
                  onAdd: () => setState(() => _photos++),
                  onRemove: (_) => setState(() => _photos = (_photos - 1).clamp(0, 9)),
                ),
                const SizedBox(height: MuSpace.s1),
                Text(l10n.unePhotoDuTerrainFerme, style: caption),
                const SizedBox(height: MuSpace.s6),
                step(3, l10n.ouVeuxTuEtreRembourse),
                const SizedBox(height: MuSpace.s3),
                MuRadioGroup<RefundTarget>(
                  label: l10n.destination,
                  value: _target,
                  onChanged: (v) => setState(() => _target = v),
                  options: [
                    MuRadioOption(value: RefundTarget.balance, label: l10n.surMonSoldeMatchup, description: l10n.plusRapideSousJoursOuvres),
                    MuRadioOption(value: RefundTarget.card, label: l10n.surMaCarte(tx?.meta.split(' · ').last ?? l10n.visa), description: l10n.aJoursOuvresSelonTa),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          if (tx != null)
            Row(
              children: [
                Expanded(child: Text(l10n.montantDemande(tx.label), style: caption)),
                Text(formatDT(tx.amount.abs()), style: MuType.numM.copyWith(color: c.text)),
              ],
            ),
          MuButton.primary(
            label: l10n.envoyerLaDemande,
            leading: PhosphorIcons.paperPlaneRight(),
            size: MuButtonSize.xl,
            fullWidth: true,
            loading: _sending,
            onPressed: tx != null && _reason != null && !_sending ? () => _send(tx) : null,
          ),
        ],
      ),
    );
  }
}

/// WAL-05 · Suivi du remboursement: the request's steps, what comes next, the request, support.
class RefundStatusScreen extends ConsumerWidget {
  const RefundStatusScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final r = (ref.watch(refundRequestsProvider).value ?? const <RefundRequest>[]).where((x) => x.id == requestId).firstOrNull;
    final balance = ref.watch(meProvider).value?.balance ?? 0;
    if (r == null) {
      return Scaffold(backgroundColor: c.bg, body: Center(child: MuSpinner(semanticLabel: l10n.chargement)));
    }
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final t = r.transaction;
    Widget stage(IconData icon, String title, String? date, String text, {required bool done, bool current = false}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: MuSize.controlS,
          height: MuSize.controlS,
          decoration: BoxDecoration(shape: BoxShape.circle, color: done ? c.successSoft : (current ? c.warningSoft : c.surfaceMuted)),
          child: Icon(icon, size: MuSize.iconXs, color: done ? c.successText : (current ? c.warningText : c.textSecondary)),
        ),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: MuSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text(title, style: MuType.label.copyWith(color: c.text))), if (date != null) Text(date, style: caption)]),
                Text(text, style: caption),
              ],
            ),
          ),
        ),
      ],
    );
    Widget next(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: MuSize.iconS, color: c.text),
          const SizedBox(width: MuSpace.s3),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: MuType.label.copyWith(color: c.text)), Text(text, style: caption)])),
        ],
      ),
    );
    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 64, child: Text(label, style: caption)), Expanded(child: Text(value, style: MuType.body.copyWith(color: c.text)))]),
    );
    final reviewing = r.stage.index >= RefundStage.reviewing.index;
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(title: l10n.suiviDuRemboursement, backLabel: l10n.retourAuPortefeuille, onBack: () => context.canPop() ? context.pop() : context.go(Routes.wallet)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                Semantics(
                  label: l10n.demandeDeRemboursement,
                  child: MuCardSurface(
                    child: Row(
                      children: [
                        if (t.sport != null) MuSportIcon(t.sport!, size: MuSize.iconM),
                        const SizedBox(width: MuSpace.s3),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.label, style: MuType.label.copyWith(color: c.text)), Text(t.meta, style: caption)])),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(l10n.aRembourser, style: caption),
                            Text(formatDT(r.amount), style: MuType.numL.copyWith(color: c.text)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MuSpace.s6),
                Row(
                  children: [
                    Expanded(child: Semantics(header: true, child: Text(l10n.ouEnEstTaDemande, style: MuType.h2.copyWith(color: c.text)))),
                    MuStatusBadge(status: reviewing ? MuStatus.pending : MuStatus.confirmed, label: reviewing ? l10n.enCoursDExamen : l10n.envoyee, size: MuBadgeSize.s),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                stage(PhosphorIcons.check(), l10n.demandeEnvoyee, formatDay(r.sentAt), l10n.motifRecus(r.photos > 0 ? l10n.etPhoto : ''), done: true),
                stage(PhosphorIcons.magnifyingGlass(), l10n.enCoursDExamen, r.reviewingSince == null ? null : formatDay(r.reviewingSince!), l10n.onVerifieAvecQueLe(t.label.split(' · ').last), done: r.stage == RefundStage.refunded, current: reviewing && r.stage != RefundStage.refunded),
                stage(PhosphorIcons.wallet(), r.target == RefundTarget.balance ? l10n.rembourseSurTonSolde : l10n.rembourseSurTaCarte, null, l10n.attenduSousJoursOuvres(r.target == RefundTarget.balance ? '5' : '10', formatDT(r.amount)), done: r.stage == RefundStage.refunded),
                const SizedBox(height: MuSpace.s2),
                Semantics(header: true, child: Text(l10n.etEnsuite, style: MuType.h3.copyWith(color: c.text))),
                next(PhosphorIcons.sealCheck(), l10n.demandeAcceptee, l10n.arriventSurTonSoldeMatchup(formatDT(r.amount), formatDT(balance + r.amount))),
                next(PhosphorIcons.chatText(), l10n.besoinDUnePrecision, l10n.onTEcritIciEt),
                next(PhosphorIcons.info(), l10n.demandeRefusee, l10n.onTExpliquePourquoiEt),
                const SizedBox(height: MuSpace.s5),
                Semantics(header: true, child: Text(l10n.taDemande, style: MuType.h3.copyWith(color: c.text))),
                const SizedBox(height: MuSpace.s2),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      line(l10n.motif, '${r.reason.label}${r.note.isEmpty ? '' : '\n« ${r.note} »'}'),
                      line(l10n.photo, r.photos == 0 ? l10n.aucune : l10n.photoJointe(r.photos, r.photos > 1 ? 's' : '', r.photos > 1 ? 's' : '')),
                      line(l10n.vers, r.target == RefundTarget.balance ? l10n.soldeMatchup : l10n.carte),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s5),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.uneQuestionSurTaDemande, style: MuType.label.copyWith(color: c.text)),
                      Text(l10n.lEquipeMatchupTeRepond, style: caption),
                      const SizedBox(height: MuSpace.s3),
                      MuButton.secondary(label: l10n.contacterLeSupport, leading: PhosphorIcons.chatCircleDots(), fullWidth: true, onPressed: () => showComingSoon(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [MuButton.primary(label: l10n.retourAuPortefeuille, size: MuButtonSize.xl, fullWidth: true, onPressed: () => context.go(Routes.wallet))],
      ),
    );
  }
}
