import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_scaffold.dart';

/// BKG-01 · Réservation 1/3: privée (friends only) or publique (the free places go to Explorer).
class BookingTypeScreen extends ConsumerWidget {
  const BookingTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final draft = ref.watch(bookingProvider);
    final booking = ref.read(bookingProvider.notifier);
    final private = draft.type == BookingType.private;
    final perHead = draft.slot == null ? 0 : draft.slot!.price / draft.capacity;

    return BookingStepScaffold(
      step: 1,
      title: 'Type de partie',
      gap: MuSpace.s6,
      bottomBar: [
        MuButton.primary(
          label: private ? 'Continuer · inviter mes amis' : 'Continuer',
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(private ? Routes.bookingInvites : Routes.bookingPublic),
        ),
      ],
      body: (context, d, slot) => [
        BookingSlotCard(slot: slot, share: perHead),
        const FlowTitle(
          'Qui joue avec toi ?',
          lead:
              'Choisis qui peut rejoindre ton terrain. Tu pourras inviter tes amis dans les deux '
              'cas.',
        ),
        MuChoiceGroup(
          label: 'Type de réservation',
          children: [
            MuChoiceCard(
              title: 'Privée',
              description: 'J’invite mes amis. Personne d’autre ne peut rejoindre.',
              leading: BookingIconTile(PhosphorIcons.lockKey()),
              selected: private,
              onTap: () => booking.setType(BookingType.private),
            ),
            MuChoiceCard(
              title: 'Publique',
              description:
                  'Je complète avec des joueurs. Tes places libres s’affichent dans '
                  'Explorer pour des joueurs à ton niveau.',
              leading: BookingIconTile(PhosphorIcons.usersThree()),
              selected: !private,
              onTap: () => booking.setType(BookingType.public),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(MuSpace.s3),
          decoration: BoxDecoration(color: c.infoSoft, borderRadius: MuRadius.mdAll),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIcons.handCoins(), size: MuSize.iconS, color: c.infoText),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chacun paie sa part', style: MuType.label.copyWith(color: c.text)),
                    Text(
                      '${formatDT(perHead)} par personne à ${d.capacity}. Tu choisis comment '
                      'partager à l’étape suivante.',
                      style: MuType.body.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
