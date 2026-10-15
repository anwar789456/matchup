import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../player_onboarding/controllers/onboarding_controller.dart';
import '../data/home_repository.dart';
import '../widgets/guided_tour.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) => FakeHomeRepository());

/// What the Home shows, loaded once.
final homeDataProvider = FutureProvider<
    ({List<MuGame> games, int notifications, int invitations})>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return (
    games: await repo.recommendedGames(),
    notifications: await repo.unreadNotifications(),
    invitations: await repo.pendingInvitations(),
  );
});

/// PLY-11 · Accueil + visite guidée: the player Home, with the 3-step tour the first time.
///
/// Only what the design shows is built; the other tabs, the assistant, game details and booking
/// come with the next milestones and say so for now.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _forYouKey = GlobalKey();
  final _createKey = GlobalKey();
  final _tabKeys = List.generate(5, (_) => GlobalKey());

  // PLY-11: game cards are 316 wide in the rail; quick actions 64 high.
  static const double _railCard = 316;
  static const double _actionHeight = 64;

  void _comingSoon() => MuToast.show(
        context,
        title: 'Bientôt disponible',
        description: 'Cet écran arrive dans une prochaine version de MatchUp.',
      );

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final onboarding = ref.watchOnboarding();
    final data = ref.watch(homeDataProvider).value;
    final firstName = (onboarding.fullName?.trim().isNotEmpty ?? false)
        ? onboarding.fullName!.trim().split(RegExp(r'\s+')).first
        : onboarding.pseudo;
    final userName = (onboarding.fullName?.trim().isNotEmpty ?? false)
        ? onboarding.fullName!.trim()
        : (onboarding.pseudo ?? 'MatchUp');
    final location = onboarding.zones.firstOrNull ?? onboarding.area ?? 'Tunis';
    final photo = ref.watch(profilePhotoProvider);
    final level = onboarding.levels.values.firstOrNull;
    final showTour = onboarding.completed && !onboarding.tourSeen && data != null;

    final page = Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: MuSize.controlXl + MuSpace.s4),
        children: [
          MuTopAppBar.home(
            greeting: firstName == null ? 'Salut !' : 'Salut $firstName',
            location: location,
            userName: userName,
            userImage: photo == null ? null : MemoryImage(photo),
            notifications: data?.notifications ?? 0,
            onLocation: _comingSoon,
            onNotifications: _comingSoon,
            onAccount: _comingSoon,
          ),
          const SizedBox(height: MuSpace.s1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: _AskBar(onTap: _comingSoon),
          ),
          const SizedBox(height: MuSpace.s5),
          KeyedSubtree(
            key: _forYouKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s2),
                  child: Row(
                    children: [
                      Semantics(
                        header: true,
                        child: Text('Parties pour toi', style: MuType.h3.copyWith(color: c.text)),
                      ),
                      const SizedBox(width: MuSpace.s2),
                      const MuAiLabel(size: MuAiLabelSize.s),
                      const Spacer(),
                      MuButton.tertiary(
                        label: 'Voir tout',
                        size: MuButtonSize.s,
                        onPressed: _comingSoon,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, MuSpace.s2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, game) in (data?.games ?? const <MuGame>[]).indexed) ...[
                        if (i > 0) const SizedBox(width: MuSpace.s3),
                        SizedBox(
                          width: _railCard,
                          child: MuGameCard(
                            game: game,
                            onTap: _comingSoon,
                            onJoin: _comingSoon,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: Semantics(
              container: true,
              label: 'Actions rapides',
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      label: 'Réserver un terrain',
                      tileColor: c.surfaceMuted,
                      icon: SvgPicture.asset(
                        MuGlyph.court,
                        width: MuSize.iconM,
                        height: MuSize.iconM,
                        colorFilter: ColorFilter.mode(c.text, BlendMode.srcIn),
                      ),
                      height: _actionHeight,
                      onTap: _comingSoon,
                    ),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: KeyedSubtree(
                      key: _createKey,
                      child: _QuickAction(
                        label: 'Créer une partie',
                        tileColor: c.accent,
                        icon: Icon(PhosphorIcons.plus(), size: MuSize.iconM, color: c.onAccent),
                        height: _actionHeight,
                        onTap: _comingSoon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MuTabBar(
        items: MuTabBar.playerTabs(matchesBadge: data?.invitations ?? 0),
        index: 0,
        itemKeys: _tabKeys,
        onChanged: (i) {
          if (i != 0) _comingSoon();
        },
      ),
      floatingActionButton: MuFab(onPressed: _comingSoon),
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
                body: 'Choisis le terrain et l’heure : on invite des joueurs à ton niveau, et chacun '
                    'paie sa part.',
              ),
              TourStep(
                target: _tabKeys[2],
                radius: MuRadius.md,
                padding: 0,
                header: Text('MES MATCHS', style: MuType.overline.copyWith(color: c.textSecondary)),
                title: 'Tous tes matchs au même endroit',
                body: 'Parties à venir, invitations et paiements en attente : tout se retrouve ici.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// « Demande à MatchUp… »: the assistant's entry in the page (AI ring, sparkle).
class _AskBar extends StatelessWidget {
  const _AskBar({required this.onTap});

  final VoidCallback onTap;

  // PLY-11: 1,5 px ai-500 ring.
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
                    Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                        size: MuSize.iconS, color: c.ai500),
                    const SizedBox(width: MuSpace.s3),
                    Text('Demande à MatchUp…',
                        style: MuType.bodyL.copyWith(color: c.textSecondary)),
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.tileColor,
    required this.height,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final Color tileColor;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: MuPressScale(
        child: Material(
          color: c.surface,
          borderRadius: MuRadius.mdAll,
          elevation: MuElevation.materialLevel1,
          shadowColor: MuElevation.of(context).shadowColor,
          child: InkWell(
            onTap: onTap,
            borderRadius: MuRadius.mdAll,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Padding(
                padding: const EdgeInsets.all(MuSpace.s3),
                child: Row(
                  children: [
                    Container(
                      width: MuSize.controlM,
                      height: MuSize.controlM,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: tileColor, borderRadius: MuRadius.smAll),
                      child: icon,
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(child: Text(label, style: MuType.label.copyWith(color: c.text))),
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
