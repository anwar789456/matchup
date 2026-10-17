import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/session.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../player_onboarding/controllers/onboarding_controller.dart';

/// SET-07 · Supprimer le compte: the consequences, an optional reason, « SUPPRIMER » to enable
/// the button; then signed out to ONB-01.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  String? _reason;
  bool _deleting = false;

  static const _word = 'SUPPRIMER';
  static const _reasons = [
    'Je ne joue plus',
    'Pas assez de parties près de chez moi',
    'Trop de notifications',
    'J’ai un autre compte',
    'Autre raison',
  ];

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool get _ok => _confirm.text.trim() == _word;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    await ref.read(sessionProvider.notifier).signOut();
    await ref.read(onboardingProvider.notifier).reset();
    if (!mounted) return;
    MuToast.show(
      context,
      title: 'Compte supprimé',
      description: 'Reconnecte-toi avant le 15 nov. pour tout garder.',
    );
    context.go(Routes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget step(IconData icon, String title, String text, {bool error = false, Widget? extra}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MuSize.controlS,
                height: MuSize.controlS,
                decoration: BoxDecoration(
                  color: error ? c.errorSoft : c.surfaceMuted,
                  borderRadius: MuRadius.smAll,
                ),
                child: Icon(icon, size: MuSize.iconS, color: error ? c.errorText : c.text),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: MuType.label.copyWith(color: error ? c.errorText : c.text)),
                    Text(text, style: MuType.body.copyWith(color: c.textSecondary)),
                    if (extra != null) ...[const SizedBox(height: MuSpace.s1), extra],
                  ],
                ),
              ),
            ],
          ),
        );
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: 'Supprimer le compte',
            backLabel: 'Retour aux paramètres',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                MuSettingsGroup(
                  title: 'Ce qui va se passer',
                  children: [
                    step(
                      PhosphorIcons.calendarX(),
                      'Tes 2 matchs à venir sont annulés',
                      'dim. 18 oct. et mer. 21 oct. Chaque joueur est remboursé, toi compris.',
                    ),
                    step(
                      PhosphorIcons.wallet(),
                      'Retire d’abord ton solde de ${formatDT(Story.myBalance)}',
                      'Une fois le compte supprimé, on ne pourra plus te le verser.',
                      extra: MuButton.link(
                        label: 'Retirer mon solde',
                        onPressed: () => showComingSoon(context),
                      ),
                    ),
                    step(
                      PhosphorIcons.hourglass(),
                      'Ton profil est effacé dans 30 jours',
                      'Niveau, matchs et avis. Reconnecte-toi avant le 15 nov. pour tout garder.',
                    ),
                    step(
                      PhosphorIcons.warning(),
                      'Après le 15 nov., c’est définitif',
                      'Personne ne pourra récupérer ton compte, même en nous écrivant.',
                      error: true,
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: 'Confirmer',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(MuSpace.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MuSelect<String>(
                            label: 'Pourquoi pars-tu ?',
                            placeholder: 'Choisis une raison',
                            helper: 'Ça nous aide à améliorer MatchUp.',
                            value: _reason,
                            options: [for (final r in _reasons) MuSelectOption(value: r, label: r)],
                            onChanged: (v) => setState(() => _reason = v),
                          ),
                          const SizedBox(height: MuSpace.s5),
                          MuTextField(
                            label: 'Tape $_word pour confirmer',
                            controller: _confirm,
                            placeholder: _word,
                            helper: _ok
                                ? 'Tu peux supprimer ton compte.'
                                : 'Le bouton s’active quand le mot est tapé.',
                            textCapitalization: TextCapitalization.characters,
                            autocorrect: false,
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_reason == null) Text('', style: caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(
            label: 'Garder mon compte',
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: () => context.go(Routes.settings),
          ),
          MuButton.destructive(
            label: 'Supprimer mon compte',
            size: MuButtonSize.xl,
            fullWidth: true,
            loading: _deleting,
            onPressed: _ok && !_deleting ? _delete : null,
          ),
        ],
      ),
    );
  }
}
