import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/forum_providers.dart';
import '../data/forum_repository.dart';
import 'forum_actions.dart';
import 'forum_format.dart';
import 'moderation_alert.dart';

/// A seller's reviews, refreshed after every change in the forum.
final sellerReviewsProvider = FutureProvider.family<ForumReviews, String>((ref, sellerId) {
  ref.watch(forumChangesProvider);
  return ref.watch(forumRepositoryProvider).sellerReviews(sellerId);
});

// ── FRM-02: what is for sale ────────────────────────────────────────────────────────────────

/// Price, condition, size and city of an Équipement listing.
class ListingFields extends StatefulWidget {
  const ListingFields({super.key, required this.initial, required this.onChanged, this.priceError});

  final ForumListing? initial;
  final ValueChanged<ForumListing> onChanged;
  final String? priceError;

  @override
  State<ListingFields> createState() => _ListingFieldsState();
}

class _ListingFieldsState extends State<ListingFields> {
  late final _price = TextEditingController(text: widget.initial == null ? '' : formatAmount(widget.initial!.price).replaceAll(RegExp(r'\s'), ''));
  late final _size = TextEditingController(text: widget.initial?.size ?? '');
  late final _city = TextEditingController(text: widget.initial?.city ?? '');
  late ListingCondition _condition = widget.initial?.condition ?? ListingCondition.likeNew;

  static const int _priceMax = 8;
  static const int _sizeMax = 12;
  static const int _cityMax = 40;

