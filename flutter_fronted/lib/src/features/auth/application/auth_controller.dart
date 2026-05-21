import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/auth_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/auth_tokens.dart';
import '../domain/usecases/login.dart';
import '../domain/usecases/register.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState._(this.status, this.tokens);

  final AuthStatus status;
  final AuthTokens? tokens;

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);
  const AuthState.authenticated(AuthTokens t)
    : this._(AuthStatus.authenticated, t);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authApiProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _load();
    return const AuthState.unknown();
  }

  Future<void> _load() async {
    final tokens = await ref.read(tokenStorageProvider).read();
    if (tokens == null) {
      state = const AuthState.unauthenticated();
    } else {
      state = AuthState.authenticated(tokens);
    }
  }

  Future<void> login({required String email, required String password}) async {
    final tokens = await ref.read(loginUseCaseProvider)(email, password);
    await ref.read(tokenStorageProvider).write(tokens);
    state = AuthState.authenticated(tokens);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final tokens = await ref.read(registerUseCaseProvider)(
      email,
      password,
      displayName,
    );
    await ref.read(tokenStorageProvider).write(tokens);
    state = AuthState.authenticated(tokens);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState.unauthenticated();
  }
}
