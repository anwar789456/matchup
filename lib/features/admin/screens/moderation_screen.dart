import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../core/search.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../controllers/admin_controller.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_widgets.dart';
import '../../../l10n/l10n.dart';

/// ADM-09 · Modération: reported contents, sorted by AI score (which never hides nor deletes
/// anything on its own), with search, type chips and the sort sheet.
class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  ModerationKind? _kind;
  String _query = '';
  ModerationSort _sort = ModerationSort.score;

  static String _sortLabel(ModerationSort s) => switch (s) {
    ModerationSort.score => l10n.scoreIaDecroissant,
    ModerationSort.recent => l10n.plusRecentsDAbord,
  };

  Future<void> _pickSort() async {
    var value = _sort;
    await MuBottomSheet.show<void>(
      context,
      title: l10n.trierLesContenus,
      height: MuSheetHeight.auto,
      footer: Builder(
        builder: (sheet) => MuButton.primary(
          label: l10n.appliquer,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () {
            setState(() => _sort = value);
            Navigator.of(sheet).pop();
          },
        ),
      ),
      child: StatefulBuilder(
        builder: (context, set) => MuRadioGroup<ModerationSort>(
          label: l10n.ordreDeLaFile,
          hideLabel: true,
          value: value,
          onChanged: (v) => set(() => value = v),
          options: [
            for (final s in ModerationSort.values) MuRadioOption(value: s, label: _sortLabel(s)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final all = ref.watch(adminModerationProvider).value;
    final items = all ?? const <ModerationItem>[];
    final q = foldAccents(_query.trim());
    final shown =
        [
          for (final m in items)
            if ((_kind == null || m.kind == _kind) &&
                (q.isEmpty || foldAccents('${m.quote} ${m.meta} ${m.type}').contains(q)))
              m,
        ]..sort(
          (a, b) => _sort == ModerationSort.score
              ? b.score.compareTo(a.score)
              : b.reported.compareTo(a.reported),
        );
    final oldest = items.isEmpty
        ? null
        : items.map((m) => m.reported).reduce((a, b) => a.isBefore(b) ? a : b);
    int count(ModerationKind k) => items.where((m) => m.kind == k).length;

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AdminHeader(
            title: l10n.moderation,
            subtitle: oldest == null
                ? l10n.aucunSignalementOuvert
                : l10n.ouvertsLePlusAncien(items.length, formatDay(oldest)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: MuSearchField<String>(
              label: l10n.rechercherUnContenu,
              placeholder: l10n.motAuteurDiscussion,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Semantics(
            container: true,
            label: l10n.typeDeContenu,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Row(
                children: [
                  for (final (k, label, n) in [
                    (null, l10n.tout, items.length),
                    (ModerationKind.comment, l10n.commentaires, count(ModerationKind.comment)),
                    (ModerationKind.post, l10n.posts, count(ModerationKind.post)),
                    (ModerationKind.review, l10n.avis, count(ModerationKind.review)),
                    (ModerationKind.profile, l10n.profils, count(ModerationKind.profile)),
                  ]) ...[
                    MuChip(
                      kind: MuChipKind.choice,
                      label: label,
                      count: n == 0 ? null : n,
                      selected: _kind == k,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                    const SizedBox(width: MuSpace.s2),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s2),
            child: SizedBox(
              height: MuSize.controlM,
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${shown.length}', style: MuType.numS),
                          const TextSpan(text: ' contenus'),
                        ],
                      ),
                      style: MuType.label.copyWith(color: c.text),
                    ),
                  ),
                  MuButton.tertiary(
                    label: _sortLabel(_sort),
                    leading: PhosphorIcons.arrowsDownUp(),
                    size: MuButtonSize.s,
                    onPressed: _pickSort,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (all == null)
                  const MuSkeleton(height: 320)
                else if (shown.isEmpty)
                  MuEmptyState(compact: true, title: l10n.aucunContenuARevoir)
                else
                  AdminList(
                    label: l10n.contenusSignales,
                    children: [
                      for (final m in shown)
                        AdminRow(
                          top: true,
                          chevron: false,
                          gap: MuSpace.s4,
                          end: AdminScore.toxicity(m.score),
                          onTap: m.reviewable
                              ? () => context.push(Routes.adminReview(m.id))
                              : () => showComingSoon(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    switch (m.kind) {
                                      ModerationKind.comment => PhosphorIcons.chatCenteredText(),
                                      ModerationKind.post => PhosphorIcons.notePencil(),
                                      ModerationKind.review => PhosphorIcons.star(),
                                      ModerationKind.profile => PhosphorIcons.userCircle(),
                                    },
                                    size: MuSize.iconXs,
                                    color: c.textSecondary,
                                  ),
                                  const SizedBox(width: MuSpace.s2 - 2),
                                  Flexible(
                                    child: Text(
                                      m.type,
                                      style: MuType.labelS.copyWith(color: c.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: MuSpace.s1),
                              Text(
                                m.quote,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: MuType.body.copyWith(color: c.text),
                              ),
                              const SizedBox(height: MuSpace.s1),
                              AdminMuted(m.meta),
                              const SizedBox(height: MuSpace.s1),
                              AdminWhy(m.why),
                            ],
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: MuSpace.s4),
                AdminMuted(
                  l10n.leScoreIaTrieLa,
                  align: TextAlign.center,
                ),
                const SizedBox(height: MuSpace.s16 + MuSpace.s10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
