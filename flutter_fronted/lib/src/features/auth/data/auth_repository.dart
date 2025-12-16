import '../domain/auth_tokens.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api);

  final AuthApi _api;

  Future<AuthTokens> login(String email, String password) {
    return _api.login(email: email, password: password);
  }

  Future<AuthTokens> register(String email, String password, String displayName) {
    return _api.register(email: email, password: password, displayName: displayName);
  }

  Future<AuthTokens> refresh(String refreshToken) => _api.refresh(refreshToken);
}


