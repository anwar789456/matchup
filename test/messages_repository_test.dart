import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/forum/data/forum_models.dart';
import 'package:matchup/features/forum/data/forum_seed.dart';
import 'package:matchup/features/forum/data/messages_repository.dart';
import 'package:matchup/features/forum/data/messages_seed.dart';
import 'package:matchup/features/forum/data/sqlite_messages_repository.dart';
import 'package:matchup/theme/theme.dart';

/// Messages between friends and group chats (schema v6): the story's conversations, private
/// conversations and groups, the FRM-03 check, polls, matches, reactions, leaving a group and
/// the demo friends' answers.
void main() {
  late AppDatabase db;
  late SqliteMessagesRepository me; // Yassine

  SqliteMessagesRepository as(String id) => SqliteMessagesRepository(db, now: () => storyNow, meId: () => id);
  final skander = ForumSeed.id(3);
  final mariem = ForumSeed.id(4);
  final group = MessagesSeed.conversationId('mercredi');

  setUp(() {
    db = AppDatabase();
    me = as(ForumSeed.me);
  });
  tearDown(() => db.close());

  test('the story: 4 conversations, most recent first, with their unread counts', () async {
    final list = await me.conversations();
    expect([for (final c in list) c.title(me.meId)], ['Skander T.', 'Five du mercredi · Arena Five', 'Padel Lac 2 · niveau 3,5', 'Mariem K.']);
    expect([for (final c in list) c.unread], [2, 2, 1, 0]);
    expect(await me.unreadCount(), 5);
    expect(list[1].admin, isTrue);
    expect(list[1].members, hasLength(6));
  });

  test('reading a conversation clears its count; muting takes it out of the badge', () async {
    await me.markRead(group);
    expect((await me.conversation(group)).unread, 0);
    await me.mute(MessagesSeed.conversationId('skander'), on: true);
    expect(await me.unreadCount(), 1);
  });

  test('the cards: poll with votes, match with answers, a reply quoting, reactions', () async {
    final messages = await me.messages(group);
    expect(messages.first.kind, ChatKind.system);
    final poll = messages.firstWhere((m) => m.kind == ChatKind.poll).poll!;
    expect(poll.question, 'Chasubles ou maillots ?');
    expect([for (final o in poll.options) o.voters.length], [3, 1]);
    expect(poll.myChoice, isNull);
    final match = messages.firstWhere((m) => m.kind == ChatKind.match).match!;
    expect(match.going, hasLength(6));
    expect(match.myAnswer, isTrue);
    final nour = messages.last;
    expect(nour.quote?.author.name, 'Omar D.');
    expect(messages.firstWhere((m) => m.body.startsWith('Je ramène')).reactions.single.count, 2);
  });

  test('voting on a poll, changing, then removing the vote', () async {
    final id = MessagesSeed.messageId('me3');
    Future<ChatPoll> poll() async => (await me.messages(group)).firstWhere((m) => m.id == id).poll!;
    await me.vote(id, '1');
    expect((await poll()).myChoice, 1);
    expect([for (final o in (await poll()).options) o.voters.length], [3, 2]);
    await me.vote(id, '0');
    expect([for (final o in (await poll()).options) o.voters.length], [4, 1]);
    await me.vote(id, '0');
    expect((await poll()).myChoice, isNull);
  });

  test('a private conversation is created once, then found again', () async {
    final id = await me.openDirect(ForumSeed.id(13));
    expect(await me.openDirect(ForumSeed.id(13)), id);
    // Empty: not in the list until something is said.
    expect((await me.conversations()).any((c) => c.id == id), isFalse);
    await me.send(id, 'Salut Karim, tu donnes des cours le samedi ?');
    final list = await me.conversations();
    expect(list.first.id, id);
    expect(list.first.title(me.meId), 'Karim J.');
    expect(await me.openDirect(skander), MessagesSeed.conversationId('skander'));
    expect(() => me.openDirect(ForumSeed.me), throwsA(isA<ForumRuleException>()));
  });

  test('a group needs a name and 2 friends; it starts with « a créé le groupe »', () async {
    expect(() => me.createGroup('', [skander, mariem]), throwsA(isA<ForumRuleException>()));
    expect(() => me.createGroup('Duo', [skander]), throwsA(isA<ForumRuleException>()));
    final id = await me.createGroup('Foot du dimanche', [skander, mariem]);
    final c = await me.conversation(id);
    expect(c.group, isTrue);
    expect(c.admin, isTrue);
    expect(c.members, hasLength(3));
    expect((await me.messages(id)).single.event, ChatEvent.created);
  });

  test('FRM-03 in a chat: a hurtful text is stopped, sent masked when confirmed', () async {
    final id = MessagesSeed.conversationId('skander');
    const text = 'T’es nul, t’as jamais touché un ballon.';
    expect(() => me.send(id, text), throwsA(isA<ForumAlertException>()));
    final sent = await me.send(id, text, confirmed: true);
    expect(sent.hidden, isTrue);
    // Skander does not read it.
    final seen = (await as(skander).messages(id)).last;
    expect(seen.hidden, isTrue);
    expect(seen.body, isEmpty);
  });

  test('only the reader deletes their messages; reports and mutes the others', () async {
    final id = MessagesSeed.conversationId('skander');
    expect(() => me.deleteMessage(MessagesSeed.messageId('sk1')), throwsA(isA<ForumRuleException>()));
    final mine = await me.send(id, 'Oups, mauvais message');
    await me.deleteMessage(mine.id);
    expect((await me.messages(id)).last.deleted, isTrue);
    await me.report(MessagesSeed.messageId('sk3'), ReportReason.spam, muteAuthor: true);
    expect((await me.messages(id)).firstWhere((m) => m.id == MessagesSeed.messageId('sk3')).hidden, isTrue);
    expect((await me.friends()).any((f) => f.id == skander), isFalse);
  });

  test('reactions toggle', () async {
    final id = MessagesSeed.messageId('me5');
    await me.react(id, '⚽');
    var r = (await me.messages(group)).firstWhere((m) => m.id == id).reactions.single;
    expect((r.emoji, r.count, r.mine), ('⚽', 1, true));
    await me.react(id, '⚽');
    r = (await me.messages(group)).firstWhere((m) => m.id == id).reactions.firstOrNull ?? const ChatReaction('', 0);
    expect(r.count, 0);
  });

  test('leaving a group: a line for the others, gone from the list', () async {
    await me.leave(group);
    expect((await me.conversations()).any((c) => c.id == group), isFalse);
    expect(() => me.messages(group), throwsA(isA<ForumRuleException>()));
    final line = (await as(skander).messages(group)).last;
    expect(line.event, ChatEvent.left);
    expect(line.author.name, 'Yassine B.');
  });

  test('a match proposal counts its author in; the demo friends answer', () async {
    final id = MessagesSeed.conversationId('padel');
    final m = await me.sendMatch(id, ChatMatchDraft(sport: MuSport.padel, place: 'Smash Padel Club', at: storyNow.add(const Duration(days: 6))));
    expect((await me.messages(id)).firstWhere((x) => x.id == m.id).match!.myAnswer, isTrue);
    expect(await me.demoAnswer(id), isTrue);
    final answered = (await me.messages(id)).firstWhere((x) => x.id == m.id).match!;
    expect(answered.going.length + answered.notGoing.length, greaterThan(1));
  });

  test('the demo friends answer a text, never a real member', () async {
    final id = MessagesSeed.conversationId('mariem');
    await me.send(id, 'On se cale une séance jeudi ?');
    expect(await me.demoAnswer(id), isTrue);
    final last = (await me.messages(id)).last;
    expect(last.author.id, mariem);
    expect(MessagesSeed.answersToQuestion, contains(last.body));
    // Nothing more until the reader writes again.
    expect(await me.demoAnswer(id), isFalse);

    const real = '33333333-3333-4333-8333-333333333333';
    await (await db.db).insert('forum_membres', {'id': real, 'auteur_id': real, 'nom': 'Real P.', 'niveau': 3.0, 'maj_le': storyNow.toIso8601String()});
    final direct = await me.openDirect(real);
    await me.send(direct, 'Salut !');
    expect(await me.demoAnswer(direct), isFalse);
  });

  test('a Supabase member keeps the story player’s conversations', () async {
    const supabase = '44444444-4444-4444-8444-444444444444';
    final list = await as(supabase).conversations();
    expect(list, hasLength(4));
    final first = (await as(supabase).messages(MessagesSeed.conversationId('mariem'))).last;
    expect(first.mine, isTrue);
  });
}
