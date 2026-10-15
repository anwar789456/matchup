import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../theme/theme.dart';
import '../../common/data/draft_file.dart';

export '../../common/data/draft_file.dart';

/// A bookable court (OWN-03).
@immutable
class Court {
  const Court({
    required this.id,
    required this.name,
    this.sport = MuSport.football,
    this.surface = 'Gazon synthétique',
    this.indoor = false,
    this.lights = true,
  });

  final String id;
  final String name;
  final MuSport sport;
  final String surface;
  final bool indoor;
  final bool lights;

  Court copyWith({String? name, MuSport? sport, String? surface, bool? indoor, bool? lights}) =>
      Court(
        id: id,
        name: name ?? this.name,
        sport: sport ?? this.sport,
        surface: surface ?? this.surface,
        indoor: indoor ?? this.indoor,
        lights: lights ?? this.lights,
      );

  /// The price group this court belongs to (one row per sport and type on OWN-05).
  String get priceKey => '${sport.name}-${indoor ? 'in' : 'out'}';

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'sport': sport.name,
    'surface': surface,
    'indoor': indoor,
    'lights': lights,
  };

  factory Court.fromJson(Map<String, Object?> j) => Court(
    id: j['id']! as String,
    name: j['name']! as String,
    sport: MuSport.values.byName(j['sport']! as String),
    surface: j['surface']! as String,
    indoor: j['indoor']! as bool,
    lights: j['lights']! as bool,
  );

  @override
  bool operator ==(Object other) =>
      other is Court &&
      other.id == id &&
      other.name == name &&
      other.sport == sport &&
      other.surface == surface &&
      other.indoor == indoor &&
      other.lights == lights;

  @override
  int get hashCode => Object.hash(id, name, sport, surface, indoor, lights);
}

/// Opening hours of one weekday, in minutes after midnight; [close] may pass midnight (1500 =
/// 01h00 the next day).
@immutable
class DayHours {
  const DayHours({this.open = true, this.from = 8 * 60, this.close = 24 * 60});

  final bool open;
  final int from;
  final int close;

  int get minutes => open ? close - from : 0;

  DayHours copyWith({bool? open, int? from, int? close}) =>
      DayHours(open: open ?? this.open, from: from ?? this.from, close: close ?? this.close);

  Map<String, Object?> toJson() => {'open': open, 'from': from, 'close': close};

  factory DayHours.fromJson(Map<String, Object?> j) =>
      DayHours(open: j['open']! as bool, from: j['from']! as int, close: j['close']! as int);

  @override
  bool operator ==(Object other) =>
      other is DayHours && other.open == open && other.from == from && other.close == close;

  @override
  int get hashCode => Object.hash(open, from, close);
}

/// Court price per hour, off-peak and peak (DT).
@immutable
class CourtPrice {
  const CourtPrice({required this.offPeak, required this.peak});

  final int? offPeak;
  final int? peak;

  CourtPrice copyWith({
    int? offPeak,
    int? peak,
    bool clearOffPeak = false,
    bool clearPeak = false,
  }) => CourtPrice(
    offPeak: clearOffPeak ? null : offPeak ?? this.offPeak,
    peak: clearPeak ? null : peak ?? this.peak,
  );

  Map<String, Object?> toJson() => {'offPeak': offPeak, 'peak': peak};

  factory CourtPrice.fromJson(Map<String, Object?> j) =>
      CourtPrice(offPeak: j['offPeak'] as int?, peak: j['peak'] as int?);
}

enum OwnerPlan { starter, pro }

/// Everything the owner wizard collects (OWN-01…08), saved after every change.
@immutable
class OwnerDraft {
  const OwnerDraft({
    this.venueName = '',
    this.legalName = '',
    this.taxId = '',
    this.legalForm = 'sarl',
    this.phone = '',
    this.email = '',
    this.manager = '',
    this.street = '',
    this.postalCode = '',
    this.city = '',
    this.governorate = 'Tunis',
    this.addressLat = 36.88025,
    this.addressLng = 10.32117,
    this.latitude = 36.88025,
    this.longitude = 10.32117,
    this.access = '',
    this.courts = const [],
    this.hours = const [
      DayHours(),
      DayHours(),
      DayHours(),
      DayHours(),
      DayHours(),
      DayHours(),
      DayHours(),
    ],
    this.prices = const {},
    this.weekendPeak = true,
    this.photos = const [],
    this.holder = '',
    this.bank = '',
    this.rib = '',
    this.ribCertificate,
    this.plan = OwnerPlan.pro,
    this.yearly = false,
    this.reached = 0,
    this.savedAt,
    this.trialStartedAt,
  });

  // OWN-01
  final String venueName;
  final String legalName;
  final String taxId;
  final String legalForm;

  /// 8 digits, without +216.
  final String phone;
  final String email;

  /// « Skander T. » — the account holder, read-only here.
  final String manager;

  // OWN-02
  final String street;
  final String postalCode;
  final String city;
  final String governorate;

  /// Where the address falls on the map (geocoded).
  final double addressLat;
  final double addressLng;

  /// The pin, moved onto the entrance.
  final double latitude;
  final double longitude;
  final String access;

  // OWN-03 to OWN-05
  final List<Court> courts;

  /// Monday first.
  final List<DayHours> hours;

  /// By [Court.priceKey].
  final Map<String, CourtPrice> prices;
  final bool weekendPeak;

  // OWN-06, OWN-07
  final List<DraftFile> photos;
  final String holder;

  /// Bank id (`attijari`, `biat`…).
  final String bank;

  /// 20 digits.
  final String rib;
  final DraftFile? ribCertificate;

  // OWN-08
  final OwnerPlan plan;
  final bool yearly;

