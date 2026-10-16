import '../../../core/api/api_client.dart';
import 'owner_draft.dart';
import 'owner_repository.dart';

/// [OwnerRepository] on the team's backend: « Démarrer l’essai gratuit » (OWN-08) publishes every
/// court to the reservation module (`reservation/terrains`), owned by the signed-in account.
/// Starting data and the RIB check stay as in [FakeOwnerRepository] for now.
class ApiOwnerRepository extends FakeOwnerRepository {
  const ApiOwnerRepository(this._api, {required this.userId});

  final ApiClient _api;
  final int? Function() userId;

  @override
  Future<void> startTrial(OwnerDraft draft) async {
    final owner = userId();
    for (final court in draft.courts) {
      final price = draft.prices[court.priceKey];
      await _api.post('reservation/terrains', {
        'nom': court.name,
        'etablissement': draft.venueName,
        'sport': court.sport.name,
        'surface': court.surface,
        'interieur': court.indoor,
        'eclairage': court.lights,
        'prixHeure': price?.offPeak ?? price?.peak ?? 0,
        'ville': draft.city,
        'adresse': draft.street,
        'proprietaireId': ?owner,
      });
    }
  }
}
