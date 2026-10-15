import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';

enum MuCountdownFormat { clock, relative }

enum MuCountdownSize { s, m, l, hero }

/// Countdown (components/Countdown.md): time left in tabular Barlow digits, recomputed every
/// second from [endsAt] so it never drifts. Urgent under [urgentAfter]; at zero it shows
/// [expiredLabel] and calls [onExpire] once.
///
/// The `blocks` format (days away) comes with the Tournaments milestone.
class MuCountdown extends StatefulWidget {
  const MuCountdown({
    super.key,
    required this.endsAt,
    this.format = MuCountdownFormat.clock,
    this.size = MuCountdownSize.m,
    this.label,
    this.urgentAfter = const Duration(minutes: 5),
    this.expiredLabel = 'Temps écoulé',
    this.centered = false,
    this.onExpire,
  });

  final DateTime endsAt;
  final MuCountdownFormat format;
  final MuCountdownSize size;
  final String? label;
  final Duration urgentAfter;
  final String expiredLabel;
  final bool centered;
  final VoidCallback? onExpire;

  @override
  State<MuCountdown> createState() => _MuCountdownState();
}

class _MuCountdownState extends State<MuCountdown> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late Duration _left;
  bool _expiredFired = false;

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: MuMotion.pulse);

  // Countdown.md: icon 16 / 20 / 24 / 28; pulse dims the icon to 40 %.
  static const double _iconHero = 28;

  @override
  void initState() {
    super.initState();
    _left = _remaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  Duration _remaining() {
    final left = widget.endsAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void didUpdateWidget(MuCountdown old) {
    super.didUpdateWidget(old);
    if (old.endsAt != widget.endsAt) {
      _expiredFired = false;
      _tick();
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _left = _remaining());
    if (_left == Duration.zero && !_expiredFired) {
      _expiredFired = true;
      widget.onExpire?.call();
    }
    _syncPulse();
  }

  void _syncPulse() {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final urgent = _left > Duration.zero && _left <= widget.urgentAfter;
    if (urgent && !reduced) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String get _value {
    if (widget.format == MuCountdownFormat.clock) return formatClock(_left);
    final m = _left.inMinutes;
    if (m < 1) return 'Dans < 1 min';
    final d = _left.inDays;
    final h = _left.inHours % 24;
    if (d > 0) return 'Dans $d j${h > 0 ? ' $h h' : ''}';
    if (_left.inHours > 0) return 'Dans ${_left.inHours} h ${m % 60} min';
    return 'Dans $m min';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final expired = _left == Duration.zero;
    final urgent = !expired && _left <= widget.urgentAfter;

    final (TextStyle digits, TextStyle labelStyle, double icon, bool stacked) = switch (widget.size) {
      MuCountdownSize.s => (MuType.numS, MuType.label, MuSize.iconXs, false),
      MuCountdownSize.m => (MuType.numM, MuType.label, MuSize.iconS, false),
      MuCountdownSize.l => (MuType.numL, MuType.labelS, MuSize.iconM, true),
      MuCountdownSize.hero => (MuType.numHero, MuType.label, _iconHero, true),
    };
    final color = urgent ? c.errorText : c.text;
    final iconColor = urgent ? c.errorText : c.textSecondary;
    final iconData = expired
        ? PhosphorIcons.hourglassSimpleLow()
        : widget.format == MuCountdownFormat.clock
            ? PhosphorIcons.timer()
            : PhosphorIcons.clock();

    final iconWidget = FadeTransition(
      opacity: Tween<double>(begin: 1, end: MuOpacity.disabled).animate(_pulse),
      child: Icon(iconData, size: icon, color: iconColor),
    );

    final Widget value = expired
        ? Text(widget.expiredLabel, style: MuType.label.copyWith(color: c.textSecondary))
        : Directionality(
            textDirection: TextDirection.ltr,
            child: Text(_value, style: digits.copyWith(color: color)),
          );

    final label = widget.label == null || expired
        ? null
        : Text(widget.label!, style: labelStyle.copyWith(color: c.textSecondary));

    final Widget content;
    if (stacked) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              if (label != null) ...[const SizedBox(width: MuSpace.s2), label],
            ],
          ),
          SizedBox(height: widget.size == MuCountdownSize.hero ? MuSpace.s1 : MuSpace.s2),
          value,
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: MuSpace.s1),
          if (label != null) ...[
            label,
            Text(' · ', style: labelStyle.copyWith(color: c.textSecondary)),
          ],
          value,
        ],
      );
    }

    // The ticking digits are hidden; a coarse sentence is read instead (minute precision).
    final minutes = _left.inMinutes;
    final spoken = expired
        ? widget.expiredLabel
        : '${widget.label ?? 'Temps restant'} ${minutes < 1 ? 'moins d’une minute' : '$minutes minutes'}';
    return Semantics(
      liveRegion: true,
      label: spoken,
      excludeSemantics: true,
      child: content,
    );
  }
}
