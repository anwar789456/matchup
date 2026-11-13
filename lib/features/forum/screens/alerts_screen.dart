import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/forum_providers.dart';
import '../data/forum_repository.dart';
import '../data/forum_watcher.dart';
import '../widgets/forum_actions.dart';
import '../widgets/forum_feed_list.dart';

/// The reader's saved searches, refreshed with the forum.
final forumAlertsProvider = FutureProvider<List<ForumAlert>>((ref) {
  ref.watch(forumChangesProvider);
  return ref.watch(forumRepositoryProvider).alerts();
});

/// « Créer une alerte »: what to watch, then saved; the reader is told about new matches.
Future<void> createAlert(BuildContext context, WidgetRef ref, {AlertKind kind = AlertKind.listing, String words = '', MuSport? sport}) async {
  final draft = await MuBottomSheet.show<_AlertDraft>(
    context,
    title: l10n.alNouvelleAlerte,
    height: MuSheetHeight.full,
    child: _AlertForm(kind: kind, words: words, sport: sport),
  );
  if (draft == null || !context.mounted) return;
  try {
    await ref
        .read(forumRepositoryProvider)
        .saveAlert(draft.kind, words: draft.words, sport: draft.sport, maxPrice: draft.maxPrice, size: draft.size);
    ref.read(forumChangesProvider.notifier).bump();
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.alAlerteCreee,
      description: l10n.alAlerteCreeeDetail,
      icon: PhosphorIcons.bellRinging(),
      action: MuAction(l10n.alMesAlertes, () => router.push(Routes.forumAlerts)),
    );
  } catch (e) {
    if (context.mounted) showForumError(context, e);
  }
}

class _AlertDraft {
  const _AlertDraft(this.kind, this.words, this.sport, this.maxPrice, this.size);
  final AlertKind kind;
  final String words;
  final MuSport? sport;
  final double? maxPrice;
  final String? size;
}

class _AlertForm extends StatefulWidget {
  const _AlertForm({required this.kind, required this.words, required this.sport});

  final AlertKind kind;
  final String words;
  final MuSport? sport;

  @override
  State<_AlertForm> createState() => _AlertFormState();
}

class _AlertFormState extends State<_AlertForm> {
  late AlertKind _kind = widget.kind;
  late MuSport? _sport = widget.sport;
  late final _words = TextEditingController(text: widget.words);
  final _price = TextEditingController();
  final _size = TextEditingController();

  static const int _wordsMax = 60;
  static const int _priceMax = 6;
  static const int _sizeMax = 12;

