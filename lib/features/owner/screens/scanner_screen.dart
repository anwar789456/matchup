import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../states/widgets/state_widgets.dart';
import '../controllers/owner_controllers.dart';
import '../data/camera.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_header.dart';
import '../widgets/owner_labels.dart';
import '../../../l10n/l10n.dart';

/// OWN-20 · Check-in: the viewfinder, the torch, « Saisir le code » and the next slot. When the
/// camera is refused it becomes STA-05 (steps to allow it, typed code). The camera is simulated
/// until `mobile_scanner` is approved: tapping the viewfinder reads the debug menu's code.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _torch = false;
  bool _checking = false;

  Future<void> _check(String code) async {
    if (_checking || code.trim().isEmpty) return;
    setState(() => _checking = true);
    final result = await ref.read(ownerActionsProvider).checkIn(code);
    if (!mounted) return;
    setState(() => _checking = false);
    await context.push(Routes.ownerCheckInResult, extra: result);
  }

  Future<void> _typeCode() async {
    final code = await showManualCodeSheet(context);
    if (code != null && mounted) await _check(code);
  }

  Future<void> _openSettings() async {
    final ok = await launchUrl(Uri.parse('app-settings:')).catchError((_) => false);
    if (!ok && mounted) {
      MuToast.show(
        context,
        title: l10n.ouvreLesReglagesDuTelephone,
        description: l10n.puisMatchupCamera,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final denied = ref.watch(cameraDeniedProvider);
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerHeader(title: l10n.checkIn),
          Expanded(
            child: denied
                ? PermissionDeniedState(
                    title: l10n.cameraBloquee,
                    description: l10n.tuAsRefuseLAcces,
                    steps: [
                      l10n.ouvreLesReglagesDuTelephone,
                      l10n.toucheMatchup,
                      l10n.activeCameraPuisReviensIci,
                    ],
                    onOpenSettings: _openSettings,
                    fallbackLabel: l10n.saisirLeCodeALa,
                    onFallback: _typeCode,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      MuSpace.s4,
                      MuSpace.s3,
                      MuSpace.s4,
                      MuSpace.s10 + MuSpace.s10,
                    ),
                    children: [
                      Center(child: _AimPill()),
                      const SizedBox(height: MuSpace.s4),
                      Center(
                        child: _Viewfinder(
                          code: ref.watch(simulatedScanProvider),
                          busy: _checking,
                          torch: _torch,
                          onScan: () => _check(ref.read(simulatedScanProvider)),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s3),
                      Text(
                        l10n.leScanPartToutSeul,
                        textAlign: TextAlign.center,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MuButton.secondary(
                            label: _torch ? l10n.lampeAllumee : l10n.lampe,
                            leading: _torch
                                ? PhosphorIcons.flashlight(PhosphorIconsStyle.fill)
                                : PhosphorIcons.flashlight(),
                            onPressed: () => setState(() => _torch = !_torch),
                          ),
                          const SizedBox(width: MuSpace.s3),
                          MuButton.secondary(
                            label: l10n.saisirLeCode,
                            leading: PhosphorIcons.keyboard(),
                            onPressed: _typeCode,
                          ),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s3),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n.laCameraNeSOuvre,
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                            Semantics(
                              link: true,
                              child: InkWell(
                                onTap: () => ref.read(cameraDeniedProvider.notifier).set(true),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
                                  child: Text(
                                    l10n.autoriserLAcces,
                                    style: MuType.labelS.copyWith(
                                      color: c.text,
                                      decoration: TextDecoration.underline,
                                      decorationColor: c.text,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MuSpace.s2),
                      const _NextSlot(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// « Saisir le code »: the code under the QR, then « Vérifier le code ». Returns the code.
Future<String?> showManualCodeSheet(BuildContext context) {
  final controller = TextEditingController();
  return MuBottomSheet.show<String>(
    context,
    title: l10n.saisirLeCode,
    height: MuSheetHeight.auto,
    child: Builder(
      builder: (context) {
        final c = context.mu;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.leCodeEstEcritSous,
              style: MuType.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: MuSpace.s4),
            MuTextField(
              label: l10n.codeDuBillet,
              controller: controller,
              placeholder: 'MU-48213',
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
            ),
          ],
        );
      },
    ),
    footer: Builder(
      builder: (context) => MuButton.primary(
        label: l10n.verifierLeCode,
        size: MuButtonSize.xl,
        fullWidth: true,
        onPressed: () => Navigator.of(context).pop(controller.text.trim()),
      ),
    ),
  );
}

class _AimPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.fullAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.qrCode(), size: MuSize.iconS, color: c.text),
          const SizedBox(width: MuSpace.s2),
          Text(l10n.viseLeQrCodeDu, style: MuType.label.copyWith(color: c.text)),
        ],
      ),
    );
  }
}

/// The simulated camera: a ticket held up in the frame, the Volt corners and the scan line.
class _Viewfinder extends StatefulWidget {
  const _Viewfinder({
    required this.code,
    required this.busy,
    required this.torch,
    required this.onScan,
  });

  final String code;
  final bool busy;
  final bool torch;
  final VoidCallback onScan;

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder> with SingleTickerProviderStateMixin {
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: MuMotion.slow * 6,
  );

  // OWN-20: 260 frame, 36 corners 4 thick, the ticket tilted 8°.
  static const double _frame = 260;
  static const double _corner = 36;
  static const double _stroke = 4;
  static const double _tilt = -0.14;
  static const double _ticketW = 150;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _line.stop();
      _line.value = 0.8;
    } else if (!_line.isAnimating) {
      _line.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: l10n.scannerLeBilletVise,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onScan,
        child: SizedBox.square(
          dimension: _frame,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: MuRadius.mdAll,
                  child: ColoredBox(
                    color: widget.torch ? c.surfaceElevated : c.surface,
                    child: Center(
                      child: Transform.rotate(
                        angle: _tilt,
                        child: Container(
                          width: _ticketW,
                          padding: const EdgeInsets.all(MuSpace.s3),
                          decoration: BoxDecoration(
                            color: c.white,
                            borderRadius: MuRadius.lgAll,
                            border: Border.all(color: c.ink700, width: MuSpace.s2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QrImageView(
                                data: widget.code,
                                padding: EdgeInsets.zero,
                                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: c.ink900),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: c.ink900,
                                ),
                              ),
                              const SizedBox(height: MuSpace.s2),
                              Text(widget.code, style: MuType.numXs.copyWith(color: c.ink700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _Corners(color: c.accent, corner: _corner, stroke: _stroke),
                ),
              ),
              AnimatedBuilder(
                animation: _line,
                builder: (context, _) => Positioned(
                  left: MuSpace.s5,
                  right: MuSpace.s5,
                  top: _frame * (0.15 + 0.7 * _line.value),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.fullAll),
                  ),
                ),
              ),
              if (widget.busy)
                Positioned.fill(
                  child: Center(
                    child: MuSpinner(size: 32, color: c.accent, semanticLabel: l10n.verification),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Corners extends CustomPainter {
  _Corners({required this.color, required this.corner, required this.stroke});

  final Color color;
  final double corner;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final h = stroke / 2;
    final w = size.width - h;
    final b = size.height - h;
    const r = 12.0;
    for (final path in [
      Path()
        ..moveTo(h, corner)
        ..lineTo(h, r)
        ..quadraticBezierTo(h, h, r, h)
        ..lineTo(corner, h),
      Path()
        ..moveTo(w - corner, h)
        ..lineTo(w - r, h)
        ..quadraticBezierTo(w, h, w, r)
        ..lineTo(w, corner),
      Path()
        ..moveTo(w, b - corner)
        ..lineTo(w, b - r)
        ..quadraticBezierTo(w, b, w - r, b)
        ..lineTo(w - corner, b),
      Path()
        ..moveTo(corner, b)
        ..lineTo(r, b)
        ..quadraticBezierTo(h, b, h, b - r)
        ..lineTo(h, b - corner),
    ]) {
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_Corners old) => old.color != color;
}

/// « Prochain créneau »: the next booking to arrive, to its detail.
class _NextSlot extends ConsumerWidget {
  const _NextSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final all = ref.watch(ownerUpcomingProvider(dayOf(now))).value;
    final next = all
        ?.where((b) => b.start.isAfter(now) && b.status != OwnerBookingStatus.cancelled)
        .firstOrNull;
    if (next == null) return const SizedBox.shrink();
    return MuCardSurface(
      semanticLabel:
          l10n.prochainCreneau(courtName(next.court), next.organiser, formatDay(next.start), hourLong(next.start.hour)),
      onTap: () => context.push(Routes.ownerBooking(next.ref)),
      child: Row(
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
                Text(l10n.prochainCreneau2, style: MuType.overline.copyWith(color: c.textSecondary)),
                Text(
                  '${courtName(next.court)} · ${next.organiser}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.label.copyWith(color: c.text),
                ),
                Text(
                  l10n.joueurs4(formatDay(next.start), next.capacity),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          Text(hourLong(next.start.hour), style: MuType.numL.copyWith(color: c.text)),
          const SizedBox(width: MuSpace.s2),
          MuDirectionalIcon(PhosphorIcons.caretRight(), size: MuSize.iconS, color: c.textSecondary),
        ],
      ),
    );
  }
}
