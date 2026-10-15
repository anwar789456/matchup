import '../data/auth_repository.dart';

/// French copy for auth failures and validation, from the screen designs and component specs.
abstract final class AuthMessages {
  static const emailTaken = 'Un compte existe déjà avec cet email.';
  static const emailMissing = 'Entre ton email.';
  static const emailIncomplete = 'Ajoute la fin de ton adresse, par exemple @gmail.com.';
  static const passwordRules = 'Ton mot de passe doit respecter les 3 règles.';
  static const passwordMissing = 'Entre ton mot de passe.';
  static const consent = 'Accepte les conditions pour continuer.';
  static const wrongCredentials = 'Email ou mot de passe incorrect.';
  static const codeIncomplete = 'Entre les 6 chiffres du code.';
  static const tooManyCodes = 'Trop d’essais. Réessaie dans 10 minutes.';
  static const phoneVerified = 'Numéro vérifié.';
  static const passwordsMatch = 'Les mots de passe correspondent.';
  static const passwordsDiffer = 'Les mots de passe ne correspondent pas.';
  static const samePassword = 'Il doit être différent de l’ancien.';
  static const providerFailed =
      'La connexion n’a pas abouti. Réessaie ou continue avec ton email.';

  /// « Il te reste 2 essais » / « Il te reste 1 essai ».
  static String attemptsLeft(int n) => 'Il te reste $n ${n == 1 ? 'essai' : 'essais'}';

  /// AUTH-03b: « Code incorrect. Il te reste 2 essais. »
  static String wrongCode(int attemptsLeft) => 'Code incorrect. ${AuthMessages.attemptsLeft(attemptsLeft)}.';

  /// AUTH-05b detail.
  static String beforeLock(int attemptsLeft) =>
      '${AuthMessages.attemptsLeft(attemptsLeft)} avant le blocage temporaire.';

  /// Null when the email looks complete.
  static String? validateEmail(String email) {
    final v = email.trim();
    if (v.isEmpty) return emailMissing;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(v)) return emailIncomplete;
    return null;
  }

  /// Message for a failed code check, or null when it is not a code failure.
  static String? codeFailure(Object e) => switch (e) {
        InvalidCode(:final attemptsLeft) => wrongCode(attemptsLeft),
        TooManyCodeAttempts() => tooManyCodes,
        _ => null,
      };
}
