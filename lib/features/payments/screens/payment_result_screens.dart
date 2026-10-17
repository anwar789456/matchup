import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/checkout_controller.dart';
import '../widgets/checkout_widgets.dart';

/// PAY-09 · Paiement réussi: the receipt, the ticket with its QR code, calendar and share, the
/// invite card, then « Terminé ».
class PaymentSuccessScreen extends ConsumerWidget {
  const PaymentSuccessScreen({super.key});

  static const double _mark = 64;
  static const double _check = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final last = ref.watch(lastPaymentProvider);
    if (last == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(child: MuButton.primary(label: 'Accueil', onPressed: () => context.go(Routes.home))),
      );
    }
    final (req, receipt) = last;
    final me = ref.watch(meProvider).value;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    void done() => context.go(req.successRoute ?? Routes.matches);
    Widget line(String label, String value, {String? sub, bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: (strong ? MuType.labelL : MuType.body).copyWith(color: strong ? c.text : c.textSecondary))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, textAlign: TextAlign.end, style: (strong ? MuType.numXl : MuType.label).copyWith(color: c.text)),
              if (sub != null) Text(sub, style: caption),
            ],
          ),
        ],
      ),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) done();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(MuSpace.s2, MuSpace.s2, MuSpace.s4, 0),
                child: Row(
                  children: [
                    MuIconButton(icon: PhosphorIcons.x(), label: 'Fermer et voir ma réservation', size: MuIconButtonSize.l, onPressed: done),
                    const Spacer(),
                    if (req.reference != null)
                      Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Réf. '),
                          TextSpan(text: req.reference, style: MuType.numXs.copyWith(color: c.text)),
                        ]),
                        style: caption,
                      ),
                  ],
                ),
              ),
            ),
            const TestRibbon(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s6),
                children: [
                  Center(
                    child: Container(
                      width: _mark,
                      height: _mark,
                      decoration: BoxDecoration(color: c.successSoft, shape: BoxShape.circle),
                      child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: _check, color: c.successText),
                    ),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  FlowTitle(
                    'Paiement réussi',
                    centered: true,
                    lead: 'Ta part de ${formatDT(receipt.amount)} est payée. Reçu envoyé à ${me?.email ?? 'ton adresse'}.',
                  ),
                  const SizedBox(height: MuSpace.s6),
                  MuCardSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Reçu', style: MuType.h3.copyWith(color: c.text))),
                            const MuStatusBadge(status: MuStatus.paid, label: 'Payé', size: MuBadgeSize.s),
                          ],
                        ),
                        const SizedBox(height: MuSpace.s2),
                        line('N°', receipt.number),
                        line('Payé le', '${formatDay(receipt.paidAt)} ${receipt.paidAt.year} · ${formatTime(receipt.paidAt)}'),
                        line('Avec', receipt.methodLabel),
                        line('Pour', '${req.eyebrow.split(' · ').first} · ${req.title}', sub: req.subtitle),
                        Divider(height: MuSpace.s4, thickness: 1, color: c.border),
                        line('Total payé', formatDT(receipt.amount), strong: true),
                        const SizedBox(height: MuSpace.s3),
                        MuButton.secondary(label: 'Voir le reçu', leading: PhosphorIcons.fileText(), fullWidth: true, onPressed: () => showComingSoon(context)),
                      ],
                    ),
                  ),
                  if (req.reference != null) ...[
                    const SizedBox(height: MuSpace.s4),
                    MuTicket(
                      reference: req.reference!,
                      sport: req.sport,
                      venue: req.title.split(' · ').first,
                      court: req.title.split(' · ').skip(1).join(' · '),
                      date: req.subtitle.split(' · ').first,
                      time: req.subtitle.split(' · ').length > 1 ? req.subtitle.split(' · ')[1].split(' – ').first : '',
                      players: '6/10',
                      paid: formatDT(receipt.amount),
                      data: 'https://matchup.tn/r/${req.reference}',
                    ),
                    const SizedBox(height: MuSpace.s3),
                    Text('Présente ce code à l’accueil ${elideDe(req.policyVenue ?? req.title)}. Il est aussi dans Mes matchs.', textAlign: TextAlign.center, style: caption),
                    const SizedBox(height: MuSpace.s4),
                    Row(
                      children: [
                        Expanded(child: _Tile(icon: PhosphorIcons.calendarPlus(), label: 'Ajouter au calendrier', onTap: () => showComingSoon(context))),
                        const SizedBox(width: MuSpace.s3),
                        Expanded(
                          child: _Tile(
                            icon: PhosphorIcons.shareNetwork(),
                            label: 'Partager',
                            onTap: () => SharePlus.instance.share(ShareParams(text: 'https://matchup.tn/r/${req.reference}')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuSpace.s4),
                    MuCardSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('Encore 4 places', style: MuType.labelL.copyWith(color: c.text))),
                              MuToneBadge(label: '6/10', tone: MuBadgeTone.warning, icon: PhosphorIcons.clock(PhosphorIconsStyle.fill)),
                            ],
                          ),
                          Text('Ta partie publique est visible dans Explorer.', style: caption),
                          const SizedBox(height: MuSpace.s3),
                          MuButton.secondary(
                            label: 'Inviter des joueurs',
                            leading: PhosphorIcons.userPlus(),
                            fullWidth: true,
                            onPressed: () => context.push(Routes.booking(req.reference!)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: StickyActionBar(
          children: [
            MuButton.primary(label: 'Terminé', size: MuButtonSize.xl, fullWidth: true, onPressed: done),
            Text('Ta réservation est dans Mes matchs.', textAlign: TextAlign.center, style: caption),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: MuRadius.mdAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: MuSpace.s4),
          decoration: BoxDecoration(color: c.surface, borderRadius: MuRadius.mdAll, border: Border.all(color: c.border)),
          child: Column(
            children: [
              Icon(icon, size: MuSize.iconM, color: c.text),
              const SizedBox(height: MuSpace.s2),
              Text(label, style: MuType.label.copyWith(color: c.text)),
            ],
          ),
        ),
      ),
    );
  }
}

