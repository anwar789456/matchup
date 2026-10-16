import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/directions.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../matches/data/bookings_repository.dart';
import '../../player_onboarding/controllers/onboarding_controller.dart';
import '../controllers/home_providers.dart';
import '../widgets/guided_tour.dart';

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
        : onboarding.pseudo ?? me?.displayName ?? 'MatchUp';
    final zone = onboarding.zones.firstOrNull ?? onboarding.area ?? me?.zone ?? 'Tunis';
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
        title: 'Impossible de charger $what',
        detail: 'Vérifie ta connexion puis réessaie.',
        tone: MuBannerTone.warning,
        icon: PhosphorIcons.wifiSlash(),
        action: MuAction('Réessayer', onRetry),
      ),
    );

    // ── Parties pour toi ──────────────────────────────────────────────────────────────────────
    final forYou = KeyedSubtree(
      key: _forYouKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionHeader(
            'Parties pour toi',
            badge: const MuAiLabel(size: MuAiLabelSize.s),
            action: games.hasValue ? 'Voir tout' : null,
            onAction: () => _explore(ExploreTab.games),
          ),
          const SizedBox(height: MuSpace.s1),
          caption(
            games.hasValue
                ? 'Choisies selon ton niveau, tes zones et tes soirs libres.'
                : 'On cherche les parties à ton niveau autour de $zone…',
          ),
          const SizedBox(height: MuSpace.s1),
          if (games.hasError && !games.hasValue)
            retry('les parties', () => ref.invalidate(recommendedGamesProvider))
          else
            _Rail(
              width: _railCard,
              loadingLabel: games.hasValue ? null : 'Chargement des parties',
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
      label: 'Actions rapides',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickAction(
                  label: 'Réserver un terrain',
                  detail: 'Paie ta part, pas tout le terrain',
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
                    label: 'Créer une partie',
                    detail: 'On complète avec des joueurs à ton niveau',
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
          'Tes prochains matchs',
          action: 'Mes matchs',
          onAction: () => context.go(Routes.matches),
        ),
        const SizedBox(height: MuSpace.s3),
        if (upcoming.hasError && next == null)
          retry('tes matchs', () => ref.invalidate(upcomingMatchesProvider))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: next == null
                ? const MuSkeletonGroup(
                    label: 'Chargement de tes matchs',
                    child: Column(
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
                      for (final (i, b) in next.bookings.indexed) ...[
                        if (i > 0) const SizedBox(height: MuSpace.s3),
                        MuBookingCard(
                          booking: b,
                          variant: i == 0
                              ? MuBookingCardVariant.standard
                              : MuBookingCardVariant.compact,
                          onTap: () => context.push(Routes.booking(b.id!)),
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
          'Terrains près de toi',
          action: 'Voir tout',
          onAction: () => _explore(ExploreTab.venues),
        ),
        const SizedBox(height: MuSpace.s3),
        if (venues.hasError && !venues.hasValue)
          retry('les terrains', () => ref.invalidate(nearbyVenuesProvider))
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
                : const MuSkeletonGroup(
                    label: 'Chargement des terrains',
                    child: Column(
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
        sectionHeader('Tournois près de chez toi'),
        caption('Inscris ton équipe avant qu’il soit complet.'),
        const SizedBox(height: MuSpace.s3),
        if (tournaments.hasError && !tournaments.hasValue)
          retry('les tournois', () => ref.invalidate(nearbyTournamentsProvider))
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
                : const MuSkeletonGroup(
                    label: 'Chargement des tournois',
                    child: MuTournamentCard.loading(),
                  ),
          ),
      ],
    );

    final page = Scaffold(
      backgroundColor: c.bg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: _bottomRoom),
          children: [
            MuTopAppBar.home(
              greeting: firstName == null ? 'Salut !' : 'Salut $firstName',
              location: zone,
              userName: userName,
              userImage: photo == null ? null : MemoryImage(photo),
              notifications: me?.unreadNotifications ?? 0,
              onLocation: () => showComingSoon(context),
              onNotifications: () => showComingSoon(context),
              onAccount: () => showComingSoon(context),
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
            const SizedBox(height: _sectionGap),
            nearVenues,
            const SizedBox(height: _sectionGap),
            nearTournaments,
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
                header: const MuAiLabel(size: MuAiLabelSize.s),
                title: 'Des parties choisies pour toi',
                body: level == null
                    ? 'Recommandé car ton niveau, tes soirs libres et tes zones correspondent.'
                    : 'Recommandé car ton niveau (${formatLevel(level)}), tes soirs libres et tes '
                          'zones correspondent.',
              ),
              TourStep(
                target: _createKey,
                padding: MuSpace.s1,
                header: Text('ORGANISER', style: MuType.overline.copyWith(color: c.textSecondary)),
                title: 'Crée ta partie en 1 minute',
                body:
                    'Choisis le terrain et l’heure : on invite des joueurs à ton niveau, et chacun '
                    'paie sa part.',
              ),
              TourStep(
                target: ref.read(playerTabKeysProvider)[2],
                radius: MuRadius.md,
                padding: 0,
                header: Text('MES MATCHS', style: MuType.overline.copyWith(color: c.textSecondary)),
                title: 'Tous tes matchs au même endroit',
                body:
                    'Parties à venir, invitations et paiements en attente : tout se retrouve ici.',
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
        '${inv.venue} · ${formatDay(inv.start)} · ${formatTime(inv.start)} · '
        '${formatDT(inv.share)} /pers.';
    return MuCardSurface(
      padding: padding,
      onTap: onTap,
      semanticLabel: '${inv.from.name} t’invite au $sport, $what. Répondre',
      child: Row(
        children: [
          MuAvatar(name: inv.from.name, size: MuAvatarSize.m),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${inv.from.name} t’invite au $sport',
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
            child: Text('Répondre', style: MuType.labelS.copyWith(color: c.onAccent)),
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
      label: 'Demande à MatchUp, l’assistant IA',
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
                      'Demande à MatchUp…',
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
