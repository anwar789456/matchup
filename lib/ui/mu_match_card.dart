import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_skeleton.dart';
import 'mu_sport_icon.dart';
import 'mu_status_badge.dart';
import 'src/card_surface.dart';
import '../l10n/l10n.dart';

enum MuMatchStatus { upcoming, live, finished }

/// A side of a match: name, the short name of compact cards, a 2–3 letter monogram, a score or
/// padel sets, and whether it is the player's side.
@immutable
class MuMatchTeam {
  const MuMatchTeam({
    required this.name,
    required this.monogram,
    this.shortName,
    this.score,
    this.sets,
    this.you = false,
  });

  final String name;
  final String monogram;
  final String? shortName;
  final int? score;
  final List<int>? sets;
  final bool you;

  String get short => shortName ?? name;
}

/// A match as the cards show it.
@immutable
class MuMatch {
  const MuMatch({
    required this.sport,
    required this.teams,
    required this.status,
    this.round,
    this.court,
    this.minute,
    this.kickoff,
    this.competition,
    this.target,
  });

  final MuSport sport;
  final List<MuMatchTeam> teams;
  final MuMatchStatus status;

  /// « Demi-finale », or the date of a casual game (« Ven. 9 oct. »).
  final String? round;
  final String? court;

  /// Live: « 34’ ».
  final String? minute;

  /// Upcoming: « 18h30 ».
  final String? kickoff;

  /// Footer: « Smash Padel Club · Lac 2 · 20h00 ».
  final String? competition;

  /// Basketball: « Premier à 21 points ».
  final int? target;

  bool get padel => teams.first.sets != null;

  /// Who won: 0, 1, or null (live, upcoming or a draw).
  int? get winner {
    if (status != MuMatchStatus.finished) return null;
    if (padel) {
      var a = 0;
      var b = 0;
      final sa = teams[0].sets!;
      final sb = teams[1].sets!;
      for (var i = 0; i < sa.length && i < sb.length; i++) {
        if (sa[i] > sb[i]) a++;
        if (sb[i] > sa[i]) b++;
      }
      return a == b ? null : (a > b ? 0 : 1);
    }
    final a = teams[0].score ?? 0;
    final b = teams[1].score ?? 0;
    return a == b ? null : (a > b ? 0 : 1);
  }
}

enum MuMatchCardVariant { standard, compact }

/// MatchCard (components/MatchCard.md): a match about its score — head (round · court, status),
/// a board of monograms, names and scores (padel: one column per set), the winner's score on Volt
/// with a trophy. Compact is the 88-high broadcast line of result lists.
class MuMatchCard extends StatelessWidget {
  const MuMatchCard({
    super.key,
    required MuMatch this.match,
    this.variant = MuMatchCardVariant.standard,
    this.onTap,
  }) : loading = false;

  const MuMatchCard.loading({super.key, this.variant = MuMatchCardVariant.standard})
    : match = null,
      loading = true,
      onTap = null;

  final MuMatch? match;
  final MuMatchCardVariant variant;
  final VoidCallback? onTap;
  final bool loading;

  // MatchCard.md: monogram 40 (compact 32, padel mini board 24); score cell 44; rows ≥ 64;
  // compact min 88.
  static const double _monogram = 40;
  static const double _monogramCompact = 32;
  static const double _monogramMini = 24;
  static const double _scoreCell = 44;
  static const double _setCell = 28;
  static const double _row = 64;
  static const double _minHeight = 88;

  String _semantics(MuMatch m) {
    final a = m.teams[0];
    final b = m.teams[1];
    final score = m.padel
        ? [for (var i = 0; i < a.sets!.length; i++) '${a.sets![i]} ${b.sets![i]}'].join(', ')
        : '${a.score ?? ''} ${b.score ?? ''}';
    return l10n.contre(a.name, b.name, m.round == null ? '' : ', ${m.round}', switch (m.status) {
          MuMatchStatus.upcoming => l10n.aVenir4(m.kickoff == null ? '' : l10n.atTime(m.kickoff!)),
          MuMatchStatus.live => l10n.enDirect4(m.minute == null ? '' : ', ${m.minute}'),
          MuMatchStatus.finished => l10n.termine5(score),
        });
  }

