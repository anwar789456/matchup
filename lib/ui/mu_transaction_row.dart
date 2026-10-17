import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_skeleton.dart';
import 'mu_sport_icon.dart';
import 'mu_status_badge.dart';

enum MuTransactionKind { booking, topup, refund, payout, subscription, penalty }

enum MuTransactionStatus { done, refunded, pending, failed }

/// One line of the wallet history.
@immutable
class MuTransaction {
  const MuTransaction({
    required this.id,
    required this.kind,
    required this.label,
    required this.meta,
    required this.amount,
    required this.date,
    this.sport,
    this.status = MuTransactionStatus.done,
    this.fromBalance = false,
  });

  final String id;
  final MuTransactionKind kind;

  /// « Part · Arena Five, mer. 21 oct. ».
  final String label;

  /// « ven. 16 oct. · 18h02 · Carte •••• 4242 ».
  final String meta;

  /// Signed: −15 for a debit, +50 for a credit.
  final num amount;
  final DateTime date;
  final MuSport? sport;
  final MuTransactionStatus status;

  /// Paid from the balance (moves it) rather than a card (listed for the record only).
  final bool fromBalance;

  bool get credit => amount > 0;
}

enum MuRowVariant { regular, compact }

/// TransactionRow (components/TransactionRow.md): category circle, label and meta, the signed
/// amount (« −15 DT » in `text`, « +45 DT » in `success-text`) and its status.
class MuTransactionRow extends StatelessWidget {
  const MuTransactionRow({
    super.key,
    required MuTransaction this.tx,
    this.variant = MuRowVariant.regular,
    this.onTap,
  }) : loading = false;

  const MuTransactionRow.loading({super.key, this.variant = MuRowVariant.regular})
    : tx = null,
      onTap = null,
      loading = true;

  final MuTransaction? tx;
  final MuRowVariant variant;
  final VoidCallback? onTap;
  final bool loading;

  // TransactionRow.md: min 72 (compact 52), circle 40 / icon 20 (compact 32 / 16).
  static const double _minHeight = 72;
  static const double _minHeightCompact = 52;
  static const double _circle = 40;
  static const double _circleCompact = 32;

  /// The divider inset to the text column.
  static double indent(MuRowVariant variant) =>
      MuSpace.s4 + (variant == MuRowVariant.compact ? _circleCompact : _circle) + MuSpace.s3;

  static String amountText(num amount) =>
      '${amount < 0 ? '−' : '+'}${formatDT(amount.abs())}';

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final compact = variant == MuRowVariant.compact;
    final circle = compact ? _circleCompact : _circle;
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
        child: Row(
          children: [
            MuSkeleton(width: circle, height: circle, radius: MuRadius.fullAll),
            const SizedBox(width: MuSpace.s3),
            const Expanded(child: MuSkeleton.text(lines: 2)),
            const SizedBox(width: MuSpace.s3),
            const MuSkeleton(width: 56, height: 20),
          ],
        ),
      );
    }
    final t = tx!;
    final (Color ground, Color ink, Widget glyph, bool ring) = switch (t.kind) {
      MuTransactionKind.booking when t.sport != null => (
        t.sport!.soft(c),
        t.sport!.text(c),
        MuSportIcon(t.sport!, size: compact ? MuSize.iconXs : MuSize.iconS, color: t.sport!.text(c)),
        false,
      ),
      MuTransactionKind.booking => (
        c.surfaceMuted,
        c.text,
        Icon(PhosphorIcons.calendarCheck(), size: compact ? MuSize.iconXs : MuSize.iconS),
        false,
      ),
      MuTransactionKind.topup => (
        c.surfaceMuted,
        c.text,
        Icon(PhosphorIcons.plus(), size: compact ? MuSize.iconXs : MuSize.iconS),
        true,
      ),
      MuTransactionKind.refund => (
        c.surfaceMuted,
        c.text,
        Icon(PhosphorIcons.arrowUUpLeft(), size: compact ? MuSize.iconXs : MuSize.iconS),
        false,
      ),
      MuTransactionKind.payout => (
        c.surfaceMuted,
        c.text,
        Icon(PhosphorIcons.bank(), size: compact ? MuSize.iconXs : MuSize.iconS),
        false,
      ),
      MuTransactionKind.subscription => (
        c.surfaceMuted,
        c.text,
        Icon(PhosphorIcons.crownSimple(), size: compact ? MuSize.iconXs : MuSize.iconS),
        false,
      ),
      MuTransactionKind.penalty => (
        c.surfaceMuted,
        c.text,
        Icon(PhosphorIcons.calendarX(), size: compact ? MuSize.iconXs : MuSize.iconS),
        false,
      ),
    };
    final badge = switch (t.status) {
      MuTransactionStatus.refunded => const MuStatusBadge(
        status: MuStatus.refunded,
        label: 'Remboursé',
        size: MuBadgeSize.s,
      ),
      MuTransactionStatus.pending => const MuStatusBadge(
        status: MuStatus.pending,
        label: 'En attente',
        size: MuBadgeSize.s,
      ),
      MuTransactionStatus.failed => const MuStatusBadge(
        status: MuStatus.failed,
        label: 'Échec',
        size: MuBadgeSize.s,
      ),
      MuTransactionStatus.done => null,
    };
    final failed = t.status == MuTransactionStatus.failed;
    final amount = Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        amountText(t.amount),
        style: MuType.numS.copyWith(
          color: failed ? c.textSecondary : (t.credit ? c.successText : c.text),
          decoration: failed ? TextDecoration.lineThrough : null,
        ),
      ),
    );
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? _minHeightCompact : _minHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MuSpace.s4,
          vertical: compact ? MuSpace.s2 : MuSpace.s3,
        ),
        child: Row(
          children: [
            Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                color: ground,
                shape: BoxShape.circle,
                border: ring ? Border.all(color: c.border) : null,
              ),
              child: IconTheme(data: IconThemeData(color: ink), child: Center(child: glyph)),
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (compact ? MuType.body : MuType.label).copyWith(color: c.text),
                  ),
                  if (!compact)
                    Text(
                      t.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: MuSpace.s3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                amount,
                if (badge != null && !compact) ...[const SizedBox(height: MuSpace.s1), badge],
              ],
            ),
            if (badge != null && compact) ...[const SizedBox(width: MuSpace.s2), badge],
            if (!compact && onTap != null) ...[
              const SizedBox(width: MuSpace.s2),
              Icon(PhosphorIcons.caretRight(), size: MuSize.iconXs, color: c.textSecondary),
            ],
          ],
        ),
      ),
    );
    final label =
        '${t.label}, ${t.meta}, ${t.credit ? 'plus' : 'moins'} ${formatDT(t.amount.abs())}'
        '${failed ? ', non débité' : ''}'
        '${t.status == MuTransactionStatus.refunded ? ', remboursé' : ''}'
        '${t.status == MuTransactionStatus.pending ? ', en attente' : ''}';
    if (onTap == null) return Semantics(label: label, excludeSemantics: true, child: row);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// A card of transaction rows with inset dividers.
class MuTransactionList extends StatelessWidget {
  const MuTransactionList({super.key, required this.children, this.variant = MuRowVariant.regular});

  final List<Widget> children;
  final MuRowVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: c.border,
                indent: MuTransactionRow.indent(variant),
              ),
            child,
          ],
        ],
      ),
    );
  }
}
