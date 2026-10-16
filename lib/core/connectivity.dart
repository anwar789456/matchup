import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown by a repository that can't reach the network.
class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() => 'OfflineException';
}

/// While the data is fake there is no network to lose: the debug gallery switches this on to see
/// the offline states (EXP-07). Fake repositories throw [OfflineException] while it is on.
class SimulatedOffline extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool offline) => state = offline;
}

final simulatedOfflineProvider = NotifierProvider<SimulatedOffline, bool>(SimulatedOffline.new);