  Widget _monogramBox(
    BuildContext context,
    MuSport sport,
    String text,
    double size, {
    bool muted = false,
  }) {
    final c = context.mu;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: sport.soft(c), borderRadius: MuRadius.smAll),
      child: Opacity(
        opacity: muted ? MuOpacity.disabled : 1,
        child: Text(
          text,
          style: (size >= _monogram ? MuType.label : MuType.labelS).copyWith(color: sport.text(c)),
        ),
      ),
    );
  }

  Widget _head(BuildContext context, MuMatch m) {
    final c = context.mu;
    final parts = [?m.round, ?m.court];
    return Row(
      children: [
        Expanded(
          child: Text(
            parts.join(' · ').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MuType.overline.copyWith(color: c.textSecondary),
          ),
        ),
        switch (m.status) {
          MuMatchStatus.live => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MuStatusBadge(status: MuStatus.live, label: l10n.enDirect, size: MuBadgeSize.s),
              if (m.minute != null) ...[
                const SizedBox(width: MuSpace.s2),
                Text(m.minute!, style: MuType.numS.copyWith(color: c.errorText)),
              ],
            ],
          ),
          MuMatchStatus.finished => Text(
            l10n.termine3,
            style: MuType.overline.copyWith(color: c.textSecondary),
          ),
          MuMatchStatus.upcoming => Text(
            m.kickoff ?? l10n.aVenir,
            style: MuType.labelS.copyWith(color: c.textSecondary),
          ),
        },
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return _loading(context);
    final m = match!;
    return variant == MuMatchCardVariant.compact ? _compact(context, m) : _standard(context, m);
  }

  Widget _score(BuildContext context, MuMatch m, int team, {bool compact = false}) {
    final c = context.mu;
    final t = m.teams[team];
    final winner = m.winner == team;
    final loser = m.winner != null && !winner;
    final style = (compact ? MuType.numL : MuType.numXl).copyWith(
      color: winner ? c.onAccent : (loser ? c.textSecondary : c.text),
    );
    return Container(
      constraints: BoxConstraints(minWidth: compact ? MuSize.controlS : _scoreCell),
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
      decoration: winner ? BoxDecoration(color: c.accent, borderRadius: MuRadius.smAll) : null,
      alignment: Alignment.center,
      child: Text('${t.score ?? '–'}', style: style),
    );
  }

  Widget _sets(BuildContext context, MuMatch m, int team, {bool compact = false}) {
    final c = context.mu;
    final a = m.teams[0].sets!;
    final b = m.teams[1].sets!;
    final mine = m.teams[team].sets!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < mine.length; i++)
          SizedBox(
            width: compact ? _setCell : _scoreCell,
            child: Text(
              '${mine[i]}',
              textAlign: TextAlign.center,
              style: (compact ? MuType.numS : MuType.numM).copyWith(
                color: (team == 0 ? a[i] >= b[i] : b[i] >= a[i]) ? c.text : c.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _standard(BuildContext context, MuMatch m) {
    final c = context.mu;
    Widget row(int i) {
      final t = m.teams[i];
      final winner = m.winner == i;
      final loser = m.winner != null && !winner;
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _row),
        child: Row(
          children: [
            _monogramBox(context, m.sport, t.monogram, _monogram, muted: loser),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      t.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: (loser ? MuType.bodyL : MuType.labelL).copyWith(
                        color: loser ? c.textSecondary : c.text,
                      ),
                    ),
                  ),
                  if (winner) ...[
                    const SizedBox(width: MuSpace.s2),
                    Icon(
                      PhosphorIcons.trophy(),
                      size: MuSize.iconXs,
                      color: c.text,
                      semanticLabel: l10n.vainqueur,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: MuSpace.s3),
            if (m.status == MuMatchStatus.upcoming)
              const SizedBox.shrink()
            else if (m.padel)
              _sets(context, m, i)
            else
              _score(context, m, i),
          ],
        ),
      );
    }

    return MuCardSurface(
      onTap: onTap,
      semanticLabel: _semantics(m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _head(context, m),
          const SizedBox(height: MuSpace.s3),
          if (m.status == MuMatchStatus.upcoming && m.kickoff != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      row(0),
                      Divider(height: 1, color: c.border),
                      row(1),
                    ],
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: MuRadius.smAll,
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.kickoff!, style: MuType.numL.copyWith(color: c.text)),
                      Text(l10n.coupDEnvoi, style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            row(0),
            Divider(height: 1, thickness: 1, color: c.border),
            row(1),
          ],
          if (m.competition != null || m.target != null) ...[
            const SizedBox(height: MuSpace.s3),
            Row(
              children: [
                MuSportIcon(m.sport, size: MuSize.iconXs, color: c.textSecondary),
                const SizedBox(width: MuSpace.s1),
                Expanded(
                  child: Text(
                    m.competition ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                if (m.target != null) ...[
                  Icon(PhosphorIcons.target(), size: MuSize.iconXs, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s1),
                  Text(
                    l10n.premierAPoints('${m.target}'),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _compact(BuildContext context, MuMatch m) {
    final c = context.mu;
    final a = m.teams[0];
    final b = m.teams[1];
    final Widget line;
    if (m.padel) {
      Widget pair(int i) {
        final t = m.teams[i];
        final loser = m.winner != null && m.winner != i;
        return Row(
          children: [
            _monogramBox(context, m.sport, t.monogram, _monogramMini, muted: loser),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: Text(
                t.short,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (loser ? MuType.body : MuType.label).copyWith(
                  color: loser ? c.textSecondary : c.text,
                ),
              ),
            ),
            _sets(context, m, i, compact: true),
          ],
        );
      }

      line = Column(
        children: [
          pair(0),
          const SizedBox(height: MuSpace.s2),
          pair(1),
        ],
      );
    } else {
      line = Row(
        children: [
          _monogramBox(
            context,
            m.sport,
            a.monogram,
            _monogramCompact,
            muted: m.winner != null && m.winner != 0,
          ),
          const SizedBox(width: MuSpace.s2),
          Expanded(
            child: Text(
              a.short,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MuType.label.copyWith(
                color: m.winner != null && m.winner != 0 ? c.textSecondary : c.text,
              ),
            ),
          ),
          _score(context, m, 0, compact: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
            child: Text('–', style: MuType.numL.copyWith(color: c.textSecondary)),
          ),
          _score(context, m, 1, compact: true),
          const SizedBox(width: MuSpace.s2),
          Expanded(
            child: Text(
              b.short,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: MuType.label.copyWith(
                color: m.winner != null && m.winner != 1 ? c.textSecondary : c.text,
              ),
            ),
          ),
          const SizedBox(width: MuSpace.s2),
          _monogramBox(
            context,
            m.sport,
            b.monogram,
            _monogramCompact,
            muted: m.winner != null && m.winner != 1,
          ),
        ],
      );
    }
    return MuCardSurface(
      onTap: onTap,
      semanticLabel: _semantics(m),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight - MuSpace.s4 * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _head(context, m),
            const SizedBox(height: MuSpace.s3),
            line,
          ],
        ),
      ),
    );
  }

  Widget _loading(BuildContext context) => MuCardSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const MuSkeleton.text(width: 120),
        const SizedBox(height: MuSpace.s3),
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              MuSkeleton(
                width: variant == MuMatchCardVariant.compact ? _monogramCompact : _monogram,
                height: variant == MuMatchCardVariant.compact ? _monogramCompact : _monogram,
              ),
              const SizedBox(width: MuSpace.s3),
              const Expanded(child: MuSkeleton.text()),
              const SizedBox(width: MuSpace.s3),
              const MuSkeleton(width: _scoreCell, height: MuSize.iconM),
            ],
          ),
        ],
      ],
    ),
  );
}
