import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_application/l10n/app_localizations.dart';

import 'router.dart';
import '../core/theme/app_colors.dart';
import '../features/notifications/application/last_notification_provider.dart';
import '../features/notifications/application/push_messaging_provider.dart';

class StartupPage extends ConsumerStatefulWidget {
  const StartupPage({super.key});

  @override
  ConsumerState<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<StartupPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      ref.read(startupDelayPassedProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationsPollingControllerProvider);
    ref.watch(pushMessagingControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/splash/splash.png',
              fit: BoxFit.contain,
              width: MediaQuery.sizeOf(context).width * 0.72,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 56 + MediaQuery.viewPaddingOf(context).bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  l10n.appBootstrapping,
                  style: const TextStyle(color: AppColors.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
