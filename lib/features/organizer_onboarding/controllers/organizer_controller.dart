import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/data/pro_providers.dart';
import '../data/organizer_draft.dart';

final organizerRepositoryProvider =
    Provider<OrganizerRepository>((ref) => const FakeOrganizerRepository());

/// The organiser wizard draft: loaded from the device (or started from the account), saved after
/// every change.
class OrganizerController extends AsyncNotifier<OrganizerDraft> {
  static const storeKey = 'organizer_onboarding.v1';

  @override
  Future<OrganizerDraft> build() async {
    final json = await ref.read(draftStoreProvider).load(storeKey);
    if (json != null) {
      try {
        return OrganizerDraft.fromJson(json);
      } on Object {
        // An older or damaged draft: start again from the account.
      }
    }
    return ref.read(organizerRepositoryProvider).start();
  }

  OrganizerDraft get current => state.requireValue;

  Future<void> edit(OrganizerDraft Function(OrganizerDraft d) change) async {
    final next = change(current).copyWith(savedAt: ref.read(clockProvider)());
    state = AsyncData(next);
    await ref.read(draftStoreProvider).save(storeKey, next.toJson());
  }

  Future<void> complete(int step) =>
      edit((d) => d.copyWith(reached: math.max(d.reached, step + 1)));
}

final organizerProvider =
    AsyncNotifierProvider<OrganizerController, OrganizerDraft>(OrganizerController.new);
