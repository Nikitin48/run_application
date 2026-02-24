import '../repositories/profile_repository.dart';

class ChangePasswordUseCase {
  ChangePasswordUseCase(this._repo);

  final ProfileRepository _repo;

  Future<void> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
