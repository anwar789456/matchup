import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_scaffold.dart';

/// BKG-05 · Réservation confirmée: the ticket with its QR code, « Ajouter au calendrier » and
/// « Partager le lien », the game's payments, then « Voir ma réservation » or back home.
class BookingDoneScreen extends ConsumerWidget {
  const BookingDoneScreen({super.key});

  // BKG-05: a 64 success disc around a 40 check.
  static const double _mark = 64;
  static const double _check = 40;

  /// Google Calendar's « add event » page (no package needed, works on every platform).
  static Uri _calendar(PickedSlot s, String ref) {
    String stamp(DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}'
        'T${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}00';
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': '${s.venue.venue.sport.label} · ${s.title}',
      'dates': '${stamp(s.start)}/${stamp(s.end)}',
      'ctz': 'Africa/Tunis',
      'location': s.venue.postalAddress,
      'details': 'Réservation $ref · https://matchup.tn/r/$ref',
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final draft = ref.watch(bookingProvider);
    final booking = draft.confirmed;
    final slot = draft.slot;
    if (booking == null || slot == null) return const BookingLost();
    final me = ref.watch(meProvider).value;
    final reference = booking.id!;
    final link = 'https://matchup.tn/r/$reference';
    final public = draft.type == BookingType.public;
    final friends = draft.invited.length;
    final policy = policyFor(slot.start);
    final paidAll = draft.split == PaymentSplit.all;
    final v = slot.venue.venue;

    void home() => context.go(Routes.home);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
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
                    MuIconButton(
                      icon: PhosphorIcons.x(),
                      label: 'Fermer et revenir à l’accueil',
                      size: MuIconButtonSize.l,
                      onPressed: home,
                    ),
                    const Spacer(),
                    Text('Réf. $reference', style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, MuSpace.s6),
                children: [
                  Center(
                    child: Container(
                      width: _mark,
                      height: _mark,
                      decoration: BoxDecoration(color: c.successSoft, shape: BoxShape.circle),
                      child: Icon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        size: _check,
                        color: c.successText,
                      ),
                    ),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  FlowTitle(
                    'C’est réservé !',
                    centered: true,
                    lead: paidAll
                        ? 'Le terrain est payé : ${formatDT(draft.amount)}. Confirmation envoyée à '
                              '${me?.email ?? 'ton adresse'}.'
                        : 'Ta part de ${formatDT(draft.amount)} est payée. Confirmation envoyée à '
                              '${me?.email ?? 'ton adresse'}.',
                  ),
                  const SizedBox(height: MuSpace.s6),
                  MuTicket(
                    reference: reference,
                    sport: v.sport,
                    venue: '${v.name} · ${v.place}',
                    court: slot.court.name,
                    date: formatDay(slot.start),
                    time: formatTime(slot.start),
                    players: '${draft.team}/${draft.players}',
                    paid: formatDT(draft.amount),
                    data: link,
                  ),
                  const SizedBox(height: MuSpace.s3),
                  Text(
                    'Présente ce code à l’accueil ${elideDe(v.name)}. Il est aussi dans Mes matchs.',
                    textAlign: TextAlign.center,
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: MuSpace.s6),
                  Row(
                    children: [
                      Expanded(
                        child: _Tile(
                          icon: PhosphorIcons.calendarPlus(),
                          label: 'Ajouter au calendrier',
                          onTap: () => launchUrl(
                            _calendar(slot, reference),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: _Tile(
                          icon: PhosphorIcons.shareNetwork(),
                          label: 'Partager le lien',
                          onTap: () => SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Rejoins-moi : ${slot.title}, ${formatDateTime(slot.start)}. '
                                  '$link',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s6),
                  Container(
                    padding: const EdgeInsets.all(MuSpace.s4),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: MuRadius.mdAll,
                      boxShadow: MuElevation.of(context).level1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      public ? 'Ta partie publique' : 'Ta partie privée',
                                      style: MuType.labelL.copyWith(color: c.text),
                                    ),
                                  ),
                                  Text(
                                    public
                                        ? '${draft.visibility == GameVisibility.everyone ? 'Dans Explorer' : 'Pour tes abonnés'}'
                                              ' · niveau ${formatLevel(draft.level.start)} – '
                                              '${formatLevel(draft.level.end)} · '
                                              '${draft.gender.label.toLowerCase()}'
                                        : 'Sur invitation · $friends ${friends == 1 ? 'ami invité' : 'amis invités'}',
                                    style: MuType.caption.copyWith(color: c.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (public && draft.spots > 0)
                              MuStatusBadge(
                                status: MuStatus.pending,
                                size: MuBadgeSize.s,
                                label: '${draft.spots} ${draft.spots == 1 ? 'place' : 'places'}',
                              ),
                          ],
                        ),
                        const SizedBox(height: MuSpace.s4),
                        MuProgressBar(
                          variant: MuProgressVariant.spots,
                          label: 'Paiements',
                          value: 1,
                          pending: friends.toDouble(),
                          max: draft.players.toDouble(),
                          people: [
                            MuPerson(me?.displayName ?? 'Moi'),
                            for (final n in draft.invited) MuPerson(n),
                          ],
                          legend: true,
                        ),
                        if (friends > 0 && !paidAll) ...[
                          const SizedBox(height: MuSpace.s4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                PhosphorIcons.hourglassMedium(),
                                size: MuSize.iconXs,
                                color: c.textSecondary,
                              ),
                              const SizedBox(width: MuSpace.s2),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            'Tes $friends ${friends == 1 ? 'ami a' : 'amis ont'} '
                                            'jusqu’au ',
                                      ),
                                      TextSpan(
                                        text: formatDateTime(policy.payBefore),
                                        style: MuType.labelS.copyWith(color: c.text),
                                      ),
                                      const TextSpan(
                                        text: ' pour payer leur part. On les relance pour toi.',
                                      ),
                                    ],
                                  ),
                                  style: MuType.caption.copyWith(color: c.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: MuSpace.s4),
                        MuButton.secondary(
                          label: 'Inviter des joueurs',
                          leading: PhosphorIcons.userPlus(),
                          size: MuButtonSize.l,
                          fullWidth: true,
                          onPressed: () => context.push(Routes.bookingInvitesAfter),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            StickyActionBar(
              children: [
                MuButton.primary(
                  label: 'Voir ma réservation',
                  size: MuButtonSize.xl,
                  fullWidth: true,
                  onPressed: () => context.go(Routes.booking(reference)),
                ),
                MuButton.tertiary(
                  label: 'Retour à l’accueil',
                  size: MuButtonSize.l,
                  fullWidth: true,
                  onPressed: home,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// An action tile: icon over its label, on a card.
class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return MuCardSurface(
      onTap: onTap,
      semanticLabel: label,
      child: Column(
        children: [
          Icon(icon, size: MuSize.iconM, color: c.text),
          const SizedBox(height: MuSpace.s2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: MuType.label.copyWith(color: c.text),
          ),
        ],
      ),
    );
  }
}
