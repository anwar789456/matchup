import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'mu_ai_label.dart';
import 'mu_icon_button.dart';

/// Takeover.Assistant (components/Takeover.md « Assistant »): the AI assistant on mobile. A bar
/// with the 32 `ai-gradient` mark, « Assistant MatchUp » and an optional context line (« Espace
/// propriétaire · Arena Five »), close at the end; an optional [banner] under it (« Connexion
/// instable »); the [thread] (`aria-live` polite); the [composer] and its disclaimer.
class MuAssistantTakeover extends StatelessWidget {
  const MuAssistantTakeover({
    super.key,
    required this.thread,
    required this.composer,
    this.subtitle,
    this.banner,
    this.onClose,
  });

  final Widget thread;
  final Widget composer;
  final String? subtitle;
  final Widget? banner;
  final VoidCallback? onClose;

  static const double _mark = 32;

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
                padding: const EdgeInsetsDirectional.fromSTEB(
                  MuSpace.s4,
                  MuSpace.s2,
                  MuSpace.s2,
                  MuSpace.s2,
                ),
                child: Row(
                  children: [
                    const MuAiMark(size: _mark),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.aiAssistantTitle,
                              style: MuType.labelL.copyWith(color: c.text),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: MuType.caption.copyWith(color: c.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ),
                    MuIconButton(
                      icon: PhosphorIcons.x(),
                      label: l10n.aiCloseAssistant,
                      size: MuIconButtonSize.l,
                      onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ),
            ?banner,
            Expanded(child: Semantics(liveRegion: true, child: thread)),
            composer,
          ],
        ),
      ),
    );
  }
}

/// The round `ai-gradient` mark with the white sparkle (bar 32, sender 24).
class MuAiMark extends StatelessWidget {
  const MuAiMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: MuGradients.ai, shape: BoxShape.circle),
      alignment: Alignment.center,
      // On the AI gradient: white in both themes.
      child: Icon(
        PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
        size: size * 0.55,
        color: MuPalette.white,
      ),
    ),
  );
}

/// « MatchUp » + the « IA » label above each answer.
class MuAiSender extends StatelessWidget {
  const MuAiSender({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      label: l10n.aiSenderLabel,
      excludeSemantics: true,
      child: Row(
        children: [
          const MuAiMark(),
          const SizedBox(width: MuSpace.s2),
          Text(l10n.aiSender, style: MuType.label.copyWith(color: c.text)),
          const SizedBox(width: MuSpace.s2),
          MuAiLabel(size: MuAiLabelSize.s, text: l10n.aiLabelShort),
        ],
      ),
    );
  }
}

/// A message: the assistant's on `ai-soft` (start side), the player's on `surface-inverse` (end).
class MuChatBubble extends StatelessWidget {
  const MuChatBubble.ai(this.text, {super.key, this.large = false}) : mine = false;
  const MuChatBubble.mine(this.text, {super.key}) : mine = true, large = false;

  final String text;
  final bool mine;

  /// The greeting uses `body-l`.
  final bool large;

