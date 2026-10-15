/// Search helpers shared by the search field and the repositories.
library;

/// Lower-case without French diacritics, for search matching (« ennasr » finds « Ennasr »,
/// « sidi bou said » finds « Sidi Bou Saïd »). Keeps the string length.
String foldAccents(String s) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}
