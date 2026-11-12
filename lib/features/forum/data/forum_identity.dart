import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import 'forum_seed.dart';

final _random = Random.secure();

/// A random v4 UUID (RFC 4122), for every post, reply, vote, reaction and report the phone
/// creates: ids made on different phones never collide once synced to Supabase.
String newForumId() {
  final b = List<int>.generate(16, (_) => _random.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // RFC 4122 variant
  final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// The member using the app, as written in `auteur_id`: the Supabase user id once the phone has
/// a session, else the story's demo player (no Supabase configured, offline start, tests).
///
/// TODO(forum): read `SupabaseConfig.userId` once Anwar's sync change is on main.
String forumUserId() {
  if (SupabaseConfig.configured && SupabaseConfig.ready) {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id != null) return id;
  }
  return ForumSeed.me;
}
