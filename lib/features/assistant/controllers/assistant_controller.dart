import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../data/assistant_models.dart';
import '../data/assistant_repository.dart';

/// The conversation of one space. It stays while the app runs (« Tes conversations restent
/// privées »: nothing is stored).
@immutable
class AssistantState {
  const AssistantState({this.turns = const []});

  final List<AssistantTurn> turns;

  /// An answer is being written (the composer shows « Réponse en cours… » and stop).
  bool get busy => turns.any((t) => t is AiTurn && t.status == TurnStatus.writing);

  /// The last answer failed because the network dropped (AI-06 banner).
  bool get offline => turns.whereType<AiTurn>().lastOrNull?.offline ?? false;
}

class AssistantController extends Notifier<AssistantState> {
  AssistantController(this.space);

  final AssistantSpace space;
  StreamSubscription<AiAnswer>? _answer;
  int _id = 0;

  @override
  AssistantState build() {
    ref.onDispose(() => _answer?.cancel());
    return const AssistantState();
  }

  DateTime get _now => ref.read(clockProvider)();

  void _replace(int id, AiTurn Function(AiTurn t) change) => state = AssistantState(
    turns: [
      for (final t in state.turns)
        if (t is AiTurn && t.id == id) change(t) else t,
    ],
  );

  /// Sends [text] and streams the answer into a new turn.
  void send(String text) {
    if (state.busy) return;
    final mine = UserTurn(++_id, _now, text);
    final ai = AiTurn(++_id, _now, request: text);
    state = AssistantState(turns: [...state.turns, mine, ai]);
    _run(ai.id, text);
  }

  void _run(int id, String request) {
    _answer?.cancel();
    _answer = ref
        .read(assistantRepositoryProvider)
        .ask(request, space)
        .listen(
          (a) => _replace(id, (t) => t.copyWith(answer: a)),
          onDone: () => _replace(id, (t) => t.copyWith(status: TurnStatus.done)),
          onError: (Object e) => _replace(
            id,
            (t) => t.copyWith(status: TurnStatus.failed, offline: e is OfflineException),
          ),
          cancelOnError: true,
        );
  }

  /// « Réessayer » (AI-06): the message was kept, the answer starts again.
  void retry(int id) {
    final t = state.turns.whereType<AiTurn>().where((t) => t.id == id).firstOrNull;
    if (t == null || state.busy) return;
    _replace(id, (t) => AiTurn(t.id, _now, request: t.request));
    _run(id, t.request);
  }

  /// Stop: keeps what was written.
  void stop() {
    _answer?.cancel();
    _answer = null;
    for (final t in state.turns.whereType<AiTurn>()) {
      if (t.status == TurnStatus.writing) {
        _replace(t.id, (t) => t.copyWith(status: TurnStatus.stopped));
      }
    }
  }

  void vote(int id, bool? useful) => _replace(id, (t) => t.copyWith(feedback: () => useful));

  /// ✕ on a suggestion, « Ignorer ».
  void dismiss(int id, int block) =>
      _replace(id, (t) => t.copyWith(dismissed: {...t.dismissed, block}));

  /// A slot of AI-02 picked.
  void pickSlot(int id, int block, int slot) => _replace(id, (t) {
    final blocks = [...t.answer.blocks];
    blocks[block] = (blocks[block] as AiSlots).pick(slot);
    return t.copyWith(
      answer: AiAnswer(understood: t.answer.understood, blocks: blocks),
    );
  });

  /// « Réserver 20h00 » → AI-03: the summary to confirm. Nothing is booked yet.
  void book(AiSlots slots) {
    if (state.busy) return;
    final s = slots.slot;
    final time = formatTime(s.start);
    final mine = UserTurn(++_id, _now, l10n.aiBookAt(time));
    final ai = AiTurn(
      ++_id,
      _now,
      request: mine.text,
      status: TurnStatus.done,
      answer: AiAnswer(
        blocks: [
          AiText(
            l10n.aiConfirmText(
              s.court,
              slots.venue,
              formatDay(s.start),
              time,
              formatDT(slots.price),
              formatDT(slots.share),
            ),
          ),
          AiConfirm(slots),
        ],
      ),
    );
    state = AssistantState(turns: [...state.turns, mine, ai]);
  }
}

final assistantProvider =
    NotifierProvider.family<AssistantController, AssistantState, AssistantSpace>(
      AssistantController.new,
    );
