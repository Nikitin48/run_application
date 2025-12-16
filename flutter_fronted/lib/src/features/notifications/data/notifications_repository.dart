import '../domain/last_notification.dart';
import '../domain/repositories/notifications_repository.dart';
import 'notifications_api.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._api);

  final NotificationsApi _api;

  Future<LastNotification?> last() async {
    final json = await _api.last();
    final has = json['has_notification'] as bool? ?? false;
    if (!has) return null;

    final kind = (json['kind'] as String?) ?? 'unknown';
    final attackerUserId = json['attacker_user_id'] as String?;
    final runId = json['run_id'] as String?;
    final stolen = (json['stolen_area_m2'] as num?)?.toDouble() ?? 0.0;
    final createdAtRaw = json['created_at'] as String?;
    final createdAt = createdAtRaw == null ? DateTime.now() : DateTime.parse(createdAtRaw);

    return LastNotification(
      kind: kind,
      attackerUserId: attackerUserId,
      runId: runId,
      stolenAreaM2: stolen,
      createdAt: createdAt,
    );
  }
}


