/// Уведомляет об инвалидации сессии (например, при неудачном refresh).
/// Используется [TokenInterceptor], чтобы приложение синхронизировало состояние авторизации и перенаправило на логин.
/// Реализации живут в слое app/auth; core не зависит от Riverpod и UI.
abstract class SessionExpiredListener {
  void onSessionExpired();
}

/// Реализация через callback.
class SessionExpiredCallback implements SessionExpiredListener {
  SessionExpiredCallback(this._onExpired);

  final void Function() _onExpired;

  @override
  void onSessionExpired() => _onExpired();
}
