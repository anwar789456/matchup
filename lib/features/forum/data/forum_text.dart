/// Light Markdown of forum posts: `**gras**`, `*italique*`, `- ` / `1. ` lists, `> ` quotes,
/// `[texte](lien)`, `@pseudo`.
abstract final class ForumText {
  /// Plain text: markers removed, whitespace collapsed (card excerpt, search).
  static String plain(String markdown) => markdown
      .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
      .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!)
      .replaceAll(RegExp(r'(\*\*|__|\*|_|`)'), '')
      .replaceAll(RegExp(r'^\s{0,3}(>|[-*+]|\d+\.)\s+', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// About [length] characters cut on a word, with « … ».
  static String excerpt(String markdown, {int length = 160}) {
    final t = plain(markdown);
    if (t.length <= length) return t;
    final cut = t.substring(0, length);
    final space = cut.lastIndexOf(' ');
    return '${cut.substring(0, space > length - 20 ? space : length).trimRight()}…';
  }
}
