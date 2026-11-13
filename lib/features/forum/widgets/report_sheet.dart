import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/forum_repository.dart';

/// What the member chose in FRM-05.
class ReportChoice {
  const ReportChoice({required this.reason, required this.mute, this.details});

  final ReportReason reason;
  final bool mute;
  final String? details;
}

/// FRM-05 · Signaler: the reasons, « Ne plus voir les messages de … » (on by default), the
/// anonymous note, « Annuler » / « Signaler ». Returns null when cancelled.
Future<ReportChoice?> showReportSheet(BuildContext context, {required ForumTarget target, required ForumAuthor author}) {
  final form = GlobalKey<_ReportFormState>();
  return MuBottomSheet.show<ReportChoice>(
    context,
    title: target == ForumTarget.post ? l10n.forumSignalerCePost : l10n.forumSignalerCeCommentaire,
    height: MuSheetHeight.auto,
    footer: Builder(
      builder: (context) => Row(
        children: [
          Expanded(
            child: MuButton.secondary(
              label: l10n.annuler,
              size: MuButtonSize.xl,
              fullWidth: true,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            flex: 2,
            child: MuButton.primary(
              label: l10n.forumSignaler,
              leading: PhosphorIcons.flag(),
              size: MuButtonSize.xl,
              fullWidth: true,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(form.currentState!.choice),
            ),
          ),
        ],
      ),
    ),
    child: _ReportForm(key: form, author: author),
  );
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({super.key, required this.author});

  final ForumAuthor author;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  ReportReason _reason = ReportReason.spam;
  bool _mute = true;
  final _details = TextEditingController();

  static const _detailsMax = 500;

  ReportChoice get choice => ReportChoice(
    reason: _reason,
    mute: _mute,
    details: _reason == ReportReason.other && _details.text.trim().isNotEmpty ? _details.text.trim() : null,
  );

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    // The sheet already pads its body by space-4.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuRadioGroup<ReportReason>(
          label: l10n.forumMotifDuSignalement,
          hideLabel: true,
          options: [for (final r in ReportReason.values) MuRadioOption(value: r, label: r.label)],
          value: _reason,
          onChanged: (r) => setState(() => _reason = r),
        ),
        if (_reason == ReportReason.other) ...[
          const SizedBox(height: MuSpace.s2),
          MuTextField(label: l10n.forumPrecise, controller: _details, multiline: true, minLines: 2, maxLines: 4, maxLength: _detailsMax),
        ],
        const SizedBox(height: MuSpace.s4),
        Container(
          padding: const EdgeInsets.all(MuSpace.s3),
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
          child: MuCheckbox(
            value: _mute,
            onChanged: (v) => setState(() => _mute = v ?? false),
            label: l10n.forumNePlusVoirLesMessagesDe(widget.author.name),
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(PhosphorIcons.shieldCheck(), size: MuSize.iconXs, color: c.textSecondary),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: Text(l10n.forumSignalementAnonyme, style: MuType.caption.copyWith(color: c.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s4),
      ],
    );
  }
}
