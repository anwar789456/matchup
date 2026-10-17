import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../data/profile_repository.dart';
import '../../../l10n/l10n.dart';

/// PRF-04 · Modifier le profil: cover and photo, handle and bio, sports and positions, zones,
/// visibility; « Enregistrer ».
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  PlayerProfile? _draft;
  late final TextEditingController _handle;
  late final TextEditingController _bio;
  bool _saving = false;

  static final _padelSides = [l10n.coteGauche, l10n.coteDroit, l10n.peuImporte];
  static final _footPositions = [l10n.gardien, l10n.defenseur, l10n.milieu, l10n.attaquant];
  static const double _cover = 140;

  @override
  void dispose() {
    _handle.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _init(PlayerProfile p) {
    _draft = p;
    _handle = TextEditingController(text: p.handle);
    _bio = TextEditingController(text: p.bio);
  }

  Future<void> _save() async {
    final d = _draft!.copyWith(handle: _handle.text.trim(), bio: _bio.text.trim());
    setState(() => _saving = true);
    await ref.read(playerProfileRepositoryProvider).save(d);
    ref.invalidate(myProfileProvider);
    if (!mounted) return;
    MuToast.show(context, tone: MuToastTone.success, title: l10n.profilEnregistre);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final profile = ref.watch(myProfileProvider);
    if (_draft == null) {
      final p = profile.value;
      if (p == null) {
        return Scaffold(
          backgroundColor: c.bg,
          body: Center(child: MuSpinner(semanticLabel: l10n.chargement)),
        );
      }
      _init(p);
    }
    final d = _draft!;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    void set(PlayerProfile Function(PlayerProfile) f) => setState(() => _draft = f(d));

    Widget head(String title, {String? sub}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: MuType.h2.copyWith(color: c.text)),
        ),
        if (sub != null) Text(sub, style: caption),
      ],
    );

    Widget positionCard(MuSport sport, String title, List<String> options) {
      final current = d.positions[sport];
      return Container(
        padding: const EdgeInsets.all(MuSpace.s3),
        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MuSportIcon(sport, size: MuSize.iconXs),
                const SizedBox(width: MuSpace.s1),
                Text(title, style: MuType.label.copyWith(color: c.text)),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            Wrap(
              spacing: MuSpace.s2,
              runSpacing: MuSpace.s2,
              children: [
                for (final o in options)
                  MuChip(
                    label: o,
                    kind: MuChipKind.choice,
                    size: MuChipSize.s,
                    selected: current?.toLowerCase() == o.toLowerCase(),
                    onSelected: (_) =>
                        set((p) => p.copyWith(positions: {...p.positions, sport: o.toLowerCase()})),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.modifierLeProfil,
            backLabel: l10n.retourAuProfilSansEnregistrer,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                head(l10n.photoEtCouverture),
                const SizedBox(height: MuSpace.s3),
                Text(l10n.couverture, style: MuType.label.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                ClipRRect(
                  borderRadius: MuRadius.mdAll,
                  child: SizedBox(
                    height: _cover,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MuCourtArt(
                          sport: d.coverSport,
                          variant: MuCourtArtVariant.photo,
                          semanticLabel: l10n.couvertureActuelle,
                        ),
                        PositionedDirectional(
                          end: MuSpace.s3,
                          bottom: MuSpace.s3,
                          child: MuButton.secondary(
                            label: l10n.changer,
                            leading: PhosphorIcons.image(),
                            size: MuButtonSize.s,
                            onPressed: () => showComingSoon(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MuSpace.s1),
                Text(l10n.tonTerrainPrefereOuUne, style: caption),
                const SizedBox(height: MuSpace.s4),
                MuFileUpload.avatar(
                  label: l10n.photoDeProfil,
                  name: d.name,
                  helper: l10n.jpgPngMoMaxVisage,
                  onAdd: () => showComingSoon(context),
                  onRemove: (_) => showComingSoon(context),
                ),
                const SizedBox(height: MuSpace.s6),
                head(l10n.infos),
                const SizedBox(height: MuSpace.s3),
                MuTextField(
                  label: l10n.pseudo,
                  controller: _handle,
                  prefixText: '@',
                  helper: l10n.tonLienDeProfilMatchup(_handle.text),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: MuSpace.s4),
                MuTextField(
                  label: l10n.bio,
                  optional: true,
                  controller: _bio,
                  multiline: true,
                  maxLength: 160,
                ),
                const SizedBox(height: MuSpace.s6),
                head(
                  l10n.sportsEtPostes,
                  sub: l10n.lesOrganisateursCherchentSouventUn,
                ),
                const SizedBox(height: MuSpace.s3),
                Wrap(
                  spacing: MuSpace.s2,
                  runSpacing: MuSpace.s2,
                  children: [
                    for (final s in MuSport.values)
                      MuChip.sport(
                        s,
                        selected: d.sports.contains(s),
                        onSelected: (on) => set(
                          (p) => p.copyWith(
                            sports: on
                                ? [...p.sports, s]
                                : [
                                    for (final x in p.sports)
                                      if (x != s) x,
                                  ],
                          ),
                        ),
                      ),
                  ],
                ),
                if (d.sports.contains(MuSport.padel)) ...[
                  const SizedBox(height: MuSpace.s3),
                  positionCard(MuSport.padel, l10n.padelTonCote, _padelSides),
                ],
                if (d.sports.contains(MuSport.football)) ...[
                  const SizedBox(height: MuSpace.s3),
                  positionCard(MuSport.football, l10n.footballTonPoste, _footPositions),
                ],
                const SizedBox(height: MuSpace.s3),
                Container(
                  padding: const EdgeInsets.all(MuSpace.s3),
                  decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.mdAll),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MuAiLabel(size: MuAiLabelSize.s, onAiSurface: true),
                      const SizedBox(width: MuSpace.s2),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: l10n.tonNiveauNEstPas,
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: MuButton.link(
                                  label: l10n.voirOuAjuster,
                                  inline: true,
                                  onPressed: () => context.pop(),
                                ),
                              ),
                            ],
                          ),
                          style: MuType.caption.copyWith(color: c.text),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s6),
                head(l10n.ouTuJoues),
                const SizedBox(height: MuSpace.s3),
                MuTagInput(
                  label: l10n.tesZones,
                  tags: d.zones,
                  max: 5,
                  helper: l10n.onTeProposeDesParties,
                  suggestions: [for (final (z, _) in Story.zones) z],
                  onChanged: (z) => set((p) => p.copyWith(zones: z)),
                ),
                const SizedBox(height: MuSpace.s6),
                head(l10n.visibilite),
                const SizedBox(height: MuSpace.s3),
                MuRadioGroup<ProfileVisibility>(
                  label: l10n.quiPeutVoirTonProfil,
                  value: d.visibility,
                  onChanged: (v) => set((p) => p.copyWith(visibility: v)),
                  options: [
                    MuRadioOption(
                      value: ProfileVisibility.everyone,
                      label: l10n.toutLeMonde,
                      description: l10n.visibleDansExplorerEtDans,
                    ),
                    MuRadioOption(
                      value: ProfileVisibility.followers,
                      label: l10n.mesAbonnes,
                      description: l10n.lesAutresVoientTonPseudo,
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                MuSwitch(
                  value: d.showLevel,
                  icon: PhosphorIcons.gauge(),
                  label: l10n.afficherMonNiveau,
                  description: l10n.pourEtreInviteAuBon,
                  onChanged: (v) => set((p) => p.copyWith(showLevel: v)),
                ),
                const SizedBox(height: MuSpace.s3),
                MuSwitch(
                  value: d.showReliability,
                  icon: PhosphorIcons.shieldCheck(),
                  label: l10n.afficherMaFiabilite,
                  description: l10n.rassureLesOrganisateursDeParties,
                  onChanged: (v) => set((p) => p.copyWith(showReliability: v)),
                ),
                const SizedBox(height: MuSpace.s3),
                MuSwitch(
                  value: d.suggestPartner,
                  icon: PhosphorIcons.sparkle(),
                  label: l10n.meProposerCommePartenaire,
                  description: l10n.suggereParLIaAux,
                  onChanged: (v) => set((p) => p.copyWith(suggestPartner: v)),
                ),
                const SizedBox(height: MuSpace.s4),
                MuSettingsRow(
                  title: l10n.plusDeReglagesDeConfidentialite,
                  onTap: () => context.push(Routes.settingsPrivacy),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(
            label: l10n.enregistrer,
            size: MuButtonSize.xl,
            fullWidth: true,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
