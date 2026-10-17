import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_status_badge.dart';

enum MuLineupRole { organizer, captain }

/// A player on a position, or `null` for a free one.
@immutable
class MuLineupPlayer {
  const MuLineupPlayer(this.name, {this.level, this.role, this.you = false});

  final String name;
  final double? level;
  final MuLineupRole? role;
  final bool you;
}

/// A team: its name (kit colour) and one entry per position, in the sport's order.
@immutable
class MuLineupTeam {
  const MuLineupTeam({required this.name, required this.players});

  final String name;
  final List<MuLineupPlayer?> players;

  int get count => players.whereType<MuLineupPlayer>().length;
}

enum MuLineupVariant { full, compact }

/// Lineup (components/Lineup.md): both teams on the court, one avatar per position and dashed
/// « + » rings on the free ones; the signed-in player gets the Volt ring and « Toi ». Compact is a
/// 64-high court with one dot per position next to « 8/10 · 2 places ».
///
/// Team A sits on the bottom half, team B on the top, turned 180° (basketball: left and right of
/// the key). The court never mirrors in RTL.
class MuLineup extends StatelessWidget {
  const MuLineup({
    super.key,
    required this.sport,
    required this.teams,
    this.variant = MuLineupVariant.full,
    this.title = 'Composition',
    this.onJoin,
    this.disabled = false,
    this.header = true,
  });

  final MuSport sport;
  final List<MuLineupTeam> teams;
  final MuLineupVariant variant;
  final String title;

  /// A free position was tapped: (team index, slot index, position name).
  final void Function(int team, int slot, String position)? onJoin;

  /// Registrations closed: free positions stay visible but are not buttons.
  final bool disabled;
  final bool header;

  // Lineup.md: court geometry in 200-unit width; avatar L 56 from 330 wide (M 40 under);
  // basketball M 40 (S 32 under); pill max 96; crown 22; you ring 3 + gap 2; compact court 64,
  // dots 10 with a 1,5 ring.
  static const double _wideCourt = 330;
  static const double _pillMax = 96;
  static const double _crown = 22;
  static const double _youRing = 3;
  static const double _youGap = 2;
  static const double _ring = 2;
  static const double _plusL = 22;
  static const double _plusM = 18;
  static const double _tagH = 24;
  static const double _compactH = 64;
  static const double _dot = 10;
  static const double _dotRing = 1.5;
  static const double _lineWidth = 2;

  /// Court size in design units (width : height).
  static Size courtSize(MuSport sport) => switch (sport) {
    MuSport.football => const Size(200, 336),
    MuSport.padel => const Size(200, 300),
    MuSport.basketball => const Size(200, 188),
  };

  /// Positions per team, in order.
  static List<String> positions(MuSport sport) => switch (sport) {
    MuSport.football => const ['Gardien', 'Défenseur', 'Défenseur', 'Attaquant', 'Attaquant'],
    MuSport.padel => const ['Côté gauche', 'Côté droit'],
    MuSport.basketball => const ['Meneur', 'Ailier', 'Pivot'],
  };

  /// Where team A's positions sit, as fractions of the court; team B is the 180° turn
  /// (basketball: the mirror across the key).
  static List<Offset> _spotsA(MuSport sport) => switch (sport) {
    MuSport.football => const [
      Offset(0.5, 0.91),
      Offset(0.25, 0.74),
      Offset(0.74, 0.74),
      Offset(0.34, 0.58),
      Offset(0.66, 0.58),
    ],
    MuSport.padel => const [Offset(0.3, 0.76), Offset(0.7, 0.76)],
    MuSport.basketball => const [Offset(0.2, 0.3), Offset(0.16, 0.68), Offset(0.36, 0.5)],
  };

  static Offset _spot(MuSport sport, int team, int slot) {
    final a = _spotsA(sport)[slot];
    if (team == 0) return a;
    return sport == MuSport.basketball ? Offset(1 - a.dx, a.dy) : Offset(1 - a.dx, 1 - a.dy);
  }

  /// The sport colour, night-lit in dark mode.
  static Color courtColor(BuildContext context) {
    final c = context.mu;
    final sport = _SportOf.of(context);
    final color = sport.color(c);
    return Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(color, MuPalette.night900, MuLineupPaint.nightMix)!
        : color;
  }

  int get _total => teams.fold(0, (n, t) => n + t.players.length);
  int get _taken => teams.fold(0, (n, t) => n + t.count);
  int get _free => _total - _taken;

  String get _sportLabel => switch (sport) {
    MuSport.football => 'Football 5 contre 5',
    MuSport.padel => 'Padel 2 contre 2',
    MuSport.basketball => 'Basket 3 contre 3',
  };

