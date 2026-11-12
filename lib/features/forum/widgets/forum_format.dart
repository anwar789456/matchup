import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../data/forum_ai.dart';
import '../data/forum_models.dart';

/// « à l’instant », « il y a 5 min », « il y a 2 h », « hier », « il y a 3 j », « 2 oct. ».
String forumTime(DateTime time, DateTime now) {
  final d = now.difference(time);
  if (d.inHours < 24) return formatSince(time, now);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final days = today.difference(day).inDays;
  if (days == 1) return l10n.hier;
  if (days < 7) return l10n.ilYAJ(days);
  return '${time.day} ${formatMonth(time)}';
}

/// « Football 4,0 · Avancé » under the author's name (FRM-04).
String forumAuthorLevel(ForumAuthor a) {
  if (a.level == null) return '';
  final sport = a.sport?.label;
  return [if (sport != null) '$sport ${formatLevel(a.level!)}' else formatLevel(a.level!), levelBand(a.level!)].join(' · ');
}

/// What a [MuForumPostCard] shows for [post].
MuForumPostData forumCardData(ForumPost post, DateTime now) => MuForumPostData(
  category: post.category.label,
  categoryIcon: post.category.icon,
  categoryGlyph: post.category.glyph,
  sport: post.sport,
  title: post.title,
  excerpt: post.excerpt,
  tags: [for (final t in post.tags) ForumAi.hashtag(t)],
  authorName: post.author.name,
  authorLevel: post.author.level,
  authorImage: post.author.imageUrl,
  time: forumTime(post.createdAt, now),
  votes: post.score,
  replies: post.replies,
  bestAnswer: post.hasBestAnswer,
  pinned: post.pinned,
);

/// The first name, for « sans viser Omar ».
String firstName(String name) => name.split(' ').first;
