import '../../../ui/ui.dart';
import '../../../theme/theme.dart';

/// The fake data shared by every Milestone 3 screen (design/screens/STORY-DATA.md): same people,
/// venues, games and prices everywhere, around « now » = ven. 16 oct. 2026, 18h00.
abstract final class Story {
  static DateTime at(int day, int hour, [int minute = 0]) => DateTime(2026, 10, day, hour, minute);

  // ── Places ──────────────────────────────────────────────────────────────────────────────────

  /// Where Yassine is (La Marsa).
  static const me = MuLatLng(36.872, 10.312);
  static const zone = 'La Marsa';

  static const arenaFive = MuVenue(
    id: 'arena-five',
    name: 'Arena Five',
    sports: [MuSport.football],
    place: 'La Marsa',
    distanceKm: 1.4,
    rating: 4.7,
    reviews: 128,
    verified: true,
    amenities: [
      MuAmenity.lighting,
      MuAmenity.changingRooms,
      MuAmenity.showers,
      MuAmenity.parking,
      MuAmenity.cafe,
      MuAmenity.bibs,
    ],
    slots: ['19h00', '21h00', '22h00'],
    pricePerPerson: 12,
    courtPrice: 120,
    position: MuLatLng(36.8805, 10.3215),
  );

  static const smashPadel = MuVenue(
    id: 'smash-padel',
    name: 'Smash Padel Club',
    sports: [MuSport.padel],
    place: 'Lac 2',
    distanceKm: 3.1,
    rating: 4.8,
    reviews: 86,
    verified: true,
    amenities: [MuAmenity.lighting, MuAmenity.covered, MuAmenity.changingRooms, MuAmenity.parking],
    slots: ['18h30', '21h30', '23h00'],
    pricePerPerson: 20,
    courtPrice: 80,
    courtPriceUnit: '/1h30',
    position: MuLatLng(36.8455, 10.2705),
  );

  static const padelHouse = MuVenue(
    id: 'padel-house-menzah',
    name: 'Padel House Menzah',
    sports: [MuSport.padel],
    place: 'Menzah 6',
    distanceKm: 5.0,
    rating: 4.6,
    reviews: 52,
    amenities: [MuAmenity.lighting, MuAmenity.parking],
    slots: ['19h30', '22h00'],
    pricePerPerson: 18,
    position: MuLatLng(36.8445, 10.1790),
  );

  static const hoopZone = MuVenue(
    id: 'hoop-zone',
    name: 'Hoop Zone',
    sports: [MuSport.basketball],
    place: 'Ennasr',
    distanceKm: 6.2,
    rating: 4.5,
    reviews: 41,
    amenities: [MuAmenity.lighting, MuAmenity.covered, MuAmenity.cafe],
    slots: ['20h00', '21h00'],
    pricePerPerson: 9,
    courtPrice: 90,
    position: MuLatLng(36.8615, 10.1625),
  );

  static const venues = [arenaFive, smashPadel, padelHouse, hoopZone];

  /// Districts the search knows, with their venues (null: everything around the player's zone).
  static const zones = <(String, List<String>?)>[
    ('La Marsa', null),
    ('Marsa Corniche', ['arena-five']),
    ('Lac 2', ['smash-padel']),
    ('Ennasr', ['hoop-zone']),
    ('Menzah 6', ['padel-house-menzah']),
  ];

  // ── People ──────────────────────────────────────────────────────────────────────────────────

  static const skander = MuPerson('Skander T.');
  static const hamza = MuPerson('Hamza R.');
  static const nour = MuPerson('Nour A.');
  static const aziz = MuPerson('Aziz H.');
  static const omar = MuPerson('Omar D.');
  static const salma = MuPerson('Salma G.');
  static const lina = MuPerson('Lina F.');
  static const ines = MuPerson('Ines M.');
  static const mariem = MuPerson('Mariem K.');
  static const rami = MuPerson('Rami S.');
  static const yassine = MuPerson('Yassine B.');

  /// Players the search finds: name, level, place.
  static const players = [
    (name: 'Mariem K.', level: 4.0, place: 'La Marsa'),
    (name: 'Omar D.', level: 3.5, place: 'La Marsa'),
    (name: 'Skander T.', level: 4.0, place: 'La Marsa'),
    (name: 'Hamza R.', level: 3.5, place: 'Ennasr'),
    (name: 'Ines M.', level: 4.0, place: 'Lac 2'),
    (name: 'Nour A.', level: 3.0, place: 'La Marsa'),
  ];

  // ── Open games ──────────────────────────────────────────────────────────────────────────────

