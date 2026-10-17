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
        AsyncError() => Center(child: MuButton.primary(label: 'Retour', onPressed: () => context.pop())),
        _ => const Center(child: MuSpinner(semanticLabel: 'Chargement')),
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
                        'Organisateur : avance les ${_pending.length} parts pour garantir le match. '
                        '${_pending.map((p) => p.name.split(' ').first).join(' et ')} te remboursent via l’app.',
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
                MuButton.primary(
                  label: 'Payer le reste',
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
      title: 'Payer le reste',
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
                    const TextSpan(text: 'Tu avances '),
                    TextSpan(text: formatDT(rest), style: MuType.numM.copyWith(color: c.text)),
                    TextSpan(text: ' pour ${_pending.map((p) => p.name).join(' et ')}. Ils pourront te rembourser via l’app.'),
                  ]),
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s4),
                Semantics(
                  label: 'Détail du montant',
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
                              Text('Parts de ${_pending.map((p) => p.name).join(' et ')}', style: MuType.label.copyWith(color: c.text)),
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
                Text('Payer avec', style: MuType.labelS.copyWith(color: c.text)),
                option(PayWith.card, PhosphorIcons.creditCard(), 'Visa •••• 4242', 'Par défaut · expire 08/27'),
                Divider(height: 1, thickness: 1, color: c.border),
                option(PayWith.balance, PhosphorIcons.wallet(), 'Solde MatchUp', '${formatDT(balance)} disponibles · il te restera ${formatDT((balance - rest).clamp(0, balance))}'),
                const SizedBox(height: MuSpace.s2),
                Row(
                  children: [
                    Icon(PhosphorIcons.arrowUUpLeft(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s1),
                    Expanded(child: Text('Ils reçoivent une demande de ${formatDT(b.share)} chacun ; leur paiement arrive sur ton solde MatchUp.', style: caption)),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                MuButton.primary(label: 'Payer ${formatDT(rest)}', size: MuButtonSize.xl, fullWidth: true, onPressed: () => Navigator.of(context, rootNavigator: true).pop(true)),
                const SizedBox(height: MuSpace.s2),
                MuButton.tertiary(label: 'Annuler', fullWidth: true, onPressed: () => Navigator.of(context, rootNavigator: true).pop(false)),
                const SizedBox(height: MuSpace.s2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s1),
                    Text('Paiement sécurisé par Stripe', style: caption),
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
        eyebrow: 'Parts avancées · réservation ${b.id}',
        title: b.title,
        subtitle: '${formatDay(b.start)} · ${b.timeRange}',
        amount: rest,
        lineLabel: 'Parts de ${_pending.map((p) => p.name.split(' ').first).join(' et ')} · ${_pending.length} × ${formatDT(b.share)}',
        sport: b.sport,
        reference: b.id,
        balanceAllowed: method == PayWith.balance,
        promoAllowed: false,
        policyVenue: b.venue,
        termsLabel: 'conditions de réservation',
        termsSuffix: '.',
        successRoute: Routes.bookingPayments(b.id!),
        onPaid: (receipt, fromBalance) async {
          await ref.read(walletActionsProvider).paid(receipt: receipt, label: 'Parts avancées · ${b.venue}', sport: b.sport, fromBalance: fromBalance);
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
                Text(p.name == Story.myName ? '${p.name} · toi' : p.name, style: MuType.label.copyWith(color: c.text)),
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
          title: 'Paiements de la partie',
          subtitle: '${b.title} · ${formatDateTime(b.start)}',
          backLabel: 'Retour à ma réservation',
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
                              Expanded(child: Text('COLLECTÉ', style: MuType.overline.copyWith(color: c.textSecondary))),
                              if (pending.isNotEmpty)
                                MuStatusBadge(status: MuStatus.pending, label: '${pending.length} parts en attente', size: MuBadgeSize.s)
                              else
                                const MuStatusBadge(status: MuStatus.paid, label: 'Tout est payé', size: MuBadgeSize.s),
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
                            label: 'Avancement des paiements',
                          ),
                          const SizedBox(height: MuSpace.s2),
                          Wrap(
                            spacing: MuSpace.s3,
                            children: [
                              Text('${paidPeople.length + (_advanced ? _pending.length : 0)} parts payées', style: caption),
                              if (pending.isNotEmpty) Text('${pending.length} en attente', style: caption),
                              if (free > 0) Text('$free place${free > 1 ? 's' : ''} libre${free > 1 ? 's' : ''}', style: caption),
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
                              Text('Tout doit être payé', style: MuType.label.copyWith(color: c.text)),
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
                                  Text('3 h avant le match', style: caption),
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
                                    TextSpan(text: 'La réservation sera annulée si tout n’est pas payé 3 h avant le match. ', style: MuType.caption.copyWith(color: c.text)),
                                    const TextSpan(text: 'Chacun serait alors remboursé sur son solde MatchUp.'),
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
                head('En attente', '${pending.length}', Text.rich(TextSpan(children: [TextSpan(text: formatDT(b.share * pending.length), style: MuType.numS.copyWith(color: c.text)), const TextSpan(text: ' à recevoir')]), style: caption)),
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
                                    MuStatusBadge(status: MuStatus.pending, label: '${formatDT(b.share)} à payer', size: MuBadgeSize.s),
                                  ],
                                ),
                              ),
                              if (_reminded.contains(p.name))
                                Row(children: [Icon(PhosphorIcons.check(), size: MuSize.iconXs, color: c.successText), const SizedBox(width: MuSpace.s1), Text(p.name.startsWith('Lina') ? 'Relancée' : 'Relancé', style: MuType.labelS.copyWith(color: c.successText))])
                              else
                                MuButton.secondary(label: 'Relancer', leading: PhosphorIcons.bellRinging(), size: MuButtonSize.s, onPressed: () => setState(() => _reminded.add(p.name))),
                            ],
                          ),
                        ),
                      const SizedBox(height: MuSpace.s2),
                      if (_reminded.length >= pending.length)
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(PhosphorIcons.check(), size: MuSize.iconXs, color: c.successText), const SizedBox(width: MuSpace.s1), Text('Rappels envoyés', style: MuType.label.copyWith(color: c.successText))])
                      else
                        MuButton.secondary(label: 'Relancer tout le monde', leading: PhosphorIcons.megaphone(), fullWidth: true, onPressed: () => setState(() => _reminded.addAll(pending.map((p) => p.name)))),
                      const SizedBox(height: MuSpace.s2),
                      Text('Notification et email avec le lien « Payer ma part · ${formatDT(b.share)} ».', textAlign: TextAlign.center, style: caption),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: MuSpace.s6),
              head('Payé', '${paidPeople.length + (_advanced ? _pending.length : 0)}', Text.rich(TextSpan(children: [TextSpan(text: formatDT(collected), style: MuType.numS.copyWith(color: c.text)), const TextSpan(text: ' reçus')]), style: caption)),
              const SizedBox(height: MuSpace.s3),
              MuCardSurface(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final p in paidPeople)
                      person(p, sub: p.name == Story.myName ? 'Organisateur' : (_joined.contains(p) ? 'A rejoint la partie publique' : null), end: const MuStatusBadge(status: MuStatus.paid, label: 'Payé', size: MuBadgeSize.s)),
                    if (_advanced)
                      for (final p in _pending) person(p, sub: 'Avancée par toi', end: const MuStatusBadge(status: MuStatus.paid, label: 'Payé', size: MuBadgeSize.s)),
                  ],
                ),
              ),
              if (free > 0) ...[
                const SizedBox(height: MuSpace.s6),
                head('Place libre', '$free', const SizedBox.shrink()),
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
                            Text('$free place${free > 1 ? 's' : ''} publique${free > 1 ? 's' : ''}', style: MuType.label.copyWith(color: c.text)),
                            Text('Le joueur qui la prend paie ${formatDT(b.share)} en rejoignant.', style: caption),
                          ],
                        ),
                      ),
                      MuButton.tertiary(label: 'Inviter', leading: PhosphorIcons.userPlus(), size: MuButtonSize.s, onPressed: () => context.push(Routes.booking(b.id!))),
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
