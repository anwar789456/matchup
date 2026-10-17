import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../home/controllers/home_providers.dart';
import '../../venue/widgets/venue_widgets.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_scaffold.dart';

/// BKG-04 · Réservation 3/3, récapitulatif: the slot and the game, who pays what (« Chacun paie sa
/// part » or « Je paie tout »), the balance, the price detail and the cancellation policy, then
/// « Payer ma part ». The payment is the fake of CLAUDE.md rule 10 (Milestone 4 designs the
/// checkout).
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
      await ref.read(bookingProvider.notifier).pay();
      if (mounted) context.go(Routes.bookingDone);
    } catch (_) {
      if (mounted) {
        MuToast.show(
          context,
          title: 'Le paiement n’est pas passé',
          description: 'Rien n’a été débité. Réessaie dans un instant.',
          tone: MuToastTone.error,
        );
      }
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
    final cta = due == 0 ? 'Payer avec mon solde' : (share ? 'Payer ma part' : 'Payer le terrain');

    return BookingStepScaffold(
      step: 3,
      title: 'Récapitulatif',
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
        final team = [MuPerson(me?.displayName ?? 'Moi'), for (final n in d.invited) MuPerson(n)];
        final players = public ? d.players : d.capacity;
        final places = players - d.team;
        final policy = policyFor(slot.start);
        final others = [
          if (friends > 0) 'Tes $friends ${friends == 1 ? 'ami' : 'amis'}',
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
            child: Text('Vérifie et paie ta part', style: MuType.h2.copyWith(color: c.text)),
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
                  'Quand',
                  Text(
                    '${formatDay(slot.start)} · ${slot.timeRange}',
                    style: MuType.label.copyWith(color: c.text),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: c.border),
                row(
                  'Partie',
                  Text(
                    public
                        ? 'Publique · ${d.gender.label.toLowerCase()} · '
                              '${formatLevel(d.level.start)} – ${formatLevel(d.level.end)}'
                        : 'Privée · sur invitation',
                    style: MuType.label.copyWith(color: c.text),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: c.border),
                row(
                  'Joueurs',
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MuAvatarStack(
                        people: team,
                        max: 3,
                        size: MuAvatarSize.xs,
                        semanticLabel: '${d.team} joueurs inscrits',
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
                    label: 'Modifier la partie',
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
                child: Text('Qui paie quoi ?', style: MuType.h3.copyWith(color: c.text)),
              ),
              const SizedBox(height: MuSpace.s3),
              MuChoiceGroup(
                label: 'Partage du paiement',
                children: [
                  MuChoiceCard(
                    title: 'Chacun paie sa part · ${formatDT(d.share)}',
                    description: others.isEmpty
                        ? 'Tu paies ta part maintenant. Les autres paient la leur en rejoignant.'
                        : 'Tu paies ta part maintenant. ${others.join(' et ')} paient la leur en '
                              '${public ? 'rejoignant' : 'acceptant'}.',
                    leading: BookingIconTile(PhosphorIcons.usersThree()),
                    selected: share,
                    onTap: () => booking.setSplit(PaymentSplit.share),
                    extra: _Tag(text: 'Recommandé', icon: PhosphorIcons.thumbsUp()),
                  ),
                  MuChoiceCard(
                    title: 'Je paie tout · ${formatDT(slot.price)}',
                    description:
                        'Tu avances le terrain. Chaque part payée ensuite t’est '
                        'remboursée sur ton solde.',
                    leading: BookingIconTile(PhosphorIcons.handCoins()),
                    selected: !share,
                    onTap: () => booking.setSplit(PaymentSplit.all),
                  ),
                ],
              ),
              if (share) ...[
                const SizedBox(height: MuSpace.s3),
                MuBanner(
                  title: 'Tout doit être payé avant ${formatDateTime(policy.payBefore)}',
                  detail:
                      'Sinon la réservation est annulée et chacun est remboursé. Tu pourras '
                      'payer le reste toi-même.',
                  icon: PhosphorIcons.hourglassMedium(),
                ),
              ],
            ],
          ),
          // ── Solde ──
          MuSwitch(
            value: d.useBalance,
            label: 'Utiliser mon solde MatchUp',
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
                  '${slot.peak ? ' · heure de pointe' : ''}',
                  money(slot.price),
                ),
                priceLine(
                  share ? 'Ta part · 1 joueur sur ${d.players}' : 'Tu avances le terrain',
                  money(d.amount),
                ),
                priceLine(
                  'Frais de service',
                  Text('Offerts', style: MuType.label.copyWith(color: c.successText)),
                ),
                if (used > 0) priceLine('Solde MatchUp', money(used, minus: true)),
                const SizedBox(height: MuSpace.s2),
                Divider(height: 1, thickness: 1, color: c.border),
                const SizedBox(height: MuSpace.s3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'À payer maintenant',
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
                child: Text('Si tu annules', style: MuType.h3.copyWith(color: c.text)),
              ),
              const SizedBox(height: MuSpace.s1),
              Text(
                'Politique ${elideDe(slot.venue.venue.name)}, appliquée à chaque joueur.',
                style: MuType.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: MuSpace.s3),
              CancellationTiers(venueName: slot.venue.venue.name, start: slot.start, small: true),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'En payant, tu acceptes les '),
                TextSpan(
                  text: 'conditions de réservation',
                  style: MuType.labelS.copyWith(color: c.text),
                ),
                TextSpan(
                  text:
                      ' ${elideDe(slot.venue.venue.name)} et la politique d’annulation '
                      'ci-dessus.',
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
