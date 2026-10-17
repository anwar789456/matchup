import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../../l10n/l10n.dart';

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

/// The desktop wizard of the pro onboardings (OWN-01…08, COA-01/02, ORG-01): the dark rail
/// (space pill, title, vertical stepper, help card), the 720 main column (overline « Étape n sur
/// N · … », h1, lead, then [body]) and the sticky footer (« Retour », draft note, « Enregistrer
/// et quitter », the primary action).
///
/// Below 1200 the draft note hides; below 960 the rail gives way to a compact header with the
/// compact stepper; below 720 the field grids stack (see [ProFieldGrid]).
class ProWizardScaffold extends StatelessWidget {
  ProWizardScaffold({
    super.key,
    required this.space,
    required this.railTitle,
    required this.railMeta,
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
  final String railTitle;

  /// « 8 étapes · environ 10 min ».
  final String railMeta;
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

  // Wizard layout (OWN-01 source): rail 304; main column 720; rail hides under 960; the draft note
  // under 1200.
  static const double _rail = 304;
  static const double content = 720;
  static const double _railBreak = 960;

  String get _stepsLabel => l10n.etapes(space.label);

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final width = MediaQuery.sizeOf(context).width;
    final rail = width >= _railBreak;
    final narrow = width < MuLayout.bpMedium;
    final side = narrow ? MuSpace.s4 : MuSpace.s8;
    final step = steps[current];

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étape ${current + 1} sur ${steps.length} · ${step.label}'.toUpperCase(),
          style: MuType.overline.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: MuSpace.s2),
        Semantics(
          header: true,
          child: Text(title, style: (narrow ? MuType.h2 : MuType.h1).copyWith(color: c.text)),
        ),
        const SizedBox(height: MuSpace.s2),
        Text(lead, style: MuType.bodyL.copyWith(color: c.textSecondary)),
      ],
    );

    final main = Column(
      children: [
        if (!rail) _CompactHeader(scaffold: this, side: side),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(side, narrow ? MuSpace.s6 : MuSpace.s10, side, MuSpace.s8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: content),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: MuSpace.s6),
                    body,
                  ],
                ),
              ),
            ),
          ),
        ),
        _Footer(scaffold: this, side: side, showDraft: width >= MuLayout.bpLarge, narrow: narrow),
      ],
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rail) _Rail(scaffold: this),
            Expanded(child: main),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.scaffold});

  final ProWizardScaffold scaffold;

  static const double _logoRow = 40;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MuTheme.dark(),
      child: Builder(
        builder: (context) {
          final c = context.mu;
          return Container(
            width: ProWizardScaffold._rail,
            color: c.navBg,
            padding: const EdgeInsetsDirectional.fromSTEB(
              MuSpace.s8,
              MuSpace.s6,
              MuSpace.s6,
              MuSpace.s6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: _logoRow,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MuLogo(tone: MuLogoTone.dark),
                  ),
                ),
                const SizedBox(height: MuSpace.s5),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    MuSpace.s2,
                    MuSpace.s1,
                    MuSpace.s3,
                    MuSpace.s1,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: MuRadius.fullAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      scaffold.space.icon(c.text, MuSize.iconXs),
                      const SizedBox(width: MuSpace.s2),
                      Text(scaffold.space.label, style: MuType.labelS.copyWith(color: c.text)),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scaffold.railTitle, style: MuType.h3.copyWith(color: c.text)),
                        const SizedBox(height: MuSpace.s1),
                        Text(
                          scaffold.railMeta,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: MuSpace.s8),
                        MuWizardStepper(
                          label: scaffold._stepsLabel,
                          steps: scaffold.steps,
                          current: scaffold.current,
                          onStepTap: scaffold.onStepTap,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MuSpace.s6),
                const _HelpCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  // OWN-01 source: 2 px between the help card's lines.
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(color: c.surfaceElevated, borderRadius: MuRadius.mdAll),
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

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.scaffold, required this.side});

  final ProWizardScaffold scaffold;
  final double side;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: side, vertical: MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const MuLogo(),
              const Spacer(),
              scaffold.space.icon(c.textSecondary, MuSize.iconXs),
              const SizedBox(width: MuSpace.s2),
              Text(scaffold.space.label, style: MuType.labelS.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          MuWizardStepper(
            label: scaffold._stepsLabel,
            variant: MuStepperVariant.compact,
            steps: scaffold.steps,
            current: scaffold.current,
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.scaffold,
    required this.side,
    required this.showDraft,
    required this.narrow,
  });

  final ProWizardScaffold scaffold;
  final double side;
  final bool showDraft;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final back = MuButton.tertiary(
      label: l10n.retour,
      leading: PhosphorIcons.arrowLeft(),
      size: MuButtonSize.l,
      onPressed: scaffold.onBack,
    );
    final save = MuButton.secondary(
      label: l10n.enregistrerEtQuitter,
      size: MuButtonSize.l,
      onPressed: scaffold.onSaveAndQuit,
    );
    final next = MuButton.primary(
      label: scaffold.continueLabel,
      trailing: PhosphorIcons.arrowRight(),
      size: MuButtonSize.l,
      loading: scaffold.continueLoading,
      fullWidth: narrow,
      onPressed: scaffold.onContinue,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: side, vertical: MuSpace.s4),
      decoration: BoxDecoration(color: c.surface, boxShadow: MuElevation.of(context).level2Up),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ProWizardScaffold.content),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    next,
                    const SizedBox(height: MuSpace.s2),
                    Row(children: [back, const Spacer(), save]),
                  ],
                )
              : Row(
                  children: [
                    back,
                    Expanded(
                      child: showDraft && scaffold.savedAt != null
                          ? DraftSavedNote(savedAt: scaffold.savedAt!)
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: MuSpace.s4),
                    save,
                    const SizedBox(width: MuSpace.s4),
                    next,
                  ],
                ),
        ),
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
        mainAxisAlignment: MainAxisAlignment.end,
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
          const SizedBox(width: MuSpace.s1),
        ],
      ),
    );
  }
}

