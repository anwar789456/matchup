import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../booking/widgets/booking_scaffold.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/game_actions.dart';
import '../data/games_repository.dart';
import '../widgets/claim_takeover.dart';
import '../../../l10n/l10n.dart';

/// GAM-03 · Liste d’attente: « Tu es 3e sur la liste d’attente », the queue, the game, how it
/// works, the SMS switch, then « Quitter la liste » and « Parties similaires ». Tapping the queue
/// card plays the « place libérée » takeover (GAM-04).
class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  bool _sms = true;

  // GAM-03: the queue dots are 40; the game thumb 56; the how-it-works tiles 36.
  static const double _dot = 40;
  static const double _thumb = 56;
  static const double _tile = 36;

  Future<void> _leave() async {
    await ref.read(gameActionsProvider).leaveWaitlist(widget.gameId);
    if (!mounted) return;
    MuToast.show(context, title: l10n.tuAsQuitteLaListe);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final details = ref.watch(gameDetailsProvider(widget.gameId));
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(title: l10n.listeDAttente, onBack: () => context.pop()),
          Expanded(
            child: switch (details) {
              AsyncData(:final value) => _body(context, value),
              AsyncError() => Center(
                child: MuEmptyState(
                  title: l10n.partieIntrouvable,
                  actions: [MuButton.primary(label: l10n.retour, onPressed: () => context.pop())],
                ),
              ),
              _ => MuSkeletonGroup(
                label: l10n.chargement,
                child: const Padding(
                  padding: EdgeInsets.all(MuSpace.s4),
                  child: MuSkeleton.text(lines: 5),
                ),
              ),
            },
          ),
        ],
      ),
      bottomNavigationBar: details.value == null
          ? null
          : StickyActionBar(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MuButton.destructiveOutline(
                        label: l10n.quitterLaListe,
                        size: MuButtonSize.xl,
                        fullWidth: true,
                        onPressed: _leave,
                      ),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: MuButton.primary(
                        label: l10n.partiesSimilaires,
                        size: MuButtonSize.xl,
                        fullWidth: true,
                        onPressed: () => context.go(Routes.explore),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _body(BuildContext context, GameDetails d) {
    final c = context.mu;
    final g = d.game;
    final position = d.waitlistPosition ?? d.waitlistCount + 1;
    final ahead = position - 1;

    Widget dot(Widget child, String label, {Color? fill, Color? ring, bool dashed = false}) =>
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _dot,
              height: _dot,
              alignment: Alignment.center,
              decoration: dashed
                  ? null
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      color: fill,
                      border: ring == null ? null : Border.all(color: ring),
                    ),
              child: dashed
                  ? CustomPaint(
                      painter: _DashedCircle(color: c.textSecondary),
                      child: SizedBox.expand(child: Center(child: child)),
                    )
                  : child,
            ),
            const SizedBox(height: MuSpace.s2),
            Text(label, style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        );

    final queue = Theme(
      data: MuTheme.dark(),
      child: Builder(
        builder: (context) {
          final dc = context.mu;
          return Container(
            padding: const EdgeInsets.all(MuSpace.s5),
            decoration: BoxDecoration(
              color: dc.bg,
              borderRadius: MuRadius.lgAll,
              boxShadow: MuElevation.of(context).level2,
            ),
            child: Semantics(
              button: true,
              hint: l10n.simulerUnePlaceLiberee,
              child: InkWell(
                borderRadius: MuRadius.lgAll,
                onTap: () => showClaimTakeover(context, ref, widget.gameId),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: MuStatusBadge(
                        status: MuStatus.pending,
                        label: l10n.enAttente,
                        size: MuBadgeSize.s,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$position',
                                style: MuType.numHero.copyWith(color: dc.accent),
                              ),
                              TextSpan(
                                text: position == 1 ? 'er' : 'e',
                                style: MuType.numM.copyWith(color: dc.accent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: MuSpace.s4),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.tuEsESurLa(position),
                              style: MuType.h2.copyWith(color: dc.text),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuSpace.s2),
                    Text(
                      ahead == 0
                          ? l10n.cEstToiLeProchain
                          : l10n.plusQueJoueurAvantToi(ahead, ahead > 1 ? 's' : ''),
                      style: MuType.body.copyWith(color: dc.textSecondary),
                    ),
                    const SizedBox(height: MuSpace.s5),
                    Row(
                      children: [
                        dot(
                          Icon(
                            PhosphorIcons.arrowLeft(),
                            size: MuSize.iconXs,
                            color: dc.textSecondary,
                          ),
                          l10n.placeLibre,
                          dashed: true,
                        ),
                        Expanded(child: Divider(color: dc.border, thickness: 1)),
                        for (var i = 1; i < position; i++) ...[
                          dot(
                            Text('$i', style: MuType.labelL.copyWith(color: dc.text)),
                            i == 1 ? '1er' : '${i}e',
                            fill: dc.surfaceMuted,
                            ring: dc.border,
                          ),
                          Expanded(child: Divider(color: dc.border, thickness: 1)),
                        ],
                        dot(
                          Text(
                            initialsOf(Story.myName),
                            style: MuType.labelL.copyWith(color: dc.onAccent),
                          ),
                          l10n.toi,
                          fill: dc.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    final gameCard = MuCardSurface(
      padding: const EdgeInsets.all(MuSpace.s3),
      onTap: () => context.pop(),
      semanticLabel: l10n.completVoirLaPartie(g.title, formatDateTime(g.start)),
      child: Row(
        children: [
          SizedBox.square(
            dimension: _thumb,
            child: ClipRRect(
              borderRadius: MuRadius.smAll,
              child: MuCourtArt(sport: g.sport, variant: MuCourtArtVariant.pattern),
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.title, style: MuType.label.copyWith(color: c.text)),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${formatDay(g.start)} · '),
                      TextSpan(
                        text: formatTime(g.start),
                        style: MuType.labelS.copyWith(color: c.text),
                      ),
                      TextSpan(
                        text:
                            ' · ${sportShort(g.sport) == 'foot' ? l10n.footVs : g.sport.label} '
                            '${g.gameType.toLowerCase()}',
                      ),
                    ],
                  ),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.usersThree(),
                      size: MuSize.iconXs - 2,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: MuSpace.s1),
                    Text(
                      '${g.spotsTotal - g.spotsLeft}/${g.spotsTotal}',
                      style: MuType.labelS.copyWith(color: c.text),
                    ),
                    Text(l10n.complet2, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatDT(g.pricePerPlayer), style: MuType.numM.copyWith(color: c.text)),
              Text('/ pers.', style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ],
      ),
    );

    Widget step(IconData icon, String title, Widget text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _tile,
          height: _tile,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: MuRadius.smAll,
            boxShadow: MuElevation.of(context).level1,
          ),
          child: Icon(icon, size: MuSize.iconS, color: c.text),
        ),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MuType.label.copyWith(color: c.text)),
              text,
            ],
          ),
        ),
      ],
    );
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    return ListView(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
      children: [
        queue,
        const SizedBox(height: MuSpace.s4),
        gameCard,
        const SizedBox(height: MuSpace.s6),
        Semantics(
          header: true,
          child: Text(l10n.commentCaMarche, style: MuType.h2.copyWith(color: c.text)),
        ),
        const SizedBox(height: MuSpace.s4),
        step(
          PhosphorIcons.bellRinging(),
          l10n.onTePrevientToutDe,
          Text(l10n.desQuUnJoueurSe, style: caption),
        ),
        const SizedBox(height: MuSpace.s4),
        step(
          PhosphorIcons.timer(),
          l10n.minPourReclamerLaPlace,
          Text(l10n.sansReponseEllePasseAu, style: caption),
        ),
        const SizedBox(height: MuSpace.s4),
        step(
          PhosphorIcons.wallet(),
          l10n.rienAPayerDIci,
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l10n.tuPaies),
                TextSpan(
                  text: formatDT(g.pricePerPlayer),
                  style: MuType.labelS.copyWith(color: c.text),
                ),
                TextSpan(text: l10n.seulementSiTuReclamesLa),
              ],
            ),
            style: caption,
          ),
        ),
        const SizedBox(height: MuSpace.s5),
        MuCardSurface(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
          child: MuSwitch(
            value: _sms,
            icon: PhosphorIcons.chatText(),
            label: l10n.mePrevenirAussiParSms,
            description: '+216 20 123 456',
            onChanged: (v) => setState(() => _sms = v),
          ),
        ),
      ],
    );
  }
}

/// The dashed « place libre » ring of the queue.
class _DashedCircle extends CustomPainter {
  const _DashedCircle({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addOval((Offset.zero & size).deflate(1));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => old.color != color;
}
