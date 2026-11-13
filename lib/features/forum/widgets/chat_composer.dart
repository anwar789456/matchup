import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/messages_models.dart';
import '../data/voice_recorder.dart';
import 'chat_format.dart';
import 'forum_image.dart';

/// The emojis of the panel: faces, gestures, then the sports side of the app.
const chatEmojiPanel = [
  '😀', '😂', '🤣', '😅', '😊', '😍', '😎', '🤩', //
  '😉', '😜', '🤔', '😮', '😢', '😡', '🥵', '🥶', //
  '👍', '👎', '👏', '🙌', '🙏', '💪', '🤝', '✌️', //
  '❤️', '🔥', '💯', '🎉', '✅', '❌', '⏰', '📍', //
  '⚽', '🥅', '🎾', '🏀', '🏆', '🥇', '🧤', '👟', //
  '🏃', '🤾', '⛹️', '🧊', '💧', '🚗', '🍕', '☕', //
];

/// The chat's bar: « + » (photo, video, poll, match, discussion), the emoji panel, the text, and
/// « Envoyer » — or the microphone while the text is empty. Recording shows the time and the
/// voice level, with « Annuler » and « Envoyer ».
class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focus,
    required this.hint,
    required this.replyTo,
    required this.onCancelReply,
    required this.sending,
    required this.onAttach,
    required this.onSend,
    required this.onVoice,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final ChatMessage? replyTo;
  final VoidCallback onCancelReply;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final ValueChanged<VoiceClip> onVoice;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  static const int _maxLines = 5;

  /// Same limit as a forum reply.
  static const int _maxLength = 2000;
  static const int _emojiColumns = 8;

  // The panel shows 4 rows of emojis, then scrolls.
  static const double _panelHeight = MuSize.touchTarget * 4 + MuSpace.s4;

  bool _emojis = false;
  bool _recording = false;
  Duration _elapsed = Duration.zero;
  double _level = 0;
  Timer? _clock;
  StreamSubscription<double>? _levels;

  VoiceRecorder get _recorder => ref.read(voiceRecorderProvider);

  @override
  void dispose() {
    _clock?.cancel();
    _levels?.cancel();
    if (_recording) _recorder.cancel();
    super.dispose();
  }

  void _toggleEmojis() {
    setState(() => _emojis = !_emojis);
    if (_emojis) {
      widget.focus.unfocus();
    } else {
      widget.focus.requestFocus();
    }
  }

  /// Puts [emoji] where the cursor is (or at the end).
  void _insert(String emoji) {
    final c = widget.controller;
    final sel = c.selection;
    final start = sel.isValid ? sel.start : c.text.length;
    final end = sel.isValid ? sel.end : c.text.length;
    c.value = TextEditingValue(
      text: c.text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  Future<void> _record() async {
    try {
      await _recorder.start();
    } on VoiceRecordingException catch (e) {
      if (!mounted) return;
      MuToast.show(
        context,
        tone: MuToastTone.error,
        title: e.problem == VoiceProblem.permission ? l10n.msgMicroRefuse : l10n.msgVocalImpossible,
        description: e.problem == VoiceProblem.permission ? l10n.msgMicroRefuseDetail : null,
      );
      return;
    } catch (_) {
      if (mounted) MuToast.show(context, tone: MuToastTone.error, title: l10n.msgVocalImpossible);
      return;
    }
    if (!mounted) return;
    final started = DateTime.now();
    setState(() {
      _recording = true;
      _emojis = false;
      _elapsed = Duration.zero;
    });
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final e = DateTime.now().difference(started);
      setState(() => _elapsed = e);
      if (e >= DeviceVoiceRecorder.maxLength) _stop(send: true);
    });
    _levels = _recorder.level.listen((v) {
      if (mounted) setState(() => _level = v);
    });
  }

  Future<void> _stop({required bool send}) async {
    if (!_recording) return;
    _clock?.cancel();
    await _levels?.cancel();
    setState(() {
      _recording = false;
      _level = 0;
    });
    if (!send) {
      await _recorder.cancel();
      return;
    }
    final clip = await _recorder.stop();
    if (!mounted) return;
    if (clip == null) {
      MuToast.show(context, tone: MuToastTone.warning, title: l10n.msgVocalTropCourt);
      return;
    }
    widget.onVoice(clip);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final hasText = widget.controller.text.trim().isNotEmpty;
    final canSend = hasText && !widget.sending;
    return Material(
      color: c.surface,
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
        padding: EdgeInsets.fromLTRB(
          MuSpace.s2,
          MuSpace.s2,
          MuSpace.s2,
          MuSpace.s2 + (_emojis ? 0 : MediaQuery.paddingOf(context).bottom),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.replyTo != null && !_recording) _ReplyStrip(message: widget.replyTo!, onCancel: widget.onCancelReply),
            if (_recording)
              _Recording(elapsed: _elapsed, level: _level, onCancel: () => _stop(send: false), onSend: () => _stop(send: true))
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MuIconButton(icon: PhosphorIcons.plusCircle(), label: l10n.msgAjouterAuMessage, onPressed: widget.onAttach),
                  MuIconButton(
                    icon: _emojis ? PhosphorIcons.keyboard() : PhosphorIcons.smiley(),
                    label: _emojis ? l10n.msgClavier : l10n.msgEmojis,
                    pressed: _emojis,
                    onPressed: _toggleEmojis,
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: MuSize.controlL),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: MuRadius.lgAll,
                        border: Border.all(color: widget.focus.hasFocus ? c.focus : c.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focus,
                        minLines: 1,
                        maxLines: _maxLines,
                        maxLength: _maxLength,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        style: MuType.body.copyWith(color: c.text),
                        onTap: () {
                          if (_emojis) setState(() => _emojis = false);
                        },
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: widget.hint,
                          hintStyle: MuType.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  if (hasText || widget.sending)
                    MuIconButton(
                      icon: PhosphorIcons.paperPlaneRight(),
                      label: l10n.envoyer,
                      variant: MuIconButtonVariant.primary,
                      onPressed: canSend ? widget.onSend : null,
                    )
                  else
                    MuIconButton(
                      icon: PhosphorIcons.microphone(),
                      label: l10n.msgEnregistrerUnVocal,
                      variant: MuIconButtonVariant.primary,
                      onPressed: _record,
                    ),
                ],
              ),
            if (_emojis && !_recording)
              SizedBox(
                height: _panelHeight + MediaQuery.paddingOf(context).bottom,
                child: GridView.count(
                  crossAxisCount: _emojiColumns,
                  padding: EdgeInsets.only(top: MuSpace.s2, bottom: MediaQuery.paddingOf(context).bottom),
                  children: [
                    for (final e in chatEmojiPanel)
                      Semantics(
                        button: true,
                        label: l10n.msgAjouterEmoji(e),
                        excludeSemantics: true,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _insert(e),
                          child: Center(child: Text(e, style: MuType.h2)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReplyStrip extends StatelessWidget {
  const _ReplyStrip({required this.message, required this.onCancel});

  final ChatMessage message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: MuSpace.s2),
      child: Row(
        children: [
          Icon(PhosphorIcons.arrowBendUpLeft(), size: MuSize.iconXs, color: c.textSecondary),
          const SizedBox(width: MuSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.forumReponseA(message.author.name), style: MuType.labelS.copyWith(color: c.textSecondary)),
                Text(chatSummary(message), maxLines: 1, overflow: TextOverflow.ellipsis, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          MuIconButton(icon: PhosphorIcons.x(), label: l10n.annuler, size: MuIconButtonSize.s, onPressed: onCancel),
        ],
      ),
    );
  }
}

/// « Enregistrement… 0:07 » with the voice level, « Annuler » and « Envoyer ».
class _Recording extends StatelessWidget {
  const _Recording({required this.elapsed, required this.level, required this.onCancel, required this.onSend});

  final Duration elapsed;
  final double level;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  // The red dot is 10, the level bar 4 high.
  static const double _dot = 10;
  static const double _bar = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      liveRegion: true,
      label: l10n.msgEnregistrementEnCours(mediaClock(elapsed)),
      child: Row(
        children: [
          MuIconButton(icon: PhosphorIcons.trash(), label: l10n.msgAnnulerLeVocal, color: c.errorText, onPressed: onCancel),
          const SizedBox(width: MuSpace.s2),
          Container(width: _dot, height: _dot, decoration: BoxDecoration(color: c.error, shape: BoxShape.circle)),
          const SizedBox(width: MuSpace.s2),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(mediaClock(elapsed), style: MuType.numS),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.msgEnregistrement, style: MuType.caption.copyWith(color: c.textSecondary)),
                const SizedBox(height: MuSpace.s1),
                ClipRRect(
                  borderRadius: MuRadius.fullAll,
                  child: Stack(
                    children: [
                      Container(height: _bar, color: c.surfaceMuted),
                      AnimatedFractionallySizedBox(
                        duration: MuMotion.durationOf(context, MuMotion.fast),
                        widthFactor: level.clamp(0.05, 1.0),
                        child: Container(height: _bar, color: c.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s2),
          MuIconButton(icon: PhosphorIcons.paperPlaneRight(), label: l10n.msgEnvoyerLeVocal, variant: MuIconButtonVariant.primary, onPressed: onSend),
        ],
      ),
    );
  }
}