  @override
  void dispose() {
    _price.dispose();
    _size.dispose();
    _city.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(
    ForumListing(
      price: double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
      condition: _condition,
      size: _size.text,
      city: _city.text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuTextField(
          label: l10n.mktPrix,
          controller: _price,
          placeholder: l10n.mktPrixPlaceholder,
          suffixText: dtUnit,
          error: widget.priceError,
          maxLength: _priceMax,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          leadingIcon: PhosphorIcons.tag(),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: MuSpace.s4),
        MuFieldLabel(label: l10n.mktEtat),
        const SizedBox(height: MuSpace.s2),
        Wrap(
          spacing: MuSpace.s2,
          runSpacing: MuSpace.s2,
          children: [
            for (final c in ListingCondition.values)
              MuChip(
                kind: MuChipKind.choice,
                label: c.label,
                selected: c == _condition,
                onSelected: (_) {
                  setState(() => _condition = c);
                  _emit();
                },
              ),
          ],
        ),
        const SizedBox(height: MuSpace.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MuTextField(
                label: l10n.mktTaille,
                controller: _size,
                optional: true,
                placeholder: l10n.mktTaillePlaceholder,
                maxLength: _sizeMax,
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: MuTextField(
                label: l10n.mktVille,
                controller: _city,
                optional: true,
                placeholder: l10n.mktVillePlaceholder,
                maxLength: _cityMax,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _emit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── The listing on a card and in FRM-04 ─────────────────────────────────────────────────────

/// « 180 DT » with the condition, size and city, « Vendu » when sold, and the seller's stars.
class ListingSummary extends StatelessWidget {
  const ListingSummary({super.key, required this.listing, this.rating, this.large = false});

  final ForumListing listing;
  final ForumRating? rating;

  /// FRM-04: the price in the large number style.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final l = listing;
    final details = [l.condition.label, if (l.size != null) l10n.mktTailleX(l.size!), ?l.city];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                formatDT(l.price),
                style: (large ? MuType.numXl : MuType.numL).copyWith(
                  color: l.sold ? c.textSecondary : c.text,
                  decoration: l.sold ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: MuSpace.s3),
            if (l.sold)
              MuStatusBadge(status: MuStatus.full, label: l10n.mktVendu, size: MuBadgeSize.s)
            else
              MuStatusBadge(status: MuStatus.confirmed, label: l10n.mktDisponible, size: MuBadgeSize.s),
          ],
        ),
        const SizedBox(height: MuSpace.s1),
        Text(details.join(' · '), style: MuType.labelS.copyWith(color: c.textSecondary)),
        if (rating != null) ...[
          const SizedBox(height: MuSpace.s1),
          MuStarRating.display(value: rating!.average, count: rating!.count, size: MuSize.iconXs),
        ],
      ],
    );
  }
}

/// A listing without photo: its sport and « Pas encore de photo ».
class ListingNoPhoto extends StatelessWidget {
  const ListingNoPhoto({super.key, this.sport});

  final MuSport? sport;

  // Same frame as one photo of the collage.
  static const double _ratio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return AspectRatio(
      aspectRatio: _ratio,
      child: ColoredBox(
        color: c.surfaceMuted,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (sport != null)
              MuSportIcon(sport!, size: MuSize.iconL)
            else
              Icon(PhosphorIcons.tShirt(), size: MuSize.iconL, color: c.textSecondary),
            const SizedBox(height: MuSpace.s2),
            Text(l10n.mktPasDePhoto, style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Avis (buyers' reviews of the seller) ────────────────────────────────────────────────────

/// « Avis sur Mariem K. »: the average in large, the stars split into bars, the reviews (stars,
/// buyer, the item, the text), and « Donner mon avis » for anyone but the seller. Kept apart
/// from the comments: no votes, no replies.
class SellerReviewsSection extends ConsumerWidget {
  const SellerReviewsSection({super.key, required this.seller, required this.postId, required this.canReview});

  final ForumAuthor seller;
  final String postId;
  final bool canReview;

  static const int _shown = 3;

  Future<void> _write(BuildContext context, WidgetRef ref, ForumReview? mine) async {
    final draft = await showReviewSheet(context, seller: seller, initial: mine);
    if (draft == null || !context.mounted) return;
    final repo = ref.read(forumRepositoryProvider);
    Future<void> save({bool confirmed = false}) async {
      try {
        if (draft.delete) {
          await repo.deleteReview(seller.id);
        } else {
          await repo.review(seller.id, draft.rating, draft.text, postId: postId, confirmed: confirmed);
        }
        ref.read(forumChangesProvider.notifier).bump();
        if (context.mounted) {
          MuToast.show(context, tone: MuToastTone.success, title: draft.delete ? l10n.mktAvisSupprime : l10n.mktMerciPourTonAvis);
        }
      } on ForumAlertException catch (e) {
        if (!context.mounted) return;
        final choice = await showModerationAlert(context, text: draft.text, analysis: e.analysis, answering: seller);
        if (choice is PublishAnyway) await save(confirmed: true);
      } catch (e) {
        if (context.mounted) showForumError(context, e);
      }
    }

    await save();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final data = ref.watch(sellerReviewsProvider(seller.id)).value;
    final now = ref.read(clockProvider)();
    return Container(
      margin: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.lgAll,
        border: Border.all(color: c.border),
      ),
      child: data == null
          ? const Center(child: MuSpinner())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.sealCheck(), size: MuSize.iconS, color: c.text),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Semantics(header: true, child: Text(l10n.mktAvisSurX(seller.name), style: MuType.h3)),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s1),
                Text(l10n.mktAvisDetail, style: MuType.caption.copyWith(color: c.textSecondary)),
                const SizedBox(height: MuSpace.s4),
                if (data.count == 0)
                  Text(l10n.mktPasEncoreDAvis, style: MuType.body.copyWith(color: c.textSecondary))
                else
                  _Summary(reviews: data),
                for (final r in data.reviews.take(_shown)) ...[
                  Divider(height: MuSpace.s6, thickness: 1, color: c.border),
                  _ReviewTile(review: r, now: now),
                ],
                if (data.reviews.length > _shown) ...[
                  const SizedBox(height: MuSpace.s2),
                  MuButton.tertiary(
                    label: l10n.mktVoirLesNAvis(data.reviews.length),
                    onPressed: () => _showAll(context, data, now),
                  ),
                ],
                if (canReview) ...[
                  const SizedBox(height: MuSpace.s4),
                  MuButton.secondary(
                    label: data.mine == null ? l10n.mktDonnerMonAvis : l10n.mktModifierMonAvis,
                    leading: PhosphorIcons.star(),
                    fullWidth: true,
                    onPressed: () => _write(context, ref, data.mine),
                  ),
                ],
              ],
            ),
    );
  }

  void _showAll(BuildContext context, ForumReviews data, DateTime now) => MuBottomSheet.show<void>(
    context,
    title: l10n.mktAvisSurX(data.seller.name),
    height: MuSheetHeight.full,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Summary(reviews: data),
          for (final r in data.reviews) ...[
            Divider(height: MuSpace.s6, thickness: 1, color: context.mu.border),
            _ReviewTile(review: r, now: now),
          ],
        ],
      ),
    ),
  );
}

