import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';

/// The signed-in player as the app shell shows them.
@immutable
class Me {
  const Me({
    required this.firstName,
    required this.displayName,
    required this.zone,
    required this.levels,
    this.email,
    this.balance = 0,
    this.unreadNotifications = 0,
    this.position,
  });

  /// « Yassine », for « Salut Yassine ».
  final String firstName;

  /// « Yassine B. », what other players see.
  final String displayName;

  /// The district of the location chip, « La Marsa ».
  final String zone;
  final Map<MuSport, double> levels;

  /// Where confirmations are sent.
  final String? email;

  /// The MatchUp balance in DT (refunds land here; it can pay a share).
  final num balance;
  final int unreadNotifications;

  /// Where the player is, for the map's « Ta position ».
  final MuLatLng? position;
}

abstract interface class MeRepository {
  Future<Me> me();

  /// Takes [amount] DT from the balance (a share paid with it).
  Future<void> debit(num amount);

  /// Puts [amount] DT back (a refund).
  Future<void> credit(num amount);
}

/// Yassine B. from the story (design/screens/STORY-DATA.md), with a 30 DT balance.
class FakeMeRepository implements MeRepository {
  FakeMeRepository();

  num _balance = Story.myBalance;

  @override
  Future<Me> me() async => Me(
    firstName: Story.myFirstName,
    displayName: Story.myName,
    zone: Story.zone,
    levels: Story.myLevels,
    email: Story.myEmail,
    balance: _balance,
    unreadNotifications: Story.unreadNotifications,
    position: Story.me,
  );

  @override
  Future<void> debit(num amount) async {
    if (amount > _balance) throw StateError('Solde insuffisant');
    _balance -= amount;
  }

  @override
  Future<void> credit(num amount) async => _balance += amount;
}

final meRepositoryProvider = Provider<MeRepository>((ref) => FakeMeRepository());
