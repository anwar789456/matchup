import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The camera of the check-in (OWN-20). Until `mobile_scanner` is added (it needs approval), the
/// camera is simulated: the debug menu refuses it (STA-05) and picks the code a scan reads.
class CameraDenied extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final cameraDeniedProvider = NotifierProvider<CameraDenied, bool>(CameraDenied.new);

/// The code the simulated camera reads when the viewfinder is tapped.
class SimulatedScan extends Notifier<String> {
  @override
  String build() => 'MU-48213';

  void set(String code) => state = code;
}

final simulatedScanProvider = NotifierProvider<SimulatedScan, String>(SimulatedScan.new);

/// Codes the debug menu offers: valid, already used, another venue.
const simulatedCodes = ['MU-48213', 'MU-48190', 'MU-48377'];
