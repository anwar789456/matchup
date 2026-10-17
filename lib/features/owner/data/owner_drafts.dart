import 'package:flutter/foundation.dart';

/// What OWN-13 opens with: a court, a day and an hour picked on the planning (OWN-11) or a
/// booking (OWN-12).
@immutable
class BlockPrefill {
  const BlockPrefill({this.court, this.day, this.startHour, this.endHour});

  final int? court;
  final DateTime? day;
  final int? startHour;
  final int? endHour;
}

/// The AI insight's proposal (OWN-10 « Appliquer »): OWN-16 opens with it filled in, and nothing
/// changes until the owner saves.
@immutable
class PromoDraft {
  const PromoDraft({
    required this.weekday,
    required this.fromHour,
    required this.toHour,
    required this.percent,
    required this.priceBefore,
  });

  /// DateTime.monday … DateTime.sunday (« Jeudi » = DateTime.thursday).
  final int weekday;
  final int fromHour;
  final int toHour;

  /// 20 → « −20 % ».
  final int percent;
  final num priceBefore;

  num get priceAfter => priceBefore * (100 - percent) / 100;

  /// OWN-10: « Jeudi 14h–17h : 80 % de créneaux vides. Proposer −20 % ? » (120 DT → 96 DT).
  static const thursdayAfternoon = PromoDraft(
    weekday: DateTime.thursday,
    fromHour: 14,
    toHour: 17,
    percent: 20,
    priceBefore: 120,
  );
}
