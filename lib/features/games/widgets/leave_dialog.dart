import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/game_actions.dart';
import '../data/games_repository.dart';
import '../../../l10n/l10n.dart';

/// MAT-07 · Quitter la partie ?: the warning dialog, then the place is given back and the
/// snackbar « Partie quittée · Annuler » takes it back on « Annuler ».
Future<bool> confirmLeaveGame(BuildContext context, WidgetRef ref, MuGame game) async {
  final nav = Navigator.of(context, rootNavigator: true);
  final freeUntil = game.start.subtract(const Duration(hours: 24));
  final leave = await MuDialog.show<bool>(
    context,
    tone: MuDialogTone.warning,
    icon: PhosphorIcons.signOut(),
    title: l10n.quitterLaPartie2,
    description:
        l10n.seraPrevenuEtTaPlace(game.sport.label, game.sport == MuSport.football ? l10n.vs3 : '', game.title, formatDateTime(game.start), game.organiser ?? l10n.lOrganisateur2)
            .replaceAll('  ', ' '),
    consequence:
        l10n.tesSerontRemboursesSurTon(formatDT(game.pricePerPlayer), formatDateTime(freeUntil)),
    consequenceIcon: PhosphorIcons.wallet(),
    actions: [
      MuButton.secondary(
        label: l10n.resterDansLaPartie,
        size: MuButtonSize.l,
        fullWidth: true,
        onPressed: () => nav.pop(false),
      ),
      MuButton.destructive(
        label: l10n.quitterLaPartie,
        size: MuButtonSize.l,
        fullWidth: true,
        onPressed: () => nav.pop(true),
      ),
    ],
  );
  if (leave != true || !context.mounted) return false;
  // The row that opened the dialog disappears with the game: the snackbar needs the app's overlay.
  final overlay = Overlay.of(context, rootOverlay: true);

  // Remember the position to give it back on « Annuler ».
  final details = await ref.read(gamesRepositoryProvider).details(game.id!);
  final team = details.joinedTeam ?? 0;
  final slot = details.joinedSlot ?? 0;
  final actions = ref.read(gameActionsProvider);
  await actions.leave(game);
  if (!overlay.mounted) return true;
  // Snackbar.md: an undo is a snackbar, not a toast.
  MuSnackbar.show(
    overlay.context,
    overlay: overlay,
    message: l10n.partieQuittee,
    action: MuAction(l10n.annuler, () => actions.rejoin(game, team: team, slot: slot)),
  );
  return true;
}
