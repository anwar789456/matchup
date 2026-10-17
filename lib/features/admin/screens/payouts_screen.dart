import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/admin_controller.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';
import '../../../l10n/l10n.dart';

/// ADM-07 · Versements et remboursements: the payouts of lun. 19 oct. to tick and validate (the
/// money leaves only after the admin confirms), then the refund requests.
class AdminPayoutsScreen extends ConsumerStatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  ConsumerState<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends ConsumerState<AdminPayoutsScreen> {
  Set<String>? _selected;
  bool _validating = false;
  final Set<String> _refunding = {};

  Future<void> _validate(List<AdminPayout> picked) async {
    final total = picked.fold<num>(0, (a, p) => a + p.amount);
    final n = picked.length;
    final ok = await MuDialog.show<bool>(
      context,
      tone: MuDialogTone.warning,
      icon: PhosphorIcons.bank(),
      title: n > 1 ? l10n.validerVersements(n) : l10n.validerLeVersement,
      description: l10n.lesVirementsPartentLunOct,
      consequenceIcon: PhosphorIcons.bank(),
      consequence: l10n.vers2(formatDT(total), picked.map((p) => p.name).join(', ')),
      actions: [
        Builder(
          builder: (context) => MuButton.secondary(
            label: l10n.pasMaintenant,
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        Builder(
          builder: (context) => MuButton.primary(
            label: n > 1 ? l10n.validerVersements2(n) : l10n.validerLeVersement2,
            size: MuButtonSize.l,
            fullWidth: true,
            price: formatDT(total),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
    if (ok != true || !mounted) return;
    setState(() => _validating = true);
    await ref.read(adminActionsProvider).validatePayouts({for (final p in picked) p.id});
    if (!mounted) return;
    setState(() {
      _validating = false;
      _selected = {};
    });
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: n > 1 ? l10n.versementsValides(n) : l10n.versementValide,
    );
  }

  Future<void> _refund(AdminRefund r) async {
    setState(() => _refunding.add(r.id));
    await ref.read(adminActionsProvider).refund(r.id);
    if (!mounted) return;
    setState(() => _refunding.remove(r.id));
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.remboursesA(formatDT(r.amount), r.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final payouts = ref.watch(adminPayoutsProvider).value;
    final refunds = (ref.watch(adminRefundsProvider).value ?? const <AdminRefund>[])
        .where((r) => !r.done)
        .toList();
    final open = [
      for (final p in payouts ?? const <AdminPayout>[])
        if (!p.validated) p,
    ];
    final validated = [
      for (final p in payouts ?? const <AdminPayout>[])
        if (p.validated) p,
    ];
    final selected = _selected ??= payouts == null ? null : {for (final p in open) p.id};
    final picked = [
      for (final p in open)
        if (selected?.contains(p.id) ?? false) p,
    ];
    final total = picked.fold<num>(0, (a, p) => a + p.amount);
    final all = open.isNotEmpty && picked.length == open.length;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          AdminBar(
            title: l10n.versementsEtRemboursements,
            caption: l10n.adminFinance,
            backLabel: l10n.retourAFinance,
            fallback: Routes.adminFinance,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s8),
              children: [
                AdminSectionHead(
                  title: l10n.versements,
                  large: true,
                  end: open.isEmpty && validated.isNotEmpty
                      ? MuStatusBadge(
                          status: MuStatus.confirmed,
                          label: l10n.valides,
                          size: MuBadgeSize.s,
                        )
                      : MuStatusBadge(
                          status: MuStatus.pending,
                          label: l10n.aValider,
                          size: MuBadgeSize.s,
                        ),
                ),
                const SizedBox(height: MuSpace.s2),
                Text(
                  l10n.versementDuLunOctPour,
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s3),
                if (payouts == null)
                  const MuSkeleton(height: 240)
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: MuRadius.mdAll,
                      boxShadow: MuElevation.of(context).level1,
                    ),
                    child: ClipRRect(
                      borderRadius: MuRadius.mdAll,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (open.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(minHeight: MuSize.touchTarget),
                                padding: const EdgeInsetsDirectional.only(
                                  start: MuSpace.s4,
                                  end: MuSpace.s4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: c.border)),
                                ),
                                child: Row(
                                  children: [
                                    MuCheckbox(
                                      value: all ? true : (picked.isEmpty ? false : null),
                                      tristate: true,
                                      semanticLabel: l10n.toutSelectionner,
                                      onChanged: _validating
                                          ? null
                                          : (_) => setState(
                                              () => _selected = all
                                                  ? {}
                                                  : {for (final p in open) p.id},
                                            ),
                                    ),
                                    const SizedBox(width: MuSpace.s3),
                                    Expanded(
                                      child: Text(
                                        picked.length > 1
                                            ? l10n.selectionnes(picked.length)
                                            : l10n.selectionne2(picked.length),
                                        style: MuType.label.copyWith(color: c.text),
                                      ),
                                    ),
                                    Text(
                                      ltr(formatDT(total)),
                                      style: MuType.numS.copyWith(color: c.text),
                                    ),
                                  ],
                                ),
                              ),
                            for (final (i, p) in [...open, ...validated].indexed) ...[
                              if (i > 0)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: AdminList.tileInset,
                                  ),
                                  child: Divider(height: 1, thickness: 1, color: c.border),
                                ),
                              _payoutRow(p, selected?.contains(p.id) ?? false),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: MuSpace.s2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.clock(), size: MuSize.iconXs, color: c.textSecondary),
                      const SizedBox(width: MuSpace.s2),
                      Expanded(
                        child: AdminMuted(l10n.dernierLunOctArenaFive),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: adminSectionGap),
                AdminSectionHead(
                  title: l10n.remboursements,
                  large: true,
                  end: AdminMuted(
                    l10n.demandes(refunds.length, formatDT(refunds.fold<num>(0, (a, r) => a + r.amount))),
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                if (refunds.isEmpty)
                  MuEmptyState(compact: true, title: l10n.aucuneDemandeDeRemboursement)
                else
                  for (final r in refunds) ...[
                    _RefundCard(r: r, busy: _refunding.contains(r.id), onRefund: () => _refund(r)),
                    const SizedBox(height: MuSpace.s2),
                  ],
                const SizedBox(height: MuSpace.s2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                  child: AdminMuted(
                    l10n.unRefusDemandeUneRaison,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: open.isEmpty
          ? null
          : StickyActionBar(
              children: [
                MuButton.primary(
                  label: picked.length > 1
                      ? l10n.validerVersements2(picked.length)
                      : l10n.validerLeVersement2,
                  leading: PhosphorIcons.bank(),
                  price: formatDT(total),
                  size: MuButtonSize.xl,
                  fullWidth: true,
                  loading: _validating,
                  onPressed: picked.isEmpty || _validating ? null : () => _validate(picked),
                ),
              ],
            ),
    );
  }

  Widget _payoutRow(AdminPayout p, bool on) {
    void toggle() => setState(() {
      final s = {...?_selected};
      on ? s.remove(p.id) : s.add(p.id);
      _selected = s;
    });
    final c = context.mu;
    return AdminRow(
      selected: on && !p.validated,
      chevron: false,
      onTap: p.validated || _validating ? null : toggle,
      leading: SizedBox(
        width: MuSpace.s6,
        child: p.validated
            ? Icon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                size: MuSize.iconS,
                color: c.successText,
              )
            : MuCheckbox(
                value: on,
                semanticLabel: l10n.selectionner(p.name),
                onChanged: _validating ? null : (_) => toggle(),
              ),
      ),
      end: Text(ltr(formatDT(p.amount)), style: MuType.numM.copyWith(color: c.text)),
      child: AdminTexts(
        title: p.name,
        lines: [p.bank, p.validated ? l10n.validePartLunOct : p.meta],
      ),
    );
  }
}

class _RefundCard extends StatelessWidget {
  const _RefundCard({required this.r, required this.busy, required this.onRefund});

  final AdminRefund r;
  final bool busy;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuAvatar(name: r.name),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(r.name, style: MuType.labelL.copyWith(color: c.text)),
                    ),
                    AdminMuted(r.line),
                  ],
                ),
              ),
              Text(ltr(formatDT(r.amount)), style: MuType.numM.copyWith(color: c.text)),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Container(
            padding: const EdgeInsets.all(MuSpace.s3),
            decoration: BoxDecoration(color: c.bg, borderRadius: MuRadius.smAll),
            child: Text(r.quote, style: MuType.body.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s3),
          for (final (kind, text) in r.facts)
            Padding(
              padding: const EdgeInsets.only(bottom: MuSpace.s2 - 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      switch (kind) {
                        AdminFactKind.photo => PhosphorIcons.image(),
                        AdminFactKind.message => PhosphorIcons.chatCenteredText(),
                        AdminFactKind.wallet => PhosphorIcons.wallet(),
                        AdminFactKind.confirmed => PhosphorIcons.checkCircle(
                          PhosphorIconsStyle.fill,
                        ),
                        AdminFactKind.card => PhosphorIcons.creditCard(),
                      },
                      size: MuSize.iconXs,
                      color: kind == AdminFactKind.confirmed ? c.successText : c.textSecondary,
                    ),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Text(text, style: MuType.caption.copyWith(color: c.text)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: MuSpace.s2),
          Row(
            children: [
              MuButton.secondary(
                label: l10n.refuser,
                size: MuButtonSize.l,
                onPressed: busy ? null : () => showComingSoon(context),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: MuButton.primary(
                  label: l10n.rembourser(formatDT(r.amount)),
                  size: MuButtonSize.l,
                  fullWidth: true,
                  loading: busy,
                  onPressed: busy ? null : onRefund,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
