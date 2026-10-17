import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../controllers/admin_controller.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../l10n/l10n.dart';

/// ADM-02 · Utilisateurs: search, filter chips, the sort sheet, and a bulk-select mode (the
/// « Sélectionner » button or a long press) whose sticky action bar replaces the tab bar.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  AdminUserQuery _q = const AdminUserQuery();
  final Set<String> _selected = {};

  bool get _bulk => ref.watch(adminBulkModeProvider);

  void _setBulk(bool on, {String? first}) {
    setState(() {
      _selected
        ..clear()
        ..addAll([?first]);
    });
    ref.read(adminBulkModeProvider.notifier).set(on);
  }

  void _toggle(String id) =>
      setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.read(clockProvider)();
    final all = ref.watch(adminUsersProvider).value;
    final total = ref.watch(adminOverviewProvider).value?.users ?? 12480;
    final users = all == null ? null : applyUserQuery(all, _q, now);
    final bulk = _bulk;
    final flagged = all?.where((u) => u.status == AdminUserStatus.flagged).length ?? 0;
    final toVerify = all?.where((u) => u.status == AdminUserStatus.toVerify).length ?? 0;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeader(title: l10n.utilisateurs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: MuSearchField<String>(
              label: l10n.rechercherUnUtilisateur,
              placeholder: l10n.nomEmailTelephone,
              onChanged: (v) => setState(() => _q = _q.copyWith(text: v)),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Semantics(
            container: true,
            label: l10n.filtres,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Row(
                children: [
                  for (final chip in [
                    MuChip(
                      label: _q.role == null ? l10n.role : _roleLabel(_q.role!),
                      trailingIcon: PhosphorIcons.caretDown(),
                      selected: _q.role != null,
                      onSelected: (_) => _pickRole(),
                    ),
                    MuChip(
                      label: _q.status == null ? l10n.statut : _statusLabel(_q.status!),
                      trailingIcon: PhosphorIcons.caretDown(),
                      selected: _q.status != null,
                      onSelected: (_) => _pickStatus(),
                    ),
                    MuChip(
                      label: l10n.signales,
                      count: flagged,
                      selected: _q.flagged,
                      onSelected: (v) => setState(() => _q = _q.copyWith(flagged: v)),
                    ),
                    MuChip(
                      label: l10n.aVerifier,
                      count: toVerify,
                      selected: _q.toVerify,
                      onSelected: (v) => setState(() => _q = _q.copyWith(toVerify: v)),
                    ),
                    MuChip(
                      label: l10n.nouveauxJours,
                      selected: _q.newOnly,
                      onSelected: (v) => setState(() => _q = _q.copyWith(newOnly: v)),
                    ),
                  ]) ...[chip, const SizedBox(width: MuSpace.s2)],
                ],
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s2),
          if (bulk) _selectionBar(c, users ?? const []) else _metaBar(c, users, total),
          Expanded(
            child: users == null
                ? const Center(child: MuSpinner())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      MuSpace.s4,
                      MuSpace.s1,
                      MuSpace.s4,
                      MuSpace.s16 + MuSpace.s16,
                    ),
                    children: [
                      if (users.isEmpty)
                        MuEmptyState(compact: true, title: l10n.aucunUtilisateurTrouve)
                      else
                        AdminList(
                          inset: AdminList.tileInset + (bulk ? MuSpace.s6 + MuSpace.s3 : 0),
                          label: l10n.utilisateurs,
                          children: [for (final u in users) _row(u, bulk)],
                        ),
                      if (!_q.filtered) ...[
                        const SizedBox(height: MuSpace.s3),
                        AdminMuted(
                          l10n.surFaisDefilerPourCharger(users.length, formatInt(total)),
                          align: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: bulk ? _tools(c, all ?? const []) : null,
    );
  }

  Widget _metaBar(MuColors c, List<AdminUser>? users, int total) => Padding(
    padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s2),
    child: SizedBox(
      height: MuSize.controlM,
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatInt(_q.filtered ? users?.length ?? 0 : total),
                    style: MuType.numS,
                  ),
                  const TextSpan(text: ' utilisateurs'),
                ],
              ),
              maxLines: 1,
              style: MuType.label.copyWith(color: c.text),
            ),
          ),
          MuButton.tertiary(
            label: _sortLabel(_q.sort),
            leading: PhosphorIcons.arrowsDownUp(),
            size: MuButtonSize.s,
            onPressed: _pickSort,
          ),
          MuIconButton(
            icon: PhosphorIcons.checkSquare(),
            label: l10n.selectionnerPlusieursUtilisateurs,
            onPressed: () => _setBulk(true),
          ),
        ],
      ),
    ),
  );

  Widget _selectionBar(MuColors c, List<AdminUser> users) {
    final n = _selected.length;
    final all = users.isNotEmpty && users.every((u) => _selected.contains(u.id));
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s2),
      child: SizedBox(
        height: MuSize.controlM,
        child: Row(
          children: [
            MuCheckbox(
              value: all ? true : (n == 0 ? false : null),
              tristate: true,
              semanticLabel: l10n.toutSelectionnerSurCettePage,
              onChanged: (_) => setState(() {
                if (all) {
                  _selected.clear();
                } else {
                  _selected.addAll(users.map((u) => u.id));
                }
              }),
            ),
            const SizedBox(width: MuSpace.s1),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$n', style: MuType.numS),
                    TextSpan(text: n > 1 ? l10n.selectionnes2 : l10n.selectionne3),
                  ],
                ),
                style: MuType.label.copyWith(color: c.text),
              ),
            ),
            MuButton.tertiary(
              label: l10n.annuler,
              size: MuButtonSize.s,
              onPressed: () => _setBulk(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AdminUser u, bool bulk) {
    final on = _selected.contains(u.id);
    final texts = AdminTexts(title: u.name, lines: [u.roleLine, u.meta]);
    final badge = _badge(u);
    if (bulk) {
      return AdminRow(
        selected: on,
        chevron: false,
        minHeight: MuSize.controlXl + MuSpace.s3,
        onTap: () => _toggle(u.id),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MuCheckbox(
              value: on,
              semanticLabel: l10n.selectionner(u.name),
              onChanged: (_) => _toggle(u.id),
            ),
            const SizedBox(width: MuSpace.s3),
            MuAvatar(name: u.name),
          ],
        ),
        end: badge,
        child: texts,
      );
    }
    return GestureDetector(
      onLongPress: () => _setBulk(true, first: u.id),
      child: AdminRow(
        minHeight: MuSize.controlXl + MuSpace.s3,
        leading: MuAvatar(name: u.name),
        end: badge,
        onTap: () {
          if (u.hasDetail) {
            context.push(Routes.adminUser(u.id));
          } else if (u.verificationId != null) {
            context.go(Routes.adminVerifications);
          } else {
            showComingSoon(context);
          }
        },
        child: texts,
      ),
    );
  }

  Widget _tools(MuColors c, List<AdminUser> all) {
    final n = _selected.length;
    Widget tool(IconData icon, String label, VoidCallback? onTap, {bool danger = false}) {
      final ink = danger ? c.errorText : c.text;
      return Expanded(
        child: Semantics(
          button: true,
          enabled: onTap != null,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            borderRadius: MuRadius.mdAll,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: MuSize.controlXl),
              child: Opacity(
                opacity: onTap == null ? MuOpacity.disabled : 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: MuSize.iconM, color: ink),
                    const SizedBox(height: MuSpace.s1),
                    Text(label, style: MuType.labelS.copyWith(color: ink)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final none = n == 0;
    return MuToastAnchor(
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surface, boxShadow: MuElevation.of(context).level2Up),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: MuSpace.s3),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s2, MuSpace.s2 - 2, MuSpace.s2, 0),
            child: Semantics(
              container: true,
              label: l10n.actionsSurLaSelection,
              child: Row(
                children: [
                  tool(
                    PhosphorIcons.envelopeSimple(),
                    l10n.message,
                    none ? null : () => showComingSoon(context),
                  ),
                  tool(
                    PhosphorIcons.downloadSimple(),
                    l10n.exporter,
                    none ? null : () => showComingSoon(context),
                  ),
                  tool(
                    PhosphorIcons.warning(),
                    l10n.avertir,
                    none ? null : () => showComingSoon(context),
                  ),
                  tool(
                    PhosphorIcons.prohibit(),
                    none ? l10n.suspendre2 : l10n.suspendre3(n),
                    none ? null : () => _suspendSelected(all),
                    danger: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bulk suspension: 7 days, confirmed with its consequence first.
  Future<void> _suspendSelected(List<AdminUser> all) async {
    final picked = [
      for (final u in all)
        if (_selected.contains(u.id)) u,
    ];
    final n = picked.length;
    final now = ref.read(clockProvider)();
    final until = now.add(AdminSuspensionLength.week.duration!);
    final ok = await MuDialog.show<bool>(
      context,
      tone: MuDialogTone.destructive,
      title: n > 1 ? l10n.suspendreComptes(n) : l10n.suspendre(picked.first.name),
      description:
          l10n.chaqueCompteEstPrevenuPar,
      consequenceIcon: PhosphorIcons.calendarX(),
      consequence:
          l10n.jusquAuNiPartieNi2(formatDay(until), formatTime(until), picked.map((u) => u.name).join(', ')),
      actions: [
        Builder(
          builder: (context) => MuButton.secondary(
            label: n > 1 ? l10n.garderLesComptesActifs : l10n.garderLeCompteActif,
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        Builder(
          builder: (context) => MuButton.destructive(
            label: l10n.suspendreJours,
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
    if (ok != true || !mounted) return;
    final actions = ref.read(adminActionsProvider);
    final repo = ref.read(adminRepositoryProvider);
    for (final u in picked) {
      final plan = await repo.sanctionPlan(u.id);
      await actions.suspend(u, length: AdminSuspensionLength.week, plan: plan, now: now);
    }
    if (!mounted) return;
    _setBulk(false);
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: n > 1 ? l10n.comptesSuspendusJours(n) : l10n.suspenduJours(picked.first.name),
    );
  }

  Future<void> _pickSort() async {
    var value = _q.sort;
    await MuBottomSheet.show<void>(
      context,
      title: l10n.trierLesUtilisateurs,
      height: MuSheetHeight.auto,
      footer: Builder(
        builder: (sheet) => MuButton.primary(
          label: l10n.appliquer,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () {
            setState(() => _q = _q.copyWith(sort: value));
            Navigator.of(sheet).pop();
          },
        ),
      ),
      child: StatefulBuilder(
        builder: (context, set) => MuRadioGroup<AdminUserSort>(
          label: l10n.ordreDeLaListe,
          hideLabel: true,
          value: value,
          onChanged: (v) => set(() => value = v),
          options: [
            for (final s in AdminUserSort.values)
              MuRadioOption(
                value: s,
                label: _sortLabel(s),
                description: s == AdminUserSort.toHandle
                    ? l10n.signalesPuisVerificationsEnAttente
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRole() => _pickOne<AdminRole?>(
    title: l10n.filtrerParRole,
    current: _q.role,
    options: [null, ...AdminRole.values],
    label: (r) => r == null ? l10n.tousLesRoles : _roleLabel(r),
    apply: (r) => _q = _q.copyWith(role: () => r),
  );

  Future<void> _pickStatus() => _pickOne<AdminUserStatus?>(
    title: l10n.filtrerParStatut,
    current: _q.status,
    options: [null, ...AdminUserStatus.values],
    label: (s) => s == null ? l10n.tousLesStatuts : _statusLabel(s),
    apply: (s) => _q = _q.copyWith(status: () => s),
  );

  Future<void> _pickOne<T>({
    required String title,
    required T current,
    required List<T> options,
    required String Function(T) label,
    required void Function(T) apply,
  }) async {
    var value = current;
    await MuBottomSheet.show<void>(
      context,
      title: title,
      height: MuSheetHeight.auto,
      footer: Builder(
        builder: (sheet) => MuButton.primary(
          label: l10n.appliquer,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () {
            setState(() => apply(value));
            Navigator.of(sheet).pop();
          },
        ),
      ),
      child: StatefulBuilder(
        builder: (context, set) => MuRadioGroup<int>(
          label: title,
          hideLabel: true,
          value: options.indexOf(value),
          onChanged: (i) => set(() => value = options[i]),
          options: [for (final (i, o) in options.indexed) MuRadioOption(value: i, label: label(o))],
        ),
      ),
    );
  }

  static String _sortLabel(AdminUserSort s) => switch (s) {
    AdminUserSort.toHandle => l10n.aTraiterDAbord,
    AdminUserSort.activity => l10n.derniereActivite,
    AdminUserSort.joined => l10n.inscriptionLaPlusRecente,
    AdminUserSort.reliability => l10n.fiabiliteLaPlusBasse,
    AdminUserSort.name => l10n.nomAZ,
  };

  static String _roleLabel(AdminRole r) => switch (r) {
    AdminRole.player => l10n.joueur,
    AdminRole.owner => l10n.proprietaire,
    AdminRole.coach => l10n.coach,
    AdminRole.organizer => l10n.organisateur,
  };

  static String _statusLabel(AdminUserStatus s) => switch (s) {
    AdminUserStatus.flagged => l10n.signale,
    AdminUserStatus.toVerify => l10n.aVerifier,
    AdminUserStatus.active => l10n.actif,
    AdminUserStatus.suspended => l10n.suspendu,
    AdminUserStatus.banned => l10n.banni,
  };

  static Widget _badge(AdminUser u) => MuStatusBadge(
    status: switch (u.status) {
      AdminUserStatus.flagged => MuStatus.failed,
      AdminUserStatus.toVerify => MuStatus.pending,
      AdminUserStatus.active => MuStatus.confirmed,
      AdminUserStatus.suspended || AdminUserStatus.banned => MuStatus.cancelled,
    },
    label: _statusLabel(u.status),
    size: MuBadgeSize.s,
  );
}