/// « 4,7 » in large with its stars and count, and one bar per star.
class _Summary extends StatelessWidget {
  const _Summary({required this.reviews});

  final ForumReviews reviews;

  // The bars are 6 high.
  static const double _bar = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = reviews;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(formatLevel(r.average), style: MuType.numXl),
            MuStarRating.display(value: r.average, size: MuSize.iconXs, showValue: false),
            const SizedBox(height: MuSpace.s1),
            Text(l10n.mktNAvis(r.count), style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
        const SizedBox(width: MuSpace.s5),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < 5; i++)
                Semantics(
                  label: l10n.mktNEtoilesNAvis(5 - i, r.stars[i]),
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: MuSpace.s1 / 2),
                    child: Row(
                      children: [
                        SizedBox(width: MuSpace.s3, child: Text('${5 - i}', style: MuType.numXs.copyWith(color: c.textSecondary))),
                        const SizedBox(width: MuSpace.s2),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: MuRadius.fullAll,
                            child: Stack(
                              children: [
                                Container(height: _bar, color: c.surfaceMuted),
                                FractionallySizedBox(
                                  widthFactor: r.count == 0 ? 0 : r.stars[i] / r.count,
                                  child: Container(height: _bar, color: c.warning),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.now});

  final ForumReview review;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = review;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MuAvatar(name: r.author.name, imageUrl: r.author.imageUrl, size: MuAvatarSize.s),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.mine ? l10n.mktToiAvis(r.author.name) : r.author.name, style: MuType.labelS),
                  Text(forumTime(r.createdAt, now), style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            MuStarRating.display(value: r.rating.toDouble(), size: MuSize.iconXs, showValue: false),
          ],
        ),
        if (r.item != null) ...[
          const SizedBox(height: MuSpace.s2),
          Text(l10n.mktAAchete(r.item!), style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
        if (r.text.isNotEmpty) ...[
          const SizedBox(height: MuSpace.s1),
          Text(r.text, style: MuType.body),
        ],
        if (r.hidden) ...[
          const SizedBox(height: MuSpace.s1),
          Row(
            children: [
              Icon(PhosphorIcons.eyeSlash(), size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s1),
              Text(l10n.msgMasqueSeulToi, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ],
      ],
    );
  }
}

/// What « Donner mon avis » returns.
class ReviewDraft {
  const ReviewDraft(this.rating, this.text, {this.delete = false});
  final int rating;
  final String text;
  final bool delete;
}

/// Stars (required) and a few words (optional); « Supprimer mon avis » when editing.
Future<ReviewDraft?> showReviewSheet(BuildContext context, {required ForumAuthor seller, ForumReview? initial}) =>
    MuBottomSheet.show<ReviewDraft>(
      context,
      title: l10n.mktTonAvisSurX(seller.name),
      height: MuSheetHeight.full,
      child: _ReviewForm(initial: initial),
    );

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({this.initial});

  final ForumReview? initial;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  late int _rating = widget.initial?.rating ?? 0;
  late final _text = TextEditingController(text: widget.initial?.text ?? '');

  static const int _max = 500;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _pop([ReviewDraft? d]) => Navigator.of(context, rootNavigator: true).pop(d);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuStarRating.input(
            value: _rating.toDouble(),
            label: l10n.mktTaNote,
            words: [l10n.mktNote1, l10n.mktNote2, l10n.mktNote3, l10n.mktNote4, l10n.mktNote5],
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: MuSpace.s4),
          MuTextField(
            label: l10n.mktTonCommentaire,
            controller: _text,
            optional: true,
            multiline: true,
            minLines: 3,
            maxLines: 6,
            maxLength: _max,
            placeholder: l10n.mktTonCommentairePlaceholder,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: MuSpace.s5),
          MuButton.primary(
            label: widget.initial == null ? l10n.mktPublierMonAvis : l10n.mktEnregistrer,
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: _rating == 0 ? null : () => _pop(ReviewDraft(_rating, _text.text)),
          ),
          if (widget.initial != null) ...[
            const SizedBox(height: MuSpace.s2),
            MuButton(
              label: l10n.mktSupprimerMonAvis,
              variant: MuButtonVariant.tertiary,
              fullWidth: true,
              onPressed: () => _pop(const ReviewDraft(0, '', delete: true)),
            ),
          ],
        ],
      ),
    );
  }
}
