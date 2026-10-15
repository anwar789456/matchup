import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/search.dart';

enum PermissionOutcome {
  granted,
  denied,

  /// Refused for good: only the system settings can change it.
  permanentlyDenied,

  /// The platform has no such permission prompt (desktop).
  unsupported,
}

/// The system permission prompts the onboarding primes (PLY-06, PLY-09).
abstract interface class DevicePermissions {
  Future<PermissionOutcome> requestLocation();

  Future<PermissionOutcome> requestNotifications();

  /// Opens MatchUp's page in the system settings (PLY-08 « Ouvrir Réglages »).
  Future<bool> openSettings();
}

/// The real prompts, through permission_handler.
class SystemPermissions implements DevicePermissions {
  const SystemPermissions();

  Future<PermissionOutcome> _request(Permission permission) async {
    try {
      final status = await permission.request();
      if (status.isGranted || status.isLimited || status.isProvisional) {
        return PermissionOutcome.granted;
      }
      if (status.isPermanentlyDenied || status.isRestricted) {
        return PermissionOutcome.permanentlyDenied;
      }
      return PermissionOutcome.denied;
    } on MissingPluginException {
      return PermissionOutcome.unsupported;
    } on UnimplementedError {
      return PermissionOutcome.unsupported;
    } on PlatformException {
      return PermissionOutcome.unsupported;
    }
  }

  @override
  Future<PermissionOutcome> requestLocation() => _request(Permission.locationWhenInUse);

  @override
  Future<PermissionOutcome> requestNotifications() => _request(Permission.notification);

  @override
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } on MissingPluginException {
      return false;
    }
  }
}

/// Districts and towns the player can add as zones (PLY-07, PLY-08), and the district of their
/// position.
abstract interface class ZoneDirectory {
  /// Zones suggested around [area].
  List<String> suggestionsNear(String? area);

  /// Zones matching [query], ignoring case and accents.
  Future<List<String>> search(String query);

  /// The district of the current position.
  Future<String> currentArea();
}

/// Tunisian districts, Greater Tunis first. The position is not geocoded yet: it is always
/// La Marsa, as in the designs.
class FakeZoneDirectory implements ZoneDirectory {
  const FakeZoneDirectory();

  static const nearby = [
    'La Marsa',
    'Lac 2',
    'Ennasr',
    'Menzah 6',
    'Ariana',
    'Carthage',
    'Gammarth',
    'Sidi Bou Saïd',
  ];

  static const _all = [
    ...nearby,
    'Lac 1',
    'Les Berges du Lac',
    'Menzah 1',
    'Menzah 5',
    'El Manar',
    'El Aouina',
    'Le Kram',
    'La Goulette',
    'Mutuelleville',
    'Centre-ville',
    'Le Bardo',
    'Ben Arous',
    'La Soukra',
    'Raoued',
    'Hammamet',
    'Nabeul',
    'Sousse',
    'Monastir',
    'Sfax',
    'Bizerte',
  ];

  @override
  List<String> suggestionsNear(String? area) => nearby;

  @override
  Future<List<String>> search(String query) async {
    final q = foldAccents(query.trim());
    if (q.isEmpty) return const [];
    final starts = _all.where((z) => foldAccents(z).startsWith(q));
    final contains = _all.where((z) => !foldAccents(z).startsWith(q) && foldAccents(z).contains(q));
    return [...starts, ...contains].take(6).toList();
  }

  @override
  Future<String> currentArea() async => 'La Marsa';
}
