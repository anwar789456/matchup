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
import '../controllers/owner_controllers.dart';
import '../data/owner_repository.dart';
import 'owner_labels.dart';
import '../../../l10n/l10n.dart';

/// OWN-12 as a sheet over the planning: the booking's detail, its money and its actions.
Future<void> showOwnerBookingSheet(BuildContext context, OwnerBooking b) =>
    MuBottomSheet.show<void>(
      context,
      title: capitalized(formatDateTime(b.start)).replaceFirst(' · ', ' · '),
      height: MuSheetHeight.auto,
      child: OwnerBookingDetail(bookingRef: b.ref),
      footer: OwnerBookingFooter(bookingRef: b.ref),
    );

/// The body of OWN-12 (sheet and page).
class OwnerBookingDetail extends ConsumerWidget {
  const OwnerBookingDetail({super.key, required this.bookingRef, this.padding = EdgeInsets.zero});

  final String bookingRef;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ownerBookingProvider(bookingRef));
    final b = async.value;
    if (b == null) {
      return async.isLoading
          ? const Padding(
              padding: EdgeInsets.all(MuSpace.s6),
              child: Center(child: MuSpinner()),
            )
          : Padding(
              padding: const EdgeInsets.all(MuSpace.s4),
              child: MuEmptyState(
                title: l10n.reservationIntrouvable,
                description: l10n.elleAPeutEtreEte,
              ),
            );
    }
    return Padding(
      padding: padding,
      child: _Detail(b: b, now: ref.read(clockProvider)()),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.b, required this.now});

  final OwnerBooking b;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final (status, statusLabel) = bookingStatus(b);
    final public = b.kind == OwnerBookingKind.public;
    final peak = isPeak(b.start.hour);
    final share = shareOf(b);
    final shares = paidShares(b);
    final missing = b.capacity - shares;
    final noShowFrom = b.start;
    final canNoShow =
        !now.isBefore(noShowFrom) &&
        b.status != OwnerBookingStatus.noShow &&
        b.status != OwnerBookingStatus.cancelled;
    final cancellable =
        b.status == OwnerBookingStatus.confirmed || b.status == OwnerBookingStatus.pendingPayment;
    final level = b.levelMin == null
        ? ''
        : ' · ${formatLevel(b.levelMin!)}–${formatLevel(b.levelMax ?? b.levelMin!)}';
    Widget divider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s4),
      child: Divider(height: 1, color: c.border),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MuStatusBadge(status: status, label: statusLabel, size: MuBadgeSize.s),
            const SizedBox(width: MuSpace.s2),
            _Tag(
              label: public ? l10n.partiePublique : l10n.privee,
              icon: public ? PhosphorIcons.usersThree() : PhosphorIcons.lockSimple(),
            ),
            const Spacer(),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.ref2),
                  TextSpan(
                    text: b.ref,
                    style: MuType.numXs.copyWith(color: c.text),
                  ),
                ],
              ),
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s3),
        Row(
          children: [
            const MuSportIcon(ownerSport, size: MuSize.iconXs),
            const SizedBox(width: MuSpace.s1 + 2),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${courtName(b.court)} · ${hourLong(b.start.hour)} – ${hourLong(b.end.hour)}',
                      style: MuType.label.copyWith(color: c.text),
                    ),
                    TextSpan(text: ' · 5v5 ${b.gameType}$level'),
                  ],
                ),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
        divider(),
        Row(
          children: [
            MuAvatar(name: b.organiser, level: b.levelMin == null ? null : 3.0),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: b.organiser,
                          style: MuType.label.copyWith(color: c.text),
                        ),
                        TextSpan(text: l10n.organisateur3),
                      ],
                    ),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                        size: MuSize.iconXs - 2,
                        color: c.successText,
                      ),
                      const SizedBox(width: MuSpace.s1),
                      Flexible(
                        child: Text(
                          l10n.fiableMatchsHonores(b.reliability, b.honoured, b.matches),
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            MuIconButton(
              icon: PhosphorIcons.chatCircleDots(),
              label: l10n.ecrireA(b.organiser),
              variant: MuIconButtonVariant.secondary,
              onPressed: () => showComingSoon(context),
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s3),
        Row(
          children: [
            MuAvatarStack(
              people: [
                for (final p in [b.organiser, ...b.arrived.skip(1)].take(b.players)) MuPerson(p),
              ],
              size: MuAvatarSize.xs,
              semanticLabel: '${b.players} joueurs',
            ),
            const SizedBox(width: MuSpace.s2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${b.players}/${b.capacity}',
                    style: MuType.numM.copyWith(color: c.text),
                  ),
                  const TextSpan(text: ' joueurs'),
                ],
              ),
              style: MuType.body.copyWith(color: c.textSecondary),
            ),
            const Spacer(),
            if (b.capacity > b.players)
              Text(
                b.capacity - b.players == 1
                    ? l10n.placeLibre4
                    : l10n.placesLibres(b.capacity - b.players),
                style: MuType.labelS.copyWith(color: c.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: MuSpace.s2),
        Semantics(
          label: l10n.joueursSur3(b.players, b.capacity),
          child: MuProgressBar(
            value: b.players.toDouble(),
            max: b.capacity.toDouble(),
            variant: MuProgressVariant.segmented,
            showValue: false,
          ),
        ),
        divider(),
        Container(
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MoneyBox(
                    label: l10n.terrainH(b.hours),
                    amount: b.price,
                    detail: peak ? l10n.heureDePointe2 : l10n.heureCreuse,
                    detailIcon: peak ? PhosphorIcons.lightning(PhosphorIconsStyle.fill) : null,
                  ),
                ),
                VerticalDivider(width: 1, color: c.border),
                Expanded(
                  child: _MoneyBox(
                    label: l10n.dejaEncaisse2,
                    amount: b.paid,
                    detail: public || !b.fullyPaid
                        ? l10n.partsDe3(shares, formatDT(share))
                        : l10n.payeEnLigne2,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (b.due > 0 && cancellable) ...[
          const SizedBox(height: MuSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIcons.clock(PhosphorIconsStyle.fill),
                size: MuSize.iconXs,
                color: c.warningText,
              ),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            l10n.attendusDeAvant(formatDT(b.due), missing, missing == 1 ? 'joueur' : 'joueurs'),
                      ),
                      TextSpan(
                        text: l10n.t18h00LeJourJ,
                        style: MuType.labelS.copyWith(color: c.text),
                      ),
                      TextSpan(text: l10n.sinonLaPartieEstAnnulee),
                    ],
                  ),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ],
        divider(),
        Row(
          children: [
            Expanded(
              child: MuButton.secondary(
                label: l10n.deplacer,
                size: MuButtonSize.s,
                leading: PhosphorIcons.arrowsLeftRight(),
                fullWidth: true,
                onPressed: cancellable ? () => showComingSoon(context) : null,
              ),
            ),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: MuButton.secondary(
                label: l10n.noShow,
                size: MuButtonSize.s,
                leading: PhosphorIcons.userMinus(),
                fullWidth: true,
                onPressed: canNoShow
                    ? () {
                        Navigator.of(context).maybePop();
                        context.push(Routes.ownerNoShow(b.ref));
                      }
                    : null,
              ),
            ),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: MuButton(
                label: l10n.annuler,
                variant: MuButtonVariant.destructiveOutline,
                size: MuButtonSize.s,
                leading: PhosphorIcons.calendarX(),
                fullWidth: true,
                onPressed: cancellable ? () => _cancel(context, ref) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s2),
        Text(
          l10n.noShowPossibleDesAnnuler(hourLong(noShowFrom.hour), b.players),
          style: MuType.caption.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context, rootNavigator: true);
    final ok = await MuDialog.show<bool>(
      context,
      tone: MuDialogTone.destructive,
      icon: PhosphorIcons.calendarX(),
      title: l10n.annulerLaReservation,
      description:
          l10n.etLesJoueursSontPrevenus(b.organiser),
      consequence: l10n.sontRemboursesAuxJoueurs(formatDT(b.paid), b.players),
      consequenceIcon: PhosphorIcons.wallet(),
      actions: [
        MuButton.secondary(
          label: l10n.garderLaReservation,
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: () => nav.pop(false),
        ),
        MuButton(
          label: l10n.annulerLaReservation2,
          variant: MuButtonVariant.destructive,
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: () => nav.pop(true),
        ),
      ],
    );
    if (ok != true || !context.mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    await ref.read(ownerActionsProvider).cancel(b.ref);
    if (context.mounted) await Navigator.of(context).maybePop();
    if (!overlay.mounted) return;
    MuToast.show(
      overlay.context,
      overlay: overlay,
      tone: MuToastTone.success,
      title: l10n.reservationAnnulee,
      description: l10n.remboursesAuxJoueurs(formatDT(b.paid)),
    );
  }
}

class _MoneyBox extends StatelessWidget {
  const _MoneyBox({
    required this.label,
    required this.amount,
    required this.detail,
    this.detailIcon,
  });

  final String label;
  final num amount;
  final String detail;
  final IconData? detailIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.all(MuSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MuType.overline.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s1),
          Text(ltr(formatDT(amount)), style: MuType.numL.copyWith(color: c.text)),
          Row(
            children: [
              if (detailIcon != null) ...[
                Icon(detailIcon, size: MuSize.iconXs - 2, color: c.warningText),
                const SizedBox(width: MuSpace.s1),
              ],
              Flexible(
                child: Text(detail, style: MuType.caption.copyWith(color: c.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// OWN-12's sticky footer: « Faire le check-in · dès 20h45 ».
class OwnerBookingFooter extends ConsumerWidget {
  const OwnerBookingFooter({super.key, required this.bookingRef});

  final String bookingRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(ownerBookingProvider(bookingRef)).value;
    if (b == null ||
        b.status == OwnerBookingStatus.cancelled ||
        b.status == OwnerBookingStatus.done ||
        b.status == OwnerBookingStatus.noShow) {
      return const SizedBox.shrink();
    }
    final from = b.start.subtract(const Duration(minutes: 15));
    return MuButton.primary(
      label: l10n.faireLeCheckIn,
      leading: PhosphorIcons.qrCode(),
      price: l10n.des3(formatTime(from)),
      size: MuButtonSize.xl,
      fullWidth: true,
      onPressed: () {
        Navigator.of(context).maybePop();
        context.go(Routes.ownerCheckIn);
      },
    );
  }
}

/// « Partie publique »: a read-only tag in the chip's outline.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2 + 2, vertical: MuSpace.s1),
      decoration: BoxDecoration(
        borderRadius: MuRadius.fullAll,
        border: Border.all(color: c.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: MuSize.iconXs, color: c.text),
          const SizedBox(width: MuSpace.s1),
          Text(label, style: MuType.labelS.copyWith(color: c.text)),
        ],
      ),
    );
  }
}
