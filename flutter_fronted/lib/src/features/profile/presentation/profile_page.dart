import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../core/ui/app_labeled_text_field.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../auth/application/auth_controller.dart';
import '../../locations/domain/location_models.dart';
import '../../locations/application/locations_provider.dart';
import '../application/profile_controller.dart';
import '../domain/me_profile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _initialized = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _selectedTerritoryColor;
  String _countryCode = 'RU';
  String _countryName = 'Россия';
  String? _regionCode;
  String? _regionName;
  String? _cityCode;
  String? _cityName;
  bool _clearRegionOnSave = false;
  bool _clearCityOnSave = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _syncForm(MeProfile profile) {
    if (!_initialized) {
      _initialized = true;
      _displayNameController.text = profile.displayName;
      _selectedTerritoryColor = profile.territoryColor.toUpperCase();
      _countryCode = profile.countryCode;
      _countryName = profile.countryName;
      _regionCode = profile.regionCode;
      _regionName = profile.regionName;
      _cityCode = profile.cityCode;
      _cityName = profile.cityName;
    }
    _emailController.text = profile.email ?? '';
  }

  Future<RegionItem?> _pickRegion() async {
    return showModalBottomSheet<RegionItem>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) {
        return _PaginatedPickerSheet<RegionItem>(
          title: 'Выберите область',
          searchHint: 'Начните вводить область...',
          itemLabel: (item) => item.name,
          loadPage: ({required query, required limit, required offset}) {
            return ref.read(searchRegionsUseCaseProvider)(
              countryCode: _countryCode,
              query: query,
              limit: limit,
              offset: offset,
            );
          },
        );
      },
    );
  }

  Future<CityItem?> _pickCity() async {
    if (_regionCode == null) return null;
    return showModalBottomSheet<CityItem>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) {
        return _PaginatedPickerSheet<CityItem>(
          title: 'Выберите город',
          searchHint: 'Начните вводить город...',
          itemLabel: (item) => item.name,
          loadPage: ({required query, required limit, required offset}) {
            return ref.read(searchCitiesUseCaseProvider)(
              countryCode: _countryCode,
              regionCode: _regionCode!,
              query: query,
              limit: limit,
              offset: offset,
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    await ref.read(profileActionsProvider.notifier).uploadAvatar(picked);
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
        final msg = toUserFriendlyError(
          next.error!,
          fallbackMessage: 'Не удалось сохранить изменения. Попробуйте снова.',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
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
          final isRussian = Localizations.localeOf(context).languageCode == 'ru';
          final progressSectionTitle = isRussian ? 'Прогресс' : 'Progress';
          final activitySectionTitle = isRussian ? 'Активность' : 'Activity';
          final resultsSectionTitle = isRussian ? 'Результаты' : 'Results';
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(meProfileProvider);
              await ref.read(meProfileProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.background,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.profilePersonalSection,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerLow,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        (profile.avatarUrl?.isNotEmpty ?? false)
                                        ? NetworkImage(profile.avatarUrl!)
                                        : null,
                                    child:
                                        (profile.avatarUrl?.isNotEmpty ?? false)
                                        ? null
                                        : Icon(
                                            Icons.person_outline,
                                            size: 52,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: isSaving
                                          ? null
                                          : _pickAndUploadAvatar,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Ink(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          size: 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : _pickAndUploadAvatar,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text(l10n.profileUploadAvatarAction),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                width: 1,
                                height: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                              TextButton.icon(
                                onPressed: isSaving || profile.avatarUrl == null
                                    ? null
                                    : () async {
                                        await ref
                                            .read(
                                              profileActionsProvider.notifier,
                                            )
                                            .deleteAvatar();
                                      },
                                icon: const Icon(Icons.delete_outline),
                                label: Text(l10n.profileDeleteAvatarAction),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppLabeledTextField(
                            label: l10n.displayNameLabel,
                            controller: _displayNameController,
                            enabled: !isSaving,
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 10),
                          AppLabeledTextField(
                            label: l10n.emailLabel,
                            controller: _emailController,
                            prefixIcon: Icons.mail_outline,
                            interactive: false,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Локация для рейтинга',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          _ProfileLocationTile(
                            icon: Icons.flag_outlined,
                            title: 'Страна',
                            value: _countryName,
                          ),
                          const SizedBox(height: 8),
                          _ProfileLocationTile(
                            icon: Icons.map_outlined,
                            title: 'Область',
                            value: _regionName ?? 'Не выбрано',
                            enabled: !isSaving,
                            onTap: isSaving
                                ? null
                                : () async {
                                    final region = await _pickRegion();
                                    if (region == null) return;
                                    setState(() {
                                      _regionCode = region.code;
                                      _regionName = region.name;
                                      _cityCode = null;
                                      _cityName = null;
                                      _clearRegionOnSave = false;
                                      _clearCityOnSave = false;
                                    });
                                  },
                          ),
                          const SizedBox(height: 8),
                          _ProfileLocationTile(
                            icon: Icons.location_city_outlined,
                            title: 'Город',
                            value: _cityName ?? 'Не выбрано',
                            enabled: !isSaving && _regionCode != null,
                            onTap: isSaving || _regionCode == null
                                ? null
                                : () async {
                                    final city = await _pickCity();
                                    if (city == null) return;
                                    setState(() {
                                      _cityCode = city.code;
                                      _cityName = city.name;
                                      _clearCityOnSave = false;
                                    });
                                  },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final displayName = _displayNameController
                                          .text
                                          .trim();
                                      await ref
                                          .read(profileActionsProvider.notifier)
                                          .saveProfile(
                                            displayName: displayName,
                                            countryCode: _countryCode,
                                            regionCode: _regionCode,
                                            cityCode: _cityCode,
                                            clearRegion: _clearRegionOnSave,
                                            clearCity: _clearCityOnSave,
                                          );
                                      _clearRegionOnSave = false;
                                      _clearCityOnSave = false;
                                    },
                              child: Text(
                                isSaving
                                    ? l10n.loading
                                    : l10n.profileSaveProfileAction,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                                  color: AppColors.text,
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _StatsSectionCard(
                          title: progressSectionTitle,
                          items: [
                            _StatsSectionItem(
                              icon: Icons.stars_rounded,
                              label: l10n.profileLevelLabel,
                              value: '${profile.stats.profileLevel}',
                            ),
                            _StatsSectionItem(
                              icon: Icons.bolt_rounded,
                              label: l10n.profileXpLabel,
                              value: '${profile.stats.profileXp} XP',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _StatsSectionCard(
                          title: activitySectionTitle,
                          items: [
                            _StatsSectionItem(
                              icon: Icons.directions_run_rounded,
                              label: l10n.profileRunsCount,
                              value: '${profile.stats.runCount}',
                            ),
                            _StatsSectionItem(
                              icon: Icons.location_on_outlined,
                              label: l10n.distance,
                              value: formatMeters(profile.stats.totalDistanceM),
                            ),
                            _StatsSectionItem(
                              icon: Icons.schedule_rounded,
                              label: l10n.elapsed,
                              value: formatDurationMmSs(
                                profile.stats.totalElapsedS,
                              ),
                            ),
                            _StatsSectionItem(
                              icon: Icons.pause_circle_outline_rounded,
                              label: l10n.paused,
                              value: formatDurationMmSs(
                                profile.stats.totalPausedS,
                              ),
                            ),
                            _StatsSectionItem(
                              icon: Icons.directions_walk_rounded,
                              label: l10n.moving,
                              value: formatDurationMmSs(
                                profile.stats.totalMovingS,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _StatsSectionCard(
                          title: resultsSectionTitle,
                          items: [
                            _StatsSectionItem(
                              icon: Icons.flag_outlined,
                              label: l10n.profileSuccessfulCapturesLabel,
                              value: '${profile.stats.successfulCapturesCount}',
                            ),
                            _StatsSectionItem(
                              icon: Icons.track_changes_rounded,
                              label: l10n.profileTotalCapturedLabel,
                              value: formatAreaM2(
                                profile.stats.totalCapturedAreaM2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            toUserFriendlyError(
              e,
              fallbackMessage:
                  'Не удалось загрузить профиль. Попробуйте снова.',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ProfileLocationTile extends StatelessWidget {
  const _ProfileLocationTile({
    required this.icon,
    required this.title,
    required this.value,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hasAction = enabled && onTap != null;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: hasAction ? colorScheme.secondary : colorScheme.onSurface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: textTheme.bodyLarge),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          if (hasAction)
            Icon(Icons.chevron_right, color: colorScheme.secondary),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: hasAction
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: content,
              )
            : content,
      ),
    );
  }
}

typedef _PagedLoader<T> =
    Future<List<T>> Function({
      required String query,
      required int limit,
      required int offset,
    });

class _PaginatedPickerSheet<T> extends StatefulWidget {
  const _PaginatedPickerSheet({
    required this.title,
    required this.searchHint,
    required this.itemLabel,
    required this.loadPage,
  });

  final String title;
  final String searchHint;
  final String Function(T item) itemLabel;
  final _PagedLoader<T> loadPage;

  @override
  State<_PaginatedPickerSheet<T>> createState() =>
      _PaginatedPickerSheetState<T>();
}

class _PaginatedPickerSheetState<T> extends State<_PaginatedPickerSheet<T>> {
  static const _pageSize = 30;
  final _items = <T>[];
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  Timer? _debounce;
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;
  String _query = '';
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _offset = 0;
        _hasMore = true;
        _items.clear();
      }
    });

    try {
      final page = await widget.loadPage(
        query: _query,
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _offset += page.length;
        _hasMore = page.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.82;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    _query = value.trim();
                    _load(reset: true);
                  });
                },
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Text(
          toUserFriendlyError(
            _error!,
            fallbackMessage:
                'Не удалось загрузить список. Проверьте сеть и попробуйте снова.',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Ничего не найдено'));
    }
    final itemCount = _items.length + (_loading || _hasMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final item = _items[index];
        return ListTile(
          dense: true,
          title: Text(widget.itemLabel(item)),
          onTap: () => Navigator.of(context).pop(item),
        );
      },
    );
  }
}

class _StatsSectionItem {
  const _StatsSectionItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _StatsSectionCard extends StatelessWidget {
  const _StatsSectionCard({required this.title, required this.items});

  final String title;
  final List<_StatsSectionItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.68),
            ),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.secondary.withValues(alpha: 0.14),
                          ),
                          child: Icon(
                            item.icon,
                            color: AppColors.secondPrimary,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.94,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.secondPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index != items.length - 1)
                    Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.42),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
