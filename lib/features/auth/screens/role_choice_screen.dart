import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/auth_providers.dart';
import '../data/auth_repository.dart';
import '../widgets/auth_widgets.dart';

/// AUTH-11 · Choix du rôle: one or more roles; « Continuer » opens the first one's onboarding.
class RoleChoiceScreen extends ConsumerStatefulWidget {
  const RoleChoiceScreen({super.key});

  @override
  ConsumerState<RoleChoiceScreen> createState() => _RoleChoiceScreenState();
}

class _RoleOption {
  const _RoleOption(this.role, this.title, this.short, this.description, this.route, this.leading);

  final UserRole role;
  final String title;

  /// Name in « Continuer · Joueur d’abord ».
  final String short;
  final String description;
  final String route;
  final Widget leading;
}

class _RoleChoiceScreenState extends ConsumerState<RoleChoiceScreen> {
  final Set<UserRole> _roles = {};
  bool _loading = false;

  static final _options = [
    _RoleOption(UserRole.player, 'Joueur', 'Joueur',
        'Trouve des parties, réserve des terrains et paie ta part.', Routes.playerSports,
        MuSportTile.icon(PhosphorIcons.personSimpleRun())),
    _RoleOption(UserRole.owner, 'Propriétaire de terrain', 'Propriétaire',
        'Gère tes terrains, ton planning et tes réservations.', Routes.ownerCompany,
        MuSportTile.icon(PhosphorIcons.storefront())),
    const _RoleOption(UserRole.coach, 'Coach', 'Coach',
        'Publie tes programmes et suis la progression de tes élèves.', Routes.coachProfile,
        MuSportTile.asset(MuGlyph.whistle)),
    const _RoleOption(UserRole.organizer, 'Organisateur', 'Organisateur',
        'Crée et gère tes tournois et tes événements.', Routes.organizerOrganisation,
        MuSportTile.asset(MuGlyph.trophy)),
  ];

  _RoleOption? get _first => _options.where((o) => _roles.contains(o.role)).firstOrNull;

  String get _label {
    final first = _first;
    if (first == null) return 'Choisis au moins un rôle';
    return _roles.length > 1 ? 'Continuer · ${first.short} d’abord' : 'Continuer';
  }

  Future<void> _continue() async {
    final first = _first;
    if (first == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).saveRoles(_roles);
      if (mounted) context.push(first.route);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return FlowScaffold(
      onBack: () => goBack(context, Routes.verifyEmail),
      body: [
        const FlowTitle('Comment vas-tu utiliser MatchUp ?', lead: 'Choisis un ou plusieurs rôles.'),
        MuChoiceGroup(
          label: 'Tes rôles sur MatchUp',
          children: [
            for (final o in _options)
              MuChoiceCard(
                title: o.title,
                description: o.description,
                leading: o.leading,
                multi: true,
                selected: _roles.contains(o.role),
                onTap: () => setState(() {
                  if (!_roles.remove(o.role)) _roles.add(o.role);
                }),
              ),
          ],
        ),
        IconLine(
          icon: PhosphorIcons.info(),
          iconSize: MuSize.iconXs,
          gap: MuSpace.s2,
          style: MuType.caption.copyWith(color: c.textSecondary),
          text: const TextSpan(text: 'Tu pourras en ajouter d’autres plus tard depuis ton profil.'),
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: _label,
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _loading,
          onPressed: _first == null ? null : _continue,
        ),
      ],
    );
  }
}
