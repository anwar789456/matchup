import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity.dart';
import '../../../core/directions.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../notifications/data/notification_repository.dart';
import '../../common/widgets/coming_soon.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../matches/data/bookings_repository.dart';
import '../../profile/widgets/account_menu.dart';
import '../../states/data/account_status.dart';
import '../../states/widgets/state_widgets.dart';
import '../../player_onboarding/controllers/onboarding_controller.dart';
import '../controllers/home_providers.dart';
import '../widgets/guided_tour.dart';
import '../../../l10n/l10n.dart';

/// HOM-01 · Accueil: « Parties pour toi » (AI), quick actions, the next matches, venues and
/// tournaments near the player. While a section loads it shows its skeleton (HOM-02) and the header
/// stays usable. The first time after the onboarding, the PLY-11 tour runs over it.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _forYouKey = GlobalKey();
  final _createKey = GlobalKey();

  // HOM-01: featured cards 318 wide in the rail; sections 28 apart; the page ends 136 above the
  // bottom so the FAB never covers the last card.
  static const double _railCard = 318;
  static const double _sectionGap = MuSpace.s6 + MuSpace.s1;
  static const double _bottomRoom = MuSpace.s16 + MuSpace.s16 + MuSpace.s2;

  Future<void> _refresh() async {
    ref
      ..invalidate(recommendedGamesProvider)
      ..invalidate(upcomingMatchesProvider)
      ..invalidate(nearbyVenuesProvider)
      ..invalidate(nearbyTournamentsProvider);
    await Future.wait([
      ref.read(recommendedGamesProvider.future),
      ref.read(upcomingMatchesProvider.future),
      ref.read(nearbyVenuesProvider.future),
      ref.read(nearbyTournamentsProvider.future),
    ]).catchError((_) => <Object>[]);
  }

  /// Opens Explorer on [tab] (« Voir tout », « Réserver un terrain »).
  void _explore(ExploreTab tab) {
    ref.read(exploreProvider.notifier).setTab(tab);
    context.go(Routes.explore);
  }

  /// A joined game opens its lobby; a booked court its booking page.
  String _openLink(UpcomingMatches next, MuBooking b) =>
      next.games.any((g) => g.id == b.id) ? Routes.game(b.id!) : Routes.booking(b.id!);

  void _directions(MuBooking b) {
    final venue = ref
        .read(nearbyVenuesProvider)
        .value
        ?.where((v) => v.name == b.venue)
        .firstOrNull;
    if (venue?.position == null) return showComingSoon(context);
    openDirections(venue!.position!);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final onboarding = ref.watchOnboarding();
    final me = ref.watch(meProvider).value;
    final games = ref.watch(recommendedGamesProvider);
    final upcoming = ref.watch(upcomingMatchesProvider);
    final venues = ref.watch(nearbyVenuesProvider);
    final tournaments = ref.watch(nearbyTournamentsProvider);
    final favourites = ref.watch(favouriteVenuesProvider);

    final fullName = onboarding.fullName?.trim();
    final firstName = (fullName?.isNotEmpty ?? false)
        ? fullName!.split(RegExp(r'\s+')).first
        : onboarding.pseudo ?? me?.firstName;
    final userName = (fullName?.isNotEmpty ?? false)
        ? fullName!
        : onboarding.pseudo ?? me?.displayName ?? l10n.matchup;
    final zone = onboarding.zones.firstOrNull ?? onboarding.area ?? me?.zone ?? l10n.tunis;
    final photo = ref.watch(profilePhotoProvider);
    final level = onboarding.levels.values.firstOrNull ?? me?.levels.values.firstOrNull;
    final showTour = onboarding.completed && !onboarding.tourSeen && games.hasValue;

    Widget sectionHeader(String title, {String? action, VoidCallback? onAction, Widget? badge}) =>
        Padding(
          padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s1),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: MuSize.controlS),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Semantics(
                          header: true,
                          child: Text(title, style: MuType.h3.copyWith(color: c.text)),
                        ),
                      ),
                      if (badge != null) ...[const SizedBox(width: MuSpace.s2), badge],
                    ],
                  ),
                ),
                if (action != null)
                  MuButton.tertiary(label: action, size: MuButtonSize.s, onPressed: onAction),
              ],
            ),
          ),
        );

    Widget caption(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
      child: Text(text, style: MuType.caption.copyWith(color: c.textSecondary)),
    );

    Widget retry(String what, VoidCallback onRetry) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
      child: MuBanner(
        title: l10n.impossibleDeCharger2(what),
        detail: l10n.verifieTaConnexionPuisReessaie,
        tone: MuBannerTone.warning,
        icon: PhosphorIcons.wifiSlash(),
        action: MuAction(l10n.reessayer, onRetry),
      ),
    );

    // ── Parties pour toi ──────────────────────────────────────────────────────────────────────
    final forYou = KeyedSubtree(
      key: _forYouKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionHeader(
            l10n.partiesPourToi,
            badge: MuAiLabel(size: MuAiLabelSize.s),
            action: games.hasValue ? l10n.voirTout : null,
            onAction: () => _explore(ExploreTab.games),
          ),
          const SizedBox(height: MuSpace.s1),
          caption(
            games.hasValue
                ? l10n.choisiesSelonTonNiveauTes
                : l10n.onChercheLesPartiesA(zone),
          ),
          const SizedBox(height: MuSpace.s1),
          if (games.hasError && !games.hasValue)
            retry(l10n.lesParties, () => ref.invalidate(recommendedGamesProvider))
          else
            _Rail(
              width: _railCard,
              loadingLabel: games.hasValue ? null : l10n.chargementDesParties,
              children: games.hasValue
                  ? [
                      for (final g in games.value!)
                        MuGameCard(
                          game: g,
                          variant: MuGameCardVariant.featured,
                          onTap: () => context.push(Routes.game(g.id!)),
                          onJoin: () => context.push(Routes.game(g.id!)),
                          onWaitlist: () => context.push(Routes.game(g.id!)),
                        ),
                    ]
                  : [
                      for (var i = 0; i < 2; i++)
                        const MuGameCard.loading(variant: MuGameCardVariant.featured),
                    ],
            ),
        ],
      ),
    );

    // ── Actions rapides ───────────────────────────────────────────────────────────────────────
    final quickActions = Semantics(
      container: true,
      label: l10n.actionsRapides,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickAction(
                  label: l10n.reserverUnTerrain,
                  detail: l10n.paieTaPartPasTout,
                  tileColor: c.surfaceMuted,
                  icon: SvgPicture.asset(
                    MuGlyph.court,
                    width: MuSize.iconM,
                    height: MuSize.iconM,
                    colorFilter: ColorFilter.mode(c.text, BlendMode.srcIn),
                  ),
                  onTap: () => _explore(ExploreTab.venues),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: KeyedSubtree(
                  key: _createKey,
                  child: _QuickAction(
                    label: l10n.creerUnePartie,
                    detail: l10n.onCompleteAvecDesJoueurs,
                    tileColor: c.accent,
                    icon: Icon(PhosphorIcons.plus(), size: MuSize.iconM, color: c.onAccent),
                    onTap: () => _explore(ExploreTab.venues),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // ── Tes prochains matchs ──────────────────────────────────────────────────────────────────
    final UpcomingMatches? next = upcoming.value;
    final nextMatches = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionHeader(
          l10n.tesProchainsMatchs,
          action: l10n.mesMatchs,
          onAction: () => context.go(Routes.matches),
        ),
        const SizedBox(height: MuSpace.s3),
        if (upcoming.hasError && next == null)
          retry(l10n.tesMatchs, () => ref.invalidate(upcomingMatchesProvider))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: next == null
                ? MuSkeletonGroup(
                    label: l10n.chargementDeTesMatchs,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InvitationRow.loading(),
                        SizedBox(height: MuSpace.s3),
                        MuBookingCard.loading(),
                        SizedBox(height: MuSpace.s3),
                        MuBookingCard.loading(variant: MuBookingCardVariant.compact),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final inv in next.invitations) ...[
                        _InvitationRow(invitation: inv, onTap: () => context.go(Routes.matches)),
                        const SizedBox(height: MuSpace.s3),
                      ],
                      for (final (i, b) in next.all.indexed) ...[
                        if (i > 0) const SizedBox(height: MuSpace.s3),
                        MuBookingCard(
                          booking: b,
                          variant: i == 0
                              ? MuBookingCardVariant.standard
                              : MuBookingCardVariant.compact,
                          onTap: () => context.push(_openLink(next, b)),
                          onShowQr: () => context.push(Routes.booking(b.id!)),
                          onDirections: () => _directions(b),
                          onMore: () => showComingSoon(context),
                          onPay: () => context.push(Routes.booking(b.id!)),
                        ),
                      ],
                    ],
                  ),
          ),
      ],
    );

    // ── Terrains près de toi ──────────────────────────────────────────────────────────────────
    final nearVenues = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionHeader(
          l10n.terrainsPresDeToi,
          action: l10n.voirTout,
          onAction: () => _explore(ExploreTab.venues),
        ),
        const SizedBox(height: MuSpace.s3),
        if (venues.hasError && !venues.hasValue)
          retry(l10n.lesTerrains, () => ref.invalidate(nearbyVenuesProvider))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: venues.hasValue
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, v) in venues.value!.take(2).indexed) ...[
                        if (i > 0) const SizedBox(height: MuSpace.s3),
                        MuVenueCard(
                          venue: v,
                          variant: MuVenueCardVariant.compact,
                          favourite: favourites.contains(v.id),
                          onFavouriteChanged: (_) =>
                              ref.read(favouriteVenuesProvider.notifier).toggle(v.id),
                          onTap: () => context.push(Routes.venue(v.id)),
                        ),
                      ],
                    ],
                  )
                : MuSkeletonGroup(
                    label: l10n.chargementDesTerrains,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MuVenueCard.loading(variant: MuVenueCardVariant.compact),
                        SizedBox(height: MuSpace.s3),
                        MuVenueCard.loading(variant: MuVenueCardVariant.compact),
                      ],
                    ),
                  ),
          ),
      ],
    );

    // ── Tournois près de chez toi ─────────────────────────────────────────────────────────────
    final nearTournaments = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionHeader(l10n.tournoisPresDeChezToi),
        caption(l10n.inscrisTonEquipeAvantQu),
        const SizedBox(height: MuSpace.s3),
        if (tournaments.hasError && !tournaments.hasValue)
          retry(l10n.lesTournois, () => ref.invalidate(nearbyTournamentsProvider))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: tournaments.hasValue
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final t in tournaments.value!.take(1))
                        MuTournamentCard(
                          tournament: t,
                          onTap: () => showComingSoon(context),
                          onRegister: () => showComingSoon(context),
                          onWaitlist: () => showComingSoon(context),
                        ),
                    ],
                  )
                : MuSkeletonGroup(
                    label: l10n.chargementDesTournois,
                    child: const MuTournamentCard.loading(),
                  ),
          ),
      ],
    );

    final offline = ref.watch(simulatedOfflineProvider);
    final flags = ref.watch(accountFlagsProvider);
    final suspension = ref.watch(suspensionsProvider)[userName];
    final page = Scaffold(
      backgroundColor: c.bg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: _bottomRoom),
          children: [
            MuTopAppBar.home(
              greeting: firstName == null ? l10n.salut : l10n.salut2(firstName),
              location: zone,
              userName: userName,
              userImage: photo == null ? null : MemoryImage(photo),
              notifications: ref.watch(unreadNotificationsProvider),
              onLocation: () => showComingSoon(context),
              onNotifications: () => context.push(Routes.notifications),
              onAccount: () => showAccountMenu(context, ref),
            ),
            // STA-07: a suspended account sees why and until when, nothing to join.
            if (suspension != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 0),
                child: SuspendedAccountView(
                  suspension: suspension,
                  now: ref.read(clockProvider)(),
                  onContest: () => showComingSoon(context),
                ),
              )
            else ...[
              // STA-01: offline, the cached lists stay with this strip on top.
              if (offline)
                OfflineBanner(
                  // The last successful sync of the fake data (17h42 in the story).
                  cachedAt: ref.read(clockProvider)().subtract(const Duration(minutes: 18)),
                  onRetry: () {
                    ref.read(simulatedOfflineProvider.notifier).set(false);
                    _refresh();
                  },
                ),
              // STA-06: the email is not verified yet.
              if (!flags.emailVerified && !flags.emailBannerHidden)
                Padding(
                  padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 0),
                  child: EmailNotVerifiedBanner(
                    email: me?.email ?? '',
                    flags: flags,
                    onResend: () =>
                        ref.read(accountFlagsProvider.notifier).emailSent(me?.email ?? ''),
                    onHide: ref.read(accountFlagsProvider.notifier).hideEmailBanner,
                  ),
                ),
              const SizedBox(height: MuSpace.s1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: _AskBar(onTap: () => showComingSoon(context)),
              ),
              const SizedBox(height: _sectionGap),
              forYou,
              const SizedBox(height: _sectionGap - MuSpace.s2),
              quickActions,
              const SizedBox(height: _sectionGap),
              nextMatches,
              if (offline) ...[
                const SizedBox(height: MuSpace.s2),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: OfflineQrNote(),
                ),
              ],
              const SizedBox(height: _sectionGap),
              nearVenues,
              const SizedBox(height: _sectionGap),
              nearTournaments,
            ],
          ],
        ),
      ),
    );

    if (!showTour) return page;
    return Stack(
      children: [
        page,
        Positioned.fill(
          child: GuidedTour(
            onDone: ref.onboarding.markTourSeen,
            steps: [
              TourStep(
                target: _forYouKey,
                header: MuAiLabel(size: MuAiLabelSize.s),
                title: l10n.desPartiesChoisiesPourToi,
                body: level == null
                    ? l10n.recommandeCarTonNiveauTes
                    : l10n.recommandeCarTonNiveauTes2(formatLevel(level)),
              ),
              TourStep(
                target: _createKey,
                padding: MuSpace.s1,
                header: Text(l10n.organiser, style: MuType.overline.copyWith(color: c.textSecondary)),
                title: l10n.creeTaPartieEnMinute,
                body:
                    l10n.choisisLeTerrainEtL,
              ),
              TourStep(
                target: ref.read(playerTabKeysProvider)[2],
                radius: MuRadius.md,
                padding: 0,
                header: Text(l10n.mesMatchs2, style: MuType.overline.copyWith(color: c.textSecondary)),
                title: l10n.tousTesMatchsAuMeme,
                body:
                    l10n.partiesAVenirInvitationsEt,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The horizontal rail of « Parties pour toi »: cards [width] wide, `space-3` apart, snapping to
/// their start; skeletons inside a [MuSkeletonGroup] while loading.
class _Rail extends StatelessWidget {
  const _Rail({required this.width, required this.children, this.loadingLabel});

  final double width;
  final List<Widget> children;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final rail = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: loadingLabel == null ? null : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, MuSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(width: MuSpace.s3),
            SizedBox(width: width, child: child),
          ],
        ],
      ),
    );
    return loadingLabel == null ? rail : MuSkeletonGroup(label: loadingLabel!, child: rail);
  }
}

/// « Mariem K. t’invite au padel »: avatar, who and what, and the Volt « Répondre » pill.
class _InvitationRow extends StatelessWidget {
  const _InvitationRow({required MatchInvitation this.invitation, required this.onTap});

  const _InvitationRow.loading() : invitation = null, onTap = null;

  final MatchInvitation? invitation;
  final VoidCallback? onTap;

  // HOM-02: the skeleton's pill is 72 × 24.
  static const double _pillW = 72;
  static const double _pillH = 24;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final inv = invitation;
    const padding = EdgeInsetsDirectional.fromSTEB(
      MuSpace.s3 + MuSpace.s1 / 2,
      MuSpace.s3,
      MuSpace.s3,
      MuSpace.s3,
    );
    if (inv == null) {
      return const MuCardSurface(
        padding: padding,
        child: Row(
          children: [
            MuSkeleton.circle(size: MuSize.avatarM),
            SizedBox(width: MuSpace.s3),
            Expanded(child: MuSkeleton.text(lines: 2)),
            SizedBox(width: MuSpace.s3),
            MuSkeleton.pill(width: _pillW, height: _pillH),
          ],
        ),
      );
    }
    final sport = inv.sport.label.toLowerCase();
    final what =
        l10n.pers2(inv.venue, formatDay(inv.start), formatTime(inv.start), formatDT(inv.share));
    return MuCardSurface(
      padding: padding,
      onTap: onTap,
      semanticLabel: l10n.tInviteAuRepondre(inv.from.name, sport, what),
      child: Row(
        children: [
          MuAvatar(name: inv.from.name, size: MuAvatarSize.m),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tInviteAu(inv.from.name, sport),
                  style: MuType.label.copyWith(color: c.text),
                ),
                const SizedBox(height: MuSpace.s1 / 2),
                Text(what, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
            decoration: ShapeDecoration(color: c.accent, shape: const StadiumBorder()),
            child: Text(l10n.repondre, style: MuType.labelS.copyWith(color: c.onAccent)),
          ),
        ],
      ),
    );
  }
}

