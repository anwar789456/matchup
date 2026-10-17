import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/game_actions.dart';
import '../data/games_repository.dart';

/// MAT-07 · Quitter la partie ?: the warning dialog, then the place is given back and the
/// snackbar « Partie quittée · Annuler » takes it back on « Annuler ».
Future<bool> confirmLeaveGame(BuildContext context, WidgetRef ref, MuGame game) async {
  final nav = Navigator.of(context, rootNavigator: true);
  final organiserFirst = (game.organiser ?? 'L’organisateur').split(' ').first;
  final freeUntil = game.start.subtract(const Duration(hours: 24));
  final leave = await MuDialog.show<bool>(
    context,
    tone: MuDialogTone.warning,
    icon: PhosphorIcons.signOut(),
    title: 'Quitter la partie ?',
    description:
        '${game.sport.label} ${game.sport == MuSport.football ? '5 vs 5' : ''} · ${game.title} · '
                '${formatDateTime(game.start)}. ${game.organiser ?? 'L’organisateur'} sera prévenu '
                'et ta place ira à la liste d’attente.'
            .replaceAll('  ', ' '),
    consequence:
        'Tes ${formatDT(game.pricePerPlayer)} seront remboursés sur ton solde MatchUp. '
        'Annulation gratuite jusqu’à ${formatDateTime(freeUntil)}.',
    consequenceIcon: PhosphorIcons.wallet(),
    actions: [
      MuButton.secondary(
        label: 'Rester dans la partie',
        size: MuButtonSize.l,
        fullWidth: true,
        onPressed: () => nav.pop(false),
      ),
      MuButton.destructive(
        label: 'Quitter la partie',
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
  MuToast.show(
    overlay.context,
    overlay: overlay,
    title: 'Partie quittée',
    description:
        '${formatDT(game.pricePerPlayer)} remboursés sur ton solde. $organiserFirst est prévenu.',
    action: MuAction('Annuler', () => actions.rejoin(game, team: team, slot: slot)),
  );
  return true;
}
