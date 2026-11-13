import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../ui/ui.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../home/controllers/home_providers.dart';
import '../../matches/data/bookings_repository.dart';
import '../../payments/controllers/checkout_controller.dart';
import '../../profile/data/me_repository.dart';
import '../../wallet/data/wallet_repository.dart';
import '../data/assistant_models.dart';

/// AI-03 « Confirmer »: prepares our checkout (PAY-01) for the slot. Only once paid is the
/// booking created — the assistant never books or pays by itself.
Future<void> startAssistantCheckout(WidgetRef ref, AiSlots b) async {
  final s = b.slot;
  final end = s.start.add(const Duration(hours: 1));
  final reference = await ref.read(bookingsRepositoryProvider).nextReference();
  final policy = policyFor(s.start);
  final range = ltr('${formatTime(s.start)}–${formatTime(end)}');
  ref
      .read(checkoutRequestProvider.notifier)
      .start(
        CheckoutRequest(
          kind: CheckoutKind.share,
          eyebrow: l10n.reservation(l10n.taPart, reference),
          title: '${b.venue} · ${s.court}',
          subtitle: '${formatDay(s.start)} · $range',
          amount: b.share,
          lineLabel: l10n.taPartJoueurSur(b.players),
          sport: b.sport,
          reference: reference,
          policy: (policy.freeUntil, policy.halfUntil),
          policyVenue: b.venue,
          spotsLine: l10n.taPartSur(formatDT(b.share), formatDT(b.price)),
          detailRows: [
            (l10n.ou, b.venue, b.place),
            (l10n.terrain2, s.court, b.surface),
            (l10n.quand, '${formatDay(s.start)} · $range', null),
          ],
          successRoute: Routes.booking(reference),
          onPaid: (receipt, fromBalance) async {
            final me = await ref.read(meRepositoryProvider).me();
            await ref
                .read(bookingsRepositoryProvider)
                .add(
                  MuBooking(
                    id: reference,
                    sport: b.sport,
                    venue: b.venue,
                    court: s.court,
                    place: b.place,
                    start: s.start,
                    end: end,
                    share: b.share,
                    players: [MuPerson(me.displayName)],
                  ),
                );
            await ref
                .read(walletActionsProvider)
                .paid(
                  receipt: receipt,
                  label: l10n.partText(b.venue),
                  sport: b.sport,
                  fromBalance: fromBalance,
                );
            ref
              ..invalidate(upcomingMatchesProvider)
              ..invalidate(meProvider);
          },
        ),
      );
}
