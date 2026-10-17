import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/directions.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../home/controllers/home_providers.dart';
import '../../states/widgets/state_widgets.dart';
import '../../notifications/controllers/live_events.dart';
import '../../payments/controllers/checkout_controller.dart';
import '../../venue/data/venue_details.dart';
import '../controllers/game_actions.dart';
import '../data/games_repository.dart';
import '../widgets/game_widgets.dart';
import '../widgets/leave_dialog.dart';
import '../../../l10n/l10n.dart';

/// GAM-01 · Partie ouverte / GAM-02 · Partie complète: the lobby of an open game — hero, facts,
/// the venue, the organiser, « Pourquoi pour toi », the lineup, the chat preview, the rules — and
/// the sticky « Rejoindre et payer » or « Rejoindre la liste d’attente ». Joined, the bar turns
/// into « Tu joues ».
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _hidden = false;

  // GAM-01: hero 188 high; the main card overlaps it by 20 with a radius-lg top.
  static const double _hero = 188;
  static const double _overlap = 20;
  static const double _bottomRoom = MuSpace.s16 + MuSpace.s8;

  /// « Rejoindre et payer »: the share goes through the checkout (PAY-01); once paid the place is
  /// taken and PAY-09 « Terminé » leads to GAM-05.
  void _join(GameDetails d, (int, int) spot) {
    final g = d.game;
    final format = g.sport == MuSport.football ? l10n.footVs : g.sport.label;
    ref.read(checkoutRequestProvider.notifier).start(
      CheckoutRequest(
        kind: CheckoutKind.share,
        eyebrow: l10n.taPartPartie('${g.id}'),
        title: g.court == null ? g.venue : '${g.venue} · ${g.court}',
        subtitle: '${formatDay(g.start)} · ${formatTime(g.start)} · $format',
        amount: g.pricePerPlayer,
        lineLabel: l10n.taPartJoueurSur(g.spotsTotal),
        sport: g.sport,
        policy: (
          g.start.subtract(VenueDetails.freeUntil),
          g.start.subtract(VenueDetails.halfUntil),
        ),
        policyVenue: g.venue,
        detailRows: [
          (l10n.quoi, l10n.placeDansUnePartieOuverte, g.levelMin == null ? g.gameType : '${g.gameType} · ${formatLevel(g.levelMin!)} – ${formatLevel(g.levelMax!)}'),
          (l10n.ou, g.venue, g.place),
          (l10n.quand, formatDateTime(g.start), null),
          (l10n.joueurs, '${g.spotsTotal - g.spotsLeft}/${g.spotsTotal}', l10n.placesEncoreOuvertes(g.spotsLeft)),
        ],
        successRoute: Routes.gameJoined(widget.gameId),
        onPaid: (receipt, fromBalance) => ref
            .read(gameActionsProvider)
            .completeJoin(g, team: spot.$1, slot: spot.$2, receipt: receipt, fromBalance: fromBalance),
      ),
    );
    context.push(Routes.checkout);
  }

  Future<void> _waitlist(GameDetails d) async {
    await ref.read(gameActionsProvider).joinWaitlist(widget.gameId);
    if (!mounted) return;
    context.push(Routes.gameWaitlist(widget.gameId));
  }

  void _share(GameDetails d) => SharePlus.instance.share(
    ShareParams(
      text:
          l10n.httpsMatchupTnG(d.game.sport.label, d.game.title, formatDateTime(d.game.start), '${d.game.id}'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final details = ref.watch(gameDetailsProvider(widget.gameId));
    // NOT-07: someone joins while the lobby is open — the lineup refreshes and a toast says so.
    ref.listen(gameLiveEventsProvider, (_, next) {
      final e = next.value;
      if (e == null || e.gameId != widget.gameId) return;
      MuToast.show(
        context,
        tone: MuToastTone.info,
        icon: PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
        title: e.title,
        description: e.description,
      );
    });
    return Scaffold(
      backgroundColor: c.bg,
      body: switch (details) {
        AsyncData(:final value) => _body(context, value),
        // STA-03: a dead link (expired, or the organiser deleted the game).
        AsyncError() => Column(
          children: [
            MuTopAppBar.compact(
              title: l10n.partie,
              onBack: () => goBack(context, Routes.explore),
            ),
            Expanded(
              child: NotFoundState(
                title: l10n.cettePartieNExistePlus,
                description:
                    l10n.leLienAExpireOu,
                link: 'matchup.tn/p/${widget.gameId}',
                actionLabel: l10n.trouverUneAutrePartie,
                onAction: () => context.go(Routes.explore),
                alternativesTitle: l10n.partiesProchesCeWeekEnd,
                alternatives: [
                  for (final g in (ref.watch(recommendedGamesProvider).value ?? const <MuGame>[]).take(2))
                    MuGameCard(
                      game: g,
                      onTap: () => context.push(Routes.game(g.id!)),
                      onJoin: () => context.push(Routes.game(g.id!)),
                    ),
                ],
              ),
            ),
          ],
        ),
        _ => Column(
          children: [
            SizedBox(
              height: _hero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const MuSkeleton(height: _hero, radius: BorderRadius.zero),
                  Align(
                    alignment: Alignment.topCenter,
                    child: MuTopAppBar.media(onBack: () => context.pop()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MuSkeletonGroup(
                label: l10n.chargementDeLaPartie,
                child: const Padding(
                  padding: EdgeInsets.all(MuSpace.s4),
                  child: MuSkeleton.text(lines: 6),
                ),
              ),
            ),
          ],
        ),
      },
      bottomNavigationBar: details.value == null ? null : _bar(context, details.value!),
    );
  }

  Widget _bar(BuildContext context, GameDetails d) {
    final c = context.mu;
    final g = d.game;
    final Widget hint;
    final Widget action;
    switch (d.membership) {
      case GameMembership.joined:
        hint = _hintRow(
          context,
          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
          c.successText,
          l10n.tuJouesAnnulationGratuiteJusqu(formatDateTime(d.freeUntil)),
        );
        action = Row(
          children: [
            Expanded(
              child: MuButton.secondary(
                label: l10n.quitterLaPartie,
                leading: PhosphorIcons.signOut(),
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: () => confirmLeaveGame(context, ref, g),
              ),
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: MuButton.primary(
                label: l10n.discussion,
                leading: PhosphorIcons.chatCircle(),
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: () => showComingSoon(context),
              ),
            ),
          ],
        );
      case GameMembership.waitlisted:
        hint = _hintRow(
          context,
          PhosphorIcons.hourglassMedium(),
          c.warningText,
          l10n.tuEsESurLa(d.waitlistPosition ?? 1),
        );
        action = MuButton.primary(
          label: l10n.voirLaListeDAttente,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(Routes.gameWaitlist(widget.gameId)),
        );
      case GameMembership.none:
        if (g.isFull) {
          hint = Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l10n.gratuitTuNePaies),
                TextSpan(
                  text: formatDT(g.pricePerPlayer),
                  style: MuType.labelS.copyWith(color: c.text),
                ),
                TextSpan(text: l10n.queSiTuReclamesUne),
              ],
            ),
            textAlign: TextAlign.center,
            style: MuType.caption.copyWith(color: c.textSecondary),
          );
          action = MuButton.primary(
            label: l10n.rejoindreLaListeDAttente,
            leading: PhosphorIcons.hourglassMedium(),
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: () => _waitlist(d),
          );
        } else {
          hint = _hintRow(
            context,
            PhosphorIcons.shieldCheck(),
            c.successText,
            l10n.annulationGratuiteJusquA(formatDateTime(d.freeUntil)),
          );
          final spot = firstFreeSlot(d.teams);
          action = MuButton.primary(
            label: l10n.rejoindreEtPayer,
            price: formatDT(g.pricePerPlayer),
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: spot == null ? null : () => _join(d, spot),
          );
        }
    }
    return StickyActionBar(children: [hint, action]);
  }

  Widget _hintRow(BuildContext context, IconData icon, Color iconColor, String text) {
    final c = context.mu;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: MuSize.iconXs, color: iconColor),
        const SizedBox(width: MuSpace.s1),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, GameDetails d) {
    final c = context.mu;
    final g = d.game;
    final full = g.isFull;
    final joined = d.membership == GameMembership.joined;
    final sportLine = g.sport == MuSport.football ? l10n.vs(g.sport.label) : g.sport.label;
    final organiserFirst = (g.organiser ?? l10n.lOrganisateur).split(' ').first;

    final hero = SizedBox(
      height: _hero + _overlap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MuCourtArt(
            sport: g.sport,
            variant: MuCourtArtVariant.photo,
            semanticLabel: '${g.venue}, ${g.court ?? ''}',
          ),
          Align(
            alignment: Alignment.topCenter,
            child: MuTopAppBar.media(
              onBack: () => context.pop(),
              actions: [
                MuBarAction(
                  icon: PhosphorIcons.shareNetwork(),
                  label: l10n.partagerLaPartie,
                  onPressed: () => _share(d),
                ),
                MuBarAction(
                  icon: PhosphorIcons.dotsThreeVertical(),
                  label: l10n.plusDActions,
                  onPressed: () => showComingSoon(context),
                ),
              ],
            ),
          ),
          Positioned(
            left: MuSpace.s4,
            right: MuSpace.s4,
            bottom: _overlap + MuSpace.s3,
            child: Row(
              children: [
                Flexible(child: KickoffPill(start: g.start)),
                const SizedBox(width: MuSpace.s2),
                if (full)
                  MuStatusBadge(status: MuStatus.full, label: l10n.complet, size: MuBadgeSize.s)
                else
                  MuStatusBadge(
                    status: MuStatus.confirmed,
                    label: l10n.terrainReserve,
                    size: MuBadgeSize.s,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final chips = Wrap(
      spacing: MuSpace.s2,
      runSpacing: MuSpace.s2,
      children: [
        MuChip(label: sportLine, kind: MuChipKind.sport, sport: g.sport, size: MuChipSize.s),
        MuChip(label: g.gameType, icon: PhosphorIcons.usersThree(), size: MuChipSize.s),
        if (g.levelLabel != null)
          MuChip(
            label: l10n.niveau2(g.levelLabel!.replaceAll('–', ' – ')),
            icon: PhosphorIcons.gauge(),
            size: MuChipSize.s,
          ),
      ],
    );

    final facts = FactsCard(
      cells: [
        FactCell(formatDay(g.start), formatTime(g.start), caption: l10n.jusquA(formatTime(d.end))),
        FactCell(
          l10n.taPart,
          formatDT(g.pricePerPlayer),
          caption: l10n.leTerrain(formatDT(d.courtPrice)),
        ),
        full
            ? FactCell(
                l10n.joueurs,
                '${g.spotsTotal}/${g.spotsTotal}',
                captionWidget: Text(l10n.complet, style: MuType.caption.copyWith(color: c.errorText)),
              )
            : FactCell(
                l10n.places,
                '${g.spotsLeft}',
                caption: '${d.playersIn}/${g.spotsTotal} joueurs',
              ),
      ],
    );

    final venueCard = MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenueRow(
            venue: d.venue,
            street: Story.streetOf(d.venue),
            distanceKm: g.distanceKm,
            onDirections: () => openDirections(d.venue.position!),
            onOpen: () => context.push(Routes.venue(d.venue.id)),
          ),
          const SizedBox(height: MuSpace.s4),
          Divider(height: 1, thickness: 1, color: c.border),
          const SizedBox(height: MuSpace.s3),
          Semantics(
            button: true,
            label: l10n.organiseeParVoirSonProfil('${g.organiser}'),
            excludeSemantics: true,
            child: InkWell(
              borderRadius: MuRadius.smAll,
              onTap: () => context.push(Routes.player(g.organiser ?? '')),
              child: Row(
                children: [
                  MuAvatar(
                    name: g.organiser ?? '',
                    level: d.teams
                        .expand((t) => t.players)
                        .firstWhere((p) => p?.role == MuLineupRole.organizer, orElse: () => null)
                        ?.level,
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.organiseePar,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                g.organiser ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MuType.labelL.copyWith(color: c.text),
                              ),
                            ),
                            if (g.organiserReliability != null) ...[
                              const SizedBox(width: MuSpace.s2),
                              MuReliabilityBadge(
                                score: g.organiserReliability!,
                                size: MuBadgeSize.s,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(PhosphorIcons.caretRight(), size: MuSize.iconS, color: c.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final why = _hidden || g.matchFit == null
        ? null
        : Container(
            padding: const EdgeInsets.all(MuSpace.s4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: MuRadius.mdAll,
              border: Border.all(color: c.aiSoft, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Semantics(
                              header: true,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  l10n.pourquoiPourToi,
                                  style: MuType.h3.copyWith(color: c.text),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: MuSpace.s2),
                          MuAiLabel(size: MuAiLabelSize.s),
                        ],
                      ),
                    ),
                    MuButton.tertiary(
                      label: l10n.pasPourMoi,
                      size: MuButtonSize.s,
                      onPressed: () {
                        setState(() => _hidden = true);
                        MuToast.show(
                          context,
                          title: l10n.merciOnEnTientCompte,
                          description: l10n.lIaProposeraMoinsDe,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                MuMatchFitScore.ring(value: g.matchFit!, factors: d.fitFactors, note: d.fitNote),
              ],
            ),
          );

    final lineup = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuLineup(
          sport: g.sport,
          teams: d.teams,
          title: l10n.composition,
          disabled: full || joined,
          onJoin: (team, slot, position) => _join(d, (team, slot)),
        ),
        const SizedBox(height: MuSpace.s2),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    full ? PhosphorIcons.hourglassMedium() : PhosphorIcons.handTap(),
                    size: MuSize.iconXs,
                    color: c.textSecondary,
                  ),
                  const SizedBox(width: MuSpace.s1),
                  Flexible(
                    child: Text(
                      full
                          ? l10n.enListeDAttenteTu(d.waitlistCount, d.waitlistCount + 1)
                          : joined
                          ? l10n.taPlaceEstPriseA(formatTime(g.start))
                          : l10n.toucheUnPourChoisirTon,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Text(l10n.moy, style: MuType.caption.copyWith(color: c.textSecondary)),
            Text(formatLevel(d.averageLevel), style: MuType.numS.copyWith(color: c.text)),
          ],
        ),
      ],
    );

    final chat = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          l10n.discussion,
          trailing: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${d.messageCount}',
                  style: MuType.numS.copyWith(color: c.text),
                ),
                const TextSpan(text: ' messages'),
              ],
            ),
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        MuCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, m) in d.messages.indexed) ...[
                if (i > 0) const SizedBox(height: MuSpace.s3),
                ChatMessage(author: m.author, time: m.time, text: m.text),
              ],
              const SizedBox(height: MuSpace.s3),
              if (joined)
                MuButton.secondary(
                  label: l10n.ouvrirLaDiscussion,
                  leading: PhosphorIcons.chatCircle(),
                  fullWidth: true,
                  onPressed: () => showComingSoon(context),
                )
              else
                ChatLocked(
                  full
                      ? l10n.tuPourrasEcrireDesQue
                      : l10n.rejoinsLaPartiePourEcrire,
                ),
            ],
          ),
        ),
      ],
    );

    final rules = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(l10n.reglesEtAnnulation),
        const SizedBox(height: MuSpace.s3),
        MuCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIcons.clock(), size: MuSize.iconS, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.arriveMinAvantLeCoup,
                          style: MuType.label.copyWith(color: c.text),
                        ),
                        Text(d.arrivalNote, style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s4),
              CancellationSteps(
                freeUntil: d.freeUntil,
                halfUntil: d.halfUntil,
                share: g.pricePerPlayer,
              ),
              const SizedBox(height: MuSpace.s3),
              Text(
                l10n.rembourseSurTonSoldeMatchup(organiserFirst),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        hero,
        Transform.translate(
          offset: const Offset(0, -_overlap),
          child: Container(
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(MuRadius.lg)),
            ),
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, _bottomRoom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                chips,
                const SizedBox(height: MuSpace.s3),
                Semantics(
                  header: true,
                  child: Text(g.title, style: MuType.h1.copyWith(color: c.text)),
                ),
                const SizedBox(height: MuSpace.s4),
                facts,
                const SizedBox(height: MuSpace.s4),
                venueCard,
                if (why != null) ...[const SizedBox(height: MuSpace.s4), why],
                const SizedBox(height: MuSpace.s6),
                lineup,
                const SizedBox(height: MuSpace.s6),
                chat,
                const SizedBox(height: MuSpace.s6),
                rules,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
