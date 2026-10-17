import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_button.dart';
import 'mu_court_art.dart';
import 'mu_takeover.dart';

/// The claim composition of Takeover (Takeover.md « Claim »): « LISTE D’ATTENTE », the title, a
/// 216 ring timer around « 14:59 » and « pour réclamer ta place », the game card, the note, then
/// « Laisser passer » above « Réclamer la place · 14:59 ». The ring turns `error` in the last
/// minute; at 0 the action is disabled and the ring says « Temps écoulé ».
class MuTakeoverClaim extends StatefulWidget {
  const MuTakeoverClaim({
    super.key,
    required this.endsAt,
    required this.total,
    required this.sport,
    required this.venue,
    required this.when,
    required this.players,
    required this.price,
    required this.onClaim,
    required this.onPass,
    this.title = 'Une place s’est libérée !',
    this.eyebrow = 'Liste d’attente',
    this.note,
    this.onClose,
  });

  final DateTime endsAt;
  final Duration total;
  final MuSport sport;

  /// « Arena Five · Terrain 2 ».
  final String venue;

  /// « dim. 18 oct. · 20h00–21h00 ».
  final String when;

  /// « 9/10 joueurs ».
  final String players;

  /// « 15 DT ».
  final String price;
  final VoidCallback onClaim;
  final VoidCallback onPass;
  final String title;
  final String eyebrow;
  final String? note;
  final VoidCallback? onClose;

  @override
  State<MuTakeoverClaim> createState() => _MuTakeoverClaimState();
}

class _MuTakeoverClaimState extends State<MuTakeoverClaim> {
  Timer? _timer;
  late Duration _left = _remaining();

  // Takeover.md: 216 ring with an 8 track; urgent in the last 60 s; game card art 48.
  static const double _ring = 216;
  static const double _track = 8;
  static const Duration _urgent = Duration(minutes: 1);
  static const double _art = 48;

  Duration _remaining() {
    final d = widget.endsAt.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _remaining();
      setState(() => _left = left);
      if (left == Duration.zero) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final expired = _left == Duration.zero;
    final urgent = !expired && _left <= _urgent;
    final clock = formatClock(_left);
    final fraction = widget.total.inSeconds == 0
        ? 0.0
        : (_left.inSeconds / widget.total.inSeconds).clamp(0.0, 1.0);
    final ink = urgent ? c.errorText : c.text;
    final progress = urgent ? c.error : c.primary;

    return MuTakeover(
      closeLabel: 'Décider plus tard',
      onClose: widget.onClose,
      barEnd: const SizedBox(width: MuSize.touchTarget),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.hourglassMedium(), size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s1),
              Text(
                widget.eyebrow.toUpperCase(),
                style: MuType.overline.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Semantics(
            header: true,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: MuType.h1.copyWith(color: c.text),
            ),
          ),
          const SizedBox(height: MuSpace.s6),
          Center(
            child: Semantics(
              label: expired ? 'Temps écoulé' : 'Temps restant $clock',
              liveRegion: true,
              excludeSemantics: true,
              child: SizedBox(
                width: _ring,
                height: _ring,
                child: CustomPaint(
                  painter: _TimerRing(
                    fraction: fraction,
                    track: c.border,
                    progress: progress,
                    width: _track,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          expired ? '0:00' : clock,
                          style: MuType.numHero.copyWith(
                            color: ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          expired ? 'Temps écoulé' : 'pour réclamer ta place',
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s6),
          Container(
            padding: const EdgeInsets.all(MuSpace.s3),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: MuRadius.mdAll,
              boxShadow: MuElevation.of(context).level1,
            ),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: _art,
                  child: ClipRRect(
                    borderRadius: MuRadius.smAll,
                    child: MuCourtArt(sport: widget.sport, variant: MuCourtArtVariant.pattern),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.venue, style: MuType.label.copyWith(color: c.text)),
                      Text(widget.when, style: MuType.caption.copyWith(color: c.textSecondary)),
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.usersThree(),
                            size: MuSize.iconXs - 2,
                            color: c.textSecondary,
                          ),
                          const SizedBox(width: MuSpace.s1),
                          Text(
                            widget.players,
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(widget.price, style: MuType.numM.copyWith(color: c.text)),
                    Text('/ joueur', style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          if (widget.note != null) ...[
            const SizedBox(height: MuSpace.s3),
            Text(
              widget.note!,
              textAlign: TextAlign.center,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MuButton.tertiary(
            label: 'Laisser passer',
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: widget.onPass,
          ),
          const SizedBox(height: MuSpace.s2),
          MuButton.primary(
            label: 'Réclamer la place',
            leading: PhosphorIcons.timer(),
            countdown: expired ? null : clock,
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: expired ? null : widget.onClaim,
          ),
        ],
      ),
    );
  }
}

/// The ring: an 8 px track and the remaining share, with a dot at its head.
class _TimerRing extends CustomPainter {
  const _TimerRing({
    required this.fraction,
    required this.track,
    required this.progress,
    required this.width,
  });

  final double fraction;
  final Color track;
  final Color progress;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, paint..color = track);
    if (fraction <= 0) return;
    final sweep = 2 * math.pi * fraction;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, paint..color = progress);
    final head = Offset(
      rect.center.dx + rect.width / 2 * math.cos(-math.pi / 2 + sweep),
      rect.center.dy + rect.height / 2 * math.sin(-math.pi / 2 + sweep),
    );
    canvas.drawCircle(head, width, Paint()..color = progress);
  }

  @override
  bool shouldRepaint(_TimerRing old) =>
      old.fraction != fraction || old.progress != progress || old.track != track;
}
