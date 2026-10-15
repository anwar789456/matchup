/// French formatting rules from design/design-system/s09-content.md, used in every language.
library;

const _nbsp = ' ';
const _narrowNbsp = ' ';

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

/// « +216 20 •• •• 56 » — a phone number with the middle digits hidden.
String maskPhone(String digits) {
  if (digits.length != 8) return formatPhone(digits);
  return '+216 ${digits.substring(0, 2)} •• •• ${digits.substring(6)}';
}

/// Initials from a display name: « Nour A. » → « NA »; [short] keeps one letter.
String initialsOf(String name, {bool short = false}) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final letters = parts.map((p) => String.fromCharCode(p.runes.first).toUpperCase()).toList();
  if (short || letters.length == 1) return letters.first;
  return '${letters.first}${letters[1]}';
}

const _weekdays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _months = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// « sam. » — short weekday.
String formatWeekday(DateTime d) => _weekdays[d.weekday - 1];

/// « oct. » — short month.
String formatMonth(DateTime d) => _months[d.month - 1];

/// « 20h00 ».
String formatTime(DateTime d) => '${d.hour}h${d.minute.toString().padLeft(2, '0')}';

/// « sam. 18 oct. ».
String formatDay(DateTime d) => '${formatWeekday(d)} ${d.day} ${formatMonth(d)}';

/// « sam. 18 oct. · 20h00 ».
String formatDateTime(DateTime d) => '${formatDay(d)} · ${formatTime(d)}';

/// « 24–26 oct. », or « 30 oct. – 2 nov. » across months.
String formatDateRange(DateTime start, DateTime end) {
  if (start.month == end.month && start.year == end.year) {
    return '${start.day}–${end.day} ${formatMonth(end)}';
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
String formatDT(num amount) => '${formatAmount(amount)}${_nbsp}DT';

/// « 14:59 » — minutes and seconds of a short hold.
String formatClock(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