/// The white form card of a wizard step: padding 32 (16 on phones), its [children] 32 apart,
/// with a hairline between them when [divided].
class ProFormCard extends StatelessWidget {
  const ProFormCard({super.key, required this.children, this.divided = true});

  final List<Widget> children;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final narrow = MediaQuery.sizeOf(context).width < MuLayout.bpMedium;
    return Container(
      padding: EdgeInsets.all(narrow ? MuSpace.s4 : MuSpace.s8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              divided
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: MuSpace.s8),
                      child: Container(height: 1, color: c.border),
                    )
                  : const SizedBox(height: MuSpace.s8),
            child,
          ],
        ],
      ),
    );
  }
}

/// A titled group inside a [ProFormCard]: h3 [title] (+ [optionalNote]), [description], an
/// end [trailing] action, then [children] 20 apart.
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: MuSpace.s4), trailing!],
            ],
          ),
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

/// Two columns of fields (rows 20 apart, columns 16), one column below 720.
class ProFieldGrid extends StatelessWidget {
  const ProFieldGrid({super.key, required this.children});

  final List<Widget> children;

  static const double _stackBelow = 720;

  @override
  Widget build(BuildContext context) {
    final single = MediaQuery.sizeOf(context).width < _stackBelow;
    if (single) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: MuSpace.s5),
            child,
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) const SizedBox(height: MuSpace.s5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: MuSpace.s4),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
            ],
          ),
        ],
      ],
    );
  }
}

/// A one-line extra at the bottom of a form card (« Fermetures exceptionnelles », « Dates
/// spéciales »): a 40 icon tile, a label and its caption, and a link action with a plus.
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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: MuSpace.s4,
      runSpacing: MuSpace.s2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _tile,
              height: _tile,
              decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
              child: Icon(icon, size: MuSize.iconS, color: c.textSecondary),
            ),
            const SizedBox(width: MuSpace.s4),
            Flexible(
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.plus(), size: MuSize.iconS, color: c.text),
            const SizedBox(width: MuSpace.s2),
            MuButton.link(label: action, onPressed: onAction),
          ],
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