/// « Demande à MatchUp… »: the assistant's entry in the page (AI ring, sparkle).
class _AskBar extends StatelessWidget {
  const _AskBar({required this.onTap});

  final VoidCallback onTap;

  // HOM-01: 1,5 px ai-500 ring.
  static const double _ring = 1.5;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: l10n.demandeAMatchupLAssistant,
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.fullAll,
        child: Material(
          color: c.surface,
          shape: StadiumBorder(side: BorderSide(color: c.ai500, width: _ring)),
          elevation: MuElevation.materialLevel1,
          shadowColor: MuElevation.of(context).shadowColor,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: MuSize.controlL),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      size: MuSize.iconS,
                      color: c.ai500,
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Text(
                      l10n.demandeAMatchup,
                      style: MuType.bodyL.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A quick action card: a 40 tile over the label and its caption.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.detail,
    required this.icon,
    required this.tileColor,
    required this.onTap,
  });

  final String label;
  final String detail;
  final Widget icon;
  final Color tileColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return MuCardSurface(
      onTap: onTap,
      semanticLabel: '$label. $detail',
      padding: const EdgeInsets.all(MuSpace.s3 + MuSpace.s1 / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MuSize.controlM,
            height: MuSize.controlM,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tileColor, borderRadius: MuRadius.smAll),
            child: icon,
          ),
          const SizedBox(height: MuSpace.s3),
          Text(label, style: MuType.label.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s1 / 2),
          Text(detail, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}
