import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../../l10n/l10n.dart';
import 'flow_scaffold.dart';

/// The three pro spaces and how their onboarding introduces itself.
enum ProSpace {
  owner,
  coach,
  organizer;

  String get label => switch (this) {
    ProSpace.owner => l10n.espaceProprietaire,
    ProSpace.coach => l10n.espaceCoach,
    ProSpace.organizer => l10n.espaceOrganisateur,
  };

  Widget icon(Color color, double size) => switch (this) {
    ProSpace.owner => Icon(PhosphorIcons.storefront(), size: size, color: color),
    ProSpace.coach => SvgPicture.asset(
      MuGlyph.whistle,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
    ProSpace.organizer => Icon(PhosphorIcons.trophy(), size: size, color: color),
  };
}

/// The phone frame of the pro spaces (CLAUDE.md rule 9): the 390-wide design scales from 360 to
/// 430; on tablets the same phone layout is centred, [maxWidth] at most.
class ProPhoneFrame extends StatelessWidget {
  const ProPhoneFrame({super.key, required this.child});

  final Widget child;

  /// CLAUDE.md « Architecture »: tablets get the phone layout centred, max width 480.
  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// The phone form of the pro onboardings (OWN-01…08, COA-01/02, ORG-01), drawn wide in the
/// designs and reflowed to one column: the compact top bar (back, [flowTitle] over the space,
/// « Voir les étapes »), the step indicator « Étape n sur N · … » over a hairline, the scrolling
/// form (h1, lead, then [body]) and the sticky action bar (draft note, the XL primary action,
/// « Enregistrer et quitter »).
///
/// « Voir les étapes » opens the steps in a sheet: done steps with what was filled in (tap one to
/// go back to it), [flowMeta] and the help line.
class ProWizardScaffold extends StatelessWidget {
  ProWizardScaffold({
    super.key,
    required this.space,
    required this.flowTitle,
    required this.flowMeta,
    required this.steps,
    required this.current,
    required this.title,
    required this.lead,
    required this.body,
    required this.onBack,
    required this.onSaveAndQuit,
    required this.onContinue,
    this.onStepTap,
    String? continueLabel,
    this.continueLoading = false,
    this.savedAt,
  }) : continueLabel = continueLabel ?? l10n.continuer;

  final ProSpace space;

  /// « Mets Arena Five en ligne ».
  final String flowTitle;

  /// « 8 étapes · environ 10 min ».
  final String flowMeta;
  final List<MuWizardStep> steps;

  /// 0-based.
  final int current;
  final ValueChanged<int>? onStepTap;
  final String title;
  final String lead;
  final Widget body;
  final VoidCallback onBack;
  final VoidCallback onSaveAndQuit;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool continueLoading;

  /// Last draft save; null hides the note.
  final DateTime? savedAt;

