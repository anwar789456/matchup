import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../auth/controllers/auth_providers.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/onboarding_controller.dart';
import '../data/profile_repository.dart';
import '../widgets/onboarding_step_scaffold.dart';
import '../../../l10n/l10n.dart';

/// PLY-10 · Profil: photo and pseudo, then « Terminer » opens the Home with its guided tour.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _pseudo;
  late final TextEditingController _name;
  Timer? _debounce;
  String? _pseudoError;
  String? _pseudoOk;
  bool _saving = false;

  // Pseudo availability is checked 400 ms after typing stops.
  static const _debounceTime = Duration(milliseconds: 400);
  // PLY-10: camera button ringed 3 px with surface, 6 px outside the avatar.
  static const double _cameraRing = 3;
  static const double _cameraOffset = 6;
  static const double _photoMax = 512;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider).value;
    final email = ref.read(authFlowProvider).email ?? '';
    final suggested = email.contains('@') ? email.split('@').first : '';
    _pseudo = TextEditingController(
      text: state?.pseudo ?? (pseudoError(suggested) == null ? suggested : ''),
    );
    _name = TextEditingController(text: state?.fullName ?? '');
    _name.addListener(() => setState(() {}));
    if (_pseudo.text.isNotEmpty) _check(_pseudo.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pseudo.dispose();
    _name.dispose();
    super.dispose();
  }

  void _onPseudo(String value) {
    setState(() {
      _pseudoError = null;
      _pseudoOk = null;
    });
    _debounce?.cancel();
    _debounce = Timer(_debounceTime, () => _check(value));
  }

  Future<bool> _check(String value) async {
    final p = value.trim();
    final error = pseudoError(p);
    if (error != null) {
      if (mounted) setState(() => _pseudoError = error);
      return false;
    }
    final free = await ref.read(profileRepositoryProvider).isPseudoAvailable(p);
    if (!mounted || _pseudo.text.trim() != p) return false;
    setState(() {
      _pseudoOk = free ? '@$p est disponible' : null;
      _pseudoError = free ? null : '@$p est déjà pris. Essaie une variante.';
    });
    return free;
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: _photoMax,
        maxHeight: _photoMax,
      );
      if (file == null) return;
      ref.read(profilePhotoProvider.notifier).set(await file.readAsBytes());
    } on Exception {
      if (mounted) {
        MuToast.show(context,
            tone: MuToastTone.error,
            title: l10n.impossibleDOuvrirTesPhotos,
            description: l10n.verifieLAccesAuxPhotos);
      }
    }
  }

  Future<void> _finish({bool skip = false}) async {
    if (!skip) {
      _debounce?.cancel();
      setState(() => _saving = true);
      final ok = await _check(_pseudo.text);
      if (!ok) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      final photo = ref.read(profilePhotoProvider);
      await ref.read(profileRepositoryProvider).saveProfile(
            pseudo: _pseudo.text.trim(),
            fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
            photo: photo,
          );
      await ref.onboarding.setProfile(
        pseudo: _pseudo.text.trim(),
        fullName: _name.text.trim(),
      );
    }
    await ref.onboarding.complete();
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final photo = ref.watch(profilePhotoProvider);
    final name = _name.text.trim();
    final shown = name.isEmpty ? null : publicName(name);
    final displayName = name.isNotEmpty
        ? name
        : (_pseudo.text.trim().isNotEmpty ? _pseudo.text.trim() : l10n.matchup);

    return OnboardingStepScaffold(
      route: Routes.playerProfile,
      step: 7,
      stepTitle: l10n.tonProfil,
      onBack: () => goBack(context, Routes.playerNotifications),
      onSkip: () => _finish(skip: true),
      body: [
        FlowTitle(
          l10n.montreToi,
          lead: l10n.unePhotoEtUnPseudo,
        ),
        Column(
          children: [
            SizedBox.square(
              dimension: MuSize.avatarXl,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  MuAvatar(
                    name: displayName,
                    size: MuAvatarSize.xl,
                    image: photo == null ? null : MemoryImage(photo),
                  ),
                  PositionedDirectional(
                    end: -_cameraOffset - _cameraRing,
                    bottom: -_cameraOffset - _cameraRing,
                    child: Container(
                      padding: const EdgeInsets.all(_cameraRing),
                      decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
                      child: MuIconButton(
                        icon: PhosphorIcons.camera(),
                        label: l10n.prendreOuChoisirUnePhoto,
                        variant: MuIconButtonVariant.primary,
                        onPressed: _pickPhoto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MuSpace.s2),
            MuButton.tertiary(
              label: photo == null ? l10n.ajouterUnePhoto : l10n.changerDePhoto,
              size: MuButtonSize.s,
              onPressed: _pickPhoto,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTextField(
              label: l10n.pseudo,
              controller: _pseudo,
              prefixText: '@',
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              error: _pseudoError,
              success: _pseudoOk,
              onChanged: _onPseudo,
            ),
            const SizedBox(height: MuSpace.s5),
            MuTextField(
              label: l10n.prenomEtNom,
              controller: _name,
              placeholder: l10n.exYassineBelhadj,
              autofillHints: const [AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              helper: shown == null
                  ? l10n.lesAutresJoueursVoientTon
                  : l10n.lesAutresJoueursVoientJamais(shown),
              onSubmitted: (_) => _finish(),
            ),
          ],
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: l10n.terminer,
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _saving,
          onPressed: _finish,
        ),
      ],
    );
  }
}
