import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/subscription_controller.dart';
import '../data/subscription_repository.dart';
import '../widgets/subscription_widgets.dart';
import '../../../l10n/l10n.dart';

/// The step bar of the two cancel steps (« Étape 1 sur 2 · Résilier Premium »).
class _CancelBar extends StatelessWidget {
  const _CancelBar({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s2, MuSpace.s2, MuSpace.s4, 0),
        child: Row(
          children: [
            MuIconButton(
              icon: PhosphorIcons.arrowLeft(),
              label: l10n.retour,
              size: MuIconButtonSize.l,
              onPressed: onBack,
            ),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: MuStepIndicator(step: step, total: 2, title: l10n.resilierPremium, showLabel: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// SUB-06 · Résilier 1/2: why (optional), what stays, then « Continuer » or « Garder Premium ».
class CancelReasonScreen extends ConsumerStatefulWidget {
  const CancelReasonScreen({super.key});

  @override
  ConsumerState<CancelReasonScreen> createState() => _CancelReasonScreenState();
}

class _CancelReasonScreenState extends ConsumerState<CancelReasonScreen> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final reason = ref.watch(cancelReasonProvider);
    final sub = ref.watch(subscriptionProvider).value;
    final balance = ref.watch(meProvider).value?.balance ?? 0;
    final end = formatDay(sub?.trialEnds ?? DateTime(2026, 10, 30));

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          _CancelBar(step: 1, onBack: () => goBack(context, Routes.subscription)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, MuSpace.s6),
              children: [
                FlowTitle(
                  l10n.pourquoiTuVeuxResilier,
                  lead: l10n.facultatifTaReponseNousAide,
                ),
                const SizedBox(height: MuSpace.s5),
                MuRadioGroup<CancelReason>(
                  label: l10n.raison,
                  hideLabel: true,
                  options: [
                    for (final r in CancelReason.values) MuRadioOption(value: r, label: r.label),
                  ],
                  value: reason,
                  onChanged: (r) => ref.read(cancelReasonProvider.notifier).set(r),
                ),
                const SizedBox(height: MuSpace.s4),
                MuTextField(
                  label: l10n.tuVeuxEnDirePlus,
                  optional: true,
                  multiline: true,
                  minLines: 2,
                  maxLength: 280,
                  placeholder: l10n.exJeJoueSurtoutL,
                  controller: _note,
                ),
                const SizedBox(height: MuSpace.s5),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.siTuResilies, style: MuType.labelL.copyWith(color: c.text)),
                      const SizedBox(height: MuSpace.s2),
                      CheckLine(
                        icon: PhosphorIcons.calendarCheck(),
                        text: l10n.premiumResteActifJusquAu(end),
                      ),
                      CheckLine(
                        icon: PhosphorIcons.creditCard(),
                        text: l10n.aucunPrelevementSurTa(sub?.cardLabel ?? 'carte'),
                      ),
                      CheckLine(
                        icon: PhosphorIcons.shieldCheck(),
                        text: l10n.tesMatchsTonNiveauEt(formatDT(balance)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(
            label: l10n.continuer,
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: () => context.push(Routes.subscriptionRetention),
          ),
          MuButton.tertiary(
            label: l10n.garderPremium,
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => context.go(Routes.subscription),
          ),
        ],
      ),
    );
  }
}

/// SUB-07 · Résilier 2/2: the AI retention offer (−30 % for 2 months) and « Non merci,
/// résilier », both the same size and weight: cancelling stays as short as subscribing.
class RetentionOfferScreen extends ConsumerStatefulWidget {
  const RetentionOfferScreen({super.key});

  @override
  ConsumerState<RetentionOfferScreen> createState() => _RetentionOfferScreenState();
}

class _RetentionOfferScreenState extends ConsumerState<RetentionOfferScreen> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    await ref.read(subscriptionProvider.notifier).acceptOffer();
    if (!mounted) return;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.offreActivee,
      description:
          '${formatDT(Subscription.offerMonthly)}/mois les 30 oct. et 30 nov., puis ${formatDT(Subscription.monthly)}/mois.',
    );
    context.go(Routes.subscription);
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    await ref.read(subscriptionProvider.notifier).cancel(reason: ref.read(cancelReasonProvider));
    if (!mounted) return;
    context.go(Routes.subscriptionCancelled);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final reason = ref.watch(cancelReasonProvider);
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    Widget column(IconData icon, String title, List<String> lines) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s4),
        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: MuSize.iconS, color: c.text),
                const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: Text(title, style: MuType.label.copyWith(color: c.text)),
                ),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            for (final l in lines) Text('• $l', style: caption),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          _CancelBar(step: 2, onBack: () => goBack(context, Routes.subscriptionCancel)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, MuSpace.s6),
              children: [
                FlowTitle(
                  l10n.uneDerniereOption,
                  lead: reason == null
                      ? l10n.siTuPreferesResilierChoisis
                      : l10n.tuAsReponduSiTu(reason.label),
                ),
                const SizedBox(height: MuSpace.s5),
                MuAiSuggestionCard(
                  context: l10n.offrePourToi,
                  title: l10n.pendantMois,
                  reason: l10n.tuAsJoueMatchsCe,
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formatDT(Subscription.offerMonthly),
                            style: MuType.numXl.copyWith(color: c.text),
                          ),
                          const SizedBox(width: MuSpace.s2),
                          Flexible(
                            child: Text(
                              '/mois au lieu de ${formatDT(Subscription.monthly)}',
                              style: MuType.body.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        l10n.lesOctEtNovPuis(formatDT(Subscription.monthly)),
                        style: caption,
                      ),
                    ],
                  ),
                  onFeedback: (_) {},
                ),
                const SizedBox(height: MuSpace.s4),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      column(PhosphorIcons.crown(), l10n.avecLOffre, [
                        l10n.premiumContinue,
                        l10n.leOct(formatDT(Subscription.offerMonthly)),
                        l10n.desLeDec(formatDT(Subscription.monthly)),
                      ]),
                      const SizedBox(width: MuSpace.s3),
                      column(PhosphorIcons.xCircle(), l10n.siTuResilies, [
                        l10n.actifJusquAuOct,
                        l10n.aucunPrelevement,
                        l10n.puisOffreGratuit,
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Same size and weight for both answers.
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.secondary(
            label: l10n.accepterLOffre,
            price: '${formatDT(Subscription.offerMonthly)}/mois',
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: _busy ? null : _accept,
          ),
          MuButton.secondary(
            label: l10n.nonMerciResilier,
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: _busy ? null : _cancel,
          ),
        ],
      ),
    );
  }
}

