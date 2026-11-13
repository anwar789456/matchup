import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity.dart';
import '../../../core/db/app_database.dart';
import 'forum_identity.dart';
import 'forum_models.dart';
import 'messages_models.dart';
import 'sqlite_messages_repository.dart';

export 'messages_models.dart';

/// Messages between friends and group chats (Communauté): private conversations, groups,
/// polls, « Proposer un match », shared discussions, reactions and replies. Text goes through
/// the same AI check as the forum (FRM-03) before it is sent.
///
/// Everything lives in the phone's database (schema v6). The tables are not synced yet: a
/// private conversation must only reach its members, which needs a « participants only » scope
/// in the sync (lib/core/sync).
abstract interface class MessagesRepository {
  /// The member using the app.
  String get meId;

  /// « Messages »: the conversations the reader is in, the most recent first.
  Future<List<Conversation>> conversations();

  /// Unread messages in conversations that are not muted (the badge on « Messages »).
  Future<int> unreadCount();

  Future<Conversation> conversation(String id);

  /// The conversation's messages, oldest first.
  Future<List<ChatMessage>> messages(String conversationId);

  /// Everything up to now is read.
  Future<void> markRead(String conversationId);

  /// Who the reader can write to: the members they follow first, then the people they already
  /// talk to, then the rest of the community; muted members never.
  Future<List<ForumAuthor>> friends();

  /// The private conversation with [memberId], created the first time. Returns its id.
  Future<String> openDirect(String memberId);

  /// A group named [name] with the reader and [memberIds] (2 at least). Returns its id.
  Future<String> createGroup(String name, List<String> memberIds);

  /// Sends a text, after the FRM-03 check: throws [ForumAlertException] when it may hurt,
  /// unless [confirmed] (then it is sent masked until a moderator reads it).
  Future<ChatMessage> send(String conversationId, String text, {String? replyToId, bool confirmed = false});

  /// « Sondage »: a question and 2 to 4 answers.
  Future<ChatMessage> sendPoll(String conversationId, String question, List<String> options);

  /// « Proposer un match ».
  Future<ChatMessage> sendMatch(String conversationId, ChatMatchDraft draft);

  /// A photo or a video (`data:` source) with an optional caption (FRM-03 checked).
  Future<ChatMessage> sendMedia(String conversationId, String src, {String caption = ''});

  /// A voice message.
  Future<ChatMessage> sendVoice(String conversationId, String src, Duration duration);

  /// « Faire une offre » on a listing, or a counter-offer: [price] in dinars.
  Future<ChatMessage> sendOffer(String conversationId, String postId, double price);

  /// The other side's answer to an offer (once).
  Future<void> answerOffer(String messageId, {required bool accept});

  /// « Envoyer à un ami » on a discussion.
  Future<ChatMessage> sharePost(String conversationId, String postId);

  /// A poll answer (its index) or a match answer (« oui » / « non »); the same choice again
  /// removes the vote.
  Future<void> vote(String messageId, String choice);

  /// Adds the reader's [emoji] under a message, or removes it.
  Future<void> react(String messageId, String emoji);

  /// Only the reader's own messages; the line stays as « Message supprimé ».
  Future<void> deleteMessage(String messageId);

  /// FRM-05 on a message; [muteAuthor] also hides the author's messages from now on.
  Future<void> report(String messageId, ReportReason reason, {String? details, bool muteAuthor = false});

  /// Group admin only.
  Future<void> rename(String conversationId, String name);

  Future<void> addMembers(String conversationId, List<String> memberIds);

  Future<void> mute(String conversationId, {required bool on});

  /// Leaves a group (« Omar D. a quitté le groupe »); a private conversation is only hidden
  /// until the next message.
  Future<void> leave(String conversationId);

  /// While there is no server, the story's friends answer in the demo: a reply to a text, a
  /// vote on a poll, an answer to a match. Never for real members. False when nobody answers.
  Future<bool> demoAnswer(String conversationId);
}

/// The chats in the phone's database (schema v6).
final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => SqliteMessagesRepository(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
    meId: forumUserId,
    offline: () => ref.read(simulatedOfflineProvider),
  ),
);
