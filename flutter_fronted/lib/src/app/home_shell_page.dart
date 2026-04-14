import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:run_application/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/histories/application/run_history_provider.dart';
import '../features/notifications/application/last_notification_provider.dart';
import '../features/runs/application/run_tracker_controller.dart';
import '../features/territories/application/territories_controller.dart';
import '../core/theme/app_colors.dart';

class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  static const _alwaysPermissionHintLastShownKey =
      'always_permission_hint_last_shown_at_ms';
  static const _alwaysPermissionHintCooldown = Duration(hours: 24);

  bool _fabExpanded = false;

  Future<void> _finishRunFromFab() async {
    if (mounted) {
      setState(() => _fabExpanded = false);
    }
    await ref.read(runTrackerProvider.notifier).finish();
    ref.invalidate(notificationsHistoryProvider);
    ref.invalidate(runHistoryProvider);
    ref.invalidate(territoriesForBboxProvider);
  }

  Future<void> _ensureAlwaysLocationPermissionBeforeStart() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    LocationPermission perm;
    try {
      perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      // On many Android devices, a second request from whileInUse can trigger
      // the "Allow all the time" choice.
      if (perm == LocationPermission.whileInUse) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always) return;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final shouldShowHint = await _shouldShowAlwaysPermissionHint();
    if (!shouldShowHint || !mounted) return;
    await _rememberAlwaysPermissionHintShownNow();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => const _AlwaysLocationPermissionHintSheet(),
    );
  }

  Future<bool> _shouldShowAlwaysPermissionHint() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownAtMs = prefs.getInt(_alwaysPermissionHintLastShownKey);
    if (lastShownAtMs == null) return true;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return (nowMs - lastShownAtMs) >= _alwaysPermissionHintCooldown.inMilliseconds;
  }

  Future<void> _rememberAlwaysPermissionHintShownNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _alwaysPermissionHintLastShownKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RunTrackerState>(runTrackerProvider, (previous, next) {
      final hadNoResult = previous?.lastFinish == null;
      final hasResult = next.lastFinish != null;
      if (!hadNoResult || !hasResult || !mounted) return;
      ref.invalidate(notificationsHistoryProvider);
      ref.invalidate(runHistoryProvider);
      ref.invalidate(territoriesForBboxProvider);
      context.push('/run-summary');
    });

    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final navigationShell = widget.navigationShell;
    final mapSelected = navigationShell.currentIndex == 0;
    final runState = ref.watch(runTrackerProvider);
    final runPhase = runState.phase;
    final tabsLocked =
        runPhase != RunPhase.idle || runState.countdownSeconds != null;
    final showRunActions =
        mapSelected &&
        _fabExpanded &&
        (runPhase == RunPhase.running || runPhase == RunPhase.paused);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 220,
        height: 122,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              top: showRunActions ? 4 : 18,
              left: showRunActions ? 20 : 78,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: showRunActions ? 1 : 0,
                child: _ActionCircleButton(
                  icon: runPhase == RunPhase.paused
                      ? Icons.play_arrow
                      : Icons.pause,
                  tooltip: runPhase == RunPhase.paused
                      ? l10n.runResume
                      : l10n.runPause,
                  enabled: runPhase != RunPhase.finishing,
                  onTap: () {
                    if (runPhase == RunPhase.paused) {
                      ref.read(runTrackerProvider.notifier).resume();
                    } else if (runPhase == RunPhase.running) {
                      ref.read(runTrackerProvider.notifier).pauseManual();
                    }
                  },
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              top: showRunActions ? 4 : 18,
              right: showRunActions ? 20 : 78,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: showRunActions ? 1 : 0,
                child: _ActionCircleButton(
                  icon: Icons.stop,
                  tooltip: l10n.runFinish,
                  enabled: runPhase != RunPhase.finishing,
                  onTap: _finishRunFromFab,
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 1.0,
                end: mapSelected ? (showRunActions ? 1.08 : 1.0) : 1.0,
              ),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.translate(
                  offset: const Offset(0, 36),
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: FloatingActionButton(
                heroTag: 'home-main-fab',
                elevation: mapSelected ? 10 : 7,
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: const CircleBorder(),
                onPressed: runPhase == RunPhase.finishing
                    ? null
                    : () async {
                        if (!mapSelected) {
                          navigationShell.goBranch(
                            0,
                            initialLocation: navigationShell.currentIndex == 0,
                          );
                          return;
                        }
                        if (runPhase == RunPhase.idle) {
                          await _ensureAlwaysLocationPermissionBeforeStart();
                          if (!mounted) return;
                          await ref.read(runTrackerProvider.notifier).start();
                          if (!mounted) return;
                          final phaseAfterStart = ref
                              .read(runTrackerProvider)
                              .phase;
                          if (phaseAfterStart == RunPhase.running ||
                              phaseAfterStart == RunPhase.paused) {
                            setState(() => _fabExpanded = true);
                          }
                          return;
                        }
                        if (runPhase == RunPhase.running ||
                            runPhase == RunPhase.paused) {
                          setState(() => _fabExpanded = !_fabExpanded);
                        }
                      },
                child: Icon(
                  !mapSelected
                      ? Icons.map_outlined
                      : switch (runPhase) {
                          RunPhase.idle => Icons.play_arrow,
                          RunPhase.running =>
                            _fabExpanded ? Icons.close : Icons.directions_run,
                          RunPhase.paused =>
                            _fabExpanded
                                ? Icons.close
                                : Icons.pause_circle_filled,
                          RunPhase.finishing => Icons.hourglass_top,
                        },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipPath(
        clipper: const _SoftNotchClipper(
          topRadius: 18,
          notchRadius: 33,
          notchDepth: 16,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.94),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: _SideNavButton(
                      tooltip: l10n.historiesTitle,
                      icon: Icons.history_outlined,
                      activeIcon: Icons.history,
                      selected: navigationShell.currentIndex == 1,
                      onTap: tabsLocked
                          ? null
                          : () => navigationShell.goBranch(
                              1,
                              initialLocation:
                                  navigationShell.currentIndex == 1,
                            ),
                    ),
                  ),
                  Expanded(
                    child: _SideNavButton(
                      tooltip: l10n.achievementsPageTitle,
                      icon: Icons.emoji_events_outlined,
                      activeIcon: Icons.emoji_events,
                      selected: navigationShell.currentIndex == 3,
                      onTap: tabsLocked
                          ? null
                          : () => navigationShell.goBranch(
                              3,
                              initialLocation:
                                  navigationShell.currentIndex == 3,
                            ),
                    ),
                  ),
                  const SizedBox(width: 82),
                  Expanded(
                    child: _SideNavButton(
                      tooltip: 'Рейтинг',
                      icon: Icons.leaderboard_outlined,
                      activeIcon: Icons.leaderboard,
                      selected: navigationShell.currentIndex == 4,
                      onTap: tabsLocked
                          ? null
                          : () => navigationShell.goBranch(
                              4,
                              initialLocation:
                                  navigationShell.currentIndex == 4,
                            ),
                    ),
                  ),
                  Expanded(
                    child: _SideNavButton(
                      tooltip: l10n.profileTitle,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      selected: navigationShell.currentIndex == 2,
                      onTap: tabsLocked
                          ? null
                          : () => navigationShell.goBranch(
                              2,
                              initialLocation:
                                  navigationShell.currentIndex == 2,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlwaysLocationPermissionHintSheet extends StatelessWidget {
  const _AlwaysLocationPermissionHintSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Для стабильной работы GPS в фоне включите разрешение "Разрешить всегда".',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'После выдачи этого разрешения подсказка больше не будет показываться.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Geolocator.openAppSettings();
                },
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Открыть настройки'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftNotchClipper extends CustomClipper<Path> {
  const _SoftNotchClipper({
    required this.topRadius,
    required this.notchRadius,
    required this.notchDepth,
  });

  final double topRadius;
  final double notchRadius;
  final double notchDepth;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final notchHalfWidth = notchRadius * 1.25;

    final path = Path()
      ..moveTo(0, topRadius)
      ..quadraticBezierTo(0, 0, topRadius, 0)
      ..lineTo(cx - notchHalfWidth, 0)
      ..cubicTo(
        cx - notchRadius * 0.85,
        0,
        cx - notchRadius * 0.62,
        notchDepth,
        cx,
        notchDepth,
      )
      ..cubicTo(
        cx + notchRadius * 0.62,
        notchDepth,
        cx + notchRadius * 0.85,
        0,
        cx + notchHalfWidth,
        0,
      )
      ..lineTo(w - topRadius, 0)
      ..quadraticBezierTo(w, 0, w, topRadius)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _SoftNotchClipper oldClipper) {
    return topRadius != oldClipper.topRadius ||
        notchRadius != oldClipper.notchRadius ||
        notchDepth != oldClipper.notchDepth;
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: enabled ? colors.primaryContainer : colors.surfaceContainerHighest,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: enabled ? AppColors.secondPrimary : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _SideNavButton extends StatelessWidget {
  const _SideNavButton({
    required this.tooltip,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(
          selected ? activeIcon : icon,
          color: selected ? AppColors.secondPrimary : AppColors.text,
        ),
      ),
    );
  }
}
