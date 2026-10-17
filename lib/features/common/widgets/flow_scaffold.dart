import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import 'balanced_text.dart';
import '../../../l10n/l10n.dart';

/// The mobile flow layout of the auth and onboarding screens: top bar (back « Retour » + an
/// optional end action), an optional [header] under it (step indicator), the scrolling body on
/// `surface`, and the sticky bottom action bar (`elevation-2-up`) holding the XL primary action.
class FlowScaffold extends StatelessWidget {
  FlowScaffold({
    super.key,
    required this.body,
    this.onBack,
    this.topAction,
    this.header,
    this.bottomBar = const [],
    this.centerBody = false,
    this.gap = MuSpace.s6,
    String? backLabel,
  }) : backLabel = backLabel ?? l10n.retour;

  final List<Widget> body;
  final VoidCallback? onBack;

  /// Name of the back button (« Question précédente » inside the questionnaire).
  final String backLabel;
  final Widget? topAction;
  final Widget? header;
  final List<Widget> bottomBar;

  /// Centre the body vertically (confirmation screens AUTH-04, 09, 10).
  final bool centerBody;

  /// Space between body groups (`space-6`; confirmation screens use `space-8`).
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final topBar = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s2, MuSpace.s2, MuSpace.s2, 0),
        child: SizedBox(
          height: MuSize.controlL,
          child: Row(
            children: [
              if (onBack != null)
                MuIconButton(
                  icon: PhosphorIcons.arrowLeft(),
                  label: backLabel,
                  size: MuIconButtonSize.l,
                  onPressed: onBack,
                )
              else
                const SizedBox(width: MuSize.controlL),
              const Spacer(),
              ?topAction,
            ],
          ),
        ),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, child) in body.indexed) ...[
          if (i > 0) SizedBox(height: gap),
          child,
        ],
      ],
    );

    final scroll = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MuSpace.s4,
          header == null ? MuSpace.s2 : MuSpace.s6,
          MuSpace.s4,
          MuSpace.s6,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: centerBody
                ? constraints.maxHeight - (header == null ? MuSpace.s2 : MuSpace.s6) - MuSpace.s6
                : 0,
          ),
          child: centerBody ? Center(child: content) : content,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          topBar,
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, 0),
              child: header,
            ),
          Expanded(child: scroll),
          if (bottomBar.isNotEmpty) StickyActionBar(children: bottomBar),
        ],
      ),
    );
  }
}

/// The sticky bottom action bar: `surface`, `elevation-2-up`, actions `space-3` apart.
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    // Toasts stay above the sticky bar.
    return MuToastAnchor(
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surface, boxShadow: MuElevation.of(context).level2Up),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: MuSpace.s3),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) const SizedBox(height: MuSpace.s3),
                  child,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen title (`h1`) and its lead paragraph (`body-l`, `text-secondary`), `space-2` apart.
class FlowTitle extends StatelessWidget {
  const FlowTitle(this.title, {super.key, this.lead, this.leadSpan, this.centered = false});

  final String title;
  final String? lead;

  /// Rich lead (with bold values and inline links), used instead of [lead].
  final InlineSpan? leadSpan;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          // Centred titles are balanced like the designs' `text-wrap: balance`.
          child: centered
              ? BalancedText(title, style: MuType.h1.copyWith(color: c.text), textAlign: align)
              : Text(title, style: MuType.h1.copyWith(color: c.text), textAlign: align),
        ),
        if (lead != null || leadSpan != null) ...[
          const SizedBox(height: MuSpace.s2),
          if (centered && leadSpan == null)
            BalancedText(
              lead!,
              style: MuType.bodyL.copyWith(color: c.textSecondary),
              textAlign: align,
            )
          else
            Text.rich(
              leadSpan ?? TextSpan(text: lead),
              style: MuType.bodyL.copyWith(color: c.textSecondary),
              textAlign: align,
            ),
        ],
      ],
    );
  }
}