  /// Furthest step reached, 0-based (8 = all done).
  final int reached;
  final DateTime? savedAt;

  /// Set when « Démarrer l’essai gratuit » succeeds: the dashboard takes over.
  final DateTime? trialStartedAt;

  int get openDays => hours.where((h) => h.open).length;

  /// How far the pin was moved from the address, in metres.
  double get pinOffsetMeters {
    const metresPerDegree = 111320.0;
    final dy = (latitude - addressLat) * metresPerDegree;
    final dx = (longitude - addressLng) * metresPerDegree * math.cos(addressLat * math.pi / 180);
    return math.sqrt(dx * dx + dy * dy);
  }

  OwnerDraft copyWith({
    String? venueName,
    String? legalName,
    String? taxId,
    String? legalForm,
    String? phone,
    String? email,
    String? manager,
    String? street,
    String? postalCode,
    String? city,
    String? governorate,
    double? addressLat,
    double? addressLng,
    double? latitude,
    double? longitude,
    String? access,
    List<Court>? courts,
    List<DayHours>? hours,
    Map<String, CourtPrice>? prices,
    bool? weekendPeak,
    List<DraftFile>? photos,
    String? holder,
    String? bank,
    String? rib,
    DraftFile? ribCertificate,
    bool clearRibCertificate = false,
    OwnerPlan? plan,
    bool? yearly,
    int? reached,
    DateTime? savedAt,
    DateTime? trialStartedAt,
  }) => OwnerDraft(
    venueName: venueName ?? this.venueName,
    legalName: legalName ?? this.legalName,
    taxId: taxId ?? this.taxId,
    legalForm: legalForm ?? this.legalForm,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    manager: manager ?? this.manager,
    street: street ?? this.street,
    postalCode: postalCode ?? this.postalCode,
    city: city ?? this.city,
    governorate: governorate ?? this.governorate,
    addressLat: addressLat ?? this.addressLat,
    addressLng: addressLng ?? this.addressLng,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    access: access ?? this.access,
    courts: courts ?? this.courts,
    hours: hours ?? this.hours,
    prices: prices ?? this.prices,
    weekendPeak: weekendPeak ?? this.weekendPeak,
    photos: photos ?? this.photos,
    holder: holder ?? this.holder,
    bank: bank ?? this.bank,
    rib: rib ?? this.rib,
    ribCertificate: clearRibCertificate ? null : ribCertificate ?? this.ribCertificate,
    plan: plan ?? this.plan,
    yearly: yearly ?? this.yearly,
    reached: reached ?? this.reached,
    savedAt: savedAt ?? this.savedAt,
    trialStartedAt: trialStartedAt ?? this.trialStartedAt,
  );

  Map<String, Object?> toJson() => {
    'venueName': venueName,
    'legalName': legalName,
    'taxId': taxId,
    'legalForm': legalForm,
    'phone': phone,
    'email': email,
    'manager': manager,
    'street': street,
    'postalCode': postalCode,
    'city': city,
    'governorate': governorate,
    'addressLat': addressLat,
    'addressLng': addressLng,
    'latitude': latitude,
    'longitude': longitude,
    'access': access,
    'courts': [for (final c in courts) c.toJson()],
    'hours': [for (final h in hours) h.toJson()],
    'prices': {for (final e in prices.entries) e.key: e.value.toJson()},
    'weekendPeak': weekendPeak,
    'photos': [for (final p in photos) p.toJson()],
    'holder': holder,
    'bank': bank,
    'rib': rib,
    'ribCertificate': ribCertificate?.toJson(),
    'plan': plan.name,
    'yearly': yearly,
    'reached': reached,
    'savedAt': savedAt?.toIso8601String(),
    'trialStartedAt': trialStartedAt?.toIso8601String(),
  };

  factory OwnerDraft.fromJson(Map<String, Object?> j) {
    List<Map<String, Object?>> list(String k) => [
      for (final e in (j[k]! as List<Object?>)) e! as Map<String, Object?>,
    ];
    DateTime? date(String k) => j[k] == null ? null : DateTime.parse(j[k]! as String);
    return OwnerDraft(
      venueName: j['venueName']! as String,
      legalName: j['legalName']! as String,
      taxId: j['taxId']! as String,
      legalForm: j['legalForm']! as String,
      phone: j['phone']! as String,
      email: j['email']! as String,
      manager: j['manager']! as String,
      street: j['street']! as String,
      postalCode: j['postalCode']! as String,
      city: j['city']! as String,
      governorate: j['governorate']! as String,
      addressLat: (j['addressLat']! as num).toDouble(),
      addressLng: (j['addressLng']! as num).toDouble(),
      latitude: (j['latitude']! as num).toDouble(),
      longitude: (j['longitude']! as num).toDouble(),
      access: j['access']! as String,
      courts: [for (final c in list('courts')) Court.fromJson(c)],
      hours: [for (final h in list('hours')) DayHours.fromJson(h)],
      prices: {
        for (final e in (j['prices']! as Map<String, Object?>).entries)
          e.key: CourtPrice.fromJson(e.value! as Map<String, Object?>),
      },
      weekendPeak: j['weekendPeak']! as bool,
      photos: [for (final p in list('photos')) DraftFile.fromJson(p)],
      holder: j['holder']! as String,
      bank: j['bank']! as String,
      rib: j['rib']! as String,
      ribCertificate: j['ribCertificate'] == null
          ? null
          : DraftFile.fromJson(j['ribCertificate']! as Map<String, Object?>),
      plan: OwnerPlan.values.byName(j['plan']! as String),
      yearly: j['yearly']! as bool,
      reached: j['reached']! as int,
      savedAt: date('savedAt'),
      trialStartedAt: date('trialStartedAt'),
    );
  }
}
