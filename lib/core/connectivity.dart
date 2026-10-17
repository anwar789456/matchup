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

/// A server that answers 5xx (STA-02). [reference] is what support asks for.
class ServerException implements Exception {
  const ServerException({this.status = 503, this.reference = 'MU-7F3A-2C'});

  final int status;
  final String reference;

  @override
  String toString() => 'ServerException($status, $reference)';
}

/// The debug menu's « Simuler une erreur serveur » (STA-02): lists of Mes matchs fail with a 503.
class SimulatedServerError extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on;
}

final simulatedServerErrorProvider = NotifierProvider<SimulatedServerError, bool>(
  SimulatedServerError.new,
);
