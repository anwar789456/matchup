import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/connectivity.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../ui/ui.dart';
import '../data/forum_models.dart';

/// One row of a « Plus d’options » sheet.
class ForumMenuItem {
  const ForumMenuItem(this.icon, this.label, this.onTap, {this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

/// « Plus d’options » on a post or a reply: a short sheet of actions. The sheet closes before
/// the action runs.
Future<void> showForumMenu(BuildContext context, List<ForumMenuItem> items) async {
  final chosen = await MuBottomSheet.show<ForumMenuItem>(
    context,
    title: l10n.plusDOptions,
    height: MuSheetHeight.auto,
    child: Builder(
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            MuSettingsRow(
              title: item.label,
              icon: item.icon,
              chevron: false,
              destructive: item.destructive,
              onTap: () => Navigator.of(context, rootNavigator: true).pop(item),
            ),
        ],
      ),
    ),
  );
  chosen?.onTap();
}

/// « Enregistrer » / « Retirer des favoris » done: says so, with « Voir » to the saved list.
void showSavedToast(BuildContext context, {required bool saved}) {
  MuToast.show(
    context,
    tone: MuToastTone.success,
    title: saved ? l10n.forumAjouteAuxFavoris : l10n.forumRetireDesFavoris,
    icon: saved ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill) : PhosphorIcons.bookmarkSimple(),
    action: saved ? MuAction(l10n.forumVoir, () => context.push(Routes.forumMine)) : null,
  );
}

/// « Copier le lien »: the discussion's link, then a toast.
void copyForumLink(BuildContext context, String postId) {
  Clipboard.setData(ClipboardData(text: forumLink(postId)));
  MuToast.show(context, tone: MuToastTone.success, title: l10n.lienCopie, icon: PhosphorIcons.link());
}

/// The public link of a discussion (shared and copied).
String forumLink(String postId) => 'https://matchup.tn/communaute/$postId';

/// Shows what went wrong with a forum action as a toast: offline, a suspension, a rule.
void showForumError(BuildContext context, Object error) {
  final (title, description) = switch (error) {
    OfflineException() => (l10n.forumHorsLigne, l10n.forumHorsLigneDetail),
    ForumSuspendedException(:final until) => (l10n.forumSuspendu, l10n.forumSuspenduJusquA(formatDateTime(until))),
    ForumRuleException(:final message) => (message, null),
    _ => (l10n.forumErreur, null),
  };
  MuToast.show(context, tone: MuToastTone.error, title: title, description: description);
}
