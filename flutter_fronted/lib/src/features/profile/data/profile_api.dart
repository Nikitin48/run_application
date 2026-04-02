import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getMeProfile() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/profile');
    return res.data!;
  }

  Future<Map<String, dynamic>> updateMeProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{};
    if (displayName != null) payload['display_name'] = displayName;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    final res = await _dio.patch<Map<String, dynamic>>(
      '/me/profile',
      data: payload,
    );
    return res.data!;
  }

  Future<String> updateTerritoryColor(String territoryColor) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/me/territory-color',
      data: {'territory_color': territoryColor},
    );
    return (res.data?['territory_color'] as String?) ?? territoryColor;
  }

  Future<String?> uploadAvatar(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/me/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data?['avatar_url'] as String?;
  }

  Future<void> deleteAvatar() async {
    await _dio.delete<Map<String, dynamic>>('/me/avatar');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch<Map<String, dynamic>>(
      '/me/password',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }
}
