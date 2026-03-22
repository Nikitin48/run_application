import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../features/notifications/application/last_notification_provider.dart';
import '../features/notifications/application/push_messaging_provider.dart';
import 'router.dart';
import '../core/theme/app_theme.dart';

class RunApp extends ConsumerWidget {
  const RunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps in-app notification polling active while app is running.
    ref.watch(notificationsPollingControllerProvider);
    // Keeps FCM token registration and foreground handling active.
    ref.watch(pushMessagingControllerProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