  /// G1, the hero lobby (GAM-01).
  static final g1 = MuGame(
    id: 'g1',
    venueId: arenaFive.id,
    sport: MuSport.football,
    venue: 'Arena Five',
    court: 'Terrain 2',
    place: 'La Marsa',
    distanceKm: 1.4,
    start: at(18, 20),
    spotsTotal: 10,
    spotsLeft: 2,
    pricePerPlayer: 15,
    levelMin: 3,
    levelMax: 4.5,
    players: const [skander, hamza, nour, aziz, omar, salma, lina, ines],
    organiser: 'Skander T.',
    organiserReliability: 96,
    matchFit: 85,
    matchFitReason: 'Milieu recherché et terrain à 1,4 km',
  );

  /// G2, padel tonight.
  static final g2 = MuGame(
    id: 'g2',
    venueId: smashPadel.id,
    sport: MuSport.padel,
    venue: 'Smash Padel Club',
    court: 'Court 3',
    place: 'Lac 2',
    distanceKm: 3.1,
    start: at(16, 20),
    dateLabel: 'Ce soir',
    spotsTotal: 4,
    spotsLeft: 2,
    pricePerPlayer: 25,
    levelMin: 3,
    levelMax: 4,
    players: const [mariem, ines],
    organiser: 'Mariem K.',
    organiserReliability: 98,
    matchFit: 92,
    matchFitReason: 'Côté gauche recherché et ton niveau (3,5)',
  );

  /// G3, basket 3x3.
  static final g3 = MuGame(
    id: 'g3',
    venueId: hoopZone.id,
    sport: MuSport.basketball,
    venue: 'Hoop Zone',
    place: 'Ennasr',
    distanceKm: 6.2,
    gameType: 'Hommes',
    start: at(17, 18),
    spotsTotal: 6,
    spotsLeft: 2,
    pricePerPlayer: 9,
    levelMin: 2.5,
    levelMax: 4,
    players: const [hamza, omar, aziz, skander],
    organiser: 'Hamza R.',
    organiserReliability: 93,
  );

  /// G4, women's 5v5, full with a waitlist.
  static final g4 = MuGame(
    id: 'g4',
    venueId: arenaFive.id,
    sport: MuSport.football,
    venue: 'Arena Five',
    court: 'Terrain 1',
    place: 'La Marsa',
    distanceKm: 1.4,
    gameType: 'Femmes',
    start: at(17, 19),
    spotsTotal: 10,
    spotsLeft: 0,
    pricePerPlayer: 12,
    levelMin: 2.5,
    levelMax: 4,
    players: const [
      MuPerson('Sarra B.'),
      MuPerson('Amel T.'),
      MuPerson('Rim H.'),
      MuPerson('Yosra M.'),
      MuPerson('Dorra K.'),
      nour,
      salma,
      lina,
      ines,
      mariem,
    ],
    organiser: 'Nour A.',
    organiserReliability: 94,
  );

