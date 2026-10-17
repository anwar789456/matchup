import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_scaffold.dart';
import '../../../l10n/l10n.dart';

/// BKG-02 · Réservation 2/3, partie publique: who is in already, places to fill (the share per
/// person follows), the level range, the game type, who can see it and a word for the players.
class BookingPublicScreen extends ConsumerStatefulWidget {
  const BookingPublicScreen({super.key});

  @override
  ConsumerState<BookingPublicScreen> createState() => _BookingPublicScreenState();
}

class _BookingPublicScreenState extends ConsumerState<BookingPublicScreen> {
  late final _note = TextEditingController(text: ref.read(bookingProvider).note);

  static final _bands = [
    MuRangeBand(1, 2.5, l10n.debutant),
    MuRangeBand(2.5, 4, l10n.intermediaire),
    MuRangeBand(4, 5.5, l10n.avance),
    MuRangeBand(5.5, 7, l10n.expert),
  ];
  static const int _noteMax = 200;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final booking = ref.read(bookingProvider.notifier);
    final me = ref.watch(meProvider).value;

    return BookingStepScaffold(
      step: 2,
      title: l10n.partiePublique,
      bottomBar: [
        MuButton.primary(
          label: l10n.continuer,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(Routes.bookingSummary),
        ),
      ],
      body: (context, d, slot) {
        final sport = slot.venue.venue.sport;
        final myLevel = me?.levels[sport];
        final friends = d.invited.length;
        final team = [MuPerson(me?.displayName ?? l10n.moi), for (final n in d.invited) MuPerson(n)];
        return [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.completeTonEquipe, style: MuType.h2.copyWith(color: c.text)),
              ),
              const SizedBox(height: MuSpace.s1),
              Text(
                '${slot.title} · ${formatDay(slot.start)} · ${formatTime(slot.start)}',
                style: MuType.body.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(MuSpace.s3),
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
            child: Row(
              children: [
                MuAvatarStack(
                  people: team,
                  size: MuAvatarSize.s,
                  semanticLabel: l10n.joueursDejaDansLEquipe(d.team),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.team == 1 ? l10n.toiSeulPourLInstant : l10n.dejaJoueurs(d.team),
                        style: MuType.label.copyWith(color: c.text),
                      ),
                      Text(
                        friends == 0
                            ? l10n.inviteDesAmisOuLaisse
                            : l10n.toiEt(friends, friends == 1 ? l10n.amiInvite : l10n.amisInvites),
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                MuButton.tertiary(
                  label: l10n.modifier,
                  size: MuButtonSize.s,
                  onPressed: () => context.push(Routes.bookingInvites),
                ),
              ],
            ),
          ),
          MuStepper(
            label: l10n.placesACompleter,
            value: d.spots,
            min: 1,
            max: (d.capacity - d.team).clamp(1, d.capacity),
            unit: d.spots == 1 ? 'place' : 'places',
            helper: (n) {
              final players = (d.team + n).clamp(1, d.capacity);
              return l10n.joueursChacun(players, formatDT(slot.price / players));
            },
            decrementLabel: l10n.retirerUnePlace,
            incrementLabel: l10n.ajouterUnePlace,
            onChanged: booking.setSpots,
          ),
          const BookingRule(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuRangeSlider(
                label: l10n.niveauDesJoueurs,
                values: d.level,
                min: 1,
                max: 7,
                step: 0.5,
                format: formatLevel,
                formatRange: (lo, hi) => '${formatLevel(lo)} – ${formatLevel(hi)}',
                bands: _bands,
                minLabel: l10n.niveauMinimum,
                maxLabel: l10n.niveauMaximum,
                onChanged: booking.setLevel,
              ),
              if (myLevel != null) ...[
                const SizedBox(height: MuSpace.s2),
                Text(
                  l10n.tonNiveauSeulsLesJoueurs(sportShort(sport), formatLevel(myLevel), levelBand(myLevel)),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ],
          ),
          const BookingRule(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.typeDePartie, style: MuType.label.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s3),
              MuSegmentedControl<GameGender>(
                semanticLabel: l10n.typeDePartie,
                expand: true,
                value: d.gender,
                segments: [for (final g in GameGender.values) MuSegment(value: g, label: g.label)],
                onChanged: booking.setGender,
              ),
            ],
          ),
          const BookingRule(),
          MuRadioGroup<GameVisibility>(
            label: l10n.quiPeutLaVoir,
            value: d.visibility,
            onChanged: booking.setVisibility,
            options: [
              MuRadioOption(
                value: GameVisibility.everyone,
                label: l10n.toutLeMonde,
                description: l10n.visibleDansExplorerParLes,
              ),
              MuRadioOption(
                value: GameVisibility.followers,
                label: l10n.mesAbonnes,
                description: l10n.seulsLesJoueursQuiTe,
              ),
            ],
          ),
          const BookingRule(),
          MuTextField(
            label: l10n.unMotPourLesJoueurs,
            controller: _note,
            optional: true,
            multiline: true,
            minLines: 2,
            maxLines: 4,
            maxLength: _noteMax,
            placeholder: l10n.ambiancePosteAPrendreMateriel,
            onChanged: booking.setNote,
          ),
        ];
      },
    );
  }
}
