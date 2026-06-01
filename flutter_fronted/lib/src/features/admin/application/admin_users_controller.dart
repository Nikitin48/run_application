import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../profile/application/profile_controller.dart';
import '../../territories/application/territories_controller.dart';
import '../data/admin_users_api.dart';
import '../data/admin_users_repository.dart';
import '../domain/admin_user.dart';
import '../domain/repositories/admin_users_repository.dart';
import '../domain/usecases/search_admin_users.dart';
import '../domain/usecases/update_admin_user.dart';

final adminUsersApiProvider = Provider<AdminUsersApi>((ref) {
  return AdminUsersApi(ref.watch(dioProvider));
});

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepositoryImpl(ref.watch(adminUsersApiProvider));
});

final searchAdminUsersUseCaseProvider = Provider<SearchAdminUsersUseCase>((
  ref,
) {
  return SearchAdminUsersUseCase(ref.watch(adminUsersRepositoryProvider));
});

final banAdminUserUseCaseProvider = Provider<BanAdminUserUseCase>((ref) {
  return BanAdminUserUseCase(ref.watch(adminUsersRepositoryProvider));
});

final unbanAdminUserUseCaseProvider = Provider<UnbanAdminUserUseCase>((ref) {
  return UnbanAdminUserUseCase(ref.watch(adminUsersRepositoryProvider));
});

final grantAdminUseCaseProvider = Provider<GrantAdminUseCase>((ref) {
  return GrantAdminUseCase(ref.watch(adminUsersRepositoryProvider));
});

final revokeAdminUseCaseProvider = Provider<RevokeAdminUseCase>((ref) {
  return RevokeAdminUseCase(ref.watch(adminUsersRepositoryProvider));
});

class AdminUsersState {
  const AdminUsersState({
    required this.query,
    required this.users,
    required this.isSearching,
    required this.actionUserIds,
    this.lastActionResult,
  });

  final String query;
  final List<AdminUser> users;
  final bool isSearching;
  final Set<String> actionUserIds;
  final AdminUserActionResult? lastActionResult;

  static const initial = AdminUsersState(
    query: '',
    users: [],
    isSearching: false,
    actionUserIds: {},
  );

  AdminUsersState copyWith({
    String? query,
    List<AdminUser>? users,
    bool? isSearching,
    Set<String>? actionUserIds,
    AdminUserActionResult? lastActionResult,
    bool clearLastActionResult = false,
  }) {
    return AdminUsersState(
      query: query ?? this.query,
      users: users ?? this.users,
      isSearching: isSearching ?? this.isSearching,
      actionUserIds: actionUserIds ?? this.actionUserIds,
      lastActionResult: clearLastActionResult
          ? null
          : lastActionResult ?? this.lastActionResult,
    );
  }
}

final adminUsersControllerProvider =
    AsyncNotifierProvider<AdminUsersController, AdminUsersState>(
      AdminUsersController.new,
    );

class AdminUsersController extends AsyncNotifier<AdminUsersState> {
  @override
  Future<AdminUsersState> build() async {
    final users = await ref.watch(searchAdminUsersUseCaseProvider)(
      query: '',
      limit: 20,
    );
    return AdminUsersState.initial.copyWith(users: users);
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull ?? AdminUsersState.initial;
    state = AsyncData(
      current.copyWith(
        query: query,
        isSearching: true,
        clearLastActionResult: true,
      ),
    );
    state = await AsyncValue.guard(() async {
      final users = await ref.read(searchAdminUsersUseCaseProvider)(
        query: query,
        limit: 20,
      );
      return current.copyWith(
        query: query,
        users: users,
        isSearching: false,
        clearLastActionResult: true,
      );
    });
  }

  Future<void> ban(String userId) async {
    await _runUserAction(userId, () async {
      final result = await ref.read(banAdminUserUseCaseProvider)(userId);
      ref.invalidate(territoriesForBboxProvider);
      return _ActionOutcome(user: result.user, result: result);
    });
  }

  Future<void> unban(String userId) async {
    await _runUserAction(userId, () async {
      return _ActionOutcome(
        user: await ref.read(unbanAdminUserUseCaseProvider)(userId),
      );
    });
  }

  Future<void> grantAdmin(String userId) async {
    await _runUserAction(userId, () async {
      ref.invalidate(meProfileProvider);
      return _ActionOutcome(
        user: await ref.read(grantAdminUseCaseProvider)(userId),
      );
    });
  }

  Future<void> revokeAdmin(String userId) async {
    await _runUserAction(userId, () async {
      ref.invalidate(meProfileProvider);
      return _ActionOutcome(
        user: await ref.read(revokeAdminUseCaseProvider)(userId),
      );
    });
  }

  Future<void> _runUserAction(
    String userId,
    Future<_ActionOutcome> Function() action,
  ) async {
    final current = state.valueOrNull ?? AdminUsersState.initial;
    state = AsyncData(
      current.copyWith(actionUserIds: {...current.actionUserIds, userId}),
    );
    try {
      final outcome = await action();
      final afterAction = state.valueOrNull ?? current;
      state = AsyncData(
        afterAction.copyWith(
          users: [
            for (final user in afterAction.users)
              if (user.id == outcome.user.id) outcome.user else user,
          ],
          actionUserIds: afterAction.actionUserIds.difference({userId}),
          lastActionResult: outcome.result,
        ),
      );
    } catch (error, stackTrace) {
      final afterError = state.valueOrNull ?? current;
      state = AsyncData(
        afterError.copyWith(
          actionUserIds: afterError.actionUserIds.difference({userId}),
        ),
      );
      state = AsyncError(error, stackTrace);
    }
  }
}

class _ActionOutcome {
  const _ActionOutcome({required this.user, this.result});

  final AdminUser user;
  final AdminUserActionResult? result;
}
