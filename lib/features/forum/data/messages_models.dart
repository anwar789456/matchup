import 'package:flutter/foundation.dart';

import '../../../theme/theme.dart';
import 'forum_models.dart';

/// A private conversation between two members, or a group chat.
enum ConversationType {
  direct('direct'),
  group('groupe');

  const ConversationType(this.code);
  final String code;

  static ConversationType fromCode(String code) => values.firstWhere((t) => t.code == code, orElse: () => direct);
}

/// What a message carries: text, or one of the cards of the chat.
enum ChatKind {
  text('texte'),

  /// « Sondage »: a question and 2 to 4 answers, one vote per member.
  poll('sondage'),

  /// « Proposer un match »: a sport, a place, a time; each member answers « Je viens » or
  /// « Pas dispo ».
  match('match'),

  /// A Communauté discussion shared in the chat.
  share('partage'),

  /// A photo or a video (`data:` source), with an optional caption.
  image('image'),
  video('video'),

  /// A voice message.
  voice('vocal'),

  /// « Faire une offre » on an Équipement listing: a price the other side accepts, refuses or
  /// answers with a counter-offer.
  offer('offre'),

  /// « Yassine B. a créé le groupe », « Omar D. a quitté le groupe »…
  system('systeme');

  const ChatKind(this.code);
  final String code;

  static ChatKind fromCode(String code) => values.firstWhere((k) => k.code == code, orElse: () => text);
}

/// What happened in a [ChatKind.system] line.
enum ChatEvent {
  created('cree'),
  added('ajoute'),
  left('quitte'),
  renamed('renomme');

  const ChatEvent(this.code);
  final String code;

  static ChatEvent fromCode(String? code) => values.firstWhere((e) => e.code == code, orElse: () => created);
}

/// One line of the « Messages » list.
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.members,
    required this.createdAt,
    this.name,
    this.last,
    this.unread = 0,
    this.muted = false,
    this.admin = false,
  });

  final String id;
  final ConversationType type;

  /// The group's name; null for a private conversation (the other member's name is shown).
  final String? name;

  /// Everyone still in it, the reader included.
  final List<ForumAuthor> members;
  final ChatMessage? last;
  final int unread;
  final bool muted;

  /// The reader created the group (renames it, adds members).
  final bool admin;
  final DateTime createdAt;

  bool get group => type == ConversationType.group;

  /// When it last moved: its last message, else its creation.
  DateTime get activity => last?.createdAt ?? createdAt;
}

/// A [Conversation] seen from the reader: the other member of a private one.
extension ConversationPeople on Conversation {
  ForumAuthor? other(String meId) => group ? null : members.where((m) => m.id != meId).firstOrNull;

  /// The group's name, or the other member's.
  String title(String meId) => name ?? other(meId)?.name ?? '';
}

/// A reaction under a message: « ⚽ 3 », with whether the reader is one of them.
@immutable
class ChatReaction {
  const ChatReaction(this.emoji, this.count, {this.mine = false});

  final String emoji;
  final int count;
  final bool mine;
}

/// The message a reply quotes.
@immutable
class ChatQuote {
  const ChatQuote({required this.id, required this.author, required this.excerpt});

  final String id;
  final ForumAuthor author;
  final String excerpt;
}

/// A poll's answer with who chose it.
@immutable
class ChatPollOption {
  const ChatPollOption(this.label, this.voters);

  final String label;
  final List<ForumAuthor> voters;
}

@immutable
class ChatPoll {
  const ChatPoll({required this.question, required this.options, this.myChoice});

  final String question;
  final List<ChatPollOption> options;

  /// The index the reader voted for, or null.
  final int? myChoice;

  int get votes => options.fold(0, (n, o) => n + o.voters.length);
}

/// « Proposer un match »: who comes and who can't.
@immutable
class ChatMatch {
  const ChatMatch({
    required this.sport,
    required this.place,
    required this.at,
    this.going = const [],
    this.notGoing = const [],
    this.myAnswer,
  });

  final MuSport sport;
  final String place;
  final DateTime at;
  final List<ForumAuthor> going;
  final List<ForumAuthor> notGoing;

  /// true « Je viens », false « Pas dispo », null not answered.
  final bool? myAnswer;
}

/// A Communauté discussion shared in a chat.
@immutable
class ChatSharedPost {
  const ChatSharedPost({required this.postId, required this.title, this.category, this.sport, this.listing, this.image});

  final String postId;
  final String title;
  final ForumCategory? category;
  final MuSport? sport;

  /// An Équipement listing: its price and whether it is sold.
  final ForumListing? listing;

  /// The post's first photo.
  final String? image;
}

/// Where an offer stands.
enum OfferStatus {
  pending,
  accepted,
  declined,

  /// A newer offer on the same item followed in the conversation.
  replaced,
}

/// « Faire une offre »: the item, its asking price, the offered price and the answer.
@immutable
class ChatOffer {
  const ChatOffer({
    required this.postId,
    required this.title,
    required this.price,
    required this.status,
    this.asking,
    this.image,
    this.sold = false,
    this.sellerId,
  });

  final String postId;
  final String title;

  /// Offered, in dinars.
  final double price;

  /// The listing's price.
  final double? asking;
  final String? image;
  final bool sold;
  final OfferStatus status;

  /// The listing's author: the one who accepts an offer marks the item sold.
  final String? sellerId;
}

/// A photo, a video or a voice message in a chat.
@immutable
class ChatMedia {
  const ChatMedia(this.src, {this.duration});

  final String src;

  /// A voice message's length.
  final Duration? duration;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.author,
    required this.kind,
    required this.createdAt,
    this.body = '',
    this.mine = false,
    this.status = ForumStatus.published,
    this.quote,
    this.reactions = const [],
    this.poll,
    this.match,
    this.shared,
    this.media,
    this.offer,
    this.event,
    this.eventName,
    this.editedAt,
  });

  final String id;
  final String conversationId;
  final ForumAuthor author;
  final ChatKind kind;
  final String body;
  final bool mine;
  final ForumStatus status;
  final ChatQuote? quote;
  final List<ChatReaction> reactions;
  final ChatPoll? poll;
  final ChatMatch? match;
  final ChatSharedPost? shared;

  /// [ChatKind.image], [ChatKind.video], [ChatKind.voice].
  final ChatMedia? media;

  /// [ChatKind.offer].
  final ChatOffer? offer;

  /// [ChatKind.system]: what happened, and the group's new name for [ChatEvent.renamed].
  final ChatEvent? event;
  final String? eventName;
  final DateTime createdAt;
  final DateTime? editedAt;

  bool get hidden => status == ForumStatus.hidden;
  bool get deleted => status == ForumStatus.deleted;
}

/// What « Proposer un match » sends.
@immutable
class ChatMatchDraft {
  const ChatMatchDraft({required this.sport, required this.place, required this.at});

  final MuSport sport;
  final String place;
  final DateTime at;
}
