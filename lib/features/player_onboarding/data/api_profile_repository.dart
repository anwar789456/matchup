import '../../../core/api/api_client.dart';
import 'profile_repository.dart';

/// [ProfileRepository] on the team's backend (module utilisateur): the pseudo is checked against
/// every account, the profile is saved on the signed-in account ([userId]).
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api, {required this.userId});

  final ApiClient _api;
  final int? Function() userId;

  static const _users = 'utilisateur/utilisateurs';

  @override
  Future<bool> isPseudoAvailable(String pseudo) async {
    final found =
        await _api.get(_users, query: {'pseudo': pseudo.trim().toLowerCase()}) as List<dynamic>;
    final me = userId();
    return found.every((u) => (u as Map<String, dynamic>)['id'] == me);
  }

  @override
  Future<void> saveProfile({required String pseudo, String? fullName, List<int>? photo}) async {
    final id = userId();
    if (id == null) return;
    final parts = (fullName ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    await _api.patch('$_users/$id', {
      'pseudo': pseudo.trim().toLowerCase(),
      if (parts.isNotEmpty) 'prenom': parts.first,
      if (parts.length > 1) 'nom': parts.skip(1).join(' '),
    });
  }
}
