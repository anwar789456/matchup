import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity.dart';
import 'assistant_models.dart';
import 'assistant_story.dart';

/// The AI assistant. The backend will stream the model's answer; nothing here books or pays:
/// actions always come back to the screen as a card the person confirms.
abstract interface class AssistantRepository {
  /// Suggestions and « Ce que j’utilise pour te répondre » (AI-01).
  Future<AiWelcome> welcome(AssistantSpace space);

  /// The answer as it is written: what was understood, each search step, then the blocks.
  /// Throws [OfflineException] when the network drops (AI-06).
  Stream<AiAnswer> ask(String request, AssistantSpace space);
}

/// The scripted answers of [AssistantStory], one step every [step]. « Simuler hors ligne »
/// ([simulatedOfflineProvider]) makes it fail as the network would.
class FakeAssistantRepository implements AssistantRepository {
  FakeAssistantRepository({required this.offline, this.step = const Duration(milliseconds: 700)});

  final bool Function() offline;
  final Duration step;

  Future<void> _wait() async {
    await Future<void>.delayed(step);
    if (offline()) throw const OfflineException();
  }

  @override
  Future<AiWelcome> welcome(AssistantSpace space) async => AiWelcome(
    greeting: '',
    suggestions: space == AssistantSpace.owner
        ? AssistantStory.ownerSuggestions
        : AssistantStory.suggestions,
    context: space == AssistantSpace.owner
        ? AssistantStory.ownerContext
        : AssistantStory.playerContext,
  );

  @override
  Stream<AiAnswer> ask(String request, AssistantSpace space) async* {
    final s = AssistantStory.answer(request, space);
    await _wait();
    yield AiAnswer(understood: s.understood, searching: s.searching, steps: s.steps);
    for (var i = 1; i < s.steps.length; i++) {
      await _wait();
      yield AiAnswer(
        understood: s.understood,
        searching: s.searching,
        steps: s.steps,
        step: i,
        // The free court shows up once the courts are read (AI-04).
        found: i >= 1 ? s.found : null,
      );
    }
    await _wait();
    yield AiAnswer(understood: s.understood, blocks: s.blocks);
  }
}

/// How long each step takes (tests make it short).
final assistantStepProvider = Provider<Duration>((ref) => const Duration(milliseconds: 700));

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => FakeAssistantRepository(
    offline: () => ref.read(simulatedOfflineProvider),
    step: ref.watch(assistantStepProvider),
  ),
);