/// SUB-08 · Résiliation confirmée: Premium active until ven. 30 oct., no charge, what stays,
/// then « Retour au profil » or « Réactiver Premium ».
class CancelledScreen extends ConsumerWidget {
  const CancelledScreen({super.key});

  // SUB-08: the check medal is 64, the date tile 48.
  static const double _medal = 64;
  static const double _tile = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final sub = ref.watch(subscriptionProvider).value;
    final me = ref.watch(meProvider).value;
    final end = sub?.trialEnds ?? DateTime(2026, 10, 30);
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s2, MuSpace.s2, 0, 0),
                child: MuIconButton(
                  icon: PhosphorIcons.x(),
                  label: l10n.fermer,
                  size: MuIconButtonSize.l,
                  onPressed: () => context.go(Routes.profile),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                Center(
                  child: Container(
                    width: _medal,
                    height: _medal,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border),
                    ),
                    child: Icon(PhosphorIcons.check(), size: MuSize.iconL, color: c.text),
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                FlowTitle(
                  l10n.resiliationConfirmee,
                  centered: true,
                  lead: l10n.premiumResteActifJusquAu2(formatDay(end)),
                ),
                const SizedBox(height: MuSpace.s5),
                MuCardSurface(
                  child: Row(
                    children: [
                      Container(
                        width: _tile,
                        padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: MuRadius.smAll,
                        ),
                        child: Column(
                          children: [
                            Text(
                              formatMonth(end).toUpperCase(),
                              style: MuType.overline.copyWith(color: c.errorText),
                            ),
                            Text('${end.day}', style: MuType.numL.copyWith(color: c.text)),
                          ],
                        ),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.finDePremium(formatDay(end)),
                              style: MuType.label.copyWith(color: c.text),
                            ),
                            Text(
                              l10n.taNeSeraPasDebitee(sub?.cardLabel ?? 'carte'),
                              style: caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.jusqueLaTuGardesTout,
                        style: MuType.labelL.copyWith(color: c.text),
                      ),
                      const SizedBox(height: MuSpace.s2),
                      CheckLine(text: l10n.prioriteSurLesListesD),
                      CheckLine(text: l10n.plansDEntrainementIaEt),
                      CheckLine(text: l10n.statistiquesAvancees),
                      CheckLine(text: l10n.pasDeFraisDeService),
                      const SizedBox(height: MuSpace.s2),
                      Divider(height: 1, thickness: 1, color: c.border),
                      const SizedBox(height: MuSpace.s2),
                      Text(
                        l10n.apresLeTesMatchsTon(end.day, formatMonth(end), formatDT(me?.balance ?? 0)),
                        style: caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.envelopeSimple(),
                      size: MuSize.iconXs,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Flexible(
                      child: Text(
                        l10n.confirmationEnvoyeeA(me?.email ?? l10n.tonAdresse),
                        style: caption,
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
            label: l10n.retourAuProfil,
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: () => context.go(Routes.profile),
          ),
          MuButton.secondary(
            label: l10n.reactiverPremium,
            leading: PhosphorIcons.arrowCounterClockwise(),
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () async {
              await ref.read(subscriptionProvider.notifier).reactivate();
              if (context.mounted) context.go(Routes.subscription);
            },
          ),
        ],
      ),
    );
  }
}
