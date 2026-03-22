import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../auth/application/auth_controller.dart';
import 'last_notification_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handling can be extended later if needed.
}

final pushMessagingControllerProvider =
    NotifierProvider<PushMessagingController, void>(PushMessagingController.new);

class PushMessagingController extends Notifier<void> {
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  String? _registeredToken;
  bool _started = false;

  @override
  void build() {
    final authStatus = ref.watch(authControllerProvider).status;
    if (authStatus == AuthStatus.authenticated) {
      _startIfNeeded();
    } else {
      _teardown();
    }

    ref.onDispose(_teardown);
  }

  void _startIfNeeded() {
    if (_started) return;
    _started = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((_) {
      ref.invalidate(notificationsHistoryProvider);
    });
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _registerToken(token);
    });
    _initAndRegister();
  }

  Future<void> _initAndRegister() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        developer.log('FCM token is empty', name: 'push');
        return;
      }
      await _registerToken(token);
    } catch (_) {
      developer.log('FCM init/register failed', name: 'push');
    }
  }

  Future<void> _registerToken(String token) async {
    if (token == _registeredToken) return;
    try {
      final platform = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => 'android',
      };
      await ref
          .read(notificationsApiProvider)
          .registerPushToken(platform: platform, token: token);
      _registeredToken = token;
      developer.log('FCM token registered on backend', name: 'push');
    } catch (_) {
      developer.log('FCM token registration request failed', name: 'push');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    developer.log('Foreground FCM message received', name: 'push');
    final attacker = message.data['attacker_display_name'] ?? 'Игрок';
    await ref
        .read(localNotificationsServiceProvider)
        .showTerritoryAttacked(attackerName: attacker);
    ref.invalidate(notificationsHistoryProvider);
  }

  void _teardown() {
    final token = _registeredToken;
    _registeredToken = null;
    _started = false;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _onMessageSub?.cancel();
    _onMessageSub = null;
    _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = null;
    if (token != null) {
      unawaited(ref.read(notificationsApiProvider).unregisterPushToken(token));
    }
  }
}

