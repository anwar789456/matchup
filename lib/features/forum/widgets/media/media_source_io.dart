import 'dart:convert';
import 'dart:io';

import 'package:video_player/video_player.dart';

/// A `data:` source becomes a temporary file (the native players read files and URLs only),
/// written once per source; a URL is streamed.
VideoPlayerController mediaController(String src) {
  if (!src.startsWith('data:')) return VideoPlayerController.networkUrl(Uri.parse(src));
  final comma = src.indexOf(',');
  final mime = src.substring(5, src.indexOf(';'));
  final ext = switch (mime) {
    'video/quicktime' => 'mov',
    'video/webm' => 'webm',
    'audio/wav' => 'wav',
    'audio/webm' => 'webm',
    'audio/mp4' => 'm4a',
    _ => mime.startsWith('audio/') ? 'audio' : 'mp4',
  };
  final file = File('${Directory.systemTemp.path}/matchup_media_${src.hashCode.toUnsigned(32)}.$ext');
  if (!file.existsSync()) file.writeAsBytesSync(base64Decode(src.substring(comma + 1)), flush: true);
  return VideoPlayerController.file(file);
}
