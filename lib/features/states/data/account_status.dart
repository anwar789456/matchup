import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A suspension decided by the admin (ADM-04 → STA-07).
@immutable
class Suspension {
  const Suspension({
    required this.until,
    required this.reason,
    this.refunded = 0,
    this.freedGames = 0,
  });

  final DateTime until;

  /// « 2 matchs manqués sans prévenir, le sam. 26 sept. et le jeu. 8 oct. ».
  final String reason;

  /// Shares refunded to the balance for the games freed during the suspension.
  final num refunded;
  final int freedGames;
}

/// Suspended accounts by player name, shared by the admin space and the player's Home.
class SuspensionsController extends Notifier<Map<String, Suspension>> {
  @override
  Map<String, Suspension> build() => const {};

  void suspend(String player, Suspension s) => state = {...state, player: s};

  void lift(String player) => state = {...state}..remove(player);
}

final suspensionsProvider = NotifierProvider<SuspensionsController, Map<String, Suspension>>(
  SuspensionsController.new,
);

/// The signed-in account's flags: email verified (STA-06) and a session that expired (STA-04).
@immutable
class AccountFlags {
  const AccountFlags({this.emailVerified = true, this.emailSentTo, this.emailBannerHidden = false});

  final bool emailVerified;

  /// Set once « Renvoyer l’email » was tapped.
  final String? emailSentTo;

  /// « Masquer jusqu’à demain ».
  final bool emailBannerHidden;

  AccountFlags copyWith({bool? emailVerified, String? emailSentTo, bool? emailBannerHidden}) =>
      AccountFlags(
        emailVerified: emailVerified ?? this.emailVerified,
        emailSentTo: emailSentTo ?? this.emailSentTo,
        emailBannerHidden: emailBannerHidden ?? this.emailBannerHidden,
      );
}

class AccountFlagsController extends Notifier<AccountFlags> {
  @override
  AccountFlags build() => const AccountFlags();

  void setEmailVerified(bool v) =>
      state = AccountFlags(emailVerified: v);

  void emailSent(String to) => state = state.copyWith(emailSentTo: to);

  void hideEmailBanner() => state = state.copyWith(emailBannerHidden: true);
}

final accountFlagsProvider = NotifierProvider<AccountFlagsController, AccountFlags>(
  AccountFlagsController.new,
);
