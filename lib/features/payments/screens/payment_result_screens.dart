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
import 'receipt_screen.dart';
import '../../../l10n/l10n.dart';

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
        body: Center(child: MuButton.primary(label: l10n.accueil, onPressed: () => context.go(Routes.home))),
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
                    MuIconButton(icon: PhosphorIcons.x(), label: l10n.fermerEtVoirMaReservation, size: MuIconButtonSize.l, onPressed: done),
                    const Spacer(),
                    if (req.reference != null)
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: l10n.ref2),
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
                    l10n.paiementReussi,
                    centered: true,
                    lead: l10n.taPartDeEstPayee2(formatDT(receipt.amount), me?.email ?? l10n.tonAdresse),
                  ),
                  const SizedBox(height: MuSpace.s6),
                  MuCardSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(l10n.recu, style: MuType.h3.copyWith(color: c.text))),
                            MuStatusBadge(status: MuStatus.paid, label: l10n.paye, size: MuBadgeSize.s),
                          ],
                        ),
                        const SizedBox(height: MuSpace.s2),
                        line('N°', receipt.number),
                        line(l10n.payeLe, '${formatDay(receipt.paidAt)} ${receipt.paidAt.year} · ${formatTime(receipt.paidAt)}'),
                        line(l10n.avec, receipt.methodLabel),
                        line(l10n.pour, '${req.eyebrow.split(' · ').first} · ${req.title}', sub: req.subtitle),
                        Divider(height: MuSpace.s4, thickness: 1, color: c.border),
                        line(l10n.totalPaye, formatDT(receipt.amount), strong: true),
                        const SizedBox(height: MuSpace.s3),
                        MuButton.secondary(label: l10n.voirLeRecu, leading: PhosphorIcons.fileText(), fullWidth: true, onPressed: () => context.push(Routes.receipt, extra: receiptFromPayment(req, receipt))),
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
                      players: req.lineup == null ? '' : '${req.lineup!.$1}/${req.lineup!.$2}',
                      paid: formatDT(receipt.amount),
                      data: 'https://matchup.tn/r/${req.reference}',
                    ),
                    const SizedBox(height: MuSpace.s3),
                    Text(l10n.presenteCeCodeAL(elideDe(req.policyVenue ?? req.title)), textAlign: TextAlign.center, style: caption),
                    const SizedBox(height: MuSpace.s4),
                    Row(
                      children: [
                        Expanded(child: _Tile(icon: PhosphorIcons.calendarPlus(), label: l10n.ajouterAuCalendrier, onTap: () => showComingSoon(context))),
                        const SizedBox(width: MuSpace.s3),
                        Expanded(
                          child: _Tile(
                            icon: PhosphorIcons.shareNetwork(),
                            label: l10n.partager,
                            onTap: () => SharePlus.instance.share(ShareParams(text: 'https://matchup.tn/r/${req.reference}')),
                          ),
                        ),
                      ],
                    ),
                    if (req.lineup != null && req.lineup!.$1 < req.lineup!.$2) ...[
                    const SizedBox(height: MuSpace.s4),
                    MuCardSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(l10n.encorePlaces(req.lineup!.$2 - req.lineup!.$1), style: MuType.labelL.copyWith(color: c.text))),
                              MuStatusBadge(status: MuStatus.pending, label: '${req.lineup!.$1}/${req.lineup!.$2}', size: MuBadgeSize.s),
                            ],
                          ),
                          Text(req.publicGame ? l10n.taPartiePubliqueEstVisible : l10n.inviteTesAmisPourCompleter, style: caption),
                          const SizedBox(height: MuSpace.s3),
                          MuButton.secondary(
                            label: l10n.inviterDesJoueurs,
                            leading: PhosphorIcons.userPlus(),
                            fullWidth: true,
                            onPressed: () => context.push(Routes.bookingInvitesAfter),
                          ),
                        ],
                      ),
                    ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: StickyActionBar(
          children: [
            MuButton.primary(label: l10n.termine, size: MuButtonSize.xl, fullWidth: true, onPressed: done),
            Text(l10n.taReservationEstDansMes, textAlign: TextAlign.center, style: caption),
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
                  MuIconButton(icon: PhosphorIcons.x(), label: l10n.fermerEtRevenirAuRecapitulatif, size: MuIconButtonSize.l, onPressed: () => context.pop()),
                  const Spacer(),
                  if (req?.reference != null) Text(l10n.ref('${req!.reference}'), style: caption),
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
                  l10n.lePaiementAEchoue,
                  centered: true,
                  lead: l10n.apresEssaisTaBanqueRefuse(cardLabel, reason ?? l10n.refusDeLaBanque),
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
                              Text(l10n.taPart5(req.subtitle, formatDT(req.amount)), style: caption),
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
                  title: l10n.taPlaceEstGardeeMin,
                  detail: l10n.passeCeDelaiLaReservation,
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(header: true, child: Text(l10n.queFaire, style: MuType.h3.copyWith(color: c.text))),
                const SizedBox(height: MuSpace.s2),
                tip(PhosphorIcons.wallet(), l10n.paieAvecTonSolde, l10n.tesCouvrentTaPartSans(formatDT(balance))),
                tip(PhosphorIcons.creditCard(), l10n.essaieUneAutreCarte, l10n.taMastercardEstValableJusqu),
                tip(PhosphorIcons.bank(), l10n.appelleTaBanque, l10n.lePaiementEnLigneEst),
                const SizedBox(height: MuSpace.s3),
                Center(child: MuButton.link(label: l10n.contacterLeSupport, onPressed: () => showComingSoon(context))),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.secondary(label: l10n.changerDeMoyenDePaiement, leading: PhosphorIcons.swap(), size: MuButtonSize.l, fullWidth: true, onPressed: () => context.pop()),
          MuButton.primary(label: l10n.reessayer, price: req == null ? null : formatDT(req.amount), size: MuButtonSize.xl, fullWidth: true, onPressed: () => context.pop()),
          Text(l10n.rienNeSeraDebiteDeux, textAlign: TextAlign.center, style: caption),
        ],
      ),
    );
  }
}