  @override
  void initState() {
    super.initState();
    for (final c in [_words, _price, _size]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _words.dispose();
    _price.dispose();
    _size.dispose();
    super.dispose();
  }

  double? get _maxPrice {
    final p = double.tryParse(_price.text.replaceAll(',', '.').trim());
    return p == null || p <= 0 ? null : p;
  }

  bool get _ready =>
      _words.text.trim().isNotEmpty || _sport != null || (_kind == AlertKind.listing && (_maxPrice != null || _size.text.trim().isNotEmpty));

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final listing = _kind == AlertKind.listing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuSegmentedControl<AlertKind>(
            semanticLabel: l10n.alCeQueTuSurveilles,
            expand: true,
            segments: [
              MuSegment(value: AlertKind.listing, label: l10n.alAnnonces),
              MuSegment(value: AlertKind.game, label: l10n.cjChercheJoueurs),
            ],
            value: _kind,
            onChanged: (k) => setState(() => _kind = k),
          ),
          const SizedBox(height: MuSpace.s2),
          Text(listing ? l10n.alAnnoncesDetail : l10n.alPartiesDetail, style: MuType.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s4),
          MuTextField(
            label: l10n.alMotsCles,
            controller: _words,
            optional: true,
            placeholder: listing ? l10n.alMotsClesAnnonce : l10n.alMotsClesPartie,
            maxLength: _wordsMax,
            leadingIcon: PhosphorIcons.magnifyingGlass(),
          ),
          const SizedBox(height: MuSpace.s4),
          MuFieldLabel(label: l10n.msgSport, optional: true),
          const SizedBox(height: MuSpace.s2),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final s in MuSport.values)
                MuChip.sport(s, selected: _sport == s, onSelected: (on) => setState(() => _sport = on ? s : null)),
            ],
          ),
          if (listing) ...[
            const SizedBox(height: MuSpace.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MuTextField(
                    label: l10n.alPrixMax,
                    controller: _price,
                    optional: true,
                    suffixText: dtUnit,
                    maxLength: _priceMax,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: MuTextField(
                    label: l10n.mktTaille,
                    controller: _size,
                    optional: true,
                    placeholder: l10n.mktTaillePlaceholder,
                    maxLength: _sizeMax,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: MuSpace.s3),
            Text(l10n.alNiveauAuto, style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
          const SizedBox(height: MuSpace.s6),
          MuButton.primary(
            label: l10n.alCreerLAlerte,
            leading: PhosphorIcons.bellRinging(),
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: _ready
                ? () => Navigator.of(context, rootNavigator: true).pop(
                    _AlertDraft(_kind, _words.text, _sport, listing ? _maxPrice : null, listing ? _size.text : null),
                  )
                : null,
          ),
          if (!_ready) ...[
            const SizedBox(height: MuSpace.s2),
            Text(l10n.alAuMoinsUnCritere, textAlign: TextAlign.center, style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// « Mes alertes »: each saved search with what it watches and how many posts match it now,
/// on / off, « Supprimer », and a tap for the matches.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final alerts = ref.watch(forumAlertsProvider);
    final list = alerts.value;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: l10n.alMesAlertes,
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.community),
              actions: [
                MuBarAction(icon: PhosphorIcons.plus(), label: l10n.alNouvelleAlerte, onPressed: () => createAlert(context, ref)),
              ],
            ),
            Expanded(
              child: list == null
                  ? const Center(child: MuSpinner())
                  : list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(MuSpace.s6),
                      child: MuEmptyState(
                        illustration: MuEmptyIllustration.notifications,
                        title: l10n.alAucuneAlerte,
                        description: l10n.alAucuneAlerteDetail,
                        actions: [
                          MuButton.primary(
                            label: l10n.alNouvelleAlerte,
                            leading: PhosphorIcons.bellRinging(),
                            onPressed: () => createAlert(context, ref),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s8),
                      children: [
                        Text(l10n.alExplication, style: MuType.caption.copyWith(color: c.textSecondary)),
                        const SizedBox(height: MuSpace.s3),
                        for (final a in list) ...[_AlertCard(alert: a), const SizedBox(height: MuSpace.s3)],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard({required this.alert});

  final ForumAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final a = alert;
    final repo = ref.read(forumRepositoryProvider);
    Future<void> run(Future<void> Function() f) async {
      try {
        await f();
        ref.read(forumChangesProvider.notifier).bump();
      } catch (e) {
        if (context.mounted) showForumError(context, e);
      }
    }

    return MuCardSurface(
      onTap: () => context.push(Routes.forumAlert(a.id)),
      semanticLabel: alertLabel(a),
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s2, MuSpace.s3),
      child: Row(
        children: [
          Container(
            width: MuSize.controlM,
            height: MuSize.controlM,
            decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
            child: Icon(a.kind == AlertKind.listing ? PhosphorIcons.tag() : PhosphorIcons.usersThree(), size: MuSize.iconS, color: c.text),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alertLabel(a), style: MuType.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: MuSpace.s1),
                Text(
                  [
                    a.kind == AlertKind.listing ? l10n.alAnnonces : l10n.cjChercheJoueurs,
                    a.kind == AlertKind.listing ? l10n.alNAnnonces(a.matches) : l10n.alNParties(a.matches),
                    if (!a.active) l10n.alEnPause,
                  ].join(' · '),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          Semantics(
            label: l10n.alActiverX(alertLabel(a)),
            child: Switch.adaptive(value: a.active, onChanged: (on) => run(() => repo.setAlertActive(a.id, active: on))),
          ),
          MuIconButton(
            icon: PhosphorIcons.trash(),
            label: l10n.alSupprimerLAlerte,
            size: MuIconButtonSize.s,
            onPressed: () => run(() => repo.deleteAlert(a.id)),
          ),
        ],
      ),
    );
  }
}

/// What an alert matches now, in the feed's cards.
class AlertResultsScreen extends ConsumerWidget {
  const AlertResultsScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final alert = ref.watch(forumAlertsProvider).value?.where((a) => a.id == alertId).firstOrNull;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: alert == null ? l10n.alMesAlertes : alertLabel(alert),
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.forumAlerts),
            ),
            Expanded(
              child: alert == null
                  ? const Center(child: MuSpinner())
                  : ForumFeedList(
                      query: alert.query,
                      empty: MuEmptyState(compact: true, title: l10n.alRienPourLInstant, description: l10n.alRienPourLInstantDetail),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
