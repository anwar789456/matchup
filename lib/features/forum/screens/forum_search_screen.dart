import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/forum_providers.dart';
import '../data/forum_repository.dart';
import '../widgets/forum_feed_list.dart';

/// « Rechercher dans la communauté » (FRM-01 magnifier): titles, texts and tags, most recent
/// first, as the member types.
class ForumSearchScreen extends ConsumerStatefulWidget {
  const ForumSearchScreen({super.key});

  @override
  ConsumerState<ForumSearchScreen> createState() => _ForumSearchScreenState();
}

class _ForumSearchScreenState extends ConsumerState<ForumSearchScreen> {
  String _q = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String v) {
    _debounce?.cancel();
    _debounce = Timer(MuMotion.slow, () => setState(() => _q = v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: l10n.forumRechercherDansLaCommunaute,
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.community),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s3),
              child: MuSearchField(
                label: l10n.forumRechercherDansLaCommunaute,
                placeholder: l10n.forumRechercheNPlaceholder,
                autofocus: true,
                onChanged: _changed,
                onSubmitted: (v) => setState(() => _q = v.trim()),
              ),
            ),
            Expanded(
              child: _q.length < 2
                  ? Padding(
                      padding: const EdgeInsets.all(MuSpace.s6),
                      child: MuEmptyState(compact: true, title: l10n.forumRechercheVide, description: l10n.forumRechercheVideDetail),
                    )
                  : ForumFeedList(
                      query: ForumQuery(search: _q, sort: ForumSort.recent),
                      empty: MuEmptyState(title: l10n.forumAucunResultat(_q), description: l10n.forumAucunResultatDetail),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Mes posts et favoris » (FRM-01 bookmark): the saved discussions and the member's own.
class ForumMineScreen extends ConsumerStatefulWidget {
  const ForumMineScreen({super.key});

  @override
  ConsumerState<ForumMineScreen> createState() => _ForumMineScreenState();
}

class _ForumMineScreenState extends ConsumerState<ForumMineScreen> {
  bool _saved = true;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final me = ref.watch(forumMeProvider).value;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: l10n.forumMesPostsEtFavoris,
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.community),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s3),
              child: MuSegmentedControl<bool>(
                semanticLabel: l10n.forumMesPostsEtFavoris,
                expand: true,
                segments: [
                  MuSegment(value: true, label: l10n.forumFavoris),
                  MuSegment(value: false, label: l10n.forumMesPosts),
                ],
                value: _saved,
                onChanged: (v) => setState(() => _saved = v),
              ),
            ),
            Expanded(
              child: me == null
                  ? const Center(child: MuSpinner())
                  : ForumFeedList(
                      query: _saved
                          ? const ForumQuery(savedOnly: true, sort: ForumSort.recent)
                          : ForumQuery(authorId: me.id, sort: ForumSort.recent),
                      empty: MuEmptyState(
                        title: _saved ? l10n.forumAucunFavori : l10n.forumAucunPost,
                        description: _saved ? l10n.forumAucunFavoriDetail : l10n.forumAucunPostDetail,
                        actions: [
                          if (!_saved) MuButton.primary(label: l10n.forumPoseTaQuestion, onPressed: () => context.push(Routes.forumNew)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
