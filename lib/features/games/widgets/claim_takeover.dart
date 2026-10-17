import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../ui/ui.dart';
import '../../payments/data/payment_repository.dart';
import '../controllers/game_actions.dart';
import '../data/games_repository.dart';

/// GAM-04 · Place disponible: a player left a full game, the takeover counts 15:00 to claim it.
/// « Réclamer la place » pays the share (fake payment) and opens GAM-05; « Laisser passer » or
/// closing keeps the player on the waitlist.
Future<void> showClaimTakeover(BuildContext context, WidgetRef ref, String gameId) async {
  final actions = ref.read(gameActionsProvider);
  await actions.freeSpot(gameId);
  final d = await ref.read(gamesRepositoryProvider).details(gameId);
  if (!context.mounted) return;
  final g = d.game;
  final endsAt = DateTime.now().add(const Duration(minutes: 15));
  final claimed = await MuTakeover.show<bool>(
    context,
    builder: (ctx) => _Claim(details: d, endsAt: endsAt),
  );
  if (claimed == true && context.mounted) {
    final spot = firstFreeSlot(d.teams) ?? (0, 0);
    final receipt = await ref
        .read(paymentRepositoryProvider)
        .pay(g.pricePerPlayer, reason: 'Partie ${g.id} · ${g.title}');
    await actions.completeJoin(g, team: spot.$1, slot: spot.$2, receipt: receipt);
    if (!context.mounted) return;
    context.go(Routes.matches);
    context.push(Routes.gameJoined(gameId));
  }
}

class _Claim extends StatefulWidget {
  const _Claim({required this.details, required this.endsAt});

  final GameDetails details;
  final DateTime endsAt;

  @override
  State<_Claim> createState() => _ClaimState();
}

class _ClaimState extends State<_Claim> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.details.game;
    final end = g.start.add(const Duration(hours: 1));
    return MuTakeoverClaim(
      endsAt: widget.endsAt,
      total: const Duration(minutes: 15),
      sport: g.sport,
      venue: g.title,
      when: '${formatDay(g.start)} · ${formatTime(g.start)}–${formatTime(end)}',
      players: '${g.spotsTotal - g.spotsLeft}/${g.spotsTotal} joueurs',
      price: formatDT(g.pricePerPlayer),
      note:
          'Sans réponse, la place passe au suivant de la liste. Annulation gratuite jusqu’à '
          '${formatDateTime(widget.details.freeUntil)}.',
      onClose: () => Navigator.of(context).pop(false),
      onPass: () => Navigator.of(context).pop(false),
      onClaim: _busy
          ? () {}
          : () {
              setState(() => _busy = true);
              Navigator.of(context).pop(true);
            },
    );
  }
}
