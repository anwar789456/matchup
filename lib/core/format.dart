/// Formatting rules from design/design-system/s09-content.md: French by default; Arabic
/// (CLAUDE.md rule 12, RTL-01…03) keeps Western digits and the decimal comma, uses 24 h « 20:00 »,
/// Arabic day and month names and « 15 د.ت ».
library;

import 'dart:ui' show Locale;

bool _arabic = false;

/// Follows the app language (set by MatchUpApp).
void setFormatLocale(Locale locale) => _arabic = locale.languageCode == 'ar';

/// « DT », « د.ت » in Arabic.
String get dtUnit => _arabic ? 'د.ت' : 'DT';

/// Left-to-right isolate for ranges, codes and card numbers inside Arabic text (U+2066…U+2069).
String ltr(String s) => _arabic ? '\u2066$s\u2069' : s;

const _nbsp = ' ';
const _narrowNbsp = ' ';

/// « 3,5 » — a level on the 1,0–7,0 scale, comma and one decimal.
String formatLevel(double level) => level.toStringAsFixed(1).replaceAll('.', ',');

/// The band of a level: Débutant < 2,5 ≤ Intermédiaire < 4,0 ≤ Avancé < 5,5 ≤ Expert.
String levelBand(double level) {
  if (level < 2.5) return _arabic ? 'مبتدئ' : 'Débutant';
  if (level < 4.0) return _arabic ? 'متوسط' : 'Intermédiaire';
  if (level < 5.5) return _arabic ? 'متقدم' : 'Avancé';
  return _arabic ? 'خبير' : 'Expert';
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

/// « +216 20 •• •• 56 » — a phone number with the middle digits hidden.
String maskPhone(String digits) {
  if (digits.length != 8) return formatPhone(digits);
  return '+216 ${digits.substring(0, 2)} •• •• ${digits.substring(6)}';
}

/// Initials from a display name, first and last word: « Nour A. » → « NA », « Tunis Padel
/// Series » → « TS »; [short] keeps one letter.
String initialsOf(String name, {bool short = false}) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final letters = parts.map((p) => String.fromCharCode(p.runes.first).toUpperCase()).toList();
  if (short || letters.length == 1) return letters.first;
  return '${letters.first}${letters.last}';
}

const _weekdays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _weekdaysAr = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const _monthsAr = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];
const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// « sam. » — short weekday.
String formatWeekday(DateTime d) => (_arabic ? _weekdaysAr : _weekdays)[d.weekday - 1];

/// « oct. » — short month.
String formatMonth(DateTime d) => (_arabic ? _monthsAr : _months)[d.month - 1];

/// « 20h00 ».
String formatTime(DateTime d) =>
    '${d.hour}${_arabic ? ':' : 'h'}${d.minute.toString().padLeft(2, '0')}';

/// « sam. 18 oct. ».
String formatDay(DateTime d) => '${formatWeekday(d)} ${d.day} ${formatMonth(d)}';

/// « sam. 18 oct. · 20h00 ».
String formatDateTime(DateTime d) => '${formatDay(d)} · ${formatTime(d)}';

/// « 24–26 oct. », or « 30 oct. – 2 nov. » across months.
String formatDateRange(DateTime start, DateTime end) {
  if (start.month == end.month && start.year == end.year) {
    return '${ltr('${start.day}–${end.day}')} ${formatMonth(end)}';
  }
  return '${start.day} ${formatMonth(start)} – ${end.day} ${formatMonth(end)}';
}

/// « 1 500 » — whole numbers with a narrow no-break space between thousands.
String formatInt(int value) {
  final s = value.abs().toString();
  final b = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(_narrowNbsp);
    b.write(s[i]);
  }
  return b.toString();
}

/// « 1 500 » without the unit, for split value + unit layouts (« 15 » + « DT »).
String formatAmount(num amount) {
  if (amount == amount.roundToDouble()) return formatInt(amount.round());
  final fixed = amount.toStringAsFixed(3).split('.');
  return '${formatInt(int.parse(fixed[0]))},${fixed[1]}';
}

/// « 15 DT », « 1 500 DT », « 12,500 DT » (three decimals after a comma when not whole).
String formatDT(num amount) => '${formatAmount(amount)}$_nbsp$dtUnit';

/// « 14:59 » — minutes and seconds of a short hold.
String formatClock(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// « 08h00 » — a time of day given in minutes after midnight (« 00h00 » for midnight, also when
/// a range closes after it).
String formatHour(int minutes) {
  final m = minutes % (24 * 60);
  if (_arabic) return '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
  return '${(m ~/ 60).toString().padLeft(2, '0')}h${(m % 60).toString().padLeft(2, '0')}';
}

/// « à l’instant », « il y a 1 min », « il y a 3 h », « il y a 2 j ».
String formatSince(DateTime time, DateTime now) {
  final d = now.difference(time);
  if (d.inMinutes < 1) return 'à l’instant';
  if (d.inHours < 1) return 'il y a ${d.inMinutes} min';
  if (d.inDays < 1) return 'il y a ${d.inHours} h';
  return 'il y a ${d.inDays} j';
}

/// « d’Arena Five », « de Smash Padel » — « de » elided before a vowel or a mute h.
String elideDe(String name) => _arabic
    ? name
    : RegExp(r'^[aeiouyàâäéèêëîïôöùûüh]', caseSensitive: false).hasMatch(name)
    ? 'd’$name'
    : 'de $name';

/// Ends [text] with a full stop unless it already has one (« … jusqu’au mer. 28 oct. »).
String withFullStop(String text) => text.endsWith('.') ? text : '$text.';
