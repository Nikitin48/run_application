import '../auth_tokens.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._repo);

  final AuthRepository _repo;

  Future<AuthTokens> call(String email, String password, String displayName) =>
      _repo.register(email, password, displayName);
}


