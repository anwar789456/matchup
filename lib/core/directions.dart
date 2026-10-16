import 'package:url_launcher/url_launcher.dart';

import '../ui/ui.dart';

/// « Itinéraire »: hands the trip to the phone's maps app (MapView.md: directions are not ours).
Future<bool> openDirections(MuLatLng to) => launchUrl(
  Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${to.lat},${to.lng}',
  }),
  mode: LaunchMode.externalApplication,
);