/// PAY-10 · Paiement échoué: after three refusals — the reason, the place kept 15 minutes, what
/// to do, then « Changer de moyen de paiement » or « Réessayer ».
class PaymentFailedScreen extends ConsumerWidget {
  const PaymentFailedScreen({super.key, required this.cardLabel, required this.reason});

  final String cardLabel;
  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final req = ref.watch(checkoutRequestProvider);
    final balance = ref.watch(meProvider).value?.balance ?? 0;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget tip(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: MuSize.iconS, color: c.text),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(title, style: MuType.label.copyWith(color: c.text)), Text(text, style: caption)],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s2, MuSpace.s2, MuSpace.s4, 0),
              child: Row(
                children: [
                  MuIconButton(icon: PhosphorIcons.x(), label: 'Fermer et revenir au récapitulatif', size: MuIconButtonSize.l, onPressed: () => context.pop()),
                  const Spacer(),
                  if (req?.reference != null) Text('Réf. ${req!.reference}', style: caption),
                ],
              ),
            ),
          ),
          const TestRibbon(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s6),
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: c.errorSoft, shape: BoxShape.circle),
                    child: Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.fill), size: 40, color: c.errorText),
                  ),
                ),
                const SizedBox(height: MuSpace.s3),
                FlowTitle(
                  'Le paiement a échoué',
                  centered: true,
                  lead: 'Après 3 essais, ta banque refuse toujours ta $cardLabel : ${reason ?? 'refus de la banque'}. Rien n’a été débité.',
                ),
                if (req != null) ...[
                  const SizedBox(height: MuSpace.s5),
                  MuCardSurface(
                    padding: const EdgeInsets.all(MuSpace.s3),
                    child: Row(
                      children: [
                        SizedBox.square(dimension: MuSize.controlL, child: ClipRRect(borderRadius: MuRadius.smAll, child: MuCourtArt(sport: req.sport, variant: MuCourtArtVariant.pattern))),
                        const SizedBox(width: MuSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req.title, style: MuType.label.copyWith(color: c.text)),
                              Text('${req.subtitle} · ta part ${formatDT(req.amount)}', style: caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: MuSpace.s4),
                MuBanner(
                  tone: MuBannerTone.warning,
                  icon: PhosphorIcons.hourglassMedium(),
                  title: 'Ta place est gardée 15 min',
                  detail: 'Passé ce délai, la réservation est annulée et tes 5 amis sont remboursés sur leur solde MatchUp.',
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(header: true, child: Text('Que faire ?', style: MuType.h3.copyWith(color: c.text))),
                const SizedBox(height: MuSpace.s2),
                tip(PhosphorIcons.wallet(), 'Paie avec ton solde.', 'Tes ${formatDT(balance)} couvrent ta part, sans passer par ta banque.'),
                tip(PhosphorIcons.creditCard(), 'Essaie une autre carte.', 'Ta Mastercard •••• 5454 est valable jusqu’à fin novembre.'),
                tip(PhosphorIcons.bank(), 'Appelle ta banque.', 'Le paiement en ligne est peut-être bloqué ou plafonné.'),
                const SizedBox(height: MuSpace.s3),
                Center(child: MuButton.link(label: 'Contacter le support', onPressed: () => showComingSoon(context))),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.secondary(label: 'Changer de moyen de paiement', leading: PhosphorIcons.swap(), size: MuButtonSize.l, fullWidth: true, onPressed: () => context.pop()),
          MuButton.primary(label: 'Réessayer', price: req == null ? null : formatDT(req.amount), size: MuButtonSize.xl, fullWidth: true, onPressed: () => context.pop()),
          Text('Rien ne sera débité deux fois.', textAlign: TextAlign.center, style: caption),
        ],
      ),
    );
  }
}
