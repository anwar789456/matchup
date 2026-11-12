import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../training/data/training_story.dart';
import '../coach_routes.dart';
import '../controllers/coach_providers.dart';
import '../data/coach_models.dart';
import '../data/coach_repository.dart';
import '../data/coach_story.dart';

enum _Speed { half, normal }

/// COA-11 · Retour vidéo: the student's clip with its moments, timestamped comments (add at the
/// playhead, edit, delete), the AI's moment to validate, a general message, « Demander une
/// nouvelle vidéo », and « Envoyer le retour ».
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  bool _loaded = false;
  List<VideoComment> _comments = [];
  Duration _at = CoachStory.commentDraftAt;

  /// The comment being written or edited: its moment (null: none open).
  Duration? _editingAt;
  final _draft = TextEditingController();
  final _message = TextEditingController();
  bool _aiAdded = false;
  bool _askVideo = true;
  bool _sending = false;
  _Speed _speed = _Speed.half;

  // COA-11: comments 280 characters, the message 2 000.
  static const _commentMax = 280;
  static const _messageMax = 2000;
  static const _frame = Duration(seconds: 1);

  @override
  void dispose() {
    _draft.dispose();
    _message.dispose();
    super.dispose();
  }

  void _load(CoachFeedback? sent) {
    if (_loaded) return;
    _loaded = true;
    if (sent != null) {
      _comments = [...sent.comments];
      _message.text = sent.message;
      _askVideo = sent.askNewVideo;
      _aiAdded = sent.comments.any((c) => c.fromAi);
      _editingAt = null;
    } else {
      _comments = [...CoachStory.comments];
      _message.text = CoachStory.message;
      _editingAt = CoachStory.commentDraftAt;
      _draft.text = CoachStory.commentDraft;
    }
  }

  void _seek(Duration at) => setState(() {
    const max = CoachStory.videoLength;
    _at = at < Duration.zero ? Duration.zero : (at > max ? max : at);
  });

  void _startComment() => setState(() {
    final existing = _comments.where((c) => c.at == _at).firstOrNull;
    _editingAt = _at;
    _draft.text = existing?.text ?? '';
  });

  void _saveComment() {
    final text = _draft.text.trim();
    final at = _editingAt;
    if (at == null || text.isEmpty) return;
    setState(() {
      _comments = [
        for (final c in _comments) if (c.at != at) c,
        VideoComment(at: at, text: text),
      ]..sort((a, b) => a.at.compareTo(b.at));
      _editingAt = null;
      _draft.clear();
    });
  }

  void _addAi() => setState(() {
    _aiAdded = true;
    _comments = [..._comments, CoachStory.aiMoment]..sort((a, b) => a.at.compareTo(b.at));
  });

  /// B, I and the bullet list of « Message général »: markers around the selection.
  void _format(String marker, {bool line = false}) {
    final t = _message;
    final sel = t.selection.isValid ? t.selection : TextSelection.collapsed(offset: t.text.length);
    if (line) {
      final start = t.text.lastIndexOf('\n', sel.start == 0 ? 0 : sel.start - 1) + 1;
      t.value = TextEditingValue(
        text: t.text.replaceRange(start, start, marker),
        selection: TextSelection.collapsed(offset: sel.end + marker.length),
      );
    } else {
      final picked = t.text.substring(sel.start, sel.end);
      t.value = TextEditingValue(
        text: t.text.replaceRange(sel.start, sel.end, '$marker$picked$marker'),
        selection: TextSelection.collapsed(offset: sel.end + marker.length * 2),
      );
    }
    setState(() {});
  }

  Future<void> _send(CoachStudent s) async {
    if (_editingAt != null && _draft.text.trim().isNotEmpty) _saveComment();
    setState(() => _sending = true);
    await ref
        .read(coachRepositoryProvider)
        .sendFeedback(
          CoachFeedback(
            studentId: s.id,
            comments: _comments,
            message: _message.text.trim(),
            askNewVideo: _askVideo,
            sentAt: ref.read(clockProvider)(),
          ),
        );
    ref
      ..invalidate(coachFeedbackProvider(s.id))
      ..invalidate(coachHandledProvider);
    if (!mounted) return;
    MuToast.show(context, tone: MuToastTone.success, title: l10n.coaFeedbackSentTo(s.name));
    context.canPop() ? context.pop() : context.go(CoachRoutes.student(s.id));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = ref.watch(coachStudentProvider(widget.studentId));
    final sent = ref.watch(coachFeedbackProvider(widget.studentId));
    void back() => context.canPop() ? context.pop() : context.go(CoachRoutes.student(widget.studentId));

    if (s == null || s.videoAt == null || sent.isLoading) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            MuTopAppBar.compact(title: l10n.coaFeedback, onBack: back),
            Expanded(
              child: sent.isLoading || ref.watch(coachStudentsProvider).isLoading
                  ? const Center(child: MuSpinner())
                  : Center(
                      child: MuEmptyState(
                        title: l10n.coaNoVideoToComment,
                        description: l10n.coaNoVideoToCommentText,
                        illustration: MuEmptyIllustration.results,
                      ),
                    ),
            ),
          ],
        ),
      );
    }
    _load(sent.value);
    final first = s.name.split(' ').first;
    final next = TrainingStory.programs
        .where((p) => p.id == s.programId)
        .firstOrNull
        ?.lessons
        .where((l) => l.index == s.current)
        .firstOrNull;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.coaFeedbackTo(s.name),
            subtitle: l10n.coaFeedbackLine(
              formatClock(CoachStory.videoLength),
              CoachStory.videoSession,
              s.programTitle,
            ),
            onBack: back,
            backLabel: l10n.coaBackToFile(s.name),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                _Player(
                  at: _at,
                  length: CoachStory.videoLength,
                  moments: [for (final c in _comments) c.at],
                  studentName: s.name,
                  onSeek: _seek,
                ),
                const SizedBox(height: MuSpace.s2),
                Row(
                  children: [
                    MuButton.tertiary(
                      label: l10n.coaPrevFrame,
                      leading: PhosphorIcons.skipBack(),
                      size: MuButtonSize.s,
                      onPressed: () => _seek(_at - _frame),
                    ),
                    const Spacer(),
                    MuSegmentedControl<_Speed>(
                      semanticLabel: l10n.coaSpeed,
                      size: MuSegmentedSize.s,
                      value: _speed,
                      onChanged: (v) => setState(() => _speed = v),
                      segments: const [
                        MuSegment(value: _Speed.half, label: '0,5×'),
                        MuSegment(value: _Speed.normal, label: '1×'),
                      ],
                    ),
                    const Spacer(),
                    MuButton.tertiary(
                      label: l10n.coaNextFrame,
                      trailing: PhosphorIcons.skipForward(),
                      size: MuButtonSize.s,
                      onPressed: () => _seek(_at + _frame),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(l10n.coaTimedComments, style: MuType.h3.copyWith(color: c.text)),
                      ),
                    ),
                    Text(
                      l10n.coaOnVideo(_comments.length),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                // The comments in time order, the one being written in its place.
                for (final cm in [
                  for (final x in _comments)
                    if (x.at != _editingAt) x,
                  if (_editingAt != null) VideoComment(at: _editingAt!, text: ''),
                ]..sort((a, b) => a.at.compareTo(b.at)))
                  Padding(
                    padding: const EdgeInsets.only(bottom: MuSpace.s3),
                    child: cm.at == _editingAt
                        ? _EditingComment(
                            at: _editingAt!,
                            controller: _draft,
                            maxLength: _commentMax,
                            onCancel: () => setState(() {
                              _editingAt = null;
                              _draft.clear();
                            }),
                            onSave: _saveComment,
                          )
                        : _CommentCard(
                            comment: cm,
                            onPlay: () => _seek(cm.at),
                            onEdit: () => setState(() {
                              _at = cm.at;
                              _editingAt = cm.at;
                              _draft.text = cm.text;
                            }),
                            onDelete: () =>
                                setState(() => _comments = [for (final x in _comments) if (x != cm) x]),
                          ),
                  ),
                if (_editingAt == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: MuSpace.s3),
                    child: MuButton.secondary(
                      label: l10n.coaCommentAt(formatClock(_at)),
                      leading: PhosphorIcons.plus(),
                      fullWidth: true,
                      onPressed: _startComment,
                    ),
                  ),
                if (!_aiAdded)
                  Container(
                    padding: const EdgeInsets.all(MuSpace.s3),
                    decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.mdAll),
                    child: Row(
                      children: [
                        MuAiLabel(size: MuAiLabelSize.s, onAiSurface: true),
                        const SizedBox(width: MuSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${formatClock(CoachStory.aiMoment.at)} · ${CoachStory.aiMoment.text.toLowerCase()}',
                                style: MuType.label.copyWith(color: c.text),
                              ),
                              Text(
                                l10n.coaAiMomentFrom(first),
                                style: MuType.caption.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        MuButton.secondary(
                          label: l10n.ajouter,
                          leading: PhosphorIcons.plus(),
                          size: MuButtonSize.s,
                          onPressed: _addAi,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: MuSpace.s5),
                Text(l10n.coaGeneralMessage, style: MuType.label.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: MuRadius.smAll,
                    border: Border.all(color: c.borderControl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                        child: Row(
                          children: [
                            MuIconButton(
                              icon: PhosphorIcons.textB(),
                              label: l10n.coaBold,
                              onPressed: () => _format('**'),
                            ),
                            MuIconButton(
                              icon: PhosphorIcons.textItalic(),
                              label: l10n.coaItalic,
                              onPressed: () => _format('_'),
                            ),
                            MuIconButton(
                              icon: PhosphorIcons.listBullets(),
                              label: l10n.coaBullets,
                              onPressed: () => _format('• ', line: true),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: c.border),
                      Padding(
                        padding: const EdgeInsets.all(MuSpace.s2),
                        child: MuTextField(
                          label: l10n.coaGeneralMessage,
                          hideLabel: true,
                          controller: _message,
                          multiline: true,
                          minLines: 5,
                          maxLines: 14,
                          maxLength: _messageMax,
                          helper: l10n.coaGeneralMessageHelper(first),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                MuCardSurface(
                  child: MuSwitch(
                    value: _askVideo,
                    labelAtStart: true,
                    label: l10n.coaAskNewVideo,
                    description: next == null
                        ? null
                        : l10n.coaAfterSession(next.index, next.title),
                    onChanged: (v) => setState(() => _askVideo = v),
                  ),
                ),
              ],
            ),
          ),
          StickyActionBar(
            children: [
              MuButton.primary(
                label: l10n.coaSendFeedback,
                leading: PhosphorIcons.paperPlaneRight(),
                size: MuButtonSize.xl,
                fullWidth: true,
                loading: _sending,
                onPressed: _sending || (_comments.isEmpty && _message.text.trim().isEmpty)
                    ? null
                    : () => _send(s),
              ),
              Text(
                l10n.coaStudentNotified(first),
                textAlign: TextAlign.center,
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The clip: « 0:18 / 0:42 », play, the timeline with the comments' moments (tap to seek).
class _Player extends StatelessWidget {
  const _Player({
    required this.at,
    required this.length,
    required this.moments,
    required this.studentName,
    required this.onSeek,
  });

  final Duration at;
  final Duration length;
  final List<Duration> moments;
  final String studentName;
  final ValueChanged<Duration> onSeek;

  static const double _play = 56;
  static const double _dot = 14;
  static const double _head = 24;
  static const double _track = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    double frac(Duration d) => length == Duration.zero ? 0 : d.inMilliseconds / length.inMilliseconds;
    return ClipRRect(
      borderRadius: MuRadius.mdAll,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MuCourtArt(sport: MuSport.padel, semanticLabel: l10n.coaVideoOf(studentName)),
            PositionedDirectional(
              start: MuSpace.s3,
              top: MuSpace.s3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
                decoration: ShapeDecoration(
                  color: MuPalette.ink900.withValues(alpha: 0.7),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  ltr('${formatClock(at)} / ${formatClock(length)}'),
                  style: MuType.numXs.copyWith(color: MuPalette.white),
                ),
              ),
            ),
            Center(
              child: Semantics(
                button: true,
                label: l10n.coaPlayVideo,
                excludeSemantics: true,
                child: Material(
                  color: MuPalette.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => showComingSoon(context),
                    child: SizedBox.square(
                      dimension: _play,
                      child: Icon(PhosphorIcons.play(PhosphorIconsStyle.fill), size: MuSize.iconM, color: MuPalette.ink900),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: MuSpace.s3,
              right: MuSpace.s3,
              bottom: MuSpace.s3,
              height: MuSize.touchTarget,
              child: Semantics(
                slider: true,
                label: l10n.coaPosition,
                value: l10n.coaPositionValue(formatClock(at), formatClock(length), moments.length),
                child: Directionality(
                  // A timeline runs left to right in every language.
                  textDirection: TextDirection.ltr,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final w = box.maxWidth;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => onSeek(length * (d.localPosition.dx / w).clamp(0, 1)),
                        onHorizontalDragUpdate: (d) => onSeek(length * (d.localPosition.dx / w).clamp(0, 1)),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: _track,
                              decoration: BoxDecoration(
                                color: MuPalette.white.withValues(alpha: MuOpacity.disabled),
                                borderRadius: MuRadius.fullAll,
                              ),
                            ),
                            Container(
                              width: w * frac(at),
                              height: _track,
                              decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.fullAll),
                            ),
                            for (final m in moments)
                              Positioned(
                                left: (w * frac(m) - _dot / 2).clamp(0, w - _dot),
                                child: Container(
                                  width: _dot,
                                  height: _dot,
                                  decoration: BoxDecoration(
                                    color: MuPalette.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: MuPalette.ink900, width: 2),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: (w * frac(at) - _head / 2).clamp(0, w - _head),
                              child: Container(
                                width: _head,
                                height: _head,
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: MuPalette.ink900, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

/// « ▶ 0:08 » and the comment, with its options.
class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  final VideoComment comment;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final cm = comment;
    return MuCardSurface(
      padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s3, MuSpace.s3, MuSpace.s1, MuSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimePill(at: cm.at, onTap: onPlay),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cm.fromAi) ...[
                  MuAiLabel(size: MuAiLabelSize.s),
                  const SizedBox(height: MuSpace.s1),
                ],
                Text(cm.text, style: MuType.body.copyWith(color: c.text)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.coaCommentOptions(formatClock(cm.at)),
            icon: Icon(PhosphorIcons.dotsThreeVertical(), size: MuSize.iconS, color: c.textSecondary),
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.coaEdit)),
              PopupMenuItem(value: 'delete', child: Text(l10n.coaDelete)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The comment being written at the playhead: « Ton commentaire à 0:18 », Annuler, Enregistrer.
class _EditingComment extends StatelessWidget {
  const _EditingComment({
    required this.at,
    required this.controller,
    required this.maxLength,
    required this.onCancel,
    required this.onSave,
  });

  final Duration at;
  final TextEditingController controller;
  final int maxLength;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.primary, width: _ring),
      ),
      child: MuCardSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TimePill(at: at, accent: true),
                const Spacer(),
                Text(l10n.coaCommentHere, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
            const SizedBox(height: MuSpace.s3),
            MuTextField(
              label: l10n.coaYourCommentAt(formatClock(at)),
              controller: controller,
              multiline: true,
              minLines: 2,
              maxLength: maxLength,
              autofocus: controller.text.isEmpty,
            ),
            const SizedBox(height: MuSpace.s2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MuButton.tertiary(label: l10n.annuler, size: MuButtonSize.s, onPressed: onCancel),
                const SizedBox(width: MuSpace.s2),
                MuButton.secondary(
                  label: l10n.enregistrer,
                  leading: PhosphorIcons.check(),
                  size: MuButtonSize.s,
                  onPressed: onSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// « ▶ 0:21 »: a moment of the video (Volt when it is the one being written).
class TimePill extends StatelessWidget {
  const TimePill({super.key, required this.at, this.onTap, this.accent = false});

  final Duration at;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final ink = accent ? c.onAccent : c.text;
    return Semantics(
      button: onTap != null,
      label: l10n.entReplayAt(formatClock(at)),
      excludeSemantics: true,
      child: Material(
        color: accent ? c.accent : c.surfaceMuted,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.play(PhosphorIconsStyle.fill), size: MuSize.iconXs, color: ink),
                const SizedBox(width: MuSpace.s1),
                Text(formatClock(at), style: MuType.numS.copyWith(color: ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
