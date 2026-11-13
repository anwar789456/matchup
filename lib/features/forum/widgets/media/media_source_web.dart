import 'package:video_player/video_player.dart';

/// The browser plays `data:` and `https:` sources directly.
VideoPlayerController mediaController(String src) => VideoPlayerController.networkUrl(Uri.parse(src));
