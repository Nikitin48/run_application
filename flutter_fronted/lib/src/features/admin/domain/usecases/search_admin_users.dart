import '../admin_user.dart';
import '../repositories/admin_users_repository.dart';

class SearchAdminUsersUseCase {
  const SearchAdminUsersUseCase(this._repository);

  final AdminUsersRepository _repository;

  Future<List<AdminUser>> call({
    required String query,
    int limit = 20,
    int offset = 0,
  }) {
    return _repository.searchUsers(query: query, limit: limit, offset: offset);
  }
}
