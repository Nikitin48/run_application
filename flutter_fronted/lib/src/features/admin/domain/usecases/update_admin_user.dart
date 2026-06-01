import '../admin_user.dart';
import '../repositories/admin_users_repository.dart';

class BanAdminUserUseCase {
  const BanAdminUserUseCase(this._repository);

  final AdminUsersRepository _repository;

  Future<AdminUserActionResult> call(String userId) {
    return _repository.banUser(userId);
  }
}

class UnbanAdminUserUseCase {
  const UnbanAdminUserUseCase(this._repository);

  final AdminUsersRepository _repository;

  Future<AdminUser> call(String userId) {
    return _repository.unbanUser(userId);
  }
}

class GrantAdminUseCase {
  const GrantAdminUseCase(this._repository);

  final AdminUsersRepository _repository;

  Future<AdminUser> call(String userId) {
    return _repository.grantAdmin(userId);
  }
}

class RevokeAdminUseCase {
  const RevokeAdminUseCase(this._repository);

  final AdminUsersRepository _repository;

  Future<AdminUser> call(String userId) {
    return _repository.revokeAdmin(userId);
  }
}
