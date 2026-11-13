import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart' show fileSourceProvider;
import '../controllers/forum_providers.dart';
import '../data/forum_ai.dart';
import '../data/forum_repository.dart';
import '../data/forum_text.dart';
import '../widgets/forum_actions.dart';
import '../widgets/forum_format.dart';
import '../widgets/forum_image.dart';
import '../widgets/forum_markdown.dart';
import '../widgets/listing_widgets.dart';
import '../widgets/media_picker.dart';
import '../widgets/moderation_alert.dart';

/// FRM-02 · Nouveau post (and « Modifier » of an own post with [editId]): category and sport,
/// the title with « Discussions similaires » appearing while typing, the message editor, up to 4
/// images, tags with the AI's suggestions, the community rules, then « Aperçu » / « Publier ».
/// The draft saves itself (« Brouillon enregistré »); publishing runs the FRM-03 check.
class NewPostScreen extends ConsumerStatefulWidget {
  const NewPostScreen({super.key, this.editId});

  final String? editId;

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  final _title = TextEditingController();
  final _body = MuMarkdownController();
  PostDraft _draft = const PostDraft();
  bool _loaded = false;
  bool _savedDraft = false;
  bool _publishing = false;
  bool _showSimilar = true;
  bool _showAiTags = true;
  String? _titleError;
  String? _bodyError;
  String? _priceError;
  List<SimilarPost> _similar = const [];
  List<TagSuggestion> _aiTags = const [];
  Timer? _debounce;

  static const _maxTitle = 120;
  static const _maxBody = 2000;
  static const _minTitle = 10;
  /// Photos and one video, shown in the feed like a social post.
  static const _maxMedia = 8;
  static const _maxTags = 5;
  static const _editorMaxLines = 10;

  /// Tags offered under the field: the forum's popular ones.
  static const _popular = ['Padel', 'Football', 'Basket', 'Bandeja', 'Technique', 'Crampons', 'Lac2', 'LaMarsa', 'Débutants bienvenus'];

