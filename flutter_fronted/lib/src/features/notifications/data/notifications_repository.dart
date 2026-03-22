import '../domain/last_notification.dart';
import '../domain/repositories/notifications_repository.dart';
import 'notifications_api.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._api);

  final NotificationsApi _api;

  @override
  Future<LastNotification?> last() async {
    final json = await _api.last();
    final has = json['has_notification'] as bool? ?? false;
    if (!has) return null;
    return _parseItem(json);
  }

  @override
  Future<List<LastNotification>> history({int limit = 10}) async {
    final json = await _api.history(limit: limit);
    final raw = json['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(_parseItem)
        .toList(growable: false);
  }

  LastNotification _parseItem(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'] as String?;
    final createdAt = createdAtRaw == null
        ? DateTime.now()
        : DateTime.parse(createdAtRaw);
    return LastNotification(
      id: (json['id'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'unknown',
      attackerUserId: json['attacker_user_id'] as String?,
      attackerDisplayName: json['attacker_display_name'] as String?,
      runId: json['run_id'] as String?,
      stolenAreaM2: (json['stolen_area_m2'] as num?)?.toDouble() ?? 0.0,
      createdAt: createdAt,
    );
  }
}
