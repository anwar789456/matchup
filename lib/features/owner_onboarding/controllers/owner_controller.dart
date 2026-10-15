import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../data/owner_draft.dart';
import '../data/owner_repository.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) => const FakeOwnerRepository());

/// The owner wizard draft: loaded from the device (or started from the account), saved after
/// every change.
class OwnerController extends AsyncNotifier<OwnerDraft> {
  static const storeKey = 'owner_onboarding.v1';

  @override
  Future<OwnerDraft> build() async {
    final json = await ref.read(draftStoreProvider).load(storeKey);
    if (json != null) {
      try {
        return OwnerDraft.fromJson(json);
      } on Object {
        // An older or damaged draft: start again from the account.
      }
    }
    return ref.read(ownerRepositoryProvider).start();
  }

  OwnerDraft get current => state.requireValue;

  Future<void> edit(OwnerDraft Function(OwnerDraft d) change) async {
    final next = change(current).copyWith(savedAt: ref.read(clockProvider)());
    state = AsyncData(next);
    await ref.read(draftStoreProvider).save(storeKey, next.toJson());
  }

  /// Marks [step] (0-based) as done.
  Future<void> complete(int step) =>
      edit((d) => d.copyWith(reached: math.max(d.reached, step + 1)));

  Future<void> startTrial() async {
    await ref.read(ownerRepositoryProvider).startTrial(current);
    await edit(
      (d) => d.copyWith(reached: OwnerSteps.all.length, trialStartedAt: ref.read(clockProvider)()),
    );
  }
}

final ownerProvider = AsyncNotifierProvider<OwnerController, OwnerDraft>(OwnerController.new);

/// The eight steps of the owner wizard and their one-line summaries in the rail.
abstract final class OwnerSteps {
  static const all = [
    'Entreprise',
    'Adresse',
    'Terrains',
    'Horaires',
    'Tarifs',
    'Photos',
    'Versements',
    'Offre',
  ];

  /// The rail steps while on [current]: done ones carry their summary.
  static List<MuWizardStep> of(OwnerDraft d, int current) => [
    for (final (i, label) in all.indexed)
      MuWizardStep(label, summary: i < current && i < d.reached ? summary(d, i) : null),
  ];

  static String? summary(OwnerDraft d, int step) => switch (step) {
    0 => d.legalName,
    1 => '${d.street}, ${d.city}',
    2 => courtsSummary(d),
    3 => '${d.openDays}j/7 · ${hoursRange(d)}',
    4 => priceRange(d),
    5 => '${d.photos.length} photos',
    6 => '${OwnerCatalog.bankName(d.bank)} · ${maskRib(d.rib)}',
    _ => d.plan == OwnerPlan.pro ? 'Pro' : 'Starter',
  };

  /// « 3 terrains · Football 5 ».
  static String courtsSummary(OwnerDraft d) {
    final n = d.courts.length;
    final sports = {for (final c in d.courts) OwnerCatalog.sportName(c.sport)}.join(', ');
    return '$n terrain${n > 1 ? 's' : ''}${sports.isEmpty ? '' : ' · $sports'}';
  }

  /// The usual opening, e.g. « 08h00–00h00 » (most frequent opening and closing times).
  static String hoursRange(OwnerDraft d) {
    final open = d.hours.where((h) => h.open).toList();
    if (open.isEmpty) return 'fermé';
    int mode(Iterable<int> values) {
      final counts = <int, int>{};
      for (final v in values) {
        counts[v] = (counts[v] ?? 0) + 1;
      }
      return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    }

    return '${formatHour(mode(open.map((h) => h.from)))}–${formatHour(mode(open.map((h) => h.close)))}';
  }

  /// (lowest, highest) court price per hour.
  static (int, int)? priceBounds(OwnerDraft d) {
    final values = [
      for (final p in d.prices.values) ...[?p.offPeak, ?p.peak],
    ];
    if (values.isEmpty) return null;
    return (values.reduce(math.min), values.reduce(math.max));
  }

  /// « 120 à 170 DT /h ».
  static String priceRange(OwnerDraft d) {
    final b = priceBounds(d);
    if (b == null) return 'à définir';
    return b.$1 == b.$2 ? '${b.$1} DT /h' : '${b.$1} à ${b.$2} DT /h';
  }

  /// « •••• 12 34 » — only the last four digits stay visible.
  static String maskRib(String rib) {
    if (rib.length < 4) return '••••';
    final last = rib.substring(rib.length - 4);
    return '•••• ${last.substring(0, 2)} ${last.substring(2)}';
  }
}