  // The bubble stops short of the far edge (Takeover.md: 88 % of the thread).
  static const double _maxShare = 0.88;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: _maxShare,
        alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Align(
          alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
            decoration: BoxDecoration(
              color: mine ? c.surfaceInverse : c.aiSoft,
              borderRadius: MuRadius.lgAll,
            ),
            child: Text(
              text,
              style: (large || mine ? MuType.bodyL : MuType.bodyL).copyWith(
                color: mine ? c.textInverse : c.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 👍 / 👎 under an answer, then the disclaimer (« L’IA peut se tromper. … »). Once voted:
/// « Merci pour ton retour · L’IA peut se tromper. »
class MuAiFeedbackRow extends StatelessWidget {
  const MuAiFeedbackRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.note,
  });

  /// true = useful, false = not, null = no vote.
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      container: true,
      label: l10n.aiFeedbackGroup,
      child: Row(
        children: [
          if (value != false)
            MuIconButton(
              icon: PhosphorIcons.thumbsUp(),
              selectedIcon: PhosphorIcons.thumbsUp(PhosphorIconsStyle.fill),
              label: l10n.aiUseful,
              size: MuIconButtonSize.s,
              pressed: value == true,
              onPressed: () => onChanged(value == true ? null : true),
            ),
          if (value != true)
            MuIconButton(
              icon: PhosphorIcons.thumbsDown(),
              selectedIcon: PhosphorIcons.thumbsDown(PhosphorIconsStyle.fill),
              label: l10n.aiNotUseful,
              size: MuIconButtonSize.s,
              pressed: value == false,
              onPressed: () => onChanged(value == false ? null : false),
            ),
          const SizedBox(width: MuSpace.s1),
          if (value == null) ...[
            Icon(PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
            const SizedBox(width: MuSpace.s1),
          ],
          Expanded(
            child: Text(
              value == null ? note : l10n.aiThanksFeedback,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The composer: a `control-xl` pill (« Demande à MatchUp… »), send (primary, disabled while
/// empty) or stop while the answer streams (« Réponse en cours… »), then the disclaimer.
class MuAssistantComposer extends StatefulWidget {
  const MuAssistantComposer({
    super.key,
    required this.onSend,
    required this.disclaimer,
    this.busy = false,
    this.onStop,
    this.controller,
  });

  final ValueChanged<String> onSend;
  final String disclaimer;
  final bool busy;
  final VoidCallback? onStop;
  final TextEditingController? controller;

  @override
  State<MuAssistantComposer> createState() => _MuAssistantComposerState();
}

class _MuAssistantComposerState extends State<MuAssistantComposer> {
  late final TextEditingController _text = widget.controller ?? TextEditingController();

  static const double _send = 40;
  static const double _edge = 1.5;

  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _text.removeListener(_changed);
    if (widget.controller == null) _text.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _text.text.trim();
    if (t.isEmpty || widget.busy) return;
    widget.onSend(t);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final empty = _text.text.trim().isEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: MuSize.controlXl),
              decoration: ShapeDecoration(
                color: c.surface,
                shape: StadiumBorder(
                  side: BorderSide(color: c.borderStrong, width: _edge),
                ),
              ),
              padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: l10n.aiYourMessage,
                      textField: true,
                      child: TextField(
                        controller: _text,
                        enabled: !widget.busy,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submit(),
                        style: MuType.bodyL.copyWith(color: c.text),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
                          filled: false,
                          hintText: widget.busy ? l10n.aiAnswering : l10n.demandeAMatchup,
                          hintStyle: MuType.bodyL.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  if (widget.busy)
                    _Round(
                      label: l10n.aiStop,
                      icon: PhosphorIcons.stop(PhosphorIconsStyle.fill),
                      filled: false,
                      onTap: widget.onStop,
                    )
                  else
                    _Round(
                      label: l10n.aiSend,
                      icon: PhosphorIcons.arrowUp(),
                      filled: !empty,
                      onTap: empty ? null : _submit,
                    ),
                ],
              ),
            ),
            const SizedBox(height: MuSpace.s2),
            Text(
              widget.disclaimer,
              textAlign: TextAlign.center,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({required this.label, required this.icon, required this.filled, this.onTap});

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: MuSize.touchTarget,
        child: Center(
          child: Material(
            color: filled ? c.primary : c.surfaceMuted,
            shape: CircleBorder(
              side: filled || enabled ? BorderSide.none : BorderSide(color: c.border),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: _MuAssistantComposerState._send,
                child: Icon(
                  icon,
                  size: MuSize.iconS,
                  color: filled ? c.onPrimary : (enabled ? c.text : c.textDisabled),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « J’ai compris » + what the assistant understood, as small input chips, then « Modifier ».
class MuAiUnderstood extends StatelessWidget {
  const MuAiUnderstood({super.key, required this.items, this.onEdit});

  final List<(IconData, String)> items;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      container: true,
      label: l10n.aiUnderstoodGroup,
      child: Wrap(
        spacing: MuSpace.s2,
        runSpacing: MuSpace.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.aiUnderstood, style: MuType.caption.copyWith(color: c.textSecondary)),
          for (final (icon, label) in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1),
              decoration: ShapeDecoration(
                color: c.surface,
                shape: StadiumBorder(side: BorderSide(color: c.border)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: MuSize.iconXs, color: c.text),
                  const SizedBox(width: MuSpace.s1),
                  Text(label, style: MuType.labelS.copyWith(color: c.text)),
                ],
              ),
            ),
          if (onEdit != null)
            InkWell(
              onTap: onEdit,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: MuSize.touchTarget),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    l10n.entEdit,
                    style: MuType.label.copyWith(
                      color: c.text,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
