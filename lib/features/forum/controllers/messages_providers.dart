import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/forum_models.dart';
import '../data/messages_repository.dart';

/// Bumped after every change in the chats, so the list, the badge and the open chat follow.
class MessagesChanges extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final messagesChangesProvider = NotifierProvider<MessagesChanges, int>(MessagesChanges.new);

/// « Messages »: the reader's conversations, the most recent first.
final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  ref.watch(messagesChangesProvider);
  return ref.watch(messagesRepositoryProvider).conversations();
});

/// The unread badge on « Messages » (muted conversations do not count).
final unreadMessagesProvider = FutureProvider<int>((ref) {
  ref.watch(messagesChangesProvider);
  return ref.watch(messagesRepositoryProvider).unreadCount();
});

/// Who the reader can write to (followed members first).
final chatFriendsProvider = FutureProvider<List<ForumAuthor>>((ref) {
  ref.watch(messagesChangesProvider);
  return ref.watch(messagesRepositoryProvider).friends();
});

final conversationProvider = FutureProvider.family<Conversation, String>((ref, id) {
  ref.watch(messagesChangesProvider);
  return ref.watch(messagesRepositoryProvider).conversation(id);
});

/// One open chat: its messages (oldest first), read as soon as they are shown, and the actions
/// on them. In the demo, the story's friends answer a moment after the reader writes.
class ChatController extends AsyncNotifier<List<ChatMessage>> {
  ChatController(this.conversationId);

  final String conversationId;

  /// How long a friend « writes » before answering (demo).
  static const typingDelay = Duration(milliseconds: 1400);
  static const answerDelay = Duration(milliseconds: 2200);

  MessagesRepository get _repo => ref.read(messagesRepositoryProvider);
  Timer? _typing;
  Timer? _answer;

  @override
  Future<List<ChatMessage>> build() async {
    ref.watch(messagesChangesProvider);
    ref.onDispose(() {
      _typing?.cancel();
      _answer?.cancel();
    });
    final repo = ref.watch(messagesRepositoryProvider);
    final list = await repo.messages(conversationId);
    final conversation = await repo.conversation(conversationId);
    if (conversation.unread > 0) {
      await repo.markRead(conversationId);
      // The list and the badge drop the count; this chat rebuilds once, already read.
      Future.microtask(() => ref.read(messagesChangesProvider.notifier).bump());
    }
    return list;
  }

  void _changed() => ref.read(messagesChangesProvider.notifier).bump();

  /// Throws [ForumAlertException] for FRM-03, like the forum.
  Future<void> send(String text, {String? replyToId, bool confirmed = false}) async {
    await _repo.send(conversationId, text, replyToId: replyToId, confirmed: confirmed);
    _changed();
    _expectAnswer(typing: true);
  }

  Future<void> sendPoll(String question, List<String> options) async {
    await _repo.sendPoll(conversationId, question, options);
    _changed();
    _expectAnswer(typing: false);
  }

  Future<void> sendMatch(ChatMatchDraft draft) async {
    await _repo.sendMatch(conversationId, draft);
    _changed();
    _expectAnswer(typing: false);
  }

  Future<void> sendMedia(String src, {String caption = ''}) async {
    await _repo.sendMedia(conversationId, src, caption: caption);
    _changed();
    _expectAnswer(typing: true);
  }

  Future<void> sendVoice(String src, Duration duration) async {
    await _repo.sendVoice(conversationId, src, duration);
    _changed();
    _expectAnswer(typing: true);
  }

  Future<void> sendOffer(String postId, double price) async {
    await _repo.sendOffer(conversationId, postId, price);
    _changed();
    _expectAnswer(typing: true);
  }

  Future<void> answerOffer(String messageId, {required bool accept}) async {
    await _repo.answerOffer(messageId, accept: accept);
    _changed();
  }

  Future<void> sharePost(String postId) async {
    await _repo.sharePost(conversationId, postId);
    _changed();
    _expectAnswer(typing: true);
  }

  Future<void> vote(String messageId, String choice) async {
    await _repo.vote(messageId, choice);
    _changed();
  }

  Future<void> react(String messageId, String emoji) async {
    await _repo.react(messageId, emoji);
    _changed();
  }

  Future<void> delete(String messageId) async {
    await _repo.deleteMessage(messageId);
    _changed();
  }

  Future<void> report(String messageId, ReportReason reason, {String? details, bool mute = false}) async {
    await _repo.report(messageId, reason, details: details, muteAuthor: mute);
    _changed();
  }

  /// The demo's friends: « … écrit » then their answer (or their votes, silently).
  void _expectAnswer({required bool typing}) {
    _typing?.cancel();
    _answer?.cancel();
    if (typing) {
      _typing = Timer(typingDelay, () {
        if (ref.mounted) ref.read(chatTypingProvider(conversationId).notifier).set(true);
      });
    }
    _answer = Timer(answerDelay, () async {
      if (!ref.mounted) return;
      try {
        final answered = await _repo.demoAnswer(conversationId);
        if (!ref.mounted) return;
        ref.read(chatTypingProvider(conversationId).notifier).set(false);
        if (answered) {
          await _repo.markRead(conversationId);
          _changed();
        }
      } catch (_) {
        if (ref.mounted) ref.read(chatTypingProvider(conversationId).notifier).set(false);
      }
    });
  }
}

final chatProvider = AsyncNotifierProvider.family<ChatController, List<ChatMessage>, String>(ChatController.new);

/// « … est en train d’écrire » under the last message (demo).
class ChatTyping extends Notifier<bool> {
  ChatTyping(this.conversationId);

  final String conversationId;

  @override
  bool build() => false;

  void set(bool on) => state = on;
}

final chatTypingProvider = NotifierProvider.family<ChatTyping, bool, String>(ChatTyping.new);
