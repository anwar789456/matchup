import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../home/controllers/home_providers.dart';
import '../../matches/data/bookings_repository.dart';
import '../../payments/controllers/checkout_controller.dart';
import '../../venue/data/venue_details.dart';
import '../../venue/widgets/venue_widgets.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_scaffold.dart';
import '../../../l10n/l10n.dart';

/// BKG-04 · Réservation 3/3, récapitulatif: the slot and the game, who pays what (« Chacun paie sa
/// part » or « Je paie tout »), the balance, the price detail and the cancellation policy, then
/// « Payer ma part », which opens the checkout (PAY-01).
class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  ConsumerState<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  bool _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final draft = ref.read(bookingProvider);
      final slot = draft.slot!;
      final reference = await ref.read(bookingsRepositoryProvider).nextReference();
      if (!mounted) return;
      final v = slot.venue;
      final public = draft.type == BookingType.public;
      final share = draft.split == PaymentSplit.share;
      final players = public ? draft.players : draft.capacity;
      final hours = slot.end.difference(slot.start).inMinutes / 60;
      final format = v.venue.sport == MuSport.football ? l10n.foot(v.format.replaceAll(' contre ', ' vs ')) : v.format;
      ref.read(checkoutRequestProvider.notifier).start(
        CheckoutRequest(
          kind: CheckoutKind.share,
          eyebrow: l10n.reservation(share ? l10n.taPart : l10n.leTerrain2, reference),
          title: slot.title,
          subtitle: '${formatDay(slot.start)} · ${slot.timeRange} · $format',
          amount: draft.amount,
          lineLabel: share ? l10n.taPartJoueurSur(players) : l10n.leTerrainJoueurs(players),
          sport: v.venue.sport,
          reference: reference,
          policy: (slot.start.subtract(VenueDetails.freeUntil), slot.start.subtract(VenueDetails.halfUntil)),
          policyVenue: v.venue.name,
          spotsLine: share ? l10n.taPartSur(formatDT(draft.share), formatDT(slot.price)) : null,
          detailRows: [
            (
              l10n.quoi,
              l10n.partDeReservation,
              public
                  ? l10n.partiePublique2(draft.gender.label.toLowerCase(), formatLevel(draft.level.start), formatLevel(draft.level.end))
                  : l10n.partiePrivee,
            ),
            (l10n.ou, v.venue.name, v.street),
            (l10n.terrain2, slot.court.name, '${v.surface[0].toUpperCase()}${v.surface.substring(1)} · ${slot.court.description.toLowerCase()}'),
            (
              l10n.quand,
              '${formatDay(slot.start)} · ${slot.timeRange}',
              '${formatAmount(hours)} h${slot.peak ? l10n.heureDePointe : ''}',
            ),
            (l10n.joueurs, '${draft.team}/$players', public ? l10n.placesEncoreOuvertes(players - draft.team) : l10n.partieEntreAmis),
          ],
          lineup: (draft.team, players),
          publicGame: public && draft.visibility == GameVisibility.everyone,
          successRoute: Routes.booking(reference),
          onPaid: (receipt, fromBalance) async {
            await ref.read(bookingProvider.notifier).completePaid(receipt, fromBalance, reference: reference);
          },
        ),
      );
      context.push(Routes.checkout);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final booking = ref.read(bookingProvider.notifier);
    final draft = ref.watch(bookingProvider);
    final me = ref.watch(meProvider).value;
    final balance = me?.balance ?? 0;
    final used = booking.balanceUsed(balance);
    final due = draft.amount - used;
    final share = draft.split == PaymentSplit.share;
    final cta = due == 0 ? 'Payer avec mon solde' : (share ? l10n.payerMaPart : l10n.payerLeTerrain);

    return BookingStepScaffold(
      step: 3,
      title: l10n.recapitulatif,
      gap: MuSpace.s6 + MuSpace.s1,
      bottomBar: [
        MuButton.primary(
          label: cta,
          leading: PhosphorIcons.lockSimple(),
          price: formatDT(due == 0 ? draft.amount : due),
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _paying,
          onPressed: _paying ? null : _pay,
        ),
      ],
      body: (context, d, slot) {
        final friends = d.invited.length;
        final public = d.type == BookingType.public;
        final team = [MuPerson(me?.displayName ?? l10n.moi), for (final n in d.invited) MuPerson(n)];
        final players = public ? d.players : d.capacity;
        final places = players - d.team;
        final policy = policyFor(slot.start);
        final others = [
          if (friends > 0) l10n.tes(friends, friends == 1 ? 'ami' : 'amis'),
          if (public && d.spots > 0) 'les ${d.spots} ${d.spots == 1 ? 'joueur' : 'joueurs'}',
        ];

        Widget row(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
          child: Row(
            children: [
              Text(label, style: MuType.body.copyWith(color: c.textSecondary)),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Align(alignment: AlignmentDirectional.centerEnd, child: value),
              ),
            ],
          ),
        );

        Widget priceLine(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: MuType.body.copyWith(color: c.textSecondary)),
              ),
              value,
            ],
          ),
        );

        Text money(num v, {bool minus = false}) =>
            Text('${minus ? '−' : ''}${formatDT(v)}', style: MuType.numS.copyWith(color: c.text));

        return [
          Semantics(
            header: true,
            child: Text(l10n.verifieEtPaieTaPart, style: MuType.h2.copyWith(color: c.text)),
          ),
          // ── The game ──
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: MuRadius.mdAll,
              border: Border.all(color: c.border),
              boxShadow: MuElevation.of(context).level1,
            ),
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: MuSize.controlL,
                      child: ClipRRect(
                        borderRadius: MuRadius.smAll,
                        child: MuCourtArt(
                          sport: slot.venue.venue.sport,
                          variant: MuCourtArtVariant.pattern,
                        ),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slot.title, style: MuType.labelL.copyWith(color: c.text)),
                          Text(
                            slot.venue.street,
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (slot.venue.venue.verified)
                      const MuStatusBadge(status: MuStatus.verified, size: MuBadgeSize.s),
                  ],
                ),
                const SizedBox(height: MuSpace.s2),
                row(
                  l10n.quand,
                  Text(
                    '${formatDay(slot.start)} · ${slot.timeRange}',
                    style: MuType.label.copyWith(color: c.text),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: c.border),
                row(
                  l10n.partie,
                  Text(
                    public
                        ? l10n.publique(d.gender.label.toLowerCase(), formatLevel(d.level.start), formatLevel(d.level.end))
                        : l10n.priveeSurInvitation,
                    style: MuType.label.copyWith(color: c.text),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: c.border),
                row(
                  l10n.joueurs,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MuAvatarStack(
                        people: team,
                        max: 3,
                        size: MuAvatarSize.xs,
                        semanticLabel: l10n.joueursInscrits(d.team),
                      ),
                      const SizedBox(width: MuSpace.s2),
                      Text(
                        '${d.team}/$players · $places ${places == 1 ? 'place' : 'places'}',
                        style: MuType.label.copyWith(color: c.text),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: MuButton.tertiary(
                    label: l10n.modifierLaPartie,
                    leading: PhosphorIcons.pencilSimple(),
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
          ),
          // ── Qui paie quoi ? ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.quiPaieQuoi, style: MuType.h3.copyWith(color: c.text)),
              ),
              const SizedBox(height: MuSpace.s3),
              MuChoiceGroup(
                label: l10n.partageDuPaiement,
                children: [
                  MuChoiceCard(
                    title: l10n.chacunPaieSaPart(formatDT(d.share)),
                    description: others.isEmpty
                        ? l10n.tuPaiesTaPartMaintenant
                        : l10n.tuPaiesTaPartMaintenant2(others.join(' et '), public ? 'rejoignant' : 'acceptant'),
                    leading: BookingIconTile(PhosphorIcons.usersThree()),
                    selected: share,
                    onTap: () => booking.setSplit(PaymentSplit.share),
                    extra: _Tag(text: l10n.recommande, icon: PhosphorIcons.thumbsUp()),
                  ),
                  MuChoiceCard(
                    title: l10n.jePaieTout(formatDT(slot.price)),
                    description:
                        l10n.tuAvancesLeTerrainChaque,
                    leading: BookingIconTile(PhosphorIcons.handCoins()),
                    selected: !share,
                    onTap: () => booking.setSplit(PaymentSplit.all),
                  ),
                ],
              ),
              if (share) ...[
                const SizedBox(height: MuSpace.s3),
                MuBanner(
                  title: l10n.toutDoitEtrePayeAvant(formatDateTime(policy.payBefore)),
                  detail:
                      l10n.sinonLaReservationEstAnnulee,
                  icon: PhosphorIcons.hourglassMedium(),
                ),
              ],
            ],
          ),
          // ── Solde ──
          MuSwitch(
            value: d.useBalance,
            label: l10n.utiliserMonSoldeMatchup,
            description: '${formatDT(balance)} disponibles',
            icon: PhosphorIcons.wallet(),
            labelAtStart: true,
            onChanged: balance > 0 ? booking.setUseBalance : null,
          ),
          // ── Détail ──
          Container(
            padding: const EdgeInsets.all(MuSpace.s4),
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                priceLine(
                  '${slot.court.name} · ${slot.lengthLabel}'
                  '${slot.peak ? l10n.heureDePointe : ''}',
                  money(slot.price),
                ),
                priceLine(
                  share ? l10n.taPartJoueurSur(d.players) : l10n.tuAvancesLeTerrain,
                  money(d.amount),
                ),
                priceLine(
                  l10n.fraisDeService,
                  Text(l10n.offerts, style: MuType.label.copyWith(color: c.successText)),
                ),
                if (used > 0) priceLine(l10n.soldeMatchup, money(used, minus: true)),
                const SizedBox(height: MuSpace.s2),
                Divider(height: 1, thickness: 1, color: c.border),
                const SizedBox(height: MuSpace.s3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.aPayerMaintenant,
                        style: MuType.labelL.copyWith(color: c.text),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(formatDT(due), style: MuType.numL.copyWith(color: c.text)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Si tu annules ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.siTuAnnules, style: MuType.h3.copyWith(color: c.text)),
              ),
              const SizedBox(height: MuSpace.s1),
              Text(
                l10n.politiqueAppliqueeAChaqueJoueur(elideDe(slot.venue.venue.name)),
                style: MuType.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: MuSpace.s3),
              CancellationTiers(venueName: slot.venue.venue.name, start: slot.start, small: true),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l10n.enPayantTuAcceptesLes),
                TextSpan(
                  text: l10n.conditionsDeReservation,
                  style: MuType.labelS.copyWith(color: c.text),
                ),
                TextSpan(
                  text:
                      l10n.etLaPolitiqueDAnnulation(elideDe(slot.venue.venue.name)),
                ),
              ],
            ),
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
        ];
      },
    );
  }
}

/// « 👍 Recommandé » on `success-soft`.
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
        decoration: BoxDecoration(color: c.successSoft, borderRadius: MuRadius.fullAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: MuSize.iconXs, color: c.successText),
            const SizedBox(width: MuSpace.s1),
            Text(text, style: MuType.labelS.copyWith(color: c.successText)),
          ],
        ),
      ),
    );
  }
}
