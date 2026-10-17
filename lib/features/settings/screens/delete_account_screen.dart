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
import '../../../l10n/l10n.dart';

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

  static final _word = l10n.supprimer2;
  static final _reasons = [
    l10n.jeNeJouePlus,
    l10n.pasAssezDePartiesPres,
    l10n.tropDeNotifications,
    l10n.jAiUnAutreCompte,
    l10n.autreRaison,
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
      title: l10n.compteSupprime,
      description: l10n.reconnecteToiAvantLeNov,
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
            title: l10n.supprimerLeCompte,
            backLabel: l10n.retourAuxParametres,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                MuSettingsGroup(
                  title: l10n.ceQuiVaSePasser,
                  children: [
                    step(
                      PhosphorIcons.calendarX(),
                      l10n.tesMatchsAVenirSont,
                      l10n.dimOctEtMerOct,
                    ),
                    step(
                      PhosphorIcons.wallet(),
                      l10n.retireDAbordTonSolde(formatDT(Story.myBalance)),
                      l10n.uneFoisLeCompteSupprime,
                      extra: MuButton.link(
                        label: l10n.retirerMonSolde,
                        onPressed: () => showComingSoon(context),
                      ),
                    ),
                    step(
                      PhosphorIcons.hourglass(),
                      l10n.tonProfilEstEffaceDans,
                      l10n.niveauMatchsEtAvisReconnecte,
                    ),
                    step(
                      PhosphorIcons.warning(),
                      l10n.apresLeNovCEst,
                      l10n.personneNePourraRecupererTon,
                      error: true,
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.confirmer,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(MuSpace.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MuSelect<String>(
                            label: l10n.pourquoiParsTu,
                            placeholder: l10n.choisisUneRaison,
                            helper: l10n.caNousAideAAmeliorer,
                            value: _reason,
                            options: [for (final r in _reasons) MuSelectOption(value: r, label: r)],
                            onChanged: (v) => setState(() => _reason = v),
                          ),
                          const SizedBox(height: MuSpace.s5),
                          MuTextField(
                            label: l10n.tapePourConfirmer(_word),
                            controller: _confirm,
                            placeholder: _word,
                            helper: _ok
                                ? l10n.tuPeuxSupprimerTonCompte
                                : l10n.leBoutonSActiveQuand,
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
            label: l10n.garderMonCompte,
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: () => context.go(Routes.settings),
          ),
          MuButton.destructive(
            label: l10n.supprimerMonCompte,
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
