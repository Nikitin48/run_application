import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/profile_api.dart';
import '../data/profile_repository.dart';
import '../domain/me_profile.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/usecases/change_password.dart';
import '../domain/usecases/get_me_profile.dart';
import '../domain/usecases/update_me_profile.dart';
import '../domain/usecases/update_territory_color.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(dioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileApiProvider));
});

final getMeProfileUseCaseProvider = Provider<GetMeProfileUseCase>((ref) {
  return GetMeProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateMeProfileUseCaseProvider = Provider<UpdateMeProfileUseCase>((ref) {
  return UpdateMeProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateTerritoryColorUseCaseProvider =
    Provider<UpdateTerritoryColorUseCase>((ref) {
      return UpdateTerritoryColorUseCase(ref.watch(profileRepositoryProvider));
    });

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(profileRepositoryProvider));
});

final meProfileProvider = FutureProvider<MeProfile>((ref) async {
  return ref.watch(getMeProfileUseCaseProvider)();
});

final profileActionsProvider =
    NotifierProvider<ProfileActionsController, AsyncValue<void>>(
      ProfileActionsController.new,
    );

class ProfileActionsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> saveProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateMeProfileUseCaseProvider)(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
      ref.invalidate(meProfileProvider);
    });
  }

  Future<void> saveTerritoryColor(String territoryColor) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateTerritoryColorUseCaseProvider)(territoryColor);
      ref.invalidate(meProfileProvider);
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(changePasswordUseCaseProvider)(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }
}
