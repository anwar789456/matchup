import '../../../theme/theme.dart';
import 'owner_draft.dart';

/// Result of the RIB check.
class RibCheck {
  const RibCheck.valid() : error = null;
  const RibCheck.invalid(this.error);

  final String? error;

  bool get valid => error == null;
}

/// The owner side of the backend.
abstract interface class OwnerRepository {
  /// What the account already knows when the wizard starts (venue name and contact from the
  /// sign-up, the owner's name).
  Future<OwnerDraft> start();

  /// Checks the RIB key against the bank. The format (20 digits) is checked on the device first.
  Future<RibCheck> checkRib(String bank, String rib);

  /// Saves the venue and starts the free trial of the chosen plan.
  Future<void> startTrial(OwnerDraft draft);
}

/// Arena Five, La Marsa — the venue of the OWN screens. The RIB key is not computed here: the
/// backend checks it with the bank.
class FakeOwnerRepository implements OwnerRepository {
  const FakeOwnerRepository({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;

  @override
  Future<OwnerDraft> start() async => const OwnerDraft(
    venueName: 'Arena Five',
    legalName: 'Arena Five SARL',
    phone: '98123456',
    email: 'contact@arenafive.tn',
    manager: 'Skander T.',
    street: '12 rue Hédi Nouira',
    postalCode: '2070',
    city: 'La Marsa',
    governorate: 'Tunis',
    latitude: 36.8805,
    longitude: 10.3215,
    access: 'Entrée côté parking, en face de la station-service.',
    courts: [
      Court(id: 'c1', name: 'Terrain 1'),
      Court(id: 'c2', name: 'Terrain 2'),
      Court(id: 'c3', name: 'Terrain 3', indoor: true),
    ],
    hours: [
      DayHours(open: false),
      DayHours(),
      DayHours(),
      DayHours(),
      DayHours(close: 25 * 60),
      DayHours(close: 25 * 60),
      DayHours(from: 9 * 60),
    ],
    prices: {
      'football-out': CourtPrice(offPeak: 120, peak: 150),
      'football-in': CourtPrice(offPeak: 140, peak: 170),
    },
    photos: [
      DraftFile(id: 'p1', name: 'Terrain 1.jpg', sizeBytes: 2400000),
      DraftFile(id: 'p2', name: 'Terrain 2.jpg', sizeBytes: 2100000),
      DraftFile(id: 'p3', name: 'Vestiaires.jpg', sizeBytes: 1800000),
      DraftFile(id: 'p4', name: 'Parking.jpg', sizeBytes: 1600000),
    ],
    holder: 'Arena Five SARL',
    bank: 'attijari',
    rib: '08006012345678901234',
    ribCertificate: DraftFile(id: 'rib', name: 'Attestation RIB.pdf', sizeBytes: 410000),
  );

  @override
  Future<RibCheck> checkRib(String bank, String rib) async {
    await Future<void>.delayed(latency);
    return RegExp(r'^\d{20}$').hasMatch(rib)
        ? const RibCheck.valid()
        : const RibCheck.invalid('Le RIB compte 20 chiffres.');
  }

  @override
  Future<void> startTrial(OwnerDraft draft) => Future<void>.delayed(latency);
}

/// The lists of the owner wizard.
abstract final class OwnerCatalog {
  static const legalForms = [
    ('sarl', 'SARL'),
    ('suarl', 'SUARL'),
    ('sa', 'SA'),
    ('pp', 'Personne physique'),
  ];

  static const governorates = ['Tunis', 'Ariana', 'Ben Arous', 'La Manouba', 'Sousse', 'Sfax'];

  static const banks = [
    ('attijari', 'Attijari bank'),
    ('biat', 'BIAT'),
    ('stb', 'STB'),
    ('bna', 'BNA'),
    ('amen', 'Amen Bank'),
    ('uib', 'UIB'),
    ('bh', 'BH Bank'),
    ('zitouna', 'Banque Zitouna'),
  ];

  static String bankName(String id) =>
      banks.where((b) => b.$1 == id).map((b) => b.$2).firstOrNull ?? '';

  static const surfaces = ['Gazon synthétique', 'Béton poreux', 'Résine', 'Parquet'];

  /// Sports a venue can list, with the team size of a game.
  static const sports = [
    (MuSport.football, 'Football 5', '10 joueurs', 10),
    (MuSport.padel, 'Padel', '4 joueurs', 4),
    (MuSport.basketball, 'Basketball 3x3', '6 joueurs', 6),
  ];

  static String sportName(MuSport s) =>
      sports.where((e) => e.$1 == s).map((e) => e.$2).firstOrNull ?? s.label;

  static int playersOf(MuSport s) =>
      sports.where((e) => e.$1 == s).map((e) => e.$4).firstOrNull ?? 10;

  /// Starter books at most this many courts.
  static const starterCourts = 2;

  static const trialDays = 14;
}
