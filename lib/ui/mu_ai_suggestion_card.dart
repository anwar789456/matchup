import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_ai_label.dart';
import 'mu_banner.dart' show MuAction;
import 'mu_button.dart';
import 'mu_icon_button.dart';

/// AiSuggestionCard (components/AiSuggestionCard.md): an AI suggestion with its « IA » mark,
/// a reason (« Basé sur … »), thumbs feedback and up to two actions. Dismissing collapses it to a
/// « Suggestion masquée » row with « Annuler ». The AI never acts without the person's tap.
///
/// The compact (media) variant comes with the Home feed.
class MuAiSuggestionCard extends StatefulWidget {
  const MuAiSuggestionCard({
    super.key,
    required this.context,
    required this.title,
    required this.reason,
    this.reasonLead = 'Recommandé car',
    this.content,
    this.body,
    this.primary,
    this.secondary,
    this.primaryIcon,
    this.onFeedback,
    this.onDismiss,
    this.secondaryDismisses = false,
  });

  /// Header line (« Assistant programme »).
  final String context;
  final String title;
  final String? content;

  /// Rich content under the title (SUB-07: the offer's price).
  final Widget? body;
  final String reasonLead;
  final String reason;
  final MuAction? primary;
  final IconData? primaryIcon;
  final MuAction? secondary;

  /// true = useful, false = not useful, null = vote withdrawn.
  final ValueChanged<bool?>? onFeedback;
  final VoidCallback? onDismiss;

  /// « Plus tard » also hides the card (with « Annuler » to bring it back).
  final bool secondaryDismisses;

  @override
  State<MuAiSuggestionCard> createState() => _MuAiSuggestionCardState();
}

class _MuAiSuggestionCardState extends State<MuAiSuggestionCard> {
  bool? _vote;
  bool _dismissed = false;

  // AiSuggestionCard.md: 1,5 px AI-gradient edge; lightbulb 18.
  static const double _edge = 1.5;
  static const double _bulb = 18;

  void _setVote(bool v) {
    setState(() => _vote = _vote == v ? null : v);
    widget.onFeedback?.call(_vote);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final duration = MuMotion.durationOf(context, MuMotion.base);
    return AnimatedSwitcher(
      duration: duration,
      child: _dismissed ? _dismissedRow(c) : _card(c),
    );
  }

  Widget _dismissedRow(MuColors c) {
    return Container(
      key: const ValueKey('dismissed'),
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s2),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.borderStrong),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.eyeSlash(), size: MuSize.iconS, color: c.textSecondary),
          const SizedBox(width: MuSpace.s2),
          Expanded(
            child: Text('Suggestion masquée', style: MuType.body.copyWith(color: c.textSecondary)),
          ),
          MuButton.tertiary(
            label: 'Annuler',
            size: MuButtonSize.s,
            onPressed: () => setState(() => _dismissed = false),
          ),
        ],
      ),
    );
  }

  Widget _card(MuColors c) {
    final thumbs = _vote == null
        ? [
            MuIconButton(
              icon: PhosphorIcons.thumbsUp(),
              label: 'Suggestion utile',
              size: MuIconButtonSize.s,
              onPressed: () => _setVote(true),
            ),
            const SizedBox(width: MuSpace.s3),
            MuIconButton(
              icon: PhosphorIcons.thumbsDown(),
              label: 'Suggestion pas utile',
              size: MuIconButtonSize.s,
              onPressed: () => _setVote(false),
            ),
          ]
        : [
            MuIconButton(
              icon: _vote! ? PhosphorIcons.thumbsUp() : PhosphorIcons.thumbsDown(),
              selectedIcon: _vote!
                  ? PhosphorIcons.thumbsUp(PhosphorIconsStyle.fill)
                  : PhosphorIcons.thumbsDown(PhosphorIconsStyle.fill),
              label: _vote! ? 'Suggestion utile' : 'Suggestion pas utile',
              size: MuIconButtonSize.s,
              pressed: true,
              onPressed: () => _setVote(_vote!),
            ),
            const SizedBox(width: MuSpace.s2),
            Flexible(
              child: Text('Merci pour ton retour',
                  style: MuType.caption.copyWith(color: c.textSecondary)),
            ),
          ];

    return Container(
      key: const ValueKey('card'),
      padding: const EdgeInsets.all(_edge),
      decoration: BoxDecoration(
        gradient: MuGradients.ai,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(MuRadius.md - _edge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const MuAiLabel(size: MuAiLabelSize.s),
                const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: Text(widget.context,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.labelS.copyWith(color: c.textSecondary)),
                ),
                if (widget.onDismiss != null)
                  MuIconButton(
                    icon: PhosphorIcons.x(),
                    label: 'Masquer la suggestion',
                    size: MuIconButtonSize.s,
                    onPressed: () {
                      setState(() => _dismissed = true);
                      widget.onDismiss!();
                    },
                  ),
              ],
            ),
            const SizedBox(height: MuSpace.s3),
            Semantics(
              header: true,
              child: Text(widget.title, style: MuType.h3.copyWith(color: c.text)),
            ),
            if (widget.content != null) ...[
              const SizedBox(height: MuSpace.s3),
              Text(widget.content!, style: MuType.body.copyWith(color: c.textSecondary)),
            ],
            if (widget.body != null) ...[const SizedBox(height: MuSpace.s3), widget.body!],
            const SizedBox(height: MuSpace.s3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
              decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.smAll),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                      size: _bulb, color: c.aiText),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '${widget.reasonLead} ', style: MuType.label),
                        TextSpan(text: widget.reason),
                      ]),
                      style: MuType.body.copyWith(color: c.aiText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MuSpace.s3),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: MuSpace.s2,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: thumbs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.secondary != null)
                      MuButton.tertiary(
                        label: widget.secondary!.label,
                        onPressed: () {
                          widget.secondary!.onPressed();
                          if (widget.secondaryDismisses) setState(() => _dismissed = true);
                        },
                      ),
                    if (widget.primary != null) ...[
                      const SizedBox(width: MuSpace.s2),
                      MuButton.secondary(
                        label: widget.primary!.label,
                        leading: widget.primaryIcon,
                        onPressed: widget.primary!.onPressed,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
