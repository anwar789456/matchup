import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A signed-in device (SET-03 « Sessions actives »).
@immutable
class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.name,
    required this.where,
    this.current = false,
    this.mobile = true,
  });

  final String id;
  final String name;

  /// « Tunis · actif maintenant », « Ariana · il y a 2 jours ».
  final String where;
  final bool current;
  final bool mobile;
}

enum Gender { male, female, unspecified }

enum InvitePolicy { everyone, teammates, nobody }

/// Everything the settings screens read and write (SET-02 to SET-06), kept in memory.
@immutable
class AccountSettings {
  const AccountSettings({
    this.email = 'yassine.b@email.tn',
    this.phone = '20123456',
    this.firstName = 'Yassine',
    this.lastName = 'Belhaj',
    this.birthDate = '12/03/1998',
    this.gender = Gender.male,
    this.passwordChanged = 'il y a 3 mois',
    this.twoFactor = true,
    this.sessions = const [
      DeviceSession(
        id: 'iphone',
        name: 'iPhone 15',
        where: 'Tunis · actif maintenant',
        current: true,
      ),
      DeviceSession(
        id: 'chrome',
        name: 'Chrome sur Windows',
        where: 'Ariana · il y a 2 jours',
        mobile: false,
      ),
    ],
    this.googleEmail = 'yassine.b@gmail.com',
    this.appleConnected = false,
    this.profilePublic = true,
    this.invites = InvitePolicy.teammates,
    this.showLevel = true,
    this.showReliability = true,
    this.preciseLocation = true,
    this.blocked = 2,
    this.notificationsSummary = 'Push · email',
  });

  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String birthDate;
  final Gender gender;
  final String passwordChanged;
  final bool twoFactor;
  final List<DeviceSession> sessions;

  /// Null when Google is not connected.
  final String? googleEmail;
  final bool appleConnected;
  final bool profilePublic;
  final InvitePolicy invites;
  final bool showLevel;
  final bool showReliability;
  final bool preciseLocation;
  final int blocked;
  final String notificationsSummary;

  /// « +216 20 ••• 456 ».
  String get maskedPhone =>
      '+216 ${phone.substring(0, 2)} ••• ${phone.substring(phone.length - 3)}';

  AccountSettings copyWith({
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? birthDate,
    Gender? gender,
    bool? twoFactor,
    List<DeviceSession>? sessions,
    Object? googleEmail = _keep,
    bool? appleConnected,
    bool? profilePublic,
    InvitePolicy? invites,
    bool? showLevel,
    bool? showReliability,
    bool? preciseLocation,
  }) => AccountSettings(
    email: email ?? this.email,
    phone: phone ?? this.phone,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    passwordChanged: passwordChanged,
    twoFactor: twoFactor ?? this.twoFactor,
    sessions: sessions ?? this.sessions,
    googleEmail: identical(googleEmail, _keep) ? this.googleEmail : googleEmail as String?,
    appleConnected: appleConnected ?? this.appleConnected,
    profilePublic: profilePublic ?? this.profilePublic,
    invites: invites ?? this.invites,
    showLevel: showLevel ?? this.showLevel,
    showReliability: showReliability ?? this.showReliability,
    preciseLocation: preciseLocation ?? this.preciseLocation,
    blocked: blocked,
    notificationsSummary: notificationsSummary,
  );

  static const _keep = Object();
}

class AccountSettingsController extends Notifier<AccountSettings> {
  @override
  AccountSettings build() => const AccountSettings();

  void update(AccountSettings Function(AccountSettings s) change) => state = change(state);

  void signOutSession(String id) => state = state.copyWith(
    sessions: [
      for (final s in state.sessions)
        if (s.id != id) s,
    ],
  );

  void signOutOthers() => state = state.copyWith(
    sessions: [
      for (final s in state.sessions)
        if (s.current) s,
    ],
  );
}

final accountSettingsProvider = NotifierProvider<AccountSettingsController, AccountSettings>(
  AccountSettingsController.new,
);
