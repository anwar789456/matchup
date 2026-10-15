/// French formatting rules from design/design-system/s09-content.md, used in every language.
library;

/// « 3,5 » — a level on the 1,0–7,0 scale, comma and one decimal.
String formatLevel(double level) => level.toStringAsFixed(1).replaceAll('.', ',');

/// The band of a level: Débutant < 2,5 ≤ Intermédiaire < 4,0 ≤ Avancé < 5,5 ≤ Expert.
String levelBand(double level) {
  if (level < 2.5) return 'Débutant';
  if (level < 4.0) return 'Intermédiaire';
  if (level < 5.5) return 'Avancé';
  return 'Expert';
}

/// « 20 123 456 » — 8 Tunisian digits grouped 2-3-3 (fewer digits are grouped as far as they go).
String groupPhoneDigits(String digits) {
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i == 2 || i == 5) b.write(' ');
    b.write(digits[i]);
  }
  return b.toString();
}

/// « +216 20 123 456 ».
String formatPhone(String digits) => '+216 ${groupPhoneDigits(digits)}';

/// Initials from a display name: « Nour A. » → « NA »; [short] keeps one letter.
String initialsOf(String name, {bool short = false}) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final letters = parts.map((p) => p.characters.first.toUpperCase()).toList();
  if (short || letters.length == 1) return letters.first;
  return '${letters.first}${letters[1]}';
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}
