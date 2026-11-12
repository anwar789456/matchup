import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'mu_ai_label.dart';
import 'mu_ai_shimmer.dart';
import 'mu_button.dart';
import 'mu_icon_button.dart';

/// AiTextBlock (components/AiTextBlock.md): text the AI wrote, on `ai-soft`, that the person can
/// regenerate, edit, copy and rate — with the honest footnote. Below 420 wide the tools are icons.
class MuAiTextBlock extends StatefulWidget {
  const MuAiTextBlock({
    super.key,
    required this.title,
    required this.text,
    this.meta,
    this.onChanged,
    this.onRegenerate,
    this.regenerating = false,
    this.regeneratingLabel,
    this.edited = false,
    this.onFeedback,
    this.footnote,
  });

  final String title;

  /// Paragraphs split by a blank line.
  final String text;

  /// « Analysé à 18h06 · confiance moyenne ».
  final String? meta;

  /// The person's edit (« Enregistrer »); null hides « Modifier ».
  final ValueChanged<String>? onChanged;
  final VoidCallback? onRegenerate;
  final bool regenerating;
  final String? regeneratingLabel;

  /// Adds « modifié par toi » to the meta.
  final bool edited;
  final ValueChanged<bool?>? onFeedback;

  /// Overrides « L’IA peut se tromper. Vérifie les infos importantes. ».
  final String? footnote;

  @override
  State<MuAiTextBlock> createState() => _MuAiTextBlockState();
}

class _MuAiTextBlockState extends State<MuAiTextBlock> {
  bool _editing = false;
  bool _copied = false;
  bool? _liked;
  late final TextEditingController _draft = TextEditingController(
    text: widget.text,
  );

  // AiTextBlock.md: icon-only tools under 420; the footnote rule is `ai-text` at 18 %.
  static const double _compactBelow = 420;
  static const double _ruleAlpha = 0.18;
  static const double _dimmed = 0.6;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(MuMotion.success);
    if (mounted) setState(() => _copied = false);
  }

  void _rate(bool liked) {
    setState(() => _liked = _liked == liked ? null : liked);
    widget.onFeedback?.call(_liked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final paragraphs = widget.text.split(RegExp(r'\n\s*\n'));
    final meta = [
      ?widget.meta,
      if (widget.edited) l10n.entEditedByYou,
    ].join(' · ');

    Widget tool(
      String label,
      IconData icon,
      VoidCallback? onPressed, {
      required bool compact,
    }) => compact
        ? MuIconButton(
            icon: icon,
            label: label,
            size: MuIconButtonSize.s,
            onPressed: onPressed,
          )
        : MuButton.tertiary(
            label: label,
            leading: icon,
            size: MuButtonSize.s,
            onPressed: onPressed,
          );

    final body = _editing
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _draft,
                maxLines: null,
                autofocus: true,
                style: MuType.bodyL.copyWith(color: c.text),
                decoration: InputDecoration(
                  labelText: widget.title,
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: MuRadius.smAll,
                    borderSide: BorderSide(color: c.borderControl),
                  ),
                ),
              ),
              const SizedBox(height: MuSpace.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MuButton.tertiary(
                    label: l10n.annuler,
                    size: MuButtonSize.s,
                    onPressed: () => setState(() {
                      _draft.text = widget.text;
                      _editing = false;
                    }),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  MuButton.primary(
                    label: l10n.enregistrer,
                    leading: PhosphorIcons.check(PhosphorIconsStyle.bold),
                    size: MuButtonSize.s,
                    onPressed: () {
                      widget.onChanged?.call(_draft.text.trim());
                      setState(() => _editing = false);
                    },
                  ),
                ],
              ),
            ],
          )
        : Opacity(
            opacity: widget.regenerating ? _dimmed : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, p) in paragraphs.indexed) ...[
                  if (i > 0) const SizedBox(height: MuSpace.s3),
                  Text(
                    p.trim(),
                    style: MuType.bodyL.copyWith(
                      color: widget.regenerating ? c.textSecondary : c.text,
                    ),
                  ),
                ],
              ],
            ),
          );

    return Semantics(
      container: true,
      label: widget.title,
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s4),
        decoration: BoxDecoration(
          color: c.aiSoft,
          borderRadius: MuRadius.mdAll,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < _compactBelow;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    MuAiLabel(size: MuAiLabelSize.s, onAiSurface: true),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          widget.title,
                          style: MuType.label.copyWith(color: c.text),
                        ),
                      ),
                    ),
                  ],
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                const SizedBox(height: MuSpace.s3),
                body,
                if (!_editing) ...[
                  const SizedBox(height: MuSpace.s3),
                  if (widget.regenerating)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: MuAiShimmer.status(
                        label: widget.regeneratingLabel ?? l10n.entAiRewriting,
                      ),
                    )
                  else
                    Row(
                      children: [
                        if (widget.onRegenerate != null)
                          tool(
                            l10n.entRegenerate,
                            PhosphorIcons.arrowsClockwise(),
                            widget.onRegenerate,
                            compact: compact,
                          ),
                        if (widget.onChanged != null)
                          tool(
                            l10n.entEdit,
                            PhosphorIcons.pencilSimple(),
                            () => setState(() => _editing = true),
                            compact: compact,
                          ),
                        _copied
                            ? Semantics(
                                liveRegion: true,
                                label: l10n.entTextCopied,
                                excludeSemantics: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: MuSpace.s2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        PhosphorIcons.check(
                                          PhosphorIconsStyle.bold,
                                        ),
                                        size: MuSize.iconXs,
                                        color: c.successText,
                                      ),
                                      const SizedBox(width: MuSpace.s1),
                                      Text(
                                        l10n.entCopied,
                                        style: MuType.labelS.copyWith(
                                          color: c.successText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : tool(
                                l10n.entCopy,
                                PhosphorIcons.copy(),
                                _copy,
                                compact: compact,
                              ),
                        const Spacer(),
                        if (widget.onFeedback != null) ...[
                          MuIconButton(
                            icon: PhosphorIcons.thumbsUp(),
                            selectedIcon: PhosphorIcons.thumbsUp(
                              PhosphorIconsStyle.fill,
                            ),
                            label: l10n.entUseful,
                            size: MuIconButtonSize.s,
                            pressed: _liked == true,
                            onPressed: () => _rate(true),
                          ),
                          MuIconButton(
                            icon: PhosphorIcons.thumbsDown(),
                            selectedIcon: PhosphorIcons.thumbsDown(
                              PhosphorIconsStyle.fill,
                            ),
                            label: l10n.entNotUseful,
                            size: MuIconButtonSize.s,
                            pressed: _liked == false,
                            onPressed: () => _rate(false),
                          ),
                        ],
                      ],
                    ),
                  if (_liked != null)
                    Text(
                      l10n.entThanksForFeedback,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                ],
                const SizedBox(height: MuSpace.s3),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: c.aiText.withValues(alpha: _ruleAlpha),
                ),
                const SizedBox(height: MuSpace.s3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIcons.info(),
                      size: MuSize.iconXs,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        widget.footnote ?? l10n.entAiFootnote,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
