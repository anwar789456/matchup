import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/connectivity.dart';
import '../../states/widgets/state_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../games/widgets/leave_dialog.dart';
import '../controllers/matches_providers.dart';
import '../data/bookings_repository.dart';
import '../widgets/rate_sheet.dart';
import '../../../l10n/l10n.dart';

/// MAT-01 to MAT-04 · Mes matchs: « À venir » (invitations to answer, the games the player joined,
/// the courts they organise — or the empty state), « Passés » (results, to rate first) and
/// « Annulés » (refunds).
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  // Room under the lists for the FAB-less tab bar.
  static const double _bottomRoom = MuSpace.s8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final tab = ref.watch(matchesTabProvider);
    final upcoming = ref.watch(upcomingMatchesProvider);
    final count = upcoming.value?.count ?? 0;
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuTopAppBar.large(
            title: l10n.mesMatchs,
            actions: [
              MuBarAction(
                icon: PhosphorIcons.calendarPlus(),
                label: l10n.reserverUnTerrain,
                onPressed: () => context.go(Routes.exploreVenues),
              ),
            ],
          ),
          MuTabs(
            label: l10n.mesMatchs,
            fullWidth: true,
            tabs: [
              MuTab(l10n.aVenir, count: count == 0 ? null : count),
              MuTab(l10n.passes),
              MuTab(l10n.annules),
            ],
            index: tab,
            onChanged: (i) => ref.read(matchesTabProvider.notifier).select(i),
          ),
          Expanded(
            child: switch (tab) {
              0 => _Upcoming(upcoming: upcoming),
              1 => const _Past(),
              _ => const _Cancelled(),
            },
          ),
        ],
      ),
    );
  }
}

/// « À RÉPONDRE », then a dated overline per game and booking.
class _Upcoming extends ConsumerWidget {
  const _Upcoming({required this.upcoming});

  final AsyncValue<UpcomingMatches> upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    if (upcoming.error is ServerException) {
      final e = upcoming.error! as ServerException;
      return ServerErrorState(
        title: l10n.tesMatchsNeSeChargent,
        status: e.status,
        reference: e.reference,
        kept: [
          TextSpan(
            children: [
              TextSpan(text: l10n.tesReservationsEtTaPlace),
              TextSpan(text: l10n.dimOct, style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: l10n.sontToujoursLa),
            ],
          ),
          TextSpan(text: l10n.aucunPaiementNAEte),
        ],
        onRetry: () {
          ref.read(simulatedServerErrorProvider.notifier).set(false);
          ref.invalidate(upcomingMatchesProvider);
        },
      );
    }
    final value = upcoming.value;
    if (value == null) {
      if (upcoming.hasError) return _Retry(() => ref.invalidate(upcomingMatchesProvider));
      return MuSkeletonGroup(
        label: l10n.chargementDeTesMatchs,
        child: const Padding(
          padding: EdgeInsets.all(MuSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuSkeleton.text(width: 96),
              SizedBox(height: MuSpace.s3),
              MuGameCard.loading(variant: MuGameCardVariant.compact),
              SizedBox(height: MuSpace.s5),
              MuSkeleton.text(width: 140),
              SizedBox(height: MuSpace.s3),
              MuBookingCard.loading(variant: MuBookingCardVariant.compact),
            ],
          ),
        ),
      );
    }
    if (value.count == 0) return const _Empty();

    final actions = ref.read(matchesActionsProvider);
    final entries = [
      for (final g in value.games) (g.start, _GameEntry(g)),
      for (final b in value.bookings) (b.start, _BookingEntry(b)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    return RefreshIndicator(
      color: c.primary,
      onRefresh: () async {
        ref.invalidate(upcomingMatchesProvider);
        await ref.read(upcomingMatchesProvider.future).catchError((_) => value);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          MuSpace.s4,
          MuSpace.s2,
          MuSpace.s4,
          MatchesScreen._bottomRoom,
        ),
        children: [
          if (value.invitations.isNotEmpty) ...[
            _Overline(l10n.aRepondre),
            for (final inv in value.invitations) ...[
              _InvitationCard(
                invitation: inv,
                onDecline: () => actions.respond(inv.id, accept: false),
                onAccept: () async {
                  await actions.respond(inv.id, accept: true);
                  if (context.mounted) {
                    MuToast.show(
                      context,
                      tone: MuToastTone.success,
                      title: l10n.invitationAcceptee,
                      description: l10n.estPrevenue(inv.from.name.split(' ').first),
                    );
                  }
                },
              ),
              const SizedBox(height: MuSpace.s5),
            ],
          ],
          for (final (_, e) in entries) ...[e, const SizedBox(height: MuSpace.s5)],
        ],
      ),
    );
  }
}

