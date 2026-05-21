import '../auth_tokens.dart';

abstract interface class AuthRepository {
  Future<AuthTokens> login(String email, String password);
  Future<AuthTokens> register(
    String email,
    String password,
    String displayName,
  );
  Future<AuthTokens> refresh(String refreshToken);
}