  bool get _editing => widget.editId != null;
  ForumRepository get _repo => ref.read(forumRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PostDraft? start;
    if (_editing) {
      final t = await _repo.thread(widget.editId!);
      final p = t.post;
      start = PostDraft(
        category: p.category,
        sport: p.sport,
        title: p.title,
        body: p.body ?? '',
        tags: p.tags,
        images: p.images,
        listing: p.listing,
      );
    } else {
      start = await _repo.loadDraft();
    }
    if (!mounted) return;
    setState(() {
      _draft = start ?? const PostDraft();
      _title.text = _draft.title;
      _body.text = _draft.body;
      _loaded = true;
      _savedDraft = !_editing && start != null && !start.isEmpty;
    });
    _refreshAi();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _change(PostDraft d) {
    setState(() {
      _draft = d;
      _savedDraft = false;
    });
    _debounce?.cancel();
    _debounce = Timer(MuMotion.counter, () async {
      _refreshAi();
      if (_editing) return;
      if (_draft.isEmpty) {
        await _repo.clearDraft();
      } else {
        await _repo.saveDraft(_draft);
        if (mounted) setState(() => _savedDraft = true);
      }
    });
  }

  Future<void> _refreshAi() async {
    final similar = _draft.title.trim().length < _minTitle
        ? const <SimilarPost>[]
        : await _repo.similar(_draft.title, sport: _draft.sport, tags: _draft.tags, exclude: widget.editId);
    final tags = await _repo.suggestTags(_draft.title, _draft.body, _draft.tags);
    if (!mounted) return;
    setState(() {
      _similar = similar;
      _aiTags = tags;
    });
  }

  Future<void> _addImages() async {
    final added = await pickPhotos(context, ref.read(fileSourceProvider), room: _maxMedia - _draft.images.length);
    if (mounted && added.isNotEmpty) _change(_draft.copyWith(images: [..._draft.images, ...added]));
  }

  Future<void> _addVideo() async {
    if (_draft.images.length >= _maxMedia) return;
    final video = await pickVideo(context, ref.read(fileSourceProvider));
    if (mounted && video != null) _change(_draft.copyWith(images: [..._draft.images, video]));
  }

  bool get _selling => _draft.listing != null;

  /// Équipement starts as an item for sale; another category is a discussion.
  void _category(ForumCategory cat) => _change(
    _draft.copyWith(
      category: cat,
      listing: () => cat == ForumCategory.equipment ? (_draft.listing ?? const ForumListing(price: 0, condition: ListingCondition.likeNew)) : null,
    ),
  );

  bool _validate() {
    final title = _draft.title.trim();
    setState(() {
      _titleError = title.length < _minTitle ? l10n.forumTitreTropCourt : null;
      _bodyError = _draft.body.trim().isEmpty
          ? l10n.forumMessageVide
          : (_draft.body.characters.length > _maxBody ? l10n.forumRetireNCaracteres(_draft.body.characters.length - _maxBody) : null);
      _priceError = _selling && _draft.listing!.price <= 0 ? l10n.mktIndiqueUnPrix : null;
    });
    return _titleError == null && _bodyError == null && _priceError == null;
  }

  Future<void> _publish({bool confirmed = false}) async {
    if (_publishing || !_validate()) return;
    setState(() => _publishing = true);
    try {
      final post = _editing
          ? await _repo.editPost(widget.editId!, _draft, confirmed: confirmed)
          : await _repo.publish(_draft, confirmed: confirmed);
      if (!_editing) await _repo.clearDraft();
      ref.invalidate(forumFeedProvider);
      ref.invalidate(forumCategoriesProvider);
      if (_editing) ref.invalidate(forumThreadProvider(post.id));
      if (!mounted) return;
      MuToast.show(
        context,
        tone: post.hidden ? MuToastTone.info : MuToastTone.success,
        title: post.hidden ? l10n.forumPostPublieMasque : (_editing ? l10n.forumPostModifie : l10n.forumPostPublie),
      );
      if (_editing) {
        context.pop();
      } else {
        context.pushReplacement(Routes.forumPost(post.id));
      }
      return;
    } on ForumAlertException catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      final choice = await showModerationAlert(context, text: '${_draft.title}\n\n${_draft.body}', analysis: e.analysis, post: true);
      if (!mounted) return;
      switch (choice) {
        case PublishAnyway():
          await _publish(confirmed: true);
        case UseRewrite(:final text):
          _body.text = text;
          _change(_draft.copyWith(body: text));
        case EditMessage():
          break;
      }
      return;
    } catch (e) {
      if (mounted) showForumError(context, e);
    }
    if (mounted) setState(() => _publishing = false);
  }

