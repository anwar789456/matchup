import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../data/subscription_repository.dart';

/// The player's Premium, shared by SUB-01 to SUB-08 and the account menu.
class SubscriptionController extends AsyncNotifier<Subscription> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);

  @override
  Future<Subscription> build() => ref.watch(subscriptionRepositoryProvider).current();

  Future<void> _run(Future<Subscription> Function() change) async {
    state = AsyncData(await change());
  }

  Future<void> startTrial(MuBillingPeriod period, String cardLabel) =>
      _run(() => _repo.startTrial(period: period, cardLabel: cardLabel));
  Future<void> changePeriod(MuBillingPeriod period) => _run(() => _repo.changePeriod(period));
  Future<void> cancel({CancelReason? reason, String? note}) =>
      _run(() => _repo.cancel(reason: reason, note: note));
  Future<void> acceptOffer() => _run(_repo.acceptOffer);
  Future<void> reactivate() => _run(_repo.reactivate);
}

final subscriptionProvider = AsyncNotifierProvider<SubscriptionController, Subscription>(
  SubscriptionController.new,
);

/// The cancel flow's answer (SUB-06), read by SUB-07.
class CancelReasonController extends Notifier<CancelReason?> {
  @override
  CancelReason? build() => CancelReason.price;

  void set(CancelReason? r) => state = r;
}

final cancelReasonProvider = NotifierProvider<CancelReasonController, CancelReason?>(
  CancelReasonController.new,
);
