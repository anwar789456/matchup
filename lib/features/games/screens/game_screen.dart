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
import '../controllers/game_actions.dart';
import '../data/games_repository.dart';
import '../widgets/game_widgets.dart';
import '../widgets/leave_dialog.dart';

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
  bool _paying = false;
  bool _hidden = false;

  // GAM-01: hero 188 high; the main card overlaps it by 20 with a radius-lg top.
  static const double _hero = 188;
  static const double _overlap = 20;
  static const double _bottomRoom = MuSpace.s16 + MuSpace.s8;

  Future<void> _join(GameDetails d, (int, int) spot) async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      await ref.read(gameActionsProvider).join(d.game, team: spot.$1, slot: spot.$2);
      if (!mounted) return;
      context.pushReplacement(Routes.gameJoined(widget.gameId));
    } catch (e) {
      if (!mounted) return;
      MuToast.show(
        context,
        tone: MuToastTone.error,
        title: 'Le paiement n’a pas abouti',
        description: 'Réessaie dans un instant.',
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _waitlist(GameDetails d) async {
    await ref.read(gameActionsProvider).joinWaitlist(widget.gameId);
    if (!mounted) return;
    context.push(Routes.gameWaitlist(widget.gameId));
  }

  void _share(GameDetails d) => SharePlus.instance.share(
    ShareParams(
      text:
          '${d.game.sport.label} · ${d.game.title} · ${formatDateTime(d.game.start)} · '
          'https://matchup.tn/g/${d.game.id}',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final details = ref.watch(gameDetailsProvider(widget.gameId));
    return Scaffold(
      backgroundColor: c.bg,
      body: switch (details) {
        AsyncData(:final value) => _body(context, value),
        AsyncError() => Center(
          child: Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: MuEmptyState(
              title: 'Partie introuvable',
              description: 'Elle a peut-être été annulée.',
              actions: [
                MuButton.primary(
                  label: 'Voir les parties',
                  onPressed: () => context.go(Routes.explore),
                ),
              ],
            ),
          ),
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
            const Expanded(
              child: MuSkeletonGroup(
                label: 'Chargement de la partie',
                child: Padding(
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
          'Tu joues · annulation gratuite jusqu’à ${formatDateTime(d.freeUntil)}',
        );
        action = Row(
          children: [
            Expanded(
              child: MuButton.secondary(
                label: 'Quitter la partie',
                leading: PhosphorIcons.signOut(),
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: () => confirmLeaveGame(context, ref, g),
              ),
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: MuButton.primary(
                label: 'Discussion',
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
          'Tu es ${d.waitlistPosition ?? 1}e sur la liste d’attente',
        );
        action = MuButton.primary(
          label: 'Voir la liste d’attente',
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(Routes.gameWaitlist(widget.gameId)),
        );
      case GameMembership.none:
        if (g.isFull) {
          hint = Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Gratuit · tu ne paies '),
                TextSpan(
                  text: formatDT(g.pricePerPlayer),
                  style: MuType.labelS.copyWith(color: c.text),
                ),
                const TextSpan(text: ' que si tu réclames une place'),
              ],
            ),
            textAlign: TextAlign.center,
            style: MuType.caption.copyWith(color: c.textSecondary),
          );
          action = MuButton.primary(
            label: 'Rejoindre la liste d’attente',
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
            'Annulation gratuite jusqu’à ${formatDateTime(d.freeUntil)}',
          );
          final spot = firstFreeSlot(d.teams);
          action = MuButton.primary(
            label: 'Rejoindre et payer',
            price: formatDT(g.pricePerPlayer),
            size: MuButtonSize.xl,
            fullWidth: true,
            loading: _paying,
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
    final sportLine = g.sport == MuSport.football ? '${g.sport.label} · 5 vs 5' : g.sport.label;
    final organiserFirst = (g.organiser ?? 'l’organisateur').split(' ').first;

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
                  label: 'Partager la partie',
                  onPressed: () => _share(d),
                ),
                MuBarAction(
                  icon: PhosphorIcons.dotsThreeVertical(),
                  label: 'Plus d’actions',
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
                  const MuStatusBadge(status: MuStatus.full, label: 'Complet', size: MuBadgeSize.s)
                else
                  const MuStatusBadge(
                    status: MuStatus.confirmed,
                    label: 'Terrain réservé',
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
            label: 'Niveau ${g.levelLabel!.replaceAll('–', ' – ')}',
            icon: PhosphorIcons.gauge(),
            size: MuChipSize.s,
          ),
      ],
    );

    final facts = FactsCard(
      cells: [
        FactCell(formatDay(g.start), formatTime(g.start), caption: 'jusqu’à ${formatTime(d.end)}'),
        FactCell(
          'Ta part',
          formatDT(g.pricePerPlayer),
          caption: '${formatDT(d.courtPrice)} le terrain',
        ),
        full
            ? FactCell(
                'Joueurs',
                '${g.spotsTotal}/${g.spotsTotal}',
                captionWidget: Text('Complet', style: MuType.caption.copyWith(color: c.errorText)),
              )
            : FactCell(
                'Places',
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
            label: 'Organisée par ${g.organiser}, voir son profil',
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
                          'Organisée par',
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
                                  'Pourquoi pour toi',
                                  style: MuType.h3.copyWith(color: c.text),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: MuSpace.s2),
                          const MuAiLabel(size: MuAiLabelSize.s),
                        ],
                      ),
                    ),
                    MuButton.tertiary(
                      label: 'Pas pour moi',
                      size: MuButtonSize.s,
                      onPressed: () {
                        setState(() => _hidden = true);
                        MuToast.show(
                          context,
                          title: 'Merci, on en tient compte',
                          description: 'L’IA proposera moins de parties comme celle-ci.',
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
          title: 'Composition',
          disabled: full || joined || _paying,
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
                          ? '${d.waitlistCount} en liste d’attente · tu serais '
                                '${d.waitlistCount + 1}e'
                          : joined
                          ? 'Ta place est prise, à ${formatTime(g.start)} sur le terrain'
                          : 'Touche un « + » pour choisir ton poste',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Text('Moy. ', style: MuType.caption.copyWith(color: c.textSecondary)),
            Text(formatLevel(d.averageLevel), style: MuType.numS.copyWith(color: c.text)),
          ],
        ),
      ],
    );

    final chat = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          'Discussion',
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
                  label: 'Ouvrir la discussion',
                  leading: PhosphorIcons.chatCircle(),
                  fullWidth: true,
                  onPressed: () => showComingSoon(context),
                )
              else
                ChatLocked(
                  full
                      ? 'Tu pourras écrire dès que tu as une place.'
                      : 'Rejoins la partie pour écrire aux joueurs.',
                ),
            ],
          ),
        ),
      ],
    );

    final rules = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHead('Règles et annulation'),
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
                          'Arrive 10 min avant le coup d’envoi',
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
                'Remboursé sur ton solde MatchUp, en entier si $organiserFirst annule.',
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