  Future<void> _preview() async {
    final me = await ref.read(forumMeProvider.future);
    if (!mounted) return;
    final now = ref.read(clockProvider)();
    await MuBottomSheet.show<void>(
      context,
      title: l10n.forumApercu,
      height: MuSheetHeight.full,
      snapPoints: const [MuSheetHeight.full],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuForumPostCard(
              post: forumCardData(
                ForumPost(
                  id: '',
                  author: me,
                  title: _draft.title.isEmpty ? l10n.forumTitre : _draft.title,
                  excerpt: ForumText.excerpt(_draft.body),
                  category: _draft.category,
                  sport: _draft.sport,
                  tags: _draft.tags,
                  createdAt: now,
                  lastActivity: now,
                  listing: _draft.listing,
                ),
                now,
              ),
              header: _draft.listing == null ? null : ListingSummary(listing: _draft.listing!),
              media: _draft.images.isEmpty ? null : ForumMediaCollage(media: _draft.images, radius: BorderRadius.zero),
            ),
            const SizedBox(height: MuSpace.s5),
            Text(_draft.title, style: MuType.h2),
            const SizedBox(height: MuSpace.s3),
            ForumMarkdown(_draft.body),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final aiTags = [
      for (final s in _aiTags)
        if (!_draft.tags.any((t) => t.toLowerCase() == s.tag.toLowerCase())) s,
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(editing: _editing, saved: _savedDraft, onClose: () => context.canPop() ? context.pop() : context.go(Routes.community)),
            Expanded(
              child: !_loaded
                  ? const Center(child: MuSpinner())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s8),
                      children: [
                        MuFieldLabel(label: l10n.forumCategorieEtSport),
                        const SizedBox(height: MuSpace.s2),
                        _ChipRow(
                          label: l10n.forumCategorieDuPost,
                          children: [
                            for (final cat in ForumCategory.values)
                              MuChip(
                                kind: MuChipKind.choice,
                                label: cat.label,
                                icon: cat.icon,
                                glyph: cat.glyph,
                                selected: _draft.category == cat,
                                onSelected: (_) => _category(cat),
                              ),
                          ],
                        ),
                        _ChipRow(
                          label: l10n.forumSportDuPost,
                          children: [
                            for (final s in const [MuSport.padel, MuSport.football, MuSport.basketball])
                              MuChip(
                                kind: MuChipKind.choice,
                                label: s.label,
                                glyph: s.asset,
                                selected: _draft.sport == s,
                                onSelected: (_) => _change(_draft.copyWith(sport: () => s)),
                              ),
                            MuChip(
                              kind: MuChipKind.choice,
                              label: l10n.forumTousLesSports,
                              selected: _draft.sport == null,
                              onSelected: (_) => _change(_draft.copyWith(sport: () => null)),
                            ),
                          ],
                        ),
                        if (_draft.category == ForumCategory.equipment) ...[
                          const SizedBox(height: MuSpace.s2),
                          MuSwitch(
                            label: l10n.mktJeVendsUnArticle,
                            description: l10n.mktJeVendsUnArticleDetail,
                            icon: PhosphorIcons.storefront(),
                            value: _selling,
                            onChanged: (on) => _change(
                              _draft.copyWith(listing: () => on ? const ForumListing(price: 0, condition: ListingCondition.likeNew) : null),
                            ),
                          ),
                          if (_selling) ...[
                            const SizedBox(height: MuSpace.s3),
                            ListingFields(
                              initial: _draft.listing!.price > 0 ? _draft.listing : null,
                              priceError: _priceError,
                              onChanged: (l) {
                                if (_priceError != null && l.price > 0) setState(() => _priceError = null);
                                _change(_draft.copyWith(listing: () => l));
                              },
                            ),
                          ],
                        ],
                        const SizedBox(height: MuSpace.s4),
                        MuTextField(
                          label: _selling ? l10n.mktCeQueTuVends : l10n.forumTitre,
                          controller: _title,
                          maxLength: _maxTitle,
                          placeholder: _selling ? l10n.mktTitrePlaceholder : l10n.forumTitrePlaceholder,
                          error: _titleError,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (v) {
                            if (_titleError != null && v.trim().length >= _minTitle) setState(() => _titleError = null);
                            _change(_draft.copyWith(title: v));
                          },
                        ),
                        if (_showSimilar && _similar.isNotEmpty) ...[
                          const SizedBox(height: MuSpace.s3),
                          _Similar(posts: _similar, onClose: () => setState(() => _showSimilar = false)),
                        ],
                        const SizedBox(height: MuSpace.s5),
                        MuRichTextEditor(
                          label: _selling ? l10n.mktDescription : l10n.forumMessage,
                          controller: _body,
                          maxLength: _maxBody,
                          maxLines: _editorMaxLines,
                          helper: l10n.forumMessageHelper,
                          error: _bodyError,
                          tools: const [
                            MuRichTool.bold,
                            MuRichTool.italic,
                            MuRichTool.bulletList,
                            MuRichTool.numberedList,
                            MuRichTool.quote,
                            MuRichTool.link,
                            MuRichTool.image,
                          ],
                          onInsertImage: _addImages,
                          onChanged: (v) {
                            if (_bodyError != null && v.trim().isNotEmpty) setState(() => _bodyError = null);
                            _change(_draft.copyWith(body: v));
                          },
                        ),
                        const SizedBox(height: MuSpace.s5),
                        MediaPickerField(
                          label: l10n.mediaPhotosEtVideo,
                          helper: _selling ? l10n.mktPhotosAide : l10n.mediaPhotosEtVideoAide,
                          media: _draft.images,
                          max: _maxMedia,
                          onAddPhotos: _addImages,
                          onAddVideo: _addVideo,
                          onRemove: (i) => _change(_draft.copyWith(images: [..._draft.images]..removeAt(i))),
                        ),
                        const SizedBox(height: MuSpace.s5),
                        MuTagInput(
                          label: l10n.forumTags,
                          tags: _draft.tags,
                          max: _maxTags,
                          placeholder: l10n.forumTagsPlaceholder,
                          helper: l10n.forumTagsHelper,
                          suggestions: _popular,
                          onChanged: (t) => _change(_draft.copyWith(tags: ForumAi.cleanTags(t, max: _maxTags))),
                        ),
                        if (_showAiTags && aiTags.isNotEmpty && _draft.tags.length < _maxTags) ...[
                          const SizedBox(height: MuSpace.s3),
                          _AiTags(
                            tags: aiTags,
                            onAdd: (t) => _change(_draft.copyWith(tags: ForumAi.cleanTags([..._draft.tags, t], max: _maxTags))),
                            onClose: () => setState(() => _showAiTags = false),
                          ),
                        ],
                        const SizedBox(height: MuSpace.s4),
                        const _Rules(),
                      ],
                    ),
            ),
            _Footer(publishing: _publishing, editing: _editing, onPreview: _loaded ? _preview : null, onPublish: _loaded ? _publish : null),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.editing, required this.saved, required this.onClose});

  final bool editing;
  final bool saved;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return SizedBox(
      height: MuSize.appBar,
      child: Row(
        children: [
          const SizedBox(width: MuSpace.s1),
          MuIconButton(icon: PhosphorIcons.x(), label: l10n.forumFermerSansPublier, onPressed: onClose),
          const SizedBox(width: MuSpace.s1),
          Expanded(
            child: Semantics(header: true, child: Text(editing ? l10n.forumModifierLePost : l10n.forumNouveauPost, style: MuType.h3)),
          ),
          AnimatedOpacity(
            opacity: saved ? 1 : 0,
            duration: MuMotion.durationOf(context, MuMotion.base),
            child: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(PhosphorIcons.checkCircle(), size: MuSize.iconXs, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s1),
                  Text(l10n.forumBrouillonEnregistre, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: MuSpace.s4),
        ],
      ),
    );
  }
}

