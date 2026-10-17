import '../data/auth_repository.dart';
import '../../../l10n/l10n.dart';

/// French copy for auth failures and validation, from the screen designs and component specs.
abstract final class AuthMessages {
  static final emailTaken = l10n.unCompteExisteDejaAvec;
  static final emailMissing = l10n.entreTonEmail;
  static final emailIncomplete = l10n.ajouteLaFinDeTon;
  static final passwordRules = l10n.tonMotDePasseDoit;
  static final passwordMissing = l10n.entreTonMotDePasse;
  static final consent = l10n.accepteLesConditionsPourContinuer;
  static final wrongCredentials = l10n.emailOuMotDePasse;
  static final codeIncomplete = l10n.entreLesChiffresDuCode;
  static final tooManyCodes = l10n.tropDEssaisReessaieDans;
  static final phoneVerified = l10n.numeroVerifie;
  static final passwordsMatch = l10n.lesMotsDePasseCorrespondent;
  static final passwordsDiffer = l10n.lesMotsDePasseNe;
  static final samePassword = l10n.ilDoitEtreDifferentDe;
  static final providerFailed =
      l10n.laConnexionNAPas;

  /// « Il te reste 2 essais » / « Il te reste 1 essai ».
  static String attemptsLeft(int n) => l10n.ilTeReste(n, n == 1 ? 'essai' : 'essais');

  /// AUTH-03b: « Code incorrect. Il te reste 2 essais. »
  static String wrongCode(int attemptsLeft) => l10n.codeIncorrect(AuthMessages.attemptsLeft(attemptsLeft));

  /// AUTH-05b detail.
  static String beforeLock(int attemptsLeft) =>
      l10n.avantLeBlocageTemporaire(AuthMessages.attemptsLeft(attemptsLeft));

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
