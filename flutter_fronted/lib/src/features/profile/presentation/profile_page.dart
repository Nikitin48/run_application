import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import '../domain/me_profile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _initialized = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _selectedTerritoryColor;

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _prettyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
      return e.message ?? 'Network error';
    }
    return e.toString();
  }

  void _syncForm(MeProfile profile) {
    if (!_initialized) {
      _initialized = true;
      _displayNameController.text = profile.displayName;
      _avatarUrlController.text = profile.avatarUrl ?? '';
      _selectedTerritoryColor = profile.territoryColor.toUpperCase();
    }
    _emailController.text = profile.email ?? '';
  }

  Future<void> _openColorPicker(
    BuildContext context,
    String currentColor,
  ) async {
    Color pickerColor = colorFromHexOrDefault(currentColor);
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(l10n.profilePickCustomColor)),
              IconButton(
                tooltip: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              enableAlpha: false,
              labelTypes: const [],
              onColorChanged: (color) => pickerColor = color,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                setState(
                  () => _selectedTerritoryColor = hexFromColor(pickerColor),
                );
                Navigator.of(context).pop();
              },
              child: Text(l10n.profileApplyColorAction),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(meProfileProvider);
    final actionState = ref.watch(profileActionsProvider);
    final isSaving = actionState.isLoading;

    ref.listen<AsyncValue<void>>(profileActionsProvider, (previous, next) {
      if (next.hasError) {
        final msg = _prettyError(next.error!);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
      if (previous?.isLoading == true && next.hasValue) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileSaveSuccess)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: Text(l10n.logout),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          _syncForm(profile);
          final currentColor =
              (_selectedTerritoryColor ?? profile.territoryColor).toUpperCase();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(meProfileProvider);
              await ref.read(meProfileProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profilePersonalSection,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _displayNameController,
                          enabled: !isSaving,
                          decoration: InputDecoration(
                            labelText: l10n.displayNameLabel,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _avatarUrlController,
                          enabled: !isSaving,
                          decoration: InputDecoration(
                            labelText: l10n.profileAvatarUrlLabel,
                            prefixIcon: const Icon(Icons.image_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          readOnly: true,
                          enabled: false,
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: l10n.emailLabel,
                            prefixIcon: const Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.profileEmailReadonlyHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final displayName = _displayNameController
                                      .text
                                      .trim();
                                  final avatarRaw = _avatarUrlController.text
                                      .trim();
                                  final avatarUrl = avatarRaw.isEmpty
                                      ? null
                                      : avatarRaw;
                                  await ref
                                      .read(profileActionsProvider.notifier)
                                      .saveProfile(
                                        displayName: displayName,
                                        avatarUrl: avatarUrl,
                                      );
                                },
                          child: Text(
                            isSaving
                                ? l10n.loading
                                : l10n.profileSaveProfileAction,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileTerritoryColorSection,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorFromHexOrDefault(currentColor),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const SizedBox(width: 34, height: 34),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${l10n.profileColorCurrent}: $currentColor',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.profilePickCustomColor,
                              onPressed: isSaving
                                  ? null
                                  : () =>
                                        _openColorPicker(context, currentColor),
                              icon: const Icon(Icons.palette_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  await ref
                                      .read(profileActionsProvider.notifier)
                                      .saveTerritoryColor(currentColor);
                                },
                          child: Text(
                            isSaving
                                ? l10n.loading
                                : l10n.profileSaveColorAction,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profilePasswordSection,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _currentPasswordController,
                          enabled: !isSaving,
                          obscureText: !_currentPasswordVisible,
                          decoration: InputDecoration(
                            labelText: l10n.profileCurrentPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _currentPasswordVisible =
                                    !_currentPasswordVisible,
                              ),
                              icon: Icon(
                                _currentPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _newPasswordController,
                          enabled: !isSaving,
                          obscureText: !_newPasswordVisible,
                          decoration: InputDecoration(
                            labelText: l10n.profileNewPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () =>
                                    _newPasswordVisible = !_newPasswordVisible,
                              ),
                              icon: Icon(
                                _newPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _confirmPasswordController,
                          enabled: !isSaving,
                          obscureText: !_confirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: l10n.profileConfirmPasswordLabel,
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _confirmPasswordVisible =
                                    !_confirmPasswordVisible,
                              ),
                              icon: Icon(
                                _confirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final current =
                                      _currentPasswordController.text;
                                  final next = _newPasswordController.text;
                                  final confirm =
                                      _confirmPasswordController.text;
                                  if (next.length < 8) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.profilePasswordMinLengthError,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (next != confirm) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.profilePasswordMismatchError,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await ref
                                      .read(profileActionsProvider.notifier)
                                      .changePassword(
                                        currentPassword: current,
                                        newPassword: next,
                                      );
                                  _currentPasswordController.clear();
                                  _newPasswordController.clear();
                                  _confirmPasswordController.clear();
                                },
                          child: Text(
                            isSaving
                                ? l10n.loading
                                : l10n.profileChangePasswordAction,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileStatsSection,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _MetricRow(
                          label: l10n.profileRunsCount,
                          value: '${profile.stats.runCount}',
                        ),
                        _MetricRow(
                          label: l10n.distance,
                          value: formatMeters(profile.stats.totalDistanceM),
                        ),
                        _MetricRow(
                          label: l10n.elapsed,
                          value: formatDurationMmSs(
                            profile.stats.totalElapsedS,
                          ),
                        ),
                        _MetricRow(
                          label: l10n.paused,
                          value: formatDurationMmSs(profile.stats.totalPausedS),
                        ),
                        _MetricRow(
                          label: l10n.moving,
                          value: formatDurationMmSs(profile.stats.totalMovingS),
                        ),
                        _MetricRow(
                          label: l10n.profileOwnedArea,
                          value: formatAreaM2(profile.stats.ownedAreaM2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(_prettyError(e))),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
