import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_labels.dart';
import '../../../l10n/l10n.dart';

/// OWN-21 valide · OWN-22 déjà utilisé · OWN-23 invalide: the takeover after a scan, its verdict
/// in colour + icon + word, the booking and what to do next.
class CheckInResultScreen extends StatelessWidget {
  const CheckInResultScreen({super.key, required this.result});

  final CheckInResult result;

  void _scanAgain(BuildContext context) => goBack(context, Routes.ownerCheckIn);

  @override
  Widget build(BuildContext context) {
    final r = result;
    final b = r.booking;
    return MuTakeover(
      title: l10n.checkIn,
      onClose: () => _scanAgain(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s4),
        children: [
          _Verdict(result: r),
          const SizedBox(height: MuSpace.s4),
          switch (r.status) {
            CheckInStatus.valid => _ValidCard(booking: b!),
            CheckInStatus.alreadyUsed => _UsedCard(result: r),
            CheckInStatus.invalid => const _InvalidCard(),
          },
          if (r.status == CheckInStatus.alreadyUsed) ...[
            const SizedBox(height: MuSpace.s4),
            _Note(
              l10n.siCEstBienIl('${r.ticketHolder}'),
            ),
          ],
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: switch (r.status) {
          CheckInStatus.valid => [
            MuButton.primary(
              label: l10n.scannerLeJoueurSuivant,
              leading: PhosphorIcons.qrCode(),
              size: MuButtonSize.xl,
              fullWidth: true,
              onPressed: () => _scanAgain(context),
            ),
            const SizedBox(height: MuSpace.s3),
            MuButton.secondary(
              label: l10n.voirLaReservation,
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: () => context.pushReplacement(Routes.ownerBooking(b!.ref)),
            ),
          ],
          CheckInStatus.alreadyUsed => [
            MuButton.primary(
              label: l10n.scannerUnAutreBillet,
              leading: PhosphorIcons.qrCode(),
              size: MuButtonSize.xl,
              fullWidth: true,
              onPressed: () => _scanAgain(context),
            ),
            const SizedBox(height: MuSpace.s3),
            MuButton.secondary(
              label: l10n.voirLesJoueursDeLa,
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: () => context.pushReplacement(Routes.ownerBooking(b!.ref)),
            ),
          ],
          CheckInStatus.invalid => [
            MuButton.primary(
              label: l10n.scannerANouveau,
              leading: PhosphorIcons.arrowsClockwise(),
              size: MuButtonSize.xl,
              fullWidth: true,
              onPressed: () => _scanAgain(context),
            ),
            const SizedBox(height: MuSpace.s3),
            MuButton.secondary(
              label: l10n.chercherDansLePlanning,
              leading: PhosphorIcons.calendarBlank(),
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: () => context.go(Routes.ownerPlanning),
            ),
          ],
        },
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.result});

  final CheckInResult result;

  // OWN-21: 96 medal in a 120 halo, 48 icon.
  static const double _medal = 96;
  static const double _halo = 120;
  static const double _icon = 48;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = result;
    final (soft, strong, ink, icon, word, line) = switch (r.status) {
      CheckInStatus.valid => (
        c.successSoft,
        c.success,
        c.successText,
        PhosphorIcons.check(PhosphorIconsStyle.bold),
        l10n.valide,
        TextSpan(text: l10n.bonMatchLaisseEntrerLe),
      ),
      CheckInStatus.alreadyUsed => (
        c.warningSoft,
        c.warning,
        c.warningText,
        PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.bold),
        l10n.dejaUtilise,
        TextSpan(
          children: [
            TextSpan(text: l10n.ceBilletEstDejaPasse),
            TextSpan(
              text: formatTime(r.firstScanAt!),
              style: MuType.numM.copyWith(color: c.text),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
      CheckInStatus.invalid => (
        c.errorSoft,
        c.error,
        c.errorText,
        PhosphorIcons.x(PhosphorIconsStyle.bold),
        l10n.invalide,
        TextSpan(text: l10n.ceBilletNEstPas(Story.arenaFive.name)),
      ),
    };
    final onStrong = r.status == CheckInStatus.alreadyUsed ? c.ink900 : c.white;
    return Semantics(
      liveRegion: true,
      label: '$word. ${line.toPlainText()}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, MuSpace.s5),
        decoration: BoxDecoration(color: soft, borderRadius: MuRadius.lgAll),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Container(
                width: _halo,
                height: _halo,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: strong.withValues(alpha: 0.25),
                ),
                child: Container(
                  width: _medal,
                  height: _medal,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: strong),
                  child: Icon(icon, size: _icon, color: onStrong),
                ),
              ),
            ),
            const SizedBox(height: MuSpace.s3),
            ExcludeSemantics(
              child: Text(word, style: MuType.display.copyWith(color: ink)),
            ),
            const SizedBox(height: MuSpace.s2),
            ExcludeSemantics(
              child: Text.rich(
                line,
                textAlign: TextAlign.center,
                style: MuType.body.copyWith(color: c.text),
              ),
            ),
            const SizedBox(height: MuSpace.s3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s1),
              decoration: BoxDecoration(color: c.surface, borderRadius: MuRadius.fullAll),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.clock(), size: MuSize.iconXs - 2, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s1),
                  Text(l10n.scanneA, style: MuType.caption.copyWith(color: c.textSecondary)),
                  Text(formatTime(r.scannedAt), style: MuType.numXs.copyWith(color: c.text)),
                  Text(' · ', style: MuType.caption.copyWith(color: c.textSecondary)),
                  Text(ltr(r.code), style: MuType.numXs.copyWith(color: c.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidCard extends StatelessWidget {
  const _ValidCard({required this.booking});

  final OwnerBooking booking;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final b = booking;
    final arrived = b.arrived.length;
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MuSize.touchTarget,
                height: MuSize.touchTarget,
                decoration: BoxDecoration(color: c.footballSoft, borderRadius: MuRadius.smAll),
                alignment: Alignment.center,
                child: MuSportIcon(ownerSport, size: MuSize.iconS, color: c.footballText),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.football5v5(courtName(b.court)),
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    Text(
                      '${formatDay(b.start)} · ${b.kind == OwnerBookingKind.public ? 'publique' : l10n.privee2} · ${b.gameType}',
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(hourLong(b.start.hour), style: MuType.numL.copyWith(color: c.text)),
                  Text(
                    '→ ${hourLong(b.end.hour)}',
                    style: MuType.numXs.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
            child: Divider(height: 1, color: c.border),
          ),
          Row(
            children: [
              MuAvatar(name: b.organiser, size: MuAvatarSize.s),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l10n.reservePar),
                      TextSpan(
                        text: b.organiser,
                        style: MuType.label.copyWith(color: c.text),
                      ),
                    ],
                  ),
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
              ),
              MuStatusBadge(
                status: b.fullyPaid ? MuStatus.paid : MuStatus.pending,
                label: b.fullyPaid
                    ? l10n.payes(formatDT(b.price))
                    : '${formatAmount(b.paid)} / ${formatDT(b.price)} payés',
                size: MuBadgeSize.s,
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              MuAvatarStack(
                people: [for (final p in b.arrived) MuPerson(p)],
                size: MuAvatarSize.xs,
                semanticLabel: l10n.arrives(arrived),
              ),
              const SizedBox(width: MuSpace.s2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$arrived/${b.capacity}',
                      style: MuType.numM.copyWith(color: c.text),
                    ),
                    TextSpan(text: l10n.joueursArrives),
                  ],
                ),
                style: MuType.body.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Semantics(
            label: l10n.joueursArrivesSur(arrived, b.capacity),
            child: MuProgressBar(
              value: arrived.toDouble(),
              max: b.capacity.toDouble(),
              variant: MuProgressVariant.segmented,
              showValue: false,
            ),
          ),
          if (b.expected.isNotEmpty) ...[
            const SizedBox(height: MuSpace.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l10n.encoreAttendus(b.expected.join(', ')),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                MuButton.tertiary(
                  label: l10n.signalerUnAbsent,
                  leading: PhosphorIcons.userMinus(),
                  size: MuButtonSize.s,
                  onPressed: () => context.push(Routes.ownerNoShow(b.ref)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UsedCard extends StatelessWidget {
  const _UsedCard({required this.result});

  final CheckInResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = result;
    final b = r.booking!;
    Widget line(String label, String value, String rest) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: MuType.body.copyWith(color: c.textSecondary)),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: MuType.numS.copyWith(color: c.text),
                ),
                TextSpan(text: rest),
              ],
            ),
            style: MuType.caption.copyWith(color: c.text),
          ),
        ],
      ),
    );
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuAvatar(name: r.ticketHolder ?? b.organiser),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.billetDe(r.ticketHolder ?? b.organiser),
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    Row(
                      children: [
                        const MuSportIcon(ownerSport, size: MuSize.iconXs - 4),
                        const SizedBox(width: MuSpace.s1),
                        Flexible(
                          child: Text(
                            '${courtName(b.court)} · ${formatDay(b.start)} · ${hourLong(b.start.hour)}–${hourLong(b.end.hour)}',
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
            child: Divider(height: 1, color: c.border),
          ),
          line(l10n.premierScan, formatTime(r.firstScanAt!), l10n.accueilPar('${r.firstScanBy}')),
          line(l10n.ceScan, formatTime(r.scannedAt), l10n.refuse),
          line(l10n.joueursEntres, '${b.capacity}/${b.capacity}', ''),
        ],
      ),
    );
  }
}

