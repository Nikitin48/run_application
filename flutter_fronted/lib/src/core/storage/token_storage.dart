import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/auth_tokens.dart';

class TokenStorage {
  TokenStorage(this._storage);

  static const _key = 'auth_tokens_v1';

  final FlutterSecureStorage _storage;

  Future<AuthTokens?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, Object?>;
    return AuthTokens.fromJson(map);
  }

  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _key, value: jsonEncode(tokens.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}


