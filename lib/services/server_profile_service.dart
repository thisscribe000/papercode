import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/server_profile.dart';

class ServerProfileService {
  final FlutterSecureStorage _storage;
  static const _key = 'server_profiles';

  ServerProfileService(this._storage);

  Future<List<ServerProfile>> loadAll() async {
    final json = await _storage.read(key: _key);
    if (json == null || json.isEmpty) return [];
    return ServerProfile.profilesFromJson(json);
  }

  Future<void> save(ServerProfile profile) async {
    final profiles = await loadAll();
    final idx = profiles.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      profiles[idx] = profile;
    } else {
      profiles.add(profile);
    }
    await _storage.write(key: _key, value: ServerProfile.profilesToJson(profiles));
  }

  Future<void> delete(String id) async {
    final profiles = await loadAll();
    profiles.removeWhere((p) => p.id == id);
    await _storage.write(key: _key, value: ServerProfile.profilesToJson(profiles));
  }

  Future<void> setLastConnected(String id) async {
    final profiles = await loadAll();
    final idx = profiles.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      profiles[idx] = profiles[idx].copyWith(lastConnected: DateTime.now());
      await _storage.write(key: _key, value: ServerProfile.profilesToJson(profiles));
    }
  }

  Future<ServerProfile?> getById(String id) async {
    final profiles = await loadAll();
    final idx = profiles.indexWhere((p) => p.id == id);
    return idx >= 0 ? profiles[idx] : null;
  }
}
