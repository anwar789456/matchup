import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../../l10n/l10n.dart';

/// « Bientôt disponible » for a button whose screen comes with a later milestone (CLAUDE.md
/// rule 8): notifications, wallet, checkout, the AI assistant…
void showComingSoon(BuildContext context) => MuToast.show(
  context,
  title: l10n.bientotDisponible,
  description: l10n.cetEcranArriveDansUne,
);

final _soonTitle = l10n.bientotDisponible;
final _soonText = l10n.cetEcranArriveDansUne;

/// A tab whose screens are not designed yet (Entraînement, Communauté; Mes matchs until its
/// phase): the tab's large title over the « Bientôt disponible » empty state.
class ComingSoonTab extends StatelessWidget {
  const ComingSoonTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: MuSize.appBar,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    header: true,
                    child: Text(title, style: MuType.h1.copyWith(color: c.text)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(MuSpace.s4),
                  child: MuEmptyState(
                    title: _soonTitle,
                    description: _soonText,
                    illustration: MuEmptyIllustration.programs,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A page a designed screen links to before its own phase is built (GAM-, VEN-, MAT-05, PRF-02):
/// back arrow, the page's name and « Bientôt disponible ».
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.fallback});

  final String title;

  /// Where « Retour » goes when there is no previous screen.
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: MuSize.appBar,
              child: Row(
                children: [
                  const SizedBox(width: MuSpace.s1),
                  MuIconButton(
                    icon: PhosphorIcons.arrowLeft(),
                    label: l10n.retour,
                    size: MuIconButtonSize.l,
                    onPressed: () => context.canPop() ? context.pop() : context.go(fallback),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.h3.copyWith(color: c.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s4),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(MuSpace.s4),
                  child: MuEmptyState(
                    title: _soonTitle,
                    description: _soonText,
                    illustration: MuEmptyIllustration.results,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
