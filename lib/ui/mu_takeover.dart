import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/theme.dart';
import 'mu_chip.dart';
import 'mu_icon_button.dart';
import 'mu_logo.dart';

/// Takeover (components/Takeover.md): a full screen over everything — bars, sheets, toasts — with
/// a bar (close, centred title), a scrolling body and a stacked footer. No scrim: it replaces the
/// view. Open it with [MuTakeover.show]; compositions such as [MuTicket] fill its body.
class MuTakeover extends StatelessWidget {
  const MuTakeover({
    super.key,
    required this.body,
    this.title,
    this.footer,
    this.closable = true,
    this.closeLabel = 'Fermer',
    this.onClose,
    this.barEnd,
  });

  final Widget body;
  final String? title;
  final Widget? footer;
  final bool closable;
  final String closeLabel;
  final VoidCallback? onClose;
  final Widget? barEnd;

  /// Pushes [builder]'s takeover on the root navigator: fade + 16 px rise over `duration-slow`,
  /// back over `duration-base`; Back is ignored when not [closable].
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool closable = true,
  }) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Navigator.of(context, rootNavigator: true).push<T>(
      PageRouteBuilder<T>(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: reduce ? Duration.zero : MuMotion.slow,
        reverseTransitionDuration: reduce ? Duration.zero : MuMotion.base,
        pageBuilder: (context, _, _) => PopScope(canPop: closable, child: builder(context)),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: MuMotion.enter,
            reverseCurve: MuMotion.exit,
          );
          return FadeTransition(
            opacity: curved,
            child: AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, MuSpace.s4 * (1 - curved.value)),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: MuSize.appBar),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                child: Row(
                  children: [
                    if (closable)
                      MuIconButton(
                        icon: PhosphorIcons.x(),
                        label: closeLabel,
                        size: MuIconButtonSize.l,
                        onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                      )
                    else
                      const SizedBox(width: MuSize.touchTarget),
                    Expanded(
                      child: title == null
                          ? const SizedBox.shrink()
                          : Semantics(
                              header: true,
                              child: Text(
                                title!,
                                textAlign: TextAlign.center,
                                style: MuType.labelL.copyWith(color: c.text),
                              ),
                            ),
                    ),
                    barEnd ?? const SizedBox(width: MuSize.touchTarget),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s4),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// The ticket composition (Takeover.md « Ticket »): sport chip, venue, court, date and time, a
/// 208 QR code in `ink-900` on `white` in both themes with the logo, the reference tracked out, a
/// perforation, then Joueurs · Payé · Statut.
class MuTicket extends StatelessWidget {
  const MuTicket({
    super.key,
    required this.reference,
    required this.sport,
    required this.venue,
    required this.court,
    required this.date,
    required this.time,
    required this.players,
    required this.paid,
    this.data,
    this.status = 'Confirmé',
  });

  final String reference;
  final MuSport sport;

  /// « Arena Five · La Marsa ».
  final String venue;
  final String court;

  /// « mer. 21 oct. ».
  final String date;
  final String time;

  /// « 6/10 ».
  final String players;

  /// « 15 DT ».
  final String paid;

  /// What the QR code holds (the booking link by default).
  final String? data;
  final String status;

  // Takeover.md: QR 208 with the logo; reference tracked 0.12 em; perforation notches 16.
  static const double _qr = 208;
  static const double _logo = 40;
  static const double _tracking = 0.12;
  static const double _notch = 16;
  static const double _dash = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = MuElevation.of(context);
    Widget fact(String label, Widget value) => Expanded(
      child: Column(
        children: [
          Text(label, style: MuType.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s1),
          value,
        ],
      ),
    );

    return Semantics(
      container: true,
      label: 'Billet de la réservation $reference',
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: MuRadius.lgAll,
          boxShadow: e.level2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, MuSpace.s4),
              child: Column(
                children: [
                  MuChip.sport(sport, size: MuChipSize.s),
                  const SizedBox(height: MuSpace.s3),
                  Text(venue, style: MuType.label.copyWith(color: c.textSecondary)),
                  const SizedBox(height: MuSpace.s1),
                  Text(court, style: MuType.h2.copyWith(color: c.text)),
                  const SizedBox(height: MuSpace.s1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        date.toUpperCase(),
                        style: MuType.overline.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Text(time, style: MuType.numL.copyWith(color: c.text)),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s4),
                  Semantics(
                    image: true,
                    label: 'QR code de la réservation $reference',
                    excludeSemantics: true,
                    child: Container(
                      color: MuPalette.white,
                      width: _qr,
                      height: _qr,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: data ?? 'https://matchup.tn/r/$reference',
                            size: _qr,
                            padding: EdgeInsets.zero,
                            backgroundColor: MuPalette.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: MuPalette.ink900,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: MuPalette.ink900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(MuSpace.s1),
                            decoration: const BoxDecoration(
                              color: MuPalette.white,
                              borderRadius: MuRadius.smAll,
                            ),
                            child: const MuLogo(
                              variant: MuLogoVariant.icon,
                              height: _logo,
                              tone: MuLogoTone.light,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: MuSpace.s4),
                  Text(
                    reference,
                    style: MuType.numM.copyWith(
                      color: c.text,
                      letterSpacing: MuType.numM.fontSize! * _tracking,
                    ),
                  ),
                ],
              ),
            ),
            _Perforation(color: c.border, notch: _notch, dash: _dash, ground: c.bg),
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s3, MuSpace.s3, MuSpace.s3, MuSpace.s4),
              child: Row(
                children: [
                  fact('Joueurs', Text(players, style: MuType.numM.copyWith(color: c.text))),
                  fact('Payé', Text(paid, style: MuType.numM.copyWith(color: c.text))),
                  fact(
                    'Statut',
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                          size: MuSize.iconXs,
                          color: c.successText,
                        ),
                        const SizedBox(width: MuSpace.s1),
                        Text(status, style: MuType.label.copyWith(color: c.successText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tear line: half-circle notches at both edges and a dashed rule between.
class _Perforation extends StatelessWidget {
  const _Perforation({
    required this.color,
    required this.notch,
    required this.dash,
    required this.ground,
  });

  final Color color;
  final double notch;
  final double dash;
  final Color ground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: notch,
      width: double.infinity,
      child: CustomPaint(painter: _PerforationPainter(color, notch, dash, ground)),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter(this.color, this.notch, this.dash, this.ground);

  final Color color;
  final double notch;
  final double dash;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final fill = Paint()..color = ground;
    canvas.drawCircle(Offset(0, y), notch / 2, fill);
    canvas.drawCircle(Offset(size.width, y), notch / 2, fill);
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = notch; x < size.width - notch; x += dash * 2) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), line);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => old.color != color || old.ground != ground;
}
