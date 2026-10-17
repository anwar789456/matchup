import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/clients_repository.dart';
import '../../../l10n/l10n.dart';

enum _ClientFilter { all, regulars, newcomers, noShows }

/// OWN-18 · Clients: search (name, phone, MU-… reference), filters (Tous, Habitués, Nouveaux, Avec
/// no-show), then the clients by visits; a row opens their visits, spend, no-shows, MatchUp
/// reliability, favourite slot and first match.
class OwnerClientsScreen extends ConsumerStatefulWidget {
  const OwnerClientsScreen({super.key});

  @override
  ConsumerState<OwnerClientsScreen> createState() => _OwnerClientsScreenState();
}

class _OwnerClientsScreenState extends ConsumerState<OwnerClientsScreen> {
  final _search = TextEditingController();
  var _filter = _ClientFilter.all;
  String? _open = 'Hamza R.';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesFilter(OwnerClient x) => switch (_filter) {
    _ClientFilter.all => true,
    _ClientFilter.regulars => x.regular,
    _ClientFilter.newcomers => x.newcomer,
    _ClientFilter.noShows => x.noShows > 0,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final data = ref.watch(ownerClientsProvider).value;
    final shown = [
      for (final x in data?.top ?? const <OwnerClient>[])
        if (_matchesFilter(x) && x.matches(_search.text)) x,
    ];
    Widget chip(_ClientFilter f, String label, int? count) => MuChip(
      kind: MuChipKind.choice,
      size: MuChipSize.s,
      label: label,
      count: count,
      selected: _filter == f,
      onSelected: (_) => setState(() => _filter = f),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.clients,
            subtitle: l10n.espaceProprietaire2(Story.arenaFive.name),
            backLabel: l10n.retourAPlus,
            onBack: () => goBack(context, Routes.ownerMore),
            actions: [
              MuBarAction(
                icon: PhosphorIcons.sortAscending(),
                label: l10n.trierLesClients,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          Expanded(
            child: data == null
                ? const Center(child: MuSpinner())
                : ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      MuSpace.s4,
                      MuSpace.s2,
                      MuSpace.s4,
                      MuSpace.s8,
                    ),
                    children: [
                      MuSearchField<String>(
                        label: l10n.rechercherUnClient,
                        placeholder: l10n.nomTelephoneOuNDe,
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Semantics(
                        container: true,
                        label: l10n.filtrerLesClients,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              chip(_ClientFilter.all, l10n.tous, data.total),
                              const SizedBox(width: MuSpace.s2),
                              chip(_ClientFilter.regulars, l10n.habitues, data.regulars),
                              const SizedBox(width: MuSpace.s2),
                              chip(_ClientFilter.newcomers, l10n.nouveaux, data.newcomers),
                              const SizedBox(width: MuSpace.s2),
                              chip(_ClientFilter.noShows, l10n.avecNoShow, data.withNoShow),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  '${formatInt(data.total)} clients · par visites'.toUpperCase(),
                                  style: MuType.overline.copyWith(color: c.textSecondary),
                                ),
                              ),
                            ),
                            Text(
                              l10n.depuisLe(data.since.day, formatMonth(data.since)),
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MuSpace.s2),
                      if (shown.isEmpty)
                        MuEmptyState(
                          compact: true,
                          title: _search.text.trim().isEmpty
                              ? l10n.aucunClientDansCeFiltre
                              : l10n.aucunClientPour(_search.text.trim()),
                          description: l10n.essaieUnAutreNomNumero,
                        )
                      else
                        MuCardSurface(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: MuRadius.mdAll,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final (i, x) in shown.indexed) ...[
                                  if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                                  _ClientTile(
                                    client: x,
                                    open: _open == x.name,
                                    onToggle: () =>
                                        setState(() => _open = _open == x.name ? null : x.name),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: MuSpace.s3),
                      MuButton.secondary(
                        label: l10n.afficherClientsDePlus,
                        fullWidth: true,
                        onPressed: () => showComingSoon(context),
                      ),
                      const SizedBox(height: MuSpace.s3),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                        child: Text(
                          l10n.tuVoisLaFiabiliteMatchup,
                          textAlign: TextAlign.center,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClientTile extends ConsumerWidget {
  const _ClientTile({required this.client, required this.open, required this.onToggle});

  final OwnerClient client;
  final bool open;
  final VoidCallback onToggle;

  // OWN-18: rows 72 high, 3 px between the name and its line, pills padded 1 px, icons 14.
  static const double _minHeight = 72;
  static const double _lineGap = 3;
  static const double _pillPadV = 1;

  /// « aujourd’hui · 17h00 », « prochaine · mer. 21 oct. », « dim. 11 oct. ».
  static String when(OwnerClient x, DateTime now) {
    final next = x.nextVisit;
    if (next != null && next.isAfter(now)) return l10n.prochaine(formatDay(next));
    final d = x.lastVisit;
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return l10n.aujourdHui5(formatTime(d));
    }
    return formatDay(d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final x = client;
    final now = ref.read(clockProvider)();
    final secondary = MuType.caption.copyWith(color: c.textSecondary);
    final number = MuType.numXs.copyWith(color: c.text);
    final visits = x.visits == 1 ? 'visite' : 'visites';

    Widget pill(IconData icon, String label, Color ground, Color ink) => Container(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: _pillPadV),
      decoration: BoxDecoration(color: ground, borderRadius: MuRadius.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconPill, color: ink),
          const SizedBox(width: MuSpace.s1),
          Text(label, style: MuType.labelS.copyWith(color: ink)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label:
              '${x.name}, ${x.visits} $visits, ${formatDT(x.spent)}'
              '${x.noShows > 0 ? l10n.noShow2(x.noShows, x.noShows > 1 ? 's' : '') : ''}'
              '${x.newcomer ? l10n.nouveau : ''}',
          excludeSemantics: true,
          child: InkWell(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  MuSpace.s4,
                  MuSpace.s3,
                  MuSpace.s3,
                  MuSpace.s3,
                ),
                child: Row(
                  children: [
                    MuAvatar(name: x.name),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: MuSpace.s2,
                            runSpacing: MuSpace.s1,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(x.name, style: MuType.labelL.copyWith(color: c.text)),
                              if (x.noShows > 0)
                                pill(
                                  PhosphorIcons.userMinus(),
                                  x.noShows == 1 ? l10n.noShow3 : '${x.noShows} no-shows',
                                  c.warningSoft,
                                  c.warningText,
                                ),
                              if (x.newcomer)
                                pill(PhosphorIcons.userPlus(), l10n.nouveau2, c.infoSoft, c.infoText),
                            ],
                          ),
                          const SizedBox(height: _lineGap),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '${x.visits}', style: number),
                                TextSpan(text: ' $visits · '),
                                TextSpan(text: formatDT(x.spent), style: number),
                                TextSpan(text: ' · ${when(x, now)}'),
                              ],
                            ),
                            style: secondary,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      open ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
                      size: MuSize.iconS,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (open) _details(context, x),
      ],
    );
  }

  static const double _iconPill = 14;

  Widget _details(BuildContext context, OwnerClient x) {
    final c = context.mu;
    final label = MuType.body.copyWith(color: c.textSecondary);
    final value = MuType.body.copyWith(color: c.text);
    Widget stat(String v, String l, {Color? color}) => Expanded(
      child: Semantics(
        label: '$l : $v',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v, style: MuType.numL.copyWith(color: color ?? c.text)),
              const SizedBox(height: MuSpace.s1 / 2),
              Text(l, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ),
    );
    Widget line(String l, Widget v) => Padding(
      padding: const EdgeInsets.only(top: MuSpace.s2),
      child: Row(
        children: [
          Expanded(child: Text(l, style: label)),
          v,
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  stat('${x.visits}', 'visites'),
                  VerticalDivider(width: 1, thickness: 1, color: c.border),
                  stat(formatDT(x.spent), l10n.depenses),
                  VerticalDivider(width: 1, thickness: 1, color: c.border),
                  stat('${x.noShows}', 'no-show', color: x.noShows > 0 ? c.warningText : null),
                ],
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s2),
          line(l10n.fiabiliteMatchup, MuReliabilityBadge(score: x.reliability, size: MuBadgeSize.s)),
          line(l10n.creneauPrefere, Text(x.favourite, style: value)),
          line(l10n.premierMatchIci, Text(formatDay(x.firstVisit), style: value)),
          const SizedBox(height: MuSpace.s4),
          Row(
            children: [
              Expanded(
                child: MuButton.secondary(
                  label: l10n.reservations,
                  leading: PhosphorIcons.listChecks(),
                  fullWidth: true,
                  onPressed: () => context.go(Routes.ownerBookings),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: MuButton.secondary(
                  label: l10n.message,
                  leading: PhosphorIcons.chatCircleDots(),
                  fullWidth: true,
                  onPressed: () => showComingSoon(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
