import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/directions.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../games/widgets/claim_takeover.dart';
import '../../matches/controllers/matches_providers.dart';
import '../../payments/controllers/checkout_controller.dart';
import '../../subscription/data/subscription_repository.dart';
import '../../venue/data/venue_details.dart';
import '../../wallet/data/wallet_repository.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';

/// Whether [target]'s screen exists yet (later phases hide their actions).
bool targetAvailable(NotificationTarget? target) => switch (target) {
  null => false,
  NotificationTarget.tournament ||
  NotificationTarget.community ||
  NotificationTarget.training ||
  NotificationTarget.ownerSpace ||
  NotificationTarget.organizerSpace => false,
  _ => true,
};

/// Opens a notification (or runs one of its actions): marks it read, then goes where it leads.
Future<void> openNotification(
  BuildContext context,
  WidgetRef ref,
  AppNotification n, {
  NotificationAction? action,
}) async {
  await ref.read(notificationRepositoryProvider).markRead(n.id);
  if (!context.mounted) return;
  final target = action?.target ?? n.target;
  if (!targetAvailable(target)) return;
  final id = n.targetId;
  switch (target!) {
    case NotificationTarget.claimSpot:
      await showClaimTakeover(context, ref, id ?? Story.g1.id!);
    case NotificationTarget.game:
      context.push(Routes.game(id ?? Story.g1.id!));
    case NotificationTarget.upcoming:
      if (action?.accept != null) {
        await ref.read(matchesActionsProvider).respond('inv-mariem', accept: action!.accept!);
        if (!context.mounted) return;
        MuToast.show(
          context,
          tone: action.accept! ? MuToastTone.success : MuToastTone.neutral,
          title: action.accept! ? 'Invitation acceptée' : 'Invitation refusée',
        );
      }
      ref.read(matchesTabProvider.notifier).select(0);
      context.go(Routes.matches);
    case NotificationTarget.past || NotificationTarget.rate:
      ref.read(matchesTabProvider.notifier).select(1);
      context.go(Routes.matches);
    case NotificationTarget.booking || NotificationTarget.invite:
      context.push(Routes.booking(id ?? 'MU-48213'));
    case NotificationTarget.checkout || NotificationTarget.paymentFailed:
      _startShareCheckout(ref, id ?? 'MU-48213');
      context.push(Routes.checkout);
    case NotificationTarget.receipt:
      final receipts = await ref.read(receiptsProvider.future);
      if (!context.mounted || receipts.isEmpty) return;
      context.push(Routes.receipt, extra: receipts.first);
    case NotificationTarget.wallet:
      context.push(Routes.wallet);
    case NotificationTarget.refundStatus:
      context.push(Routes.walletRefundStatus(id ?? 'rf-hoop'));
    case NotificationTarget.subscription:
      context.push(Routes.subscription);
    case NotificationTarget.explore:
      context.go(Routes.exploreVenues);
    case NotificationTarget.directions:
      final to = Story.arenaFive.position;
      if (to != null) await openDirections(to);
    case NotificationTarget.tournament ||
        NotificationTarget.community ||
        NotificationTarget.training ||
        NotificationTarget.ownerSpace ||
        NotificationTarget.organizerSpace:
      break;
  }
}

/// « Payer ma part · 15 DT » of MU-48213 (Arena Five, mer. 21 oct. · 21h00).
void _startShareCheckout(WidgetRef ref, String reference) {
  final start = Story.at(21, 21);
  ref
      .read(checkoutRequestProvider.notifier)
      .start(
        CheckoutRequest(
          kind: CheckoutKind.share,
          eyebrow: 'Ta part · réservation $reference',
          title: 'Arena Five · Terrain 1',
          subtitle: 'mer. 21 oct. · 21h00 – 22h00 · Foot 5 vs 5',
          amount: 15,
          lineLabel: 'Ta part · 1 joueur sur 10',
          sport: MuSport.football,
          reference: reference,
          policy: (start.subtract(VenueDetails.freeUntil), start.subtract(VenueDetails.halfUntil)),
          policyVenue: 'Arena Five',
          spotsLine: 'Ta part : 15 DT sur 150 DT',
          lineup: (6, 10),
          publicGame: true,
          successRoute: Routes.booking(reference),
          onPaid: (receipt, fromBalance) => ref
              .read(walletActionsProvider)
              .paid(
                receipt: receipt,
                label: 'Part · Arena Five',
                sport: MuSport.football,
                fromBalance: fromBalance,
              ),
        ),
      );
}
