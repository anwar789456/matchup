/// A player for a post's or a message's video or voice note kept as a `data:` URI (until media
/// go to Supabase Storage): the browser reads the URI itself, a phone gets a temporary file.
library;

export 'media_source_web.dart' if (dart.library.io) 'media_source_io.dart';
