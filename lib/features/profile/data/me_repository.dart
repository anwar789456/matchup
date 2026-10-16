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
  final int unreadNotifications;

  /// Where the player is, for the map's « Ta position ».
  final MuLatLng? position;
}

abstract interface class MeRepository {
  Future<Me> me();
}

/// Yassine B. from the story (design/screens/STORY-DATA.md).
class FakeMeRepository implements MeRepository {
  const FakeMeRepository();

  @override
  Future<Me> me() async => const Me(
    firstName: Story.myFirstName,
    displayName: Story.myName,
    zone: Story.zone,
    levels: Story.myLevels,
    unreadNotifications: Story.unreadNotifications,
    position: Story.me,
  );
}

final meRepositoryProvider = Provider<MeRepository>((ref) => const FakeMeRepository());
