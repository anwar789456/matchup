import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_match_card.dart';
import 'src/card_surface.dart';

/// A side of the scoreboard: name, short name, the players (one per line for padel), and whether
/// it is the player's team.
@immutable
class MuScoreTeam {
  const MuScoreTeam({required this.name, this.short, this.players = const [], this.you = false});

  final String name;
  final String? short;
  final List<String> players;
  final bool you;

  /// A 2–3 letter monogram from the name.
  String get monogram {
    final words = name
        .replaceAll('/', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w != '·')
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length.clamp(0, 2)).toUpperCase();
    }
    return (words.first[0] + words[1][0]).toUpperCase();
  }
}

enum MuScoreboardVariant { full, compact }

/// Scoreboard (components/Scoreboard.md): the score at the top of a match — status line, two
/// crests with names and « Ton équipe » / « Vainqueur » tags, the score (padel: « SET 1 · SET 2 »
/// columns, the lost sets in `text-secondary`), basketball meters to the target.
class MuScoreboard extends StatelessWidget {
  const MuScoreboard({
    super.key,
    required this.sport,
    required this.status,
    required this.teams,
    this.score,
    this.sets,
    this.clock,
    this.period,
    this.date,
    this.kickoff,
    this.venue,
    this.target = 21,
    this.variant = MuScoreboardVariant.full,
  });

  final MuSport sport;
  final MuMatchStatus status;
  final List<MuScoreTeam> teams;

  /// Football and basketball: (home, away).
  final (int, int)? score;

  /// Padel: one (home, away) per set.
  final List<(int, int)>? sets;
  final String? clock;
  final String? period;

  /// Final: « ven. 9 oct. ».
  final String? date;

  /// Upcoming: « 20h00 ».
  final String? kickoff;
  final String? venue;
  final int target;
  final MuScoreboardVariant variant;

  // Scoreboard.md: crest 56 × 64; set columns 36; compact min 48.
  static const double _crestW = 56;
  static const double _crestH = 64;
  static const double _setCol = 36;
  static const double _compactMin = 48;
  static const double _meter = 8;

  /// Who won: 0, 1, or null.
  int? get winner {
    if (status != MuMatchStatus.finished) return null;
    if (sets != null) {
      var a = 0;
      var b = 0;
      for (final (x, y) in sets!) {
        if (x > y) a++;
        if (y > x) b++;
      }
      return a == b ? null : (a > b ? 0 : 1);
    }
    if (score == null || score!.$1 == score!.$2) return null;
    return score!.$1 > score!.$2 ? 0 : 1;
  }

  String get _statusText => switch (status) {
    MuMatchStatus.live => 'En direct${clock == null ? '' : ', $clock'}',
    MuMatchStatus.finished => 'Terminé${date == null ? '' : ' · $date'}',
    MuMatchStatus.upcoming => 'À venir${kickoff == null ? '' : ' · $kickoff'}',
  };

  String get _scoreText {
    if (sets != null) return [for (final (a, b) in sets!) '$a $b'].join(', ');
    if (score == null) return '';
    return '${score!.$1} ${score!.$2}';
  }

  @override
  Widget build(BuildContext context) =>
      variant == MuScoreboardVariant.compact ? _compact(context) : _full(context);