/// « DIM. 18 OCT. · TU JOUES » + « Quitter », then the compact game card.
class _GameEntry extends ConsumerWidget {
  const _GameEntry(this.game);

  final MuGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Overline(
        l10n.tuJoues(_capital(formatDay(game.start))),
        trailing: MuButton.tertiary(
          label: l10n.quitter,
          leading: PhosphorIcons.signOut(),
          size: MuButtonSize.s,
          onPressed: () => confirmLeaveGame(context, ref, game),
        ),
      ),
      MuGameCard(
        game: game,
        variant: MuGameCardVariant.compact,
        onTap: () => context.push(Routes.game(game.id!)),
      ),
    ],
  );
}

/// « MER. 21 OCT. · TU ORGANISES », the compact booking card and the players progress.
class _BookingEntry extends StatelessWidget {
  const _BookingEntry(this.booking);

  final MuBooking booking;

  // The public game has 10 places.
  static const int _spots = 10;

  @override
  Widget build(BuildContext context) {
    final missing = _spots - booking.players.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Overline(l10n.tuOrganises2(_capital(formatDay(booking.start)))),
        MuBookingCard(
          booking: booking,
          variant: MuBookingCardVariant.compact,
          onTap: () => context.push(Routes.booking(booking.id!)),
          onShowQr: () => context.push(Routes.booking(booking.id!)),
        ),
        if (missing > 0) ...[
          const SizedBox(height: MuSpace.s2),
          MuCardSurface(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: l10n.enAttenteDeJoueurs(missing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${booking.players.length}/$_spots',
                                    style: MuType.numL.copyWith(color: context.mu.text),
                                  ),
                                  TextSpan(
                                    text: ' joueurs',
                                    style: MuType.body.copyWith(color: context.mu.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              l10n.placesLibres(missing),
                              style: MuType.caption.copyWith(color: context.mu.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: MuSpace.s2),
                        MuProgressBar(
                          variant: MuProgressVariant.spots,
                          size: MuProgressSize.s,
                          value: booking.players.length.toDouble(),
                          max: _spots.toDouble(),
                          showValue: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                MuButton.secondary(
                  label: l10n.inviter2,
                  leading: PhosphorIcons.userPlus(),
                  size: MuButtonSize.s,
                  onPressed: () => context.push(Routes.booking(booking.id!)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// MAT-01's « Mariem K. t’invite au padel » card.
class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.onDecline,
    required this.onAccept,
  });

  final MatchInvitation invitation;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final inv = invitation;
    final first = inv.from.name.split(' ').first;
    return MuCardSurface(
      semanticLabel:
          l10n.tInviteAuTaPart(first, inv.sport.label.toLowerCase(), inv.venue, formatDateTime(inv.start), formatDT(inv.share)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MuAvatar(name: inv.from.name, level: 4.0),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tInviteAu(inv.from.name, inv.sport.label.toLowerCase()),
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        MuSportIcon(inv.sport, size: MuSize.iconXs, color: c.textSecondary),
                        const SizedBox(width: MuSpace.s1),
                        Flexible(
                          child: Text(
                            '${inv.venue} · ${inv.place}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.body.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      l10n.joueurs2(formatDateTime(inv.start), inv.spotsTotal - inv.spotsLeft, inv.spotsTotal),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MuSpace.s2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatDT(inv.share), style: MuType.numM.copyWith(color: c.text)),
                  Text(l10n.taPart3, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          Row(
            children: [
              Expanded(
                child: MuButton.secondary(label: l10n.refuser, fullWidth: true, onPressed: onDecline),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: MuButton.primary(label: l10n.accepter, fullWidth: true, onPressed: onAccept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// MAT-04 · Aucun match.
class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s8, MuSpace.s4, MuSpace.s8),
      child: Column(
        children: [
          MuEmptyState(
            illustration: MuEmptyIllustration.bookings,
            title: l10n.aucunMatchAVenir,
            description:
                l10n.rejoinsUnePartieATon,
            actions: [
              MuButton.primary(
                label: l10n.trouverUnePartie,
                leading: PhosphorIcons.compass(),
                size: MuButtonSize.l,
                onPressed: () => context.go(Routes.explore),
              ),
              MuButton.secondary(
                label: l10n.reserverUnTerrain,
                leading: PhosphorIcons.courtBasketball(),
                size: MuButtonSize.l,
                onPressed: () => context.go(Routes.exploreVenues),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          Text(
            l10n.partiesOuvertesCetteSemaineA(Story.openGames.length),
            textAlign: TextAlign.center,
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// MAT-02 · Passés.
class _Past extends ConsumerWidget {
  const _Past();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final past = ref.watch(pastMatchesProvider);
    final matches = past.value;
    if (matches == null) {
      if (past.hasError) return _Retry(() => ref.invalidate(pastMatchesProvider));
      return MuSkeletonGroup(
        label: l10n.chargementDeTesMatchs,
        child: const Padding(
          padding: EdgeInsets.all(MuSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuMatchCard.loading(variant: MuMatchCardVariant.compact),
              SizedBox(height: MuSpace.s3),
              MuMatchCard.loading(variant: MuMatchCardVariant.compact),
            ],
          ),
        ),
      );
    }
    if (matches.isEmpty) {
      return Center(
        child: MuEmptyState(
          illustration: MuEmptyIllustration.results,
          title: l10n.aucunMatchJoue,
          description: l10n.tesResultatsEtTesEvaluations,
        ),
      );
    }
    final toRate = [
      for (final m in matches)
        if (!m.rated && m.mates.isNotEmpty) m,
    ];
    final earlier = [
      for (final m in matches)
        if (!toRate.contains(m)) m,
    ];
    final now = ref.read(clockProvider)();
    final since = matches.map((m) => m.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final wins = matches.where((m) => m.won).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MuSpace.s4,
        MuSpace.s2,
        MuSpace.s4,
        MatchesScreen._bottomRoom,
      ),
      children: [
        if (toRate.isNotEmpty) ...[
          _Overline(l10n.aEvaluer),
          for (final m in toRate) ...[
            MuMatchCard(match: m.match, variant: MuMatchCardVariant.compact),
            const SizedBox(height: MuSpace.s3),
            MuCardSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      MuAvatarStack(
                        people: [for (final mate in m.mates) mate.person],
                        semanticLabel: _names(m.mates),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.evalueTesCoequipiers,
                              style: MuType.labelL.copyWith(color: c.text),
                            ),
                            Text(
                              l10n.min(_names(m.mates)),
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s4),
                  MuButton.primary(
                    label: l10n.evaluerLesJoueurs,
                    leading: PhosphorIcons.star(),
                    fullWidth: true,
                    onPressed: () => showRateSheet(context, ref, m),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MuSpace.s5),
          ],
        ],
        if (earlier.isNotEmpty) ...[
          _Overline(
            l10n.plusTot,
            trailing: Row(
              children: [
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  size: MuSize.iconXs,
                  color: c.successText,
                ),
                const SizedBox(width: MuSpace.s1),
                Text(l10n.evalues, style: MuType.caption.copyWith(color: c.successText)),
              ],
            ),
          ),
          for (final m in earlier) ...[
            MuMatchCard(
              match: m.match,
              variant: MuMatchCardVariant.compact,
              onTap: m.sport == MuSport.padel && m.sets != null
                  ? () => context.push(Routes.matchScore(m.id))
                  : null,
            ),
            const SizedBox(height: MuSpace.s3),
          ],
        ],
        const SizedBox(height: MuSpace.s2),
        Text(
          l10n.matchsDepuisVictoire(matches.length, _monthName(since, now), wins, wins > 1 ? 's' : ''),
          textAlign: TextAlign.center,
          style: MuType.caption.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: MuSpace.s1),
        Center(
          child: MuButton.link(
            label: l10n.voirToutesMesStats,
            onPressed: () => context.push(Routes.profile),
          ),
        ),
      ],
    );
  }

  static String _names(List<MatchMate> mates) {
    final names = [for (final m in mates) m.person.name.split(' ').first];
    if (names.length <= 1) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')} et ${names.last}';
  }

  static String _monthName(DateTime d, DateTime now) => switch (d.month) {
    1 => 'janvier',
    2 => l10n.fevrier,
    3 => 'mars',
    4 => 'avril',
    5 => 'mai',
    6 => 'juin',
    7 => 'juillet',
    8 => l10n.aout,
    9 => 'septembre',
    10 => 'octobre',
    11 => 'novembre',
    _ => l10n.decembre,
  };
}

/// MAT-03 · Annulés.
class _Cancelled extends ConsumerWidget {
  const _Cancelled();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final cancelled = ref.watch(cancelledMatchesProvider);
    final items = cancelled.value;
    if (items == null) {
      if (cancelled.hasError) return _Retry(() => ref.invalidate(cancelledMatchesProvider));
      return MuSkeletonGroup(
        label: l10n.chargement,
        child: const Padding(padding: EdgeInsets.all(MuSpace.s4), child: MuBookingCard.loading()),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: MuEmptyState(
          illustration: MuEmptyIllustration.bookings,
          title: l10n.aucuneAnnulation,
          description: l10n.lesPartiesEtReservationsAnnulees,
        ),
      );
    }
    final balance = ref.watch(meProvider).value?.balance ?? Story.myBalance;
    final captionStyle = MuType.caption.copyWith(color: c.textSecondary);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MuSpace.s4,
        MuSpace.s2,
        MuSpace.s4,
        MatchesScreen._bottomRoom,
      ),
      children: [
        for (final (i, item) in items.indexed) ...[
          if (i == 0 || items[i - 1].booking.start.month != item.booking.start.month)
            _Overline(_capital(_Past._monthName(item.booking.start, item.booking.start))),
          MuBookingCard(
            booking: item.booking,
            onRebook: () {
              final v = Story.venues.where((v) => v.name == item.booking.venue).firstOrNull;
              context.push(Routes.venue(v?.id ?? Story.arenaFive.id));
            },
          ),
          const SizedBox(height: MuSpace.s3),
          MuCardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.remboursement, style: MuType.h3.copyWith(color: c.text)),
                    ),
                    MuStatusBadge(
                      status: MuStatus.refunded,
                      label: l10n.rembourse2,
                      size: MuBadgeSize.s,
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MuAvatar(name: item.cancelledBy.name, size: MuAvatarSize.s),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: item.byMe
                                  ? l10n.annuleeParToiLeTerrain
                                  : l10n.annuleeParLOrganisateur(item.cancelledBy.name),
                              style: MuType.body.copyWith(color: c.text),
                            ),
                            if (item.reason != null)
                              TextSpan(
                                text: ' « ${item.reason} »',
                                style: MuType.body.copyWith(color: c.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                _Line(
                  l10n.crediteLe(formatDateTime(item.refundedAt)),
                  '+${formatDT(item.refund)}',
                  valueColor: c.successText,
                ),
                if (item.totalRefund != null && item.playersRefunded > 1)
                  _Line(
                    l10n.totalRembourseJoueurs(item.playersRefunded),
                    formatDT(item.totalRefund!),
                  ),
                _Line(l10n.tonSoldeMatchup, formatDT(balance)),
                const SizedBox(height: MuSpace.s3),
                Container(
                  padding: const EdgeInsets.all(MuSpace.s3),
                  decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
                      const SizedBox(width: MuSpace.s2),
                      Expanded(
                        child: Text(
                          item.byMe
                              ? l10n.chaqueJoueurEstRembourseEn
                              : l10n.quandLOrganisateurOuLe,
                          style: captionStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s5),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: MuType.body.copyWith(color: c.text)),
          ),
          Text(value, style: MuType.numS.copyWith(color: valueColor ?? c.text)),
        ],
      ),
    );
  }
}

/// The section overline of the lists (« À RÉPONDRE »), with an optional action at the end.
class _Overline extends StatelessWidget {
  const _Overline(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.only(bottom: MuSpace.s2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MuSize.controlS),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  text.toUpperCase(),
                  style: MuType.overline.copyWith(color: c.textSecondary),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry(this.onRetry);

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: MuEmptyState(
      title: l10n.impossibleDeChargerTesMatchs,
      description: l10n.verifieTaConnexionPuisReessaie,
      compact: true,
      actions: [MuButton.secondary(label: l10n.reessayer, onPressed: onRetry)],
    ),
  );
}

String _capital(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