  /// The other open games near La Marsa, so Explorer counts 12.
  static final more = [
    MuGame(
      id: 'g5',
      venueId: padelHouse.id,
      sport: MuSport.padel,
      venue: 'Padel House Menzah',
      court: 'Court 2',
      place: 'Menzah 6',
      distanceKm: 5.0,
      start: at(17, 18, 30),
      spotsTotal: 4,
      spotsLeft: 1,
      pricePerPlayer: 18,
      levelMin: 3,
      levelMax: 4,
      players: const [rami, lina, ines],
      organiser: 'Rami S.',
      organiserReliability: 91,
      matchFit: 78,
      matchFitReason: 'Ton niveau (3,5) et ton samedi soir libre',
    ),
    MuGame(
      id: 'g6',
      venueId: arenaFive.id,
      sport: MuSport.football,
      venue: 'Arena Five',
      court: 'Terrain 3',
      place: 'La Marsa',
      distanceKm: 1.4,
      gameType: 'Hommes',
      start: at(18, 18),
      spotsTotal: 10,
      spotsLeft: 3,
      pricePerPlayer: 15,
      levelMin: 3,
      levelMax: 4,
      players: const [aziz, omar, hamza, rami, skander, MuPerson('Karim B.'), MuPerson('Walid S.')],
      organiser: 'Aziz H.',
      organiserReliability: 95,
      matchFit: 74,
      matchFitReason: 'Terrain à 1,4 km et ton niveau en football (3,0)',
    ),
    MuGame(
      id: 'g7',
      venueId: smashPadel.id,
      sport: MuSport.padel,
      venue: 'Smash Padel Club',
      court: 'Court 1',
      place: 'Lac 2',
      distanceKm: 3.1,
      start: at(17, 19, 30),
      spotsTotal: 4,
      spotsLeft: 2,
      pricePerPlayer: 25,
      levelMin: 3.5,
      levelMax: 4.5,
      players: const [ines, nour],
      organiser: 'Ines M.',
      organiserReliability: 97,
    ),
    MuGame(
      id: 'g8',
      venueId: arenaFive.id,
      sport: MuSport.football,
      venue: 'Arena Five',
      court: 'Terrain 1',
      place: 'La Marsa',
      distanceKm: 1.4,
      start: at(19, 20),
      spotsTotal: 10,
      spotsLeft: 5,
      pricePerPlayer: 15,
      levelMin: 2.5,
      levelMax: 4,
      players: const [omar, salma, lina, nour, hamza],
      organiser: 'Omar D.',
      organiserReliability: 92,
    ),
    MuGame(
      id: 'g9',
      venueId: smashPadel.id,
      sport: MuSport.padel,
      venue: 'Smash Padel Club',
      court: 'Court 2',
      place: 'Lac 2',
      distanceKm: 3.1,
      gameType: 'Femmes',
      start: at(20, 18, 30),
      spotsTotal: 4,
      spotsLeft: 3,
      pricePerPlayer: 25,
      levelMin: 3,
      levelMax: 4.5,
      players: const [salma],
      organiser: 'Salma G.',
      organiserReliability: 90,
    ),
    MuGame(
      id: 'g10',
      venueId: arenaFive.id,
      sport: MuSport.football,
      venue: 'Arena Five',
      court: 'Terrain 2',
      place: 'La Marsa',
      distanceKm: 1.4,
      start: at(22, 21),
      spotsTotal: 10,
      spotsLeft: 6,
      pricePerPlayer: 15,
      levelMin: 3,
      levelMax: 4.5,
      players: const [skander, aziz, hamza, nour],
      organiser: 'Skander T.',
      organiserReliability: 96,
    ),
    MuGame(
      id: 'g11',
      venueId: padelHouse.id,
      sport: MuSport.padel,
      venue: 'Padel House Menzah',
      court: 'Court 1',
      place: 'Menzah 6',
      distanceKm: 5.0,
      start: at(23, 20),
      spotsTotal: 4,
      spotsLeft: 2,
      pricePerPlayer: 18,
      levelMin: 3,
      levelMax: 4,
      players: const [rami, omar],
      organiser: 'Rami S.',
      organiserReliability: 91,
    ),
    MuGame(
      id: 'g12',
      venueId: arenaFive.id,
      sport: MuSport.football,
      venue: 'Arena Five',
      court: 'Terrain 3',
      place: 'La Marsa',
      distanceKm: 1.4,
      start: at(24, 18),
      spotsTotal: 10,
      spotsLeft: 4,
      pricePerPlayer: 12,
      levelMin: 2.5,
      levelMax: 4,
      players: const [lina, salma, nour, ines, mariem, MuPerson('Sarra B.')],
      organiser: 'Lina F.',
      organiserReliability: 93,
    ),
  ];

  /// Explorer's list, recommended first.
  static final openGames = [g1, g2, g4, g3, ...more];

  // ── Mes matchs ──────────────────────────────────────────────────────────────────────────────

  /// G1, which Yassine plays and paid 15 DT.
  static final g1Booking = MuBooking(
    id: 'g1',
    sport: MuSport.football,
    venue: 'Arena Five',
    court: 'Terrain 2',
    place: 'La Marsa',
    start: at(18, 20),
    end: at(18, 21),
    share: 15,
    players: const [skander, hamza, nour, aziz, omar, salma, lina, ines, yassine],
  );

  /// MU-48213, the court Yassine booked: a public game with 4 places to fill.
  static final myBooking = MuBooking(
    id: 'MU-48213',
    sport: MuSport.football,
    venue: 'Arena Five',
    court: 'Terrain 1',
    place: 'La Marsa',
    start: at(21, 21),
    end: at(21, 22),
    share: 15,
    players: const [yassine, skander, hamza, aziz, omar, nour],
  );

  /// Mariem's padel invitation.
  static final invitation = (
    from: mariem,
    sport: MuSport.padel,
    venue: 'Smash Padel Club',
    start: at(23, 19, 30),
    share: 25,
    spotsTotal: 4,
    spotsLeft: 2,
  );

  // ── Tournaments ─────────────────────────────────────────────────────────────────────────────

  static final padelMasters = MuTournament(
    id: 'padel-masters-lac-2',
    sport: MuSport.padel,
    name: 'Padel Masters Lac 2',
    start: at(24, 9),
    end: at(26, 9),
    venue: 'Smash Padel Club',
    place: 'Lac 2',
    feePerTeam: 120,
    prize: 1500,
    teamsTotal: 16,
    teamsRegistered: 12,
    levelMin: 3.5,
    levelMax: 5,
  );

  // ── Me ──────────────────────────────────────────────────────────────────────────────────────

  static const myName = 'Yassine B.';
  static const myFirstName = 'Yassine';
  static const myLevels = {MuSport.padel: 3.5, MuSport.football: 3.0};
  static const unreadNotifications = 3;

  static const recentSearches = [
    'padel la marsa',
    'foot 5 ce soir',
    'Smash Padel Club',
    'Mariem K.',
  ];
}