  Widget _statusLine(BuildContext context, {bool compact = false}) {
    final c = context.mu;
    final (Widget lead, Color ink) = switch (status) {
      MuMatchStatus.live => (
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c.live, shape: BoxShape.circle),
        ),
        c.errorText,
      ),
      MuMatchStatus.finished => (
        Icon(PhosphorIcons.flagCheckered(), size: MuSize.iconXs, color: c.text),
        c.text,
      ),
      MuMatchStatus.upcoming => (
        Icon(PhosphorIcons.clock(), size: MuSize.iconXs, color: c.text),
        c.text,
      ),
    };
    final word = switch (status) {
      MuMatchStatus.live => Text('EN DIRECT', style: MuType.overline.copyWith(color: ink)),
      MuMatchStatus.finished => Text('Terminé', style: MuType.labelS.copyWith(color: ink)),
      MuMatchStatus.upcoming => Text('À venir', style: MuType.labelS.copyWith(color: ink)),
    };
    final extra = switch (status) {
      MuMatchStatus.live => clock,
      MuMatchStatus.finished => date,
      MuMatchStatus.upcoming => kickoff,
    };
    return Row(
      children: [
        lead,
        const SizedBox(width: MuSpace.s1),
        word,
        if (extra != null) ...[
          Text(' · ', style: MuType.caption.copyWith(color: c.textSecondary)),
          Text(
            extra,
            style: (status == MuMatchStatus.live ? MuType.numS : MuType.caption).copyWith(
              color: status == MuMatchStatus.live ? c.errorText : c.textSecondary,
            ),
          ),
        ],
        if (period != null) ...[
          const SizedBox(width: MuSpace.s2),
          Text(period!, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
        const Spacer(),
        if (venue != null && !compact) ...[
          Icon(PhosphorIcons.mapPin(), size: MuSize.iconXs - 2, color: c.textSecondary),
          const SizedBox(width: MuSpace.s1),
          Flexible(
            child: Text(
              venue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _crest(BuildContext context, int i) {
    final c = context.mu;
    final t = teams[i];
    final loser = winner != null && winner != i;
    return Opacity(
      opacity: loser ? 0.55 : 1,
      child: CustomPaint(
        painter: _ShieldPainter(
          fill: i == 0 ? c.surfaceInverse : c.surfaceMuted,
          edge: i == 0 ? null : c.borderStrong,
        ),
        child: SizedBox(
          width: _crestW,
          height: _crestH,
          child: Center(
            child: Text(
              t.monogram,
              style: MuType.labelL.copyWith(color: i == 0 ? c.textInverse : c.text),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, int i) {
    final c = context.mu;
    final t = teams[i];
    if (winner == i) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
        decoration: BoxDecoration(color: c.surfaceInverse, borderRadius: MuRadius.fullAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.trophy(), size: MuSize.iconXs - 2, color: c.textInverse),
            const SizedBox(width: MuSpace.s1),
            Text('Vainqueur', style: MuType.labelS.copyWith(color: c.textInverse)),
          ],
        ),
      );
    }
    if (t.you) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
        decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.fullAll),
        child: Text('Ton équipe', style: MuType.labelS.copyWith(color: c.onAccent)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _full(BuildContext context) {
    final c = context.mu;
    final padel = sets != null;
    final Widget board;
    if (padel) {
      final n = sets!.length;
      Widget name(int i) {
        final t = teams[i];
        final loser = winner != null && winner != i;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in t.players.isEmpty ? [t.name] : t.players)
              Text(
                p,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MuType.label.copyWith(color: loser ? c.textSecondary : c.text),
              ),
          ],
        );
      }

      Widget setCells(int i) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var s = 0; s < n; s++)
            SizedBox(
              width: _setCol,
              child: Text(
                '${i == 0 ? sets![s].$1 : sets![s].$2}',
                textAlign: TextAlign.center,
                style: MuType.numL.copyWith(
                  color: (i == 0 ? sets![s].$1 >= sets![s].$2 : sets![s].$2 >= sets![s].$1)
                      ? c.text
                      : c.textSecondary,
                ),
              ),
            ),
        ],
      );

      board = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              for (var s = 0; s < n; s++)
                SizedBox(
                  width: _setCol,
                  child: Text(
                    'SET ${s + 1}',
                    textAlign: TextAlign.center,
                    style: MuType.overline.copyWith(color: c.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          for (final i in [0, 1]) ...[
            if (i > 0) const SizedBox(height: MuSpace.s4),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: MuSpace.s2,
                    runSpacing: MuSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      name(i),
                      _tag(context, i),
                      if (winner == i)
                        Icon(PhosphorIcons.trophy(), size: MuSize.iconS, color: c.text),
                    ],
                  ),
                ),
                setCells(i),
              ],
            ),
          ],
        ],
      );
    } else {
      board = Row(
        children: [
          Expanded(child: _side(context, 0)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == MuMatchStatus.upcoming) ...[
                Text(kickoff ?? '', style: MuType.numL.copyWith(color: c.text)),
                Text('Coup d’envoi', style: MuType.caption.copyWith(color: c.textSecondary)),
              ] else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _bigScore(context, 0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                      child: Text('–', style: MuType.score.copyWith(color: c.textSecondary)),
                    ),
                    _bigScore(context, 1),
                  ],
                ),
            ],
          ),
          Expanded(child: _side(context, 1)),
        ],
      );
    }

    return Semantics(
      liveRegion: status == MuMatchStatus.live,
      label:
          '$_statusText. ${teams[0].name} ${_scoreText.isEmpty ? '' : _scoreText.split(' ').first} '
          '${teams[1].name} ${_scoreText.split(' ').length > 1 ? _scoreText.split(' ')[1] : ''}',
      excludeSemantics: true,
      child: MuCardSurface(
        padding: const EdgeInsets.fromLTRB(MuSpace.s5, MuSpace.s5, MuSpace.s5, MuSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusLine(context, compact: true),
            if (venue != null) ...[
              const SizedBox(height: MuSpace.s1),
              Row(
                children: [
                  Icon(PhosphorIcons.mapPin(), size: MuSize.iconXs - 2, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s1),
                  Expanded(
                    child: Text(
                      venue!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: MuSpace.s5),
            board,
            if (sport == MuSport.basketball && score != null) ...[
              const SizedBox(height: MuSpace.s5),
              _meters(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bigScore(BuildContext context, int i) {
    final c = context.mu;
    final loser = winner != null && winner != i;
    final v = i == 0 ? score?.$1 : score?.$2;
    return Text(
      '${v ?? '–'}',
      style: MuType.score.copyWith(color: loser ? c.textSecondary : c.text),
    );
  }

  Widget _side(BuildContext context, int i) {
    final c = context.mu;
    final t = teams[i];
    final loser = winner != null && winner != i;
    return Column(
      children: [
        _crest(context, i),
        const SizedBox(height: MuSpace.s2),
        Text(
          t.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: MuType.labelL.copyWith(color: loser ? c.textSecondary : c.text),
        ),
        const SizedBox(height: MuSpace.s1),
        _tag(context, i),
      ],
    );
  }

  Widget _meters(BuildContext context) {
    final c = context.mu;
    Widget meter(int v, {required bool reverse}) => Semantics(
      label: '$v points sur $target',
      child: ClipRRect(
        borderRadius: MuRadius.fullAll,
        child: Container(
          height: _meter,
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            border: Border.all(color: c.border),
          ),
          alignment: reverse ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: (v / target).clamp(0, 1),
            heightFactor: 1,
            child: ColoredBox(color: MuSport.basketball.color(c)),
          ),
        ),
      ),
    );
    return Row(
      children: [
        Expanded(child: meter(score!.$1, reverse: true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3),
          child: Text('Premier à $target', style: MuType.caption.copyWith(color: c.textSecondary)),
        ),
        Expanded(child: meter(score!.$2, reverse: false)),
      ],
    );
  }

  Widget _compact(BuildContext context) {
    final c = context.mu;
    final padel = sets != null;
    return Semantics(
      label: '$_statusText. ${teams[0].name} $_scoreText ${teams[1].name}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: _compactMin),
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: MuRadius.smAll,
          border: Border.all(color: c.border),
        ),
        child: padel
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusLine(context, compact: true),
                  const SizedBox(height: MuSpace.s1),
                  for (final i in [0, 1])
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            teams[i].short ?? teams[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.labelS.copyWith(color: c.text),
                          ),
                        ),
                        for (final (a, b) in sets!)
                          SizedBox(
                            width: MuSpace.s5,
                            child: Text(
                              '${i == 0 ? a : b}',
                              textAlign: TextAlign.center,
                              style: MuType.numS.copyWith(
                                color: (i == 0 ? a >= b : b >= a) ? c.text : c.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _statusLine(context, compact: true)),
                  Text(
                    teams[0].short ?? teams[0].name,
                    style: MuType.labelS.copyWith(color: c.text),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                    child: Text(
                      status == MuMatchStatus.upcoming
                          ? (kickoff ?? '')
                          : '${score?.$1 ?? '–'} – ${score?.$2 ?? '–'}',
                      style: MuType.numM.copyWith(color: c.text),
                    ),
                  ),
                  Text(
                    teams[1].short ?? teams[1].name,
                    style: MuType.labelS.copyWith(color: c.text),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A crest shield: a rectangle whose bottom edge comes to a point.
class _ShieldPainter extends CustomPainter {
  const _ShieldPainter({required this.fill, this.edge});

  final Color fill;
  final Color? edge;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(MuRadius.sm, 0)
      ..lineTo(w - MuRadius.sm, 0)
      ..quadraticBezierTo(w, 0, w, MuRadius.sm)
      ..lineTo(w, h * 0.68)
      ..quadraticBezierTo(w, h * 0.86, w / 2, h)
      ..quadraticBezierTo(0, h * 0.86, 0, h * 0.68)
      ..lineTo(0, MuRadius.sm)
      ..quadraticBezierTo(0, 0, MuRadius.sm, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    if (edge != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = edge!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.fill != fill || old.edge != edge;
}