class _InvalidCard extends StatelessWidget {
  const _InvalidCard();

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final body = MuType.body.copyWith(color: c.text);
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MuSize.touchTarget,
                height: MuSize.touchTarget,
                decoration: BoxDecoration(color: c.errorSoft, borderRadius: MuRadius.smAll),
                alignment: Alignment.center,
                child: Icon(PhosphorIcons.mapPin(), size: MuSize.iconS, color: c.errorText),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reserveDansUnAutreTerrain,
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    Text(
                      l10n.leCodeEstBienUn,
                      style: MuType.body.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
            child: Divider(height: 1, color: c.border),
          ),
          Text(l10n.queFaire2, style: MuType.overline.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      l10n.demandeAuJoueurDOuvrir(Story.arenaFive.name),
                ),
                TextSpan(
                  text: l10n.mesMatchs,
                  style: MuType.label.copyWith(color: c.text),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            style: body,
          ),
          const SizedBox(height: MuSpace.s2),
          Text(l10n.pasDeBilletChercheSon, style: body),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(PhosphorIcons.info(), size: MuSize.iconS, color: c.textSecondary),
        const SizedBox(width: MuSpace.s2),
        Expanded(
          child: Text(text, style: MuType.body.copyWith(color: c.textSecondary)),
        ),
      ],
    );
  }
}
