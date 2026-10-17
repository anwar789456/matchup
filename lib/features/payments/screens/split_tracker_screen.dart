import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../matches/controllers/matches_providers.dart';
import '../../matches/data/bookings_repository.dart';
import '../../wallet/data/wallet_repository.dart';
import '../controllers/checkout_controller.dart';
import '../data/payment_repository.dart';
import '../../../l10n/l10n.dart';

/// PAY-11 · Suivi des paiements: collected so far, the deadline (3 h before), who still owes,
/// reminders, who paid, the open place, and « Payer le reste » (PAY-12).
class SplitTrackerScreen extends ConsumerStatefulWidget {
  const SplitTrackerScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<SplitTrackerScreen> createState() => _SplitTrackerScreenState();
}

class _SplitTrackerScreenState extends ConsumerState<SplitTrackerScreen> {
  final _reminded = <String>{};
  bool _advanced = false;

  // STORY-DATA PAY-11: Ines joined the public game; Lina and Rami still owe.
  static const _joined = [Story.ines];
  static const _pending = [Story.lina, Story.rami];

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final details = ref.watch(bookingDetailsProvider(widget.bookingId));
    return Scaffold(
      backgroundColor: c.bg,
      body: switch (details) {
        AsyncData(:final value) => _body(context, value),
        AsyncError() => Center(child: MuButton.primary(label: l10n.retour, onPressed: () => context.pop())),
        _ => Center(child: MuSpinner(semanticLabel: l10n.chargement)),
      },
      bottomNavigationBar: details.value == null || _advanced
          ? null
          : StickyActionBar(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(PhosphorIcons.handCoins(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.organisateurAvanceLesPartsPour(_pending.length, _pending.map((p) => p.name.split(' ').first).join(' et ')),
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
                MuButton.primary(
                  label: l10n.payerLeReste,
                  price: formatDT(details.value!.booking.share * _pending.length),
                  size: MuButtonSize.xl,
                  fullWidth: true,
                  onPressed: () => _payRest(details.value!),
                ),
              ],
            ),
    );
  }

