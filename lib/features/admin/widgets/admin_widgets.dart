import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../../l10n/l10n.dart';

/// The bar of the admin's pushed screens (ADM-03, 07, 08): back arrow, title over a caption,
/// optional [actions].
class AdminBar extends StatelessWidget {
  const AdminBar({
    super.key,
    required this.title,
    required this.caption,
    required this.backLabel,
    required this.fallback,
    this.actions = const [],
  });

  final String title;
  final String caption;
  final String backLabel;

  /// Where the arrow goes when there is nothing to pop.
  final String fallback;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          MuSpace.s1,
          MuSpace.s2,
          MuSpace.s2,
          MuSpace.s2,
        ),
        child: Row(
          children: [
            MuIconButton(
              icon: PhosphorIcons.arrowLeft(),
              label: backLabel,
              size: MuIconButtonSize.l,
              onPressed: () => goBack(context, fallback),
            ),
            const SizedBox(width: MuSpace.s1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: MuType.labelL.copyWith(color: c.text)),
                  ),
                  Text(caption, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// A section head: title (`h3`, or `h2` for [large]) and an end widget, min 32 high.
class AdminSectionHead extends StatelessWidget {
  const AdminSectionHead({super.key, required this.title, this.end, this.large = false});

  final String title;
  final Widget? end;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: MuSize.controlS),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: (large ? MuType.h2 : MuType.h3).copyWith(color: c.text)),
            ),
          ),
          ?end,
        ],
      ),
    );
  }
}

/// `caption` in `text-secondary`.
class AdminMuted extends StatelessWidget {
  const AdminMuted(this.text, {super.key, this.maxLines, this.align});

  final String text;
  final int? maxLines;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: maxLines,
    textAlign: align,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    style: MuType.caption.copyWith(color: context.mu.textSecondary),
  );
}

/// adm-list: rows on one `surface` card, hairlines between them from [inset] (16, or 68 past a
/// 40 px leading tile).
class AdminList extends StatelessWidget {
  const AdminList({super.key, required this.children, this.inset = MuSpace.s4, this.label});

  final List<Widget> children;
  final double inset;
  final String? label;

  /// Past a 40 px tile + 12 gap + 16 padding.
  static const double tileInset = 68;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      container: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: MuRadius.mdAll,
          boxShadow: MuElevation.of(context).level1,
        ),
        child: ClipRRect(
          borderRadius: MuRadius.mdAll,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, row) in children.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: inset),
                      child: Divider(height: 1, thickness: 1, color: c.border),
                    ),
                  row,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// adm-row: [leading], a text column, [end] and a chevron when it opens something; min 64 high,
/// padding 12 16.
class AdminRow extends StatelessWidget {
  const AdminRow({
    super.key,
    required this.child,
    this.leading,
    this.end,
    this.onTap,
    this.chevron,
    this.top = false,
    this.minHeight = MuSize.controlXl + MuSpace.s2,
    this.semanticLabel,
    this.selected = false,
    this.gap = MuSpace.s3,
  });

  final Widget child;
  final Widget? leading;
  final Widget? end;
  final VoidCallback? onTap;

  /// Defaults to « shown when [onTap] is set ».
  final bool? chevron;
  final bool top;
  final double minHeight;
  final String? semanticLabel;

  /// `surface-muted` behind a selected row (bulk mode).
  final bool selected;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
        child: Row(
          crossAxisAlignment: top ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, SizedBox(width: gap)],
            Expanded(child: child),
            if (end != null) ...[SizedBox(width: gap), end!],
            if (chevron ?? onTap != null) ...[
              const SizedBox(width: MuSpace.s2),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 0),
                child: MuDirectionalIcon(
                  PhosphorIcons.caretRight(),
                  size: MuSize.iconS,
                  color: c.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    final body = AnimatedContainer(
      duration: MuMotion.durationOf(context, MuMotion.fast),
      color: selected ? c.surfaceMuted : c.surfaceMuted.withValues(alpha: 0),
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
    if (semanticLabel == null) return body;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: body,
    );
  }
}

/// Title (`label`) over caption lines, one line each.
class AdminTexts extends StatelessWidget {
  const AdminTexts({super.key, required this.title, this.lines = const [], this.titleEnd});

  final String title;
  final List<String> lines;

  /// A widget after the title (the « IA » label).
  final Widget? titleEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final t = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: MuType.label.copyWith(color: c.text),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titleEnd == null)
          t
        else
          Row(
            children: [
              Flexible(child: t),
              const SizedBox(width: MuSpace.s2 - 2),
              titleEnd!,
            ],
          ),
        for (final l in lines) ...[const SizedBox(height: 2), AdminMuted(l, maxLines: 1)],
      ],
    );
  }
}

