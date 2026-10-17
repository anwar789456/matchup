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

/// BKG-02 · Réservation 2/3, partie publique: who is in already, places to fill (the share per
/// person follows), the level range, the game type, who can see it and a word for the players.
class BookingPublicScreen extends ConsumerStatefulWidget {
  const BookingPublicScreen({super.key});

  @override
  ConsumerState<BookingPublicScreen> createState() => _BookingPublicScreenState();
}

class _BookingPublicScreenState extends ConsumerState<BookingPublicScreen> {
  late final _note = TextEditingController(text: ref.read(bookingProvider).note);

  static const _bands = [
    MuRangeBand(1, 2.5, 'Débutant'),
    MuRangeBand(2.5, 4, 'Intermédiaire'),
    MuRangeBand(4, 5.5, 'Avancé'),
    MuRangeBand(5.5, 7, 'Expert'),
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
      title: 'Partie publique',
      bottomBar: [
        MuButton.primary(
          label: 'Continuer',
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(Routes.bookingSummary),
        ),
      ],
      body: (context, d, slot) {
        final sport = slot.venue.venue.sport;
        final myLevel = me?.levels[sport];
        final friends = d.invited.length;
        final team = [MuPerson(me?.displayName ?? 'Moi'), for (final n in d.invited) MuPerson(n)];
        return [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text('Complète ton équipe', style: MuType.h2.copyWith(color: c.text)),
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
                  semanticLabel: '${d.team} joueurs déjà dans l’équipe',
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.team == 1 ? 'Toi seul pour l’instant' : 'Déjà ${d.team} joueurs',
                        style: MuType.label.copyWith(color: c.text),
                      ),
                      Text(
                        friends == 0
                            ? 'Invite des amis ou laisse les joueurs te rejoindre'
                            : 'Toi et $friends ${friends == 1 ? 'ami invité' : 'amis invités'}',
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                MuButton.tertiary(
                  label: 'Modifier',
                  size: MuButtonSize.s,
                  onPressed: () => context.push(Routes.bookingInvites),
                ),
              ],
            ),
          ),
          MuStepper(
            label: 'Places à compléter',
            value: d.spots,
            min: 1,
            max: (d.capacity - d.team).clamp(1, d.capacity),
            unit: d.spots == 1 ? 'place' : 'places',
            helper: (n) {
              final players = (d.team + n).clamp(1, d.capacity);
              return '$players joueurs · ${formatDT(slot.price / players)} chacun';
            },
            decrementLabel: 'Retirer une place',
            incrementLabel: 'Ajouter une place',
            onChanged: booking.setSpots,
          ),
          const BookingRule(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuRangeSlider(
                label: 'Niveau des joueurs',
                values: d.level,
                min: 1,
                max: 7,
                step: 0.5,
                format: formatLevel,
                formatRange: (lo, hi) => '${formatLevel(lo)} – ${formatLevel(hi)}',
                bands: _bands,
                minLabel: 'Niveau minimum',
                maxLabel: 'Niveau maximum',
                onChanged: booking.setLevel,
              ),
              if (myLevel != null) ...[
                const SizedBox(height: MuSpace.s2),
                Text(
                  'Ton niveau ${sportShort(sport)} : ${formatLevel(myLevel)} · '
                  '${levelBand(myLevel)}. Seuls les joueurs dans cette fourchette peuvent '
                  'rejoindre.',
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ],
          ),
          const BookingRule(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Type de partie', style: MuType.label.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s3),
              MuSegmentedControl<GameGender>(
                semanticLabel: 'Type de partie',
                expand: true,
                value: d.gender,
                segments: [for (final g in GameGender.values) MuSegment(value: g, label: g.label)],
                onChanged: booking.setGender,
              ),
            ],
          ),
          const BookingRule(),
          MuRadioGroup<GameVisibility>(
            label: 'Qui peut la voir ?',
            value: d.visibility,
            onChanged: booking.setVisibility,
            options: const [
              MuRadioOption(
                value: GameVisibility.everyone,
                label: 'Tout le monde',
                description: 'Visible dans Explorer par les joueurs de ton niveau.',
              ),
              MuRadioOption(
                value: GameVisibility.followers,
                label: 'Mes abonnés',
                description: 'Seuls les joueurs qui te suivent la voient.',
              ),
            ],
          ),
          const BookingRule(),
          MuTextField(
            label: 'Un mot pour les joueurs',
            controller: _note,
            optional: true,
            multiline: true,
            minLines: 2,
            maxLines: 4,
            maxLength: _noteMax,
            placeholder: 'Ambiance, poste à prendre, matériel fourni…',
            onChanged: booking.setNote,
          ),
        ];
      },
    );
  }
}
