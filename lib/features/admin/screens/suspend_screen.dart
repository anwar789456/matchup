import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/admin_controller.dart';
import '../data/admin_repository.dart';
import '../../../l10n/l10n.dart';

/// ADM-04 · Suspendre: a destructive dialog over the user's sheet — duration, reason, message,
/// and the consequence it states before anything happens. « Garder le compte actif » closes it;
/// the destructive button applies the suspension (or the ban), which reaches the player's Home
/// (STA-07). From ADM-10, [reviewId] is the comment removed with it.
class AdminSuspendScreen extends ConsumerStatefulWidget {
  const AdminSuspendScreen({super.key, required this.userId, this.reviewId});

  final String userId;
  final String? reviewId;

  @override
  ConsumerState<AdminSuspendScreen> createState() => _AdminSuspendScreenState();
}

class _AdminSuspendScreenState extends ConsumerState<AdminSuspendScreen> {
  AdminSuspensionLength _length = AdminSuspensionLength.week;
  AdminSanctionReason? _reason;
  TextEditingController? _message;
  bool _busy = false;

  @override
  void dispose() {
    _message?.dispose();
    super.dispose();
  }

  void _close() => goBack(context, Routes.adminUser(widget.userId));

  Future<void> _apply(AdminUser user, AdminSanctionPlan plan, DateTime now) async {
    setState(() => _busy = true);
    final actions = ref.read(adminActionsProvider);
    await actions.suspend(user, length: _length, plan: plan, now: now);
    if (widget.reviewId != null) {
      await actions.decide(widget.reviewId!, ModerationDecision.suspend);
    }
    if (!mounted) return;
    final ban = _length == AdminSuspensionLength.ban;
    final title = ban ? l10n.estBanni(user.name) : l10n.estSuspendu(user.name);
    context.go(widget.reviewId != null ? Routes.adminModeration : Routes.adminUsers);
    MuToast.show(context, tone: MuToastTone.success, title: title);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.read(clockProvider)();
    final user = ref
        .watch(adminUsersProvider)
        .value
        ?.where((u) => u.id == widget.userId)
        .firstOrNull;
    final plan = ref.watch(adminSanctionPlanProvider(widget.userId)).value;
    if (user == null || plan == null) {
      return Scaffold(
        backgroundColor: c.bg.withValues(alpha: 0),
        body: const Center(child: MuSpinner()),
      );
    }
    _message ??= TextEditingController(text: plan.message);
    final reason = _reason ?? plan.reason;
    final ban = _length == AdminSuspensionLength.ban;
    final until = ban ? null : now.add(_length.duration!);
    final freed = plan.freedGames > 0
        ? l10n.sesPartiesAVenirSont(plan.freedGames, formatDT(plan.refund))
        : '';
    final consequence = until == null
        ? l10n.compteFermeSansReinscriptionPossible(freed)
        : l10n.jusquAuNiPartieNi(formatDay(until), formatTime(until), freed);
    final cta = switch (_length) {
      AdminSuspensionLength.day => l10n.suspendreH,
      AdminSuspensionLength.week => l10n.suspendreJours,
      AdminSuspensionLength.month => l10n.suspendreJours2,
      AdminSuspensionLength.ban => l10n.bannirDefinitivement,
    };

    return Scaffold(
      backgroundColor: c.bg.withValues(alpha: 0),
      body: MuDialog(
        tone: MuDialogTone.destructive,
        icon: PhosphorIcons.prohibit(),
        title: ban ? l10n.bannir(user.name) : l10n.suspendre(user.name),
        description: ban
            ? l10n.ilEstPrevenuParEmail
            : l10n.ilEstPrevenuParEmail2,
        consequenceIcon: PhosphorIcons.calendarX(),
        consequence: consequence,
        busy: _busy,
        onClose: _close,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              label: l10n.duree,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text(l10n.duree, style: MuType.label.copyWith(color: c.text)),
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Wrap(
                    spacing: MuSpace.s2,
                    runSpacing: MuSpace.s2,
                    children: [
                      for (final l in AdminSuspensionLength.values)
                        MuChip(
                          kind: MuChipKind.choice,
                          label: switch (l) {
                            AdminSuspensionLength.day => '24 h',
                            AdminSuspensionLength.week => l10n.jours,
                            AdminSuspensionLength.month => l10n.jours2,
                            AdminSuspensionLength.ban => l10n.definitif,
                          },
                          selected: _length == l,
                          onSelected: _busy ? null : (_) => setState(() => _length = l),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: MuSpace.s4),
            MuSelect<AdminSanctionReason>(
              label: l10n.raison,
              value: reason,
              onChanged: _busy ? null : (v) => setState(() => _reason = v),
              options: [
                for (final r in AdminSanctionReason.values)
                  MuSelectOption(value: r, label: r.label),
              ],
            ),
            const SizedBox(height: MuSpace.s4),
            MuTextField(
              label: l10n.messageA(user.name),
              controller: _message,
              multiline: true,
              minLines: 2,
              maxLength: 280,
              enabled: !_busy,
            ),
          ],
        ),
        actions: [
          MuButton.secondary(
            label: l10n.garderLeCompteActif,
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: _busy ? null : _close,
          ),
          MuButton.destructive(
            label: cta,
            size: MuButtonSize.l,
            fullWidth: true,
            loading: _busy,
            onPressed: _busy ? null : () => _apply(user, plan, now),
          ),
        ],
      ),
    );
  }
}
