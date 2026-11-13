import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../data/messages_models.dart';
import 'forum_format.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The time of a conversation in the list: « 17h40 » today, « hier », « mer. » this week,
/// then « 14 oct. ».
String chatListTime(DateTime time, DateTime now) {
  final days = _day(now).difference(_day(time)).inDays;
  if (days <= 0) return formatTime(time);
  if (days == 1) return l10n.hier;
  if (days < 7) return formatWeekday(time);
  return '${time.day} ${formatMonth(time)}';
}

/// The day between messages: « Aujourd’hui », « Hier », « mer. 14 oct. ».
String chatDayLabel(DateTime day, DateTime now) {
  final days = _day(now).difference(_day(day)).inDays;
  if (days <= 0) return l10n.msgAujourdhui;
  if (days == 1) return l10n.msgHier;
  return formatDay(day);
}

/// « Yassine B. a créé le groupe », « Omar D. a quitté le groupe »…
String chatEventLine(ChatMessage m) => switch (m.event ?? ChatEvent.created) {
  ChatEvent.created => l10n.msgACreeLeGroupe(m.author.name),
  ChatEvent.added => l10n.msgAAjoute(m.author.name, m.eventName ?? ''),
  ChatEvent.left => l10n.msgAQuitteLeGroupe(m.author.name),
  ChatEvent.renamed => l10n.msgARenommeLeGroupe(m.author.name, m.eventName ?? ''),
};

/// What a message says in one line (list preview, a reply's quote).
String chatSummary(ChatMessage m) {
  if (m.deleted) return l10n.forumMessageSupprime;
  if (m.hidden && !m.mine) return l10n.msgMessageMasque;
  return switch (m.kind) {
    ChatKind.text => m.body,
    ChatKind.poll => l10n.msgApercuSondage(m.poll?.question ?? ''),
    ChatKind.match => l10n.msgApercuMatch(m.match?.place ?? ''),
    ChatKind.share => l10n.msgApercuPartage(m.shared?.title ?? ''),
    ChatKind.image => m.body.isEmpty ? l10n.msgApercuPhoto : l10n.msgApercuPhotoTexte(m.body),
    ChatKind.video => m.body.isEmpty ? l10n.msgApercuVideo : l10n.msgApercuVideoTexte(m.body),
    ChatKind.voice => l10n.msgApercuVocal(formatClock(m.media?.duration ?? Duration.zero)),
    ChatKind.system => chatEventLine(m),
  };
}

/// The list's preview: « Toi : … » for the reader, « Omar : … » in a group.
String conversationPreview(Conversation c, String meId) {
  final m = c.last;
  if (m == null) return l10n.msgDisBonjour;
  final text = chatSummary(m).replaceAll('\n', ' ');
  if (m.kind == ChatKind.system) return text;
  if (m.mine) return l10n.msgToiPrefixe(text);
  if (c.group) return l10n.msgAuteurPrefixe(firstName(m.author.name), text);
  return text;
}