enum AdminTileTone { neutral, error, warning, info, ai, success }

/// adm-ico: a 40 px `radius-sm` tile with a 20 px icon on the tone's soft colour.
class AdminIconTile extends StatelessWidget {
  const AdminIconTile(this.icon, {super.key, this.tone = AdminTileTone.neutral});

  final IconData icon;
  final AdminTileTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (Color ground, Color ink) = switch (tone) {
      AdminTileTone.neutral => (c.surfaceMuted, c.text),
      AdminTileTone.error => (c.errorSoft, c.errorText),
      AdminTileTone.warning => (c.warningSoft, c.warningText),
      AdminTileTone.info => (c.infoSoft, c.infoText),
      AdminTileTone.ai => (c.aiSoft, c.aiText),
      AdminTileTone.success => (c.successSoft, c.successText),
    };
    return Container(
      width: MuSize.controlM,
      height: MuSize.controlM,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: ground, borderRadius: MuRadius.smAll),
      child: Icon(icon, size: MuSize.iconS, color: ink),
    );
  }
}

enum AdminScoreLevel { high, mid, low }

/// adm-score: the AI score (`num-m`), a 4 px meter and its level in words. It sorts and
/// suggests; it never decides.
class AdminScore extends StatelessWidget {
  const AdminScore({
    super.key,
    required this.value,
    required this.fraction,
    required this.level,
    required this.levelLabel,
    this.width = 76,
  });

  /// Moderation score 0–1 (« 0,62 », « Moyen »).
  factory AdminScore.toxicity(double score) {
    final level = score >= 0.8
        ? AdminScoreLevel.high
        : score >= 0.5
        ? AdminScoreLevel.mid
        : AdminScoreLevel.low;
    return AdminScore(
      value: score.toStringAsFixed(2).replaceAll('.', ','),
      fraction: score,
      level: level,
      levelLabel: switch (level) {
        AdminScoreLevel.high => l10n.eleve,
        AdminScoreLevel.mid => l10n.moyen,
        AdminScoreLevel.low => l10n.faible,
      },
    );
  }

  final String value;
  final double fraction;
  final AdminScoreLevel level;
  final String levelLabel;
  final double width;

  // adm-score: track 4 high.
  static const double _track = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (Color fill, Color ink) = switch (level) {
      AdminScoreLevel.high => (c.error, c.errorText),
      AdminScoreLevel.mid => (c.warning, c.warningText),
      AdminScoreLevel.low => (c.textSecondary, c.textSecondary),
    };
    return Semantics(
      label: l10n.scoreIa(value, levelLabel),
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: MuType.numM.copyWith(color: c.text)),
            const SizedBox(height: MuSpace.s1),
            ClipRRect(
              borderRadius: MuRadius.fullAll,
              child: SizedBox(
                height: _track,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: c.surfaceMuted)),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: fraction.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: fill, borderRadius: MuRadius.fullAll),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MuSpace.s1),
            Text(levelLabel, style: MuType.labelS.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}

/// adm-why: the « IA » label and the AI's reading.
class AdminWhy extends StatelessWidget {
  const AdminWhy(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      MuAiLabel(size: MuAiLabelSize.s),
      const SizedBox(width: MuSpace.s2 - 2),
      Flexible(child: AdminMuted(text, maxLines: 1)),
    ],
  );
}

/// A page shown over the previous one, behind `scrim` (ADM-04's dialog, ADM-10's sheet).
CustomTransitionPage<void> adminOverlayPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierDismissible: true,
    barrierColor: context.mu.scrim,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: reduce ? Duration.zero : MuMotion.slow,
    reverseTransitionDuration: reduce ? Duration.zero : MuMotion.base,
    child: child,
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: MuMotion.enter,
        reverseCurve: MuMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// adm sections sit 28 apart.
const double adminSectionGap = MuSpace.s6 + MuSpace.s1;

/// « +312 », « −12 ».
String signedInt(num v) => '${v < 0 ? '−' : '+'}${formatInt(v.abs().round())}';

/// « +8 % », « −12 % ».
String signedPercent(num v) => '${signedInt(v)}\u202f%';

/// Two KPI cards per row, `space-3` apart (ADM-01, ADM-06).
class AdminKpiGrid extends StatelessWidget {
  const AdminKpiGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i += 2) ...[
        if (i > 0) const SizedBox(height: MuSpace.s3),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: MuSpace.s3),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
            ],
          ),
        ),
      ],
    ],
  );
}