  String get _freeLabel =>
      _free == 0 ? 'Complet' : '$_free ${_free == 1 ? 'place libre' : 'places libres'}';

  @override
  Widget build(BuildContext context) =>
      variant == MuLineupVariant.compact ? _compact(context) : _full(context);

  Widget _full(BuildContext context) {
    final c = context.mu;
    final size = courtSize(sport);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: MuSize.controlS),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: MuType.labelL.copyWith(color: c.text)),
                  ),
                ),
                Text('$_taken/$_total', style: MuType.numM.copyWith(color: c.text)),
                const SizedBox(width: MuSpace.s2),
                if (_free == 0)
                  const MuStatusBadge(status: MuStatus.full, size: MuBadgeSize.s)
                else
                  Text(_freeLabel, style: MuType.labelS.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
        ],
        Semantics(
          container: true,
          label: '$_sportLabel — $_taken joueurs sur $_total',
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _SportScope(
              sport: sport,
              child: AspectRatio(
                aspectRatio: size.width / size.height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    final avatar = switch (sport) {
                      MuSport.basketball => w >= _wideCourt ? MuAvatarSize.m : MuAvatarSize.s,
                      _ => w >= _wideCourt ? MuAvatarSize.l : MuAvatarSize.m,
                    };
                    final d = switch (avatar) {
                      MuAvatarSize.l => MuSize.avatarL,
                      MuAvatarSize.m => MuSize.avatarM,
                      _ => MuSize.avatarS,
                    };
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: courtColor(context),
                              borderRadius: MuRadius.mdAll,
                              boxShadow: MuElevation.of(context).level1,
                            ),
                            child: ClipRRect(
                              borderRadius: MuRadius.mdAll,
                              child: CustomPaint(
                                painter: MuLineupPaint(
                                  sport: sport,
                                  line: c.courtLine,
                                  lineWidth: _lineWidth,
                                ),
                              ),
                            ),
                          ),
                        ),
                        for (final (t, team) in teams.indexed)
                          for (final (s, p) in team.players.indexed)
                            _place(context, t, s, p, avatar, d, w, h),
                        for (final (t, team) in teams.indexed) _tag(context, t, team),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tag(BuildContext context, int team, MuLineupTeam t) {
    final c = context.mu;
    final tag = Container(
      height: _tagH,
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.fullAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.tShirt(PhosphorIconsStyle.fill),
            size: MuSize.iconXs - 2,
            color: c.textSecondary,
          ),
          const SizedBox(width: MuSpace.s1),
          Text(t.name, style: MuType.labelS.copyWith(color: c.text)),
          const SizedBox(width: MuSpace.s2),
          Container(width: 1, height: MuSpace.s3, color: c.borderStrong),
          const SizedBox(width: MuSpace.s2),
          Text('${t.count}/${t.players.length}', style: MuType.numXs.copyWith(color: c.text)),
        ],
      ),
    );
    final excluded = ExcludeSemantics(child: tag);
    // A at the bottom-left corner, B at the top-left (basketball: A left, B right at the top).
    if (sport == MuSport.basketball) {
      return team == 0
          ? Positioned(left: MuSpace.s2, top: MuSpace.s2, child: excluded)
          : Positioned(right: MuSpace.s2, top: MuSpace.s2, child: excluded);
    }
    return team == 0
        ? Positioned(left: MuSpace.s2, bottom: MuSpace.s2, child: excluded)
        : Positioned(left: MuSpace.s2, top: MuSpace.s2, child: excluded);
  }

  Widget _place(
    BuildContext context,
    int team,
    int slot,
    MuLineupPlayer? p,
    MuAvatarSize avatar,
    double d,
    double w,
    double h,
  ) {
    final c = context.mu;
    final at = _spot(sport, team, slot);
    final position = positions(sport)[slot];
    final teamName = teams[team].name;
    // Room for the Volt ring, the pill below and the crown above.
    final outer = d + (_youRing + _youGap) * 2;
    const width = _pillMax + MuSpace.s2;
    final top = at.dy * h - outer / 2 - _crown / 2;

    Widget pill(String text, {bool you = false, bool muted = false}) => Container(
      constraints: const BoxConstraints(maxWidth: _pillMax),
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
      decoration: BoxDecoration(
        color: you ? c.accent : c.surface,
        borderRadius: MuRadius.smAll,
        boxShadow: muted ? null : MuElevation.of(context).level1,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: MuType.labelS.copyWith(color: you ? c.onAccent : (muted ? c.textSecondary : c.text)),
      ),
    );

    final Widget body;
    if (p == null) {
      final plus = avatar == MuAvatarSize.l ? _plusL : _plusM;
      final free = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: _crown / 2),
          SizedBox(
            width: outer,
            height: outer,
            child: Center(
              child: Opacity(
                opacity: disabled ? 0.6 : 1,
                child: CustomPaint(
                  painter: _DashedRing(color: c.courtLine, width: _ring),
                  child: SizedBox(
                    width: d,
                    height: d,
                    child: Icon(PhosphorIcons.plus(), size: plus, color: c.courtLine),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s1),
          pill(position, muted: true),
        ],
      );
      body = disabled || onJoin == null
          ? Semantics(label: '$position, libre', child: free)
          : Semantics(
              button: true,
              label: 'Rejoindre ce poste — $position, $teamName',
              excludeSemantics: true,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: MuRadius.mdAll,
                  onTap: () => onJoin!(team, slot, position),
                  child: free,
                ),
              ),
            );
    } else {
      final role = switch (p.role) {
        MuLineupRole.organizer => ', organisateur',
        MuLineupRole.captain => ', capitaine',
        null => '',
      };
      body = Semantics(
        label:
            '$position : ${p.you ? 'Toi' : p.name}'
            '${p.level == null ? '' : ', niveau ${formatLevel(p.level!)}'}$role',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: _crown / 2),
            SizedBox(
              width: outer,
              height: outer,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (p.you)
                    Container(
                      width: outer,
                      height: outer,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.accent, width: _youRing),
                      ),
                    ),
                  Container(
                    width: d + _ring * 2,
                    height: d + _ring * 2,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface),
                  ),
                  MuAvatar(name: p.name, level: p.level, size: avatar),
                  if (p.role != null)
                    Positioned(
                      top: -_crown / 2 + _youRing,
                      left: -_crown / 2 + _youRing + MuSpace.s1,
                      child: Container(
                        width: _crown,
                        height: _crown,
                        decoration: BoxDecoration(color: c.surfaceInverse, shape: BoxShape.circle),
                        child: Icon(
                          PhosphorIcons.crown(PhosphorIconsStyle.fill),
                          size: MuSize.iconXs - 2,
                          color: c.textInverse,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: MuSpace.s1),
            pill(p.you ? 'Toi' : p.name, you: p.you),
          ],
        ),
      );
    }

    return Positioned(
      left: at.dx * w - width / 2,
      top: top,
      width: width,
      child: Center(child: body),
    );
  }

  Widget _compact(BuildContext context) {
    final c = context.mu;
    final landscape = sport != MuSport.basketball;
    final size = courtSize(sport);
    final ratio = landscape ? size.height / size.width : size.width / size.height;
    return Semantics(
      image: true,
      label: '$_sportLabel : $_taken joueurs sur $_total, ${_freeLabel.toLowerCase()}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: _SportScope(
              sport: sport,
              child: SizedBox(
                height: _compactH,
                width: _compactH * ratio,
                child: ClipRRect(
                  borderRadius: MuRadius.smAll,
                  child: Builder(
                    builder: (context) => CustomPaint(
                      painter: MuLineupPaint(
                        sport: sport,
                        line: c.courtLine,
                        lineWidth: 1,
                        fill: courtColor(context),
                        landscape: landscape,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final (t, team) in teams.indexed)
                            for (final (s, p) in team.players.indexed)
                              () {
                                var at = _spot(sport, t, s);
                                // Turned landscape: x along the long side.
                                if (landscape) at = Offset(at.dy, 1 - at.dx);
                                return Positioned(
                                  left: at.dx * _compactH * ratio - _dot / 2,
                                  top: at.dy * _compactH - _dot / 2,
                                  child: p == null
                                      ? CustomPaint(
                                          painter: _DashedRing(
                                            color: c.courtLine,
                                            width: _dotRing,
                                            dash: 2,
                                          ),
                                          child: const SizedBox(width: _dot, height: _dot),
                                        )
                                      : Container(
                                          width: _dot,
                                          height: _dot,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: p.you ? c.accent : MuPalette.white,
                                            border: Border.all(
                                              color: MuPalette.ink900,
                                              width: _dotRing,
                                            ),
                                          ),
                                        ),
                                );
                              }(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_taken/$_total', style: MuType.numM.copyWith(color: c.text)),
              Text(
                _free == 0 ? 'Complet' : '$_free ${_free == 1 ? 'place' : 'places'}',
                style: MuType.labelS.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Passes the sport down to [MuLineup.courtColor].
class _SportScope extends InheritedWidget {
  const _SportScope({required this.sport, required super.child});

  final MuSport sport;

  @override
  bool updateShouldNotify(_SportScope oldWidget) => sport != oldWidget.sport;
}

abstract final class _SportOf {
  static MuSport of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SportScope>()?.sport ?? MuSport.football;
}

/// The court markings on the 200-unit geometry: football pitch, padel court with glass and net,
/// basketball half court with the key, the arc and the hoop.
class MuLineupPaint extends CustomPainter {
  const MuLineupPaint({
    required this.sport,
    required this.line,
    required this.lineWidth,
    this.fill,
    this.landscape = false,
  });

  final MuSport sport;
  final Color line;
  final double lineWidth;

  /// Painted under the markings (the full court fills through its box instead).
  final Color? fill;
  final bool landscape;

  /// Dark mode: the sport colour mixed 68 % with night-900 → lerp 0.32.
  static const double nightMix = 0.32;

  @override
  void paint(Canvas canvas, Size size) {
    if (fill != null) canvas.drawRect(Offset.zero & size, Paint()..color = fill!);
    final design = MuLineup.courtSize(sport);
    canvas.save();
    if (landscape) {
      // Turn the portrait geometry on its side.
      canvas.translate(size.width, 0);
      canvas.rotate(1.5707963267948966);
      canvas.scale(size.height / design.width, size.width / design.height);
    } else {
      canvas.scale(size.width / design.width, size.height / design.height);
    }
    final paint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth / (size.width / design.width);
    final w = design.width;
    final h = design.height;
    switch (sport) {
      case MuSport.football:
        const inset = 8.0;
        canvas.drawRect(Rect.fromLTRB(inset, inset, w - inset, h - inset), paint);
        canvas.drawLine(Offset(inset, h / 2), Offset(w - inset, h / 2), paint);
        canvas.drawCircle(Offset(w / 2, h / 2), 28, paint);
        for (final top in [true, false]) {
          final y = top ? inset : h - inset;
          final dir = top ? 1 : -1;
          canvas.drawRect(Rect.fromLTRB(w / 2 - 56, y, w / 2 + 56, y + dir * 46), paint);
          canvas.drawRect(Rect.fromLTRB(w / 2 - 26, y, w / 2 + 26, y + dir * 18), paint);
          canvas.drawRect(Rect.fromLTRB(w / 2 - 16, y, w / 2 + 16, y - dir * 6), paint);
        }
      case MuSport.padel:
        const inset = 10.0;
        canvas.drawRect(Rect.fromLTRB(inset, inset, w - inset, h - inset), paint);
        // Glass: a lighter double line along the walls.
        canvas.drawRect(
          Rect.fromLTRB(inset + 4, inset + 4, w - inset - 4, h - inset - 4),
          Paint()
            ..color = line.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = paint.strokeWidth,
        );
        // Net.
        canvas.drawLine(Offset(inset, h / 2), Offset(w - inset, h / 2), paint);
        for (var x = inset + 4; x < w - inset; x += 8) {
          canvas.drawLine(Offset(x, h / 2 - 3), Offset(x, h / 2 + 3), paint);
        }
        // Service lines and the centre lines.
        canvas.drawLine(Offset(inset, h * 0.27), Offset(w - inset, h * 0.27), paint);
        canvas.drawLine(Offset(inset, h * 0.73), Offset(w - inset, h * 0.73), paint);
        canvas.drawLine(Offset(w / 2, inset), Offset(w / 2, h * 0.27), paint);
        canvas.drawLine(Offset(w / 2, h * 0.73), Offset(w / 2, h - inset), paint);
      case MuSport.basketball:
        const inset = 8.0;
        canvas.drawRect(Rect.fromLTRB(inset, inset, w - inset, h - inset), paint);
        // The key, the hoop and the arc, baseline on the left.
        canvas.drawRect(Rect.fromLTRB(inset, h / 2 - 34, inset + 60, h / 2 + 34), paint);
        canvas.drawCircle(Offset(inset + 60, h / 2), 22, paint);
        canvas.drawCircle(Offset(inset + 14, h / 2), 5, paint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(inset + 14, h / 2), radius: 92),
          -1.25,
          2.5,
          false,
          paint,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MuLineupPaint old) =>
      old.sport != sport ||
      old.line != line ||
      old.fill != fill ||
      old.landscape != landscape ||
      old.lineWidth != lineWidth;
}

/// A dashed circle (the free position ring).
class _DashedRing extends CustomPainter {
  const _DashedRing({required this.color, required this.width, this.dash = 5});

  final Color color;
  final double width;
  final double dash;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - width / 2;
    final centre = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final circumference = 2 * 3.141592653589793 * r;
    final n = (circumference / (dash * 2)).floor();
    final sweep = 2 * 3.141592653589793 / n;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: r),
        i * sweep,
        sweep / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) =>
      old.color != color || old.width != width || old.dash != dash;
}