  /// PAY-12 · Payer le reste.
  Future<void> _payRest(BookingDetails d) async {
    final b = d.booking;
    final rest = b.share * _pending.length;
    final balance = ref.read(meProvider).value?.balance ?? 0;
    var method = PayWith.card;
    final go = await MuBottomSheet.show<bool>(
      context,
      title: l10n.payerLeReste,
      height: MuSheetHeight.auto,
      child: StatefulBuilder(
        builder: (context, setState) {
          final c = context.mu;
          final caption = MuType.caption.copyWith(color: c.textSecondary);
          Widget option(PayWith v, IconData icon, String title, String sub) => Semantics(
            button: true,
            selected: method == v,
            label: '$title, $sub',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => setState(() => method = v),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
                child: Row(
                  children: [
                    Icon(method == v ? PhosphorIcons.radioButton(PhosphorIconsStyle.fill) : PhosphorIcons.circle(), size: MuSize.iconS, color: method == v ? c.primary : c.borderStrong),
                    const SizedBox(width: MuSpace.s3),
                    Icon(icon, size: MuSize.iconM, color: c.text),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(title, style: MuType.label.copyWith(color: c.text)), Text(sub, style: caption)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: l10n.tuAvances),
                    TextSpan(text: formatDT(rest), style: MuType.numM.copyWith(color: c.text)),
                    TextSpan(text: l10n.pourIlsPourrontTeRembourser(_pending.map((p) => p.name).join(' et '))),
                  ]),
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s4),
                Semantics(
                  label: l10n.detailDuMontant,
                  child: Container(
                    padding: const EdgeInsets.all(MuSpace.s3),
                    decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                    child: Row(
                      children: [
                        const MuAvatarStack(people: _pending, size: MuAvatarSize.xs),
                        const SizedBox(width: MuSpace.s2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.partsDe(_pending.map((p) => p.name).join(' et ')), style: MuType.label.copyWith(color: c.text)),
                              Text('${_pending.length} × ${formatDT(b.share)}', style: caption),
                            ],
                          ),
                        ),
                        Text(formatDT(rest), style: MuType.numM.copyWith(color: c.text)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MuSpace.s3),
                Text(l10n.payerAvec, style: MuType.labelS.copyWith(color: c.text)),
                option(PayWith.card, PhosphorIcons.creditCard(), l10n.visa, l10n.parDefautExpire),
                Divider(height: 1, thickness: 1, color: c.border),
                option(PayWith.balance, PhosphorIcons.wallet(), l10n.soldeMatchup, l10n.disponiblesIlTeRestera(formatDT(balance), formatDT((balance - rest).clamp(0, balance)))),
                const SizedBox(height: MuSpace.s2),
                Row(
                  children: [
                    Icon(PhosphorIcons.arrowUUpLeft(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s1),
                    Expanded(child: Text(l10n.ilsRecoiventUneDemandeDe(formatDT(b.share)), style: caption)),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                MuButton.primary(label: l10n.payer2(formatDT(rest)), size: MuButtonSize.xl, fullWidth: true, onPressed: () => Navigator.of(context, rootNavigator: true).pop(true)),
                const SizedBox(height: MuSpace.s2),
                MuButton.tertiary(label: l10n.annuler, fullWidth: true, onPressed: () => Navigator.of(context, rootNavigator: true).pop(false)),
                const SizedBox(height: MuSpace.s2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s1),
                    Text(l10n.paiementSecuriseParStripe, style: caption),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (go != true || !mounted) return;
    ref.read(checkoutRequestProvider.notifier).start(
      CheckoutRequest(
        kind: CheckoutKind.advance,
        eyebrow: l10n.partsAvanceesReservation('${b.id}'),
        title: b.title,
        subtitle: '${formatDay(b.start)} · ${b.timeRange}',
        amount: rest,
        lineLabel: l10n.partsDe2(_pending.map((p) => p.name.split(' ').first).join(' et '), _pending.length, formatDT(b.share)),
        sport: b.sport,
        reference: b.id,
        balanceAllowed: method == PayWith.balance,
        promoAllowed: false,
        policyVenue: b.venue,
        termsLabel: l10n.conditionsDeReservation,
        termsSuffix: '.',
        successRoute: Routes.bookingPayments(b.id!),
        onPaid: (receipt, fromBalance) async {
          await ref.read(walletActionsProvider).paid(receipt: receipt, label: l10n.partsAvancees(b.venue), sport: b.sport, fromBalance: fromBalance);
          if (mounted) setState(() => _advanced = true);
        },
      ),
    );
    context.push(Routes.checkout);
  }

  Widget _body(BuildContext context, BookingDetails d) {
    final c = context.mu;
    final b = d.booking;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final paidPeople = [...b.players, ..._joined];
    final pending = _advanced ? const <MuPerson>[] : _pending;
    final collected = b.share * (paidPeople.length + (_advanced ? _pending.length : 0));
    final deadline = b.start.subtract(const Duration(hours: 3));
    final free = d.spotsTotal - paidPeople.length - _pending.length;

    Widget head(String title, String count, Widget end) => Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text.rich(TextSpan(children: [TextSpan(text: title), TextSpan(text: ' · $count', style: MuType.h2.copyWith(color: c.textSecondary))]), style: MuType.h2.copyWith(color: c.text)),
          ),
        ),
        end,
      ],
    );
    Widget person(MuPerson p, {String? sub, Widget? end}) => Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: Row(
        children: [
          MuAvatar(name: p.name, size: MuAvatarSize.s),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name == Story.myName ? l10n.toi2(p.name) : p.name, style: MuType.label.copyWith(color: c.text)),
                if (sub != null) Text(sub, style: caption),
              ],
            ),
          ),
          ?end,
        ],
      ),
    );

    return Column(
      children: [
        MuTopAppBar.compact(
          title: l10n.paiementsDeLaPartie,
          subtitle: '${b.title} · ${formatDateTime(b.start)}',
          backLabel: l10n.retourAMaReservation,
          onBack: () => context.pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
            children: [
              MuCardSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(MuSpace.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(l10n.collecte, style: MuType.overline.copyWith(color: c.textSecondary))),
                              if (pending.isNotEmpty)
                                MuStatusBadge(status: MuStatus.pending, label: l10n.partsEnAttente(pending.length), size: MuBadgeSize.s)
                              else
                                MuStatusBadge(status: MuStatus.paid, label: l10n.toutEstPaye, size: MuBadgeSize.s),
                            ],
                          ),
                          const SizedBox(height: MuSpace.s1),
                          Text.rich(TextSpan(children: [TextSpan(text: formatDT(collected), style: MuType.numXl.copyWith(color: c.text)), TextSpan(text: ' sur ${formatDT(d.courtPrice)}', style: MuType.body.copyWith(color: c.textSecondary))])),
                          const SizedBox(height: MuSpace.s3),
                          MuProgressBar(
                            variant: MuProgressVariant.spots,
                            size: MuProgressSize.s,
                            value: paidPeople.length.toDouble() + (_advanced ? _pending.length : 0),
                            pending: pending.length.toDouble(),
                            max: d.spotsTotal.toDouble(),
                            showValue: false,
                            label: l10n.avancementDesPaiements,
                          ),
                          const SizedBox(height: MuSpace.s2),
                          Wrap(
                            spacing: MuSpace.s3,
                            children: [
                              Text(l10n.partsPayees(paidPeople.length + (_advanced ? _pending.length : 0)), style: caption),
                              if (pending.isNotEmpty) Text(l10n.enAttente2(pending.length), style: caption),
                              if (free > 0) Text(l10n.placeLibre2(free, free > 1 ? 's' : '', free > 1 ? 's' : ''), style: caption),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(MuSpace.s4),
                      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(MuRadius.md))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(PhosphorIcons.clock(), size: MuSize.iconS, color: c.textSecondary),
                              const SizedBox(width: MuSpace.s2),
                              Text(l10n.toutDoitEtrePaye, style: MuType.label.copyWith(color: c.text)),
                            ],
                          ),
                          const SizedBox(height: MuSpace.s2),
                          Row(
                            children: [
                              Expanded(child: MuCountdown(endsAt: deadline, format: MuCountdownFormat.relative, size: MuCountdownSize.m, urgentAfter: const Duration(hours: 1))),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formatDateTime(deadline), style: MuType.label.copyWith(color: c.text)),
                                  Text(l10n.hAvantLeMatch, style: caption),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: MuSpace.s2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill), size: MuSize.iconXs, color: c.warningText),
                              const SizedBox(width: MuSpace.s2),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(text: l10n.laReservationSeraAnnuleeSi, style: MuType.caption.copyWith(color: c.text)),
                                    TextSpan(text: l10n.chacunSeraitAlorsRembourseSur),
                                  ]),
                                  style: caption,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: MuSpace.s6),
                head(l10n.enAttente, '${pending.length}', Text.rich(TextSpan(children: [TextSpan(text: formatDT(b.share * pending.length), style: MuType.numS.copyWith(color: c.text)), TextSpan(text: l10n.aRecevoir)]), style: caption)),
                const SizedBox(height: MuSpace.s3),
                MuCardSurface(
                  padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, p) in pending.indexed)
                        Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
                          decoration: i == 0 ? null : BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                          child: Row(
                            children: [
                              MuAvatar(name: p.name, size: MuAvatarSize.s),
                              const SizedBox(width: MuSpace.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: MuType.label.copyWith(color: c.text)),
                                    MuStatusBadge(status: MuStatus.pending, label: l10n.aPayer(formatDT(b.share)), size: MuBadgeSize.s),
                                  ],
                                ),
                              ),
                              if (_reminded.contains(p.name))
                                Row(children: [Icon(PhosphorIcons.check(), size: MuSize.iconXs, color: c.successText), const SizedBox(width: MuSpace.s1), Text(p.name.startsWith('Lina') ? l10n.relancee : l10n.relance, style: MuType.labelS.copyWith(color: c.successText))])
                              else
                                MuButton.secondary(label: l10n.relancer, leading: PhosphorIcons.bellRinging(), size: MuButtonSize.s, onPressed: () => setState(() => _reminded.add(p.name))),
                            ],
                          ),
                        ),
                      const SizedBox(height: MuSpace.s2),
                      if (_reminded.length >= pending.length)
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(PhosphorIcons.check(), size: MuSize.iconXs, color: c.successText), const SizedBox(width: MuSpace.s1), Text(l10n.rappelsEnvoyes, style: MuType.label.copyWith(color: c.successText))])
                      else
                        MuButton.secondary(label: l10n.relancerToutLeMonde, leading: PhosphorIcons.megaphone(), fullWidth: true, onPressed: () => setState(() => _reminded.addAll(pending.map((p) => p.name)))),
                      const SizedBox(height: MuSpace.s2),
                      Text(l10n.notificationEtEmailAvecLe(formatDT(b.share)), textAlign: TextAlign.center, style: caption),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: MuSpace.s6),
              head(l10n.paye, '${paidPeople.length + (_advanced ? _pending.length : 0)}', Text.rich(TextSpan(children: [TextSpan(text: formatDT(collected), style: MuType.numS.copyWith(color: c.text)), TextSpan(text: l10n.recus)]), style: caption)),
              const SizedBox(height: MuSpace.s3),
              MuCardSurface(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final p in paidPeople)
                      person(p, sub: p.name == Story.myName ? 'Organisateur' : (_joined.contains(p) ? l10n.aRejointLaPartiePublique : null), end: MuStatusBadge(status: MuStatus.paid, label: l10n.paye, size: MuBadgeSize.s)),
                    if (_advanced)
                      for (final p in _pending) person(p, sub: l10n.avanceeParToi, end: MuStatusBadge(status: MuStatus.paid, label: l10n.paye, size: MuBadgeSize.s)),
                  ],
                ),
              ),
              if (free > 0) ...[
                const SizedBox(height: MuSpace.s6),
                head(l10n.placeLibre, '$free', const SizedBox.shrink()),
                const SizedBox(height: MuSpace.s3),
                MuCardSurface(
                  child: Row(
                    children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.borderStrong)), child: Icon(PhosphorIcons.plus(), size: MuSize.iconXs, color: c.textSecondary)),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.placePublique(free, free > 1 ? 's' : '', free > 1 ? 's' : ''), style: MuType.label.copyWith(color: c.text)),
                            Text(l10n.leJoueurQuiLaPrend(formatDT(b.share)), style: caption),
                          ],
                        ),
                      ),
                      MuButton.tertiary(label: l10n.inviter2, leading: PhosphorIcons.userPlus(), size: MuButtonSize.s, onPressed: () => context.push(Routes.booking(b.id!))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
