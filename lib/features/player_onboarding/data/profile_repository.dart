/// The player's public profile: pseudo, name, photo.
abstract interface class ProfileRepository {
  /// Whether [pseudo] is free (« @yassine.b est disponible »).
  Future<bool> isPseudoAvailable(String pseudo);

  Future<void> saveProfile({required String pseudo, String? fullName, List<int>? photo});
}

/// A few pseudos are already taken, so the « déjà pris » state can be tried.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;
  static const taken = {'mariem.k', 'skander.t', 'hamza.r', 'ines.m', 'nour.a', 'matchup'};

  String? savedPseudo;
  String? savedName;

  @override
  Future<bool> isPseudoAvailable(String pseudo) async {
    await Future<void>.delayed(latency);
    return !taken.contains(pseudo.trim().toLowerCase());
  }

  @override
  Future<void> saveProfile({required String pseudo, String? fullName, List<int>? photo}) async {
    await Future<void>.delayed(latency);
    savedPseudo = pseudo;
    savedName = fullName;
  }
}

/// Pseudo rules: 3–20 characters, letters, digits, « . » and « _ ».
String? pseudoError(String pseudo) {
  final p = pseudo.trim();
  if (p.isEmpty) return 'Choisis un pseudo.';
  if (p.length < 3) return 'Ton pseudo doit faire au moins 3 caractères.';
  if (p.length > 20) return 'Ton pseudo doit faire 20 caractères au maximum.';
  if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(p)) {
    return 'Lettres, chiffres, point et tiret bas uniquement.';
  }
  return null;
}

/// « Yassine B. » from « Yassine Belhadj ».
String publicName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${String.fromCharCode(parts.last.runes.first).toUpperCase()}.';
}