/// A horizontal row of choice chips that scrolls.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: SizedBox(
      height: MuSize.touchTarget + MuSpace.s1,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(width: MuSpace.s2), Center(child: child)],
        ],
      ),
    ),
  );
}

/// « Discussions similaires · Ta question a peut-être déjà des réponses. »
class _Similar extends ConsumerWidget {
  const _Similar({required this.posts, required this.onClose});

  final List<SimilarPost> posts;
  final VoidCallback onClose;

  // FRM-02: the panel's icon disc is 32.
  static const double _disc = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final now = ref.read(clockProvider)();
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: MuRadius.mdAll,
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.fromLTRB(MuSpace.s3, MuSpace.s3, MuSpace.s1, MuSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _disc,
                  height: _disc,
                  child: Icon(PhosphorIcons.chatsCircle(), size: MuSize.iconS, color: c.text),
                ),
                const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.forumDiscussionsSimilaires, style: MuType.label),
                      Text(l10n.forumTaQuestionADejaDesReponses, style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                MuIconButton(
                  icon: PhosphorIcons.x(),
                  label: l10n.forumMasquerLesDiscussionsSimilaires,
                  size: MuIconButtonSize.s,
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            for (final s in posts)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: MuSpace.s2, top: MuSpace.s2),
                child: MuForumPostCard(
                  variant: MuCardVariant.compact,
                  post: forumCardData(s.post, now),
                  onTap: () => context.push(Routes.forumPost(s.post.id)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// « ✦ Suggérés par l’IA · D’après ton titre et ton texte » and the « + Technique » chips.
class _AiTags extends StatelessWidget {
  const _AiTags({required this.tags, required this.onAdd, required this.onClose});

  final List<TagSuggestion> tags;
  final ValueChanged<String> onAdd;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MuAiLabel(variant: MuAiLabelVariant.inline, size: MuAiLabelSize.s, text: l10n.forumSuggeresParLIa),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: Text(l10n.forumDApresTonTitreEtTonTexte, style: MuType.caption.copyWith(color: c.textSecondary)),
            ),
            MuIconButton(icon: PhosphorIcons.x(), label: l10n.forumMasquerLesSuggestions, size: MuIconButtonSize.s, onPressed: onClose),
          ],
        ),
        Wrap(
          spacing: MuSpace.s2,
          runSpacing: MuSpace.s2,
          children: [
            for (final t in tags)
              Semantics(
                button: true,
                label: l10n.forumAjouterLeTag(t.tag),
                excludeSemantics: true,
                child: Tooltip(
                  message: l10n.forumDApres(t.reason),
                  child: Material(
                    color: c.aiSoft,
                    shape: StadiumBorder(side: BorderSide(color: c.aiText)),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => onAdd(t.tag),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s1 + MuSpace.s1 / 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIcons.plus(), size: MuSize.iconXs, color: c.aiText),
                            const SizedBox(width: MuSpace.s1),
                            Text(t.tag, style: MuType.label.copyWith(color: c.aiText)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// « Respecte les règles de la communauté : pas d’insultes, pas de pub. » — one sentence, the
/// rules link underlined in it.
class _Rules extends StatefulWidget {
  const _Rules();

  @override
  State<_Rules> createState() => _RulesState();
}

class _RulesState extends State<_Rules> {
  late final _tap = TapGestureRecognizer()..onTap = () => _showRules(context);

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(PhosphorIcons.shieldCheck(), size: MuSize.iconXs, color: c.textSecondary),
        const SizedBox(width: MuSpace.s2),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: caption,
              children: [
                TextSpan(text: '${l10n.forumRespecteLes} '),
                TextSpan(
                  text: l10n.forumReglesDeLaCommunaute,
                  recognizer: _tap,
                  style: caption.copyWith(color: c.text, decoration: TextDecoration.underline, decorationColor: c.text),
                ),
                TextSpan(text: l10n.forumReglesSuite),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showRules(BuildContext context) => MuBottomSheet.show<void>(
  context,
  title: l10n.forumReglesTitre,
  child: Padding(
    padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s6),
    child: ForumMarkdown(l10n.forumReglesTexte, style: MuType.body),
  ),
);

class _Footer extends StatelessWidget {
  const _Footer({required this.publishing, required this.editing, required this.onPreview, required this.onPublish});

  final bool publishing;
  final bool editing;
  final VoidCallback? onPreview;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: MuButton.secondary(label: l10n.forumApercu, size: MuButtonSize.xl, fullWidth: true, onPressed: onPreview),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            flex: 2,
            child: MuButton.primary(
              label: editing ? l10n.enregistrer : l10n.forumPublier,
              leading: PhosphorIcons.paperPlaneRight(),
              size: MuButtonSize.xl,
              fullWidth: true,
              loading: publishing,
              onPressed: publishing ? null : onPublish,
            ),
          ),
        ],
      ),
    );
  }
}
