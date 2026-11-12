import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/forum_models.dart';
import 'forum_format.dart';
import 'forum_markdown.dart';

/// What the author chose in FRM-03.
sealed class AlertChoice {
  const AlertChoice();
}

/// « Publier quand même »: published masked until a moderator reads it.
class PublishAnyway extends AlertChoice {
  const PublishAnyway();
}

/// « Modifier mon message » (or closed): back to the text.
class EditMessage extends AlertChoice {
  const EditMessage();
}

/// « Utiliser cette version »: the AI's calmer text replaces the message.
class UseRewrite extends AlertChoice {
  const UseRewrite(this.text);
  final String text;
}

/// FRM-03 · Message à revoir: the warning before publishing a text that may hurt — what
/// happens if published as is, the text with the hurtful words marked, the AI's calmer version
/// when there is one, then « Publier quand même » / « Modifier mon message ».
Future<AlertChoice> showModerationAlert(
  BuildContext context, {
  required String text,
  required ModerationAnalysis analysis,
  ForumAuthor? answering,
  bool post = false,
}) async {
  final choice = await MuDialog.show<AlertChoice>(
    context,
    tone: MuDialogTone.warning,
    showIcon: false,
    placement: MuDialogPlacement.bottom,
    title: l10n.forumAlerteTitre,
    consequence: l10n.forumAlerteConsequence,
    consequenceIcon: PhosphorIcons.eyeSlash(),
    content: _AlertContent(text: text, analysis: analysis, answering: answering, post: post),
    actions: [
      Builder(
        builder: (context) => MuButton.secondary(
          label: l10n.forumPublierQuandMeme,
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(const PublishAnyway()),
        ),
      ),
      Builder(
        builder: (context) => MuButton.primary(
          label: l10n.forumModifierMonMessage,
          leading: PhosphorIcons.pencilSimple(),
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(const EditMessage()),
        ),
      ),
    ],
  );
  return choice ?? const EditMessage();
}

class _AlertContent extends StatefulWidget {
  const _AlertContent({required this.text, required this.analysis, this.answering, required this.post});

  final String text;
  final ModerationAnalysis analysis;
  final ForumAuthor? answering;
  final bool post;

  @override
  State<_AlertContent> createState() => _AlertContentState();
}

class _AlertContentState extends State<_AlertContent> {
  bool _showRewrite = true;

  // FRM-03: the quoted text has a 3 px rule.
  static const double _rule = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final rewrite = widget.analysis.rewrite;
    final who = widget.answering;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.post
              ? l10n.forumTonPostPasEncorePublie
              : who != null
              ? l10n.forumTaReponseAPasEncorePubliee(who.name)
              : l10n.forumTaReponsePasEncorePubliee,
          style: MuType.caption.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: MuSpace.s2),
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s2, MuSpace.s3, MuSpace.s2),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            border: BorderDirectional(
              start: BorderSide(color: c.borderStrong, width: _rule),
            ),
          ),
          child: ForumMarkdown(widget.text, style: MuType.body, highlights: [for (final e in widget.analysis.excerpts) (e.start, e.end)]),
        ),
        if (rewrite != null && _showRewrite) ...[
          const SizedBox(height: MuSpace.s4),
          MuAiSuggestionCard(
            context: l10n.forumReformulation,
            title: l10n.forumUneVersionPlusPosee,
            content: '« $rewrite »',
            reason: who != null ? l10n.forumGardeTonConseilSansViser(firstName(who.name)) : l10n.forumGardeTonConseil,
            primary: MuAction(l10n.forumUtiliserCetteVersion, () => Navigator.of(context, rootNavigator: true).pop(UseRewrite(rewrite))),
            primaryIcon: PhosphorIcons.arrowsClockwise(),
            onFeedback: (_) {},
            onDismiss: () => setState(() => _showRewrite = false),
          ),
        ],
      ],
    );
  }
}
