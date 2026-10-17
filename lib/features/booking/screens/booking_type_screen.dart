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
import '../../../l10n/l10n.dart';

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
      title: l10n.typeDePartie,
      gap: MuSpace.s6,
      bottomBar: [
        MuButton.primary(
          label: private ? l10n.continuerInviterMesAmis : l10n.continuer,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(private ? Routes.bookingInvites : Routes.bookingPublic),
        ),
      ],
      body: (context, d, slot) => [
        BookingSlotCard(slot: slot, share: perHead),
        FlowTitle(
          l10n.quiJoueAvecToi,
          lead:
              l10n.choisisQuiPeutRejoindreTon,
        ),
        MuChoiceGroup(
          label: l10n.typeDeReservation,
          children: [
            MuChoiceCard(
              title: l10n.privee,
              description: l10n.jInviteMesAmisPersonne,
              leading: BookingIconTile(PhosphorIcons.lockKey()),
              selected: private,
              onTap: () => booking.setType(BookingType.private),
            ),
            MuChoiceCard(
              title: l10n.publique2,
              description:
                  l10n.jeCompleteAvecDesJoueurs,
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
                    Text(l10n.chacunPaieSaPart2, style: MuType.label.copyWith(color: c.text)),
                    Text(
                      l10n.parPersonneATuChoisis(formatDT(perHead), d.capacity),
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