  Future<void> _showSteps(BuildContext context) => MuBottomSheet.show<void>(
    context,
    title: flowTitle,
    height: MuSheetHeight.auto,
    child: Builder(
      builder: (sheet) {
        final c = sheet.mu;
        return Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flowMeta, style: MuType.caption.copyWith(color: c.textSecondary)),
              const SizedBox(height: MuSpace.s6),
              MuWizardStepper(
                label: l10n.etapes(space.label),
                steps: steps,
                current: current,
                onStepTap: onStepTap == null
                    ? null
                    : (i) {
                        Navigator.of(sheet).pop();
                        onStepTap!(i);
                      },
              ),
              const SizedBox(height: MuSpace.s6),
              const _HelpCard(),
            ],
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final step = steps[current];
    return Scaffold(
      backgroundColor: c.surface,
      body: ProPhoneFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: flowTitle,
              subtitle: space.label,
              onBack: onBack,
              actions: [
                MuBarAction(
                  icon: PhosphorIcons.listNumbers(),
                  label: l10n.voirLesEtapes,
                  onPressed: () => _showSteps(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, MuSpace.s4),
              child: MuStepIndicator(step: current + 1, total: steps.length, title: step.label),
            ),
            Container(height: 1, color: c.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s6, MuSpace.s4, MuSpace.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FlowTitle(title, lead: lead),
                    const SizedBox(height: MuSpace.s6),
                    body,
                  ],
                ),
              ),
            ),
            StickyActionBar(
              children: [
                if (savedAt != null) DraftSavedNote(savedAt: savedAt!),
                MuButton.primary(
                  label: continueLabel,
                  trailing: PhosphorIcons.arrowRight(),
                  size: MuButtonSize.xl,
                  fullWidth: true,
                  loading: continueLoading,
                  onPressed: onContinue,
                ),
                MuButton.tertiary(
                  label: l10n.enregistrerEtQuitter,
                  fullWidth: true,
                  onPressed: onSaveAndQuit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// « Besoin d’aide ? » and the support line, at the end of the steps sheet.
class _HelpCard extends StatelessWidget {
  const _HelpCard();

  // OWN-01 source: 2 px between the help card's lines.
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIcons.lifebuoy(), size: MuSize.iconS, color: c.textSecondary),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.besoinDAide, style: MuType.label.copyWith(color: c.text)),
                const SizedBox(height: _lineGap),
                Text(
                  l10n.appelleNousAuDuLundi,
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « Brouillon enregistré · il y a 1 min », kept current.
class DraftSavedNote extends StatefulWidget {
  const DraftSavedNote({super.key, required this.savedAt});

  final DateTime savedAt;

  @override
  State<DraftSavedNote> createState() => _DraftSavedNoteState();
}

class _DraftSavedNoteState extends State<DraftSavedNote> {
  Timer? _timer;

  static const _refresh = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_refresh, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final text = l10n.brouillonEnregistre(formatSince(widget.savedAt, DateTime.now()));
    return Semantics(
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.cloudCheck(), size: MuSize.iconXs, color: c.textSecondary),
          const SizedBox(width: MuSpace.s2),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The groups of a wizard step, stacked on the page: [children] `space-6` apart, with a hairline
/// between them when [divided] (the wide designs' white form card, reflowed for phones).
class ProFormSections extends StatelessWidget {
  const ProFormSections({super.key, required this.children, this.divided = true});

  final List<Widget> children;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0)
            divided
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: MuSpace.s6),
                    child: Container(height: 1, color: c.border),
                  )
                : const SizedBox(height: MuSpace.s6),
          child,
        ],
      ],
    );
  }
}

/// A titled group of a wizard step: h3 [title] (+ [optionalNote]), [description], its
/// [trailing] action under them, then [children] 20 apart.
class ProFormSection extends StatelessWidget {
  const ProFormSection({
    super.key,
    this.title,
    this.optionalNote,
    this.description,
    this.trailing,
    required this.children,
  });

  final String? title;

  /// « (facultatif) » after the title.
  final String? optionalNote;
  final String? description;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: title),
                  if (optionalNote != null)
                    TextSpan(
                      text: ' $optionalNote',
                      style: MuType.body.copyWith(color: c.textSecondary),
                    ),
                ],
              ),
              style: MuType.h3.copyWith(color: c.text),
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: MuSpace.s1),
            Text(description!, style: MuType.body.copyWith(color: c.textSecondary)),
          ],
          if (trailing != null) ...[
            const SizedBox(height: MuSpace.s2),
            Align(alignment: AlignmentDirectional.centerStart, child: trailing),
          ],
          const SizedBox(height: MuSpace.s5),
        ],
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const SizedBox(height: MuSpace.s5),
          child,
        ],
      ],
    );
  }
}

/// Fields one under the other, 20 apart.
class ProFieldColumn extends StatelessWidget {
  const ProFieldColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) const SizedBox(height: MuSpace.s5),
        child,
      ],
    ],
  );
}

/// A one-line extra at the end of a step (« Fermetures exceptionnelles », « Dates spéciales »):
/// a 40 icon tile, a label and its caption, then a link action with a plus.
class ProExtraRow extends StatelessWidget {
  const ProExtraRow({
    super.key,
    required this.icon,
    required this.title,
    required this.caption,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String caption;
  final String action;
  final VoidCallback onAction;

  // OWN-04 source: 40 tile; 2 px between the lines.
  static const double _tile = 40;
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: _tile,
              height: _tile,
              decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
              child: Icon(icon, size: MuSize.iconS, color: c.textSecondary),
            ),
            const SizedBox(width: MuSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MuType.label.copyWith(color: c.text)),
                  const SizedBox(height: _lineGap),
                  Text(caption, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s2),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: _tile + MuSpace.s4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.plus(), size: MuSize.iconS, color: c.text),
              const SizedBox(width: MuSpace.s2),
              MuButton.link(label: action, onPressed: onAction),
            ],
          ),
        ),
      ],
    );
  }
}

/// Toast for destinations designed in a later milestone.
void showComingSoon(BuildContext context) => MuToast.show(
  context,
  title: l10n.bientotDisponible,
  description: l10n.cetEcranArriveDansUne,
);
