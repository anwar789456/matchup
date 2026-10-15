import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/format.dart';
import 'package:matchup/features/coach_onboarding/data/coach_draft.dart';
import 'package:matchup/features/common/data/file_services.dart';
import 'package:matchup/features/organizer_onboarding/data/organizer_draft.dart';
import 'package:matchup/features/owner_onboarding/controllers/owner_controller.dart';
import 'package:matchup/features/owner_onboarding/data/owner_draft.dart';
import 'package:matchup/features/owner_onboarding/data/owner_repository.dart';
import 'package:matchup/features/owner_onboarding/screens/payout_screen.dart';
import 'package:matchup/ui/ui.dart';

void main() {
  group('format', () {
    test('hours of the day, past midnight too', () {
      expect(formatHour(8 * 60), '08h00');
      expect(formatHour(24 * 60), '00h00');
      expect(formatHour(25 * 60 + 30), '01h30');
    });

    test('time since the draft was saved', () {
      final now = DateTime(2026, 10, 14, 10);
      expect(formatSince(now.subtract(const Duration(seconds: 20)), now), 'à l’instant');
      expect(formatSince(now.subtract(const Duration(minutes: 1)), now), 'il y a 1 min');
      expect(formatSince(now.subtract(const Duration(hours: 3)), now), 'il y a 3 h');
    });

    test('« de » elides before a vowel', () {
      expect(elideDe('Arena Five SARL'), 'd’Arena Five SARL');
      expect(elideDe('Smash Padel'), 'de Smash Padel');
    });

    test('initials take the first and last word', () {
      expect(initialsOf('Tunis Padel Series'), 'TS');
      expect(initialsOf('Arena Five'), 'AF');
      expect(initialsOf('Skander T.'), 'ST');
    });

    test('file sizes in decimal units', () {
      expect(formatFileSize(410000), '410 Ko');
      expect(formatFileSize(14200000), '14,2 Mo');
      expect(formatFileSize(1887437), '1,9 Mo');
      expect(formatFileSize(10000000), '10 Mo');
    });
  });

  test('RIB groups 2-3-13-2 and keeps 20 digits', () {
    final f = RibFormatter();
    final v = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '0800601234567890123499',
        selection: TextSelection.collapsed(offset: 22),
      ),
    );
    expect(v.text, '08 006 0123456789012 34');
    expect(RibFormatter.digitsOf(v.text), '08006012345678901234');
  });

  group('owner draft', () {
    late OwnerDraft seed;
    setUp(() async => seed = await const FakeOwnerRepository().start());

    test('rail summaries read like the design', () {
      final d = seed.copyWith(reached: 8);
      expect(OwnerSteps.summary(d, 0), 'Arena Five SARL');
      expect(OwnerSteps.summary(d, 1), '12 rue Hédi Nouira, La Marsa');
      expect(OwnerSteps.summary(d, 2), '3 terrains · Football 5');
      expect(OwnerSteps.summary(d, 3), '6j/7 · 08h00–00h00');
      expect(OwnerSteps.summary(d, 4), '120 à 170 DT /h');
      expect(OwnerSteps.summary(d, 6), 'Attijari bank · •••• 12 34');
      expect(OwnerSteps.of(d, 2).map((s) => s.summary), [
        'Arena Five SARL',
        '12 rue Hédi Nouira, La Marsa',
        null,
        null,
        null,
        null,
        null,
        null,
      ]);
    });

    test('the seeded pin sits about 40 m from the address', () {
      expect(seed.pinOffsetMeters.round(), 40);
    });

    test('survives a JSON round trip', () {
      final back = OwnerDraft.fromJson(seed.toJson());
      expect(back.toJson(), seed.toJson());
      expect(back.courts, seed.courts);
      expect(back.hours, seed.hours);
    });

    test('RIB format is checked before the bank', () async {
      const repo = FakeOwnerRepository(latency: Duration.zero);
      expect((await repo.checkRib('attijari', '08006012345678901234')).valid, isTrue);
      expect((await repo.checkRib('attijari', '0800')).error, 'Le RIB compte 20 chiffres.');
    });
  });

  test('coach and organiser drafts survive a JSON round trip', () async {
    final coach = await FakeCoachRepository(now: () => DateTime(2026, 10, 14)).start();
    expect(CoachDraft.fromJson(coach.toJson()).toJson(), coach.toJson());
    expect(coach.district, 'Lac 2');

    final org = await const FakeOrganizerRepository().start();
    expect(OrganizerDraft.fromJson(org.toJson()).toJson(), org.toJson());
    expect(org.events.single.summary, 'mars 2026 · 16 équipes · Smash Padel Club');
  });

  test('the fake upload reports progress up to 1', () async {
    final steps = await const FakeUploadService(minimum: Duration(milliseconds: 300))
        .upload('photo.jpg', 0)
        .toList();
    expect(steps.last, 1);
    expect(steps, orderedEquals([...steps]..sort()));
  });

  test('a refused photo carries its long and short message', () {
    const file = MuUploadFile(
      id: 'x',
      name: 'Tribune de nuit.png',
      sizeBytes: 14200000,
      status: MuUploadStatus.error,
      error: 'Tribune de nuit.png pèse 14,2 Mo (max 10 Mo).',
      shortError: 'Fichier trop lourd',
    );
    expect(file.copyWith(progress: 0.5).shortError, 'Fichier trop lourd');
  });
}
