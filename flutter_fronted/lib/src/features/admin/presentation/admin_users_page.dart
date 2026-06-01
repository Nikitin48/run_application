import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../profile/application/profile_controller.dart';
import '../application/admin_users_controller.dart';
import '../domain/admin_user.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(adminUsersControllerProvider.notifier).search(value);
    });
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(actionLabel),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Отмена'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(meProfileProvider);

    ref.listen<AsyncValue<AdminUsersState>>(adminUsersControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        final msg = toUserFriendlyError(
          next.error!,
          fallbackMessage: 'Не удалось выполнить действие администратора.',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Управление игроками')),
      body: profileAsync.when(
        data: (profile) {
          if (!profile.isAdmin) {
            return const Center(
              child: Text('Доступ только для администраторов.'),
            );
          }
          return _AdminUsersBody(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            confirm: _confirm,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              toUserFriendlyError(
                error,
                fallbackMessage: 'Не удалось проверить права администратора.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminUsersBody extends ConsumerWidget {
  const _AdminUsersBody({
    required this.searchController,
    required this.onSearchChanged,
    required this.confirm,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Future<bool> Function({
    required String title,
    required String message,
    required String actionLabel,
  })
  confirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(adminUsersControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Имя, email или логин',
              prefixIcon: Icon(Icons.search),
              helperText: 'Оставьте пустым, чтобы увидеть последних игроков.',
            ),
            onChanged: onSearchChanged,
            onSubmitted: (value) =>
                ref.read(adminUsersControllerProvider.notifier).search(value),
          ),
        ),
        Expanded(
          child: stateAsync.when(
            data: (state) {
              if (state.users.isEmpty && !state.isSearching) {
                return const Center(child: Text('Игроки не найдены.'));
              }
              return RefreshIndicator(
                onRefresh: () => ref
                    .read(adminUsersControllerProvider.notifier)
                    .search(searchController.text),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: state.users.length + (state.isSearching ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.users.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return _AdminUserCard(
                      user: state.users[index],
                      isBusy: state.actionUserIds.contains(
                        state.users[index].id,
                      ),
                      confirm: confirm,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  toUserFriendlyError(
                    error,
                    fallbackMessage: 'Не удалось загрузить игроков.',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminUserCard extends ConsumerWidget {
  const _AdminUserCard({
    required this.user,
    required this.isBusy,
    required this.confirm,
  });

  final AdminUser user;
  final bool isBusy;
  final Future<bool> Function({
    required String title,
    required String message,
    required String actionLabel,
  })
  confirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(adminUsersControllerProvider.notifier);
    final subtitleParts = [
      if (user.email?.isNotEmpty ?? false) user.email!,
      '@${user.username}',
      formatAreaM2(user.ownedAreaM2),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: (user.avatarUrl?.isNotEmpty ?? false)
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: (user.avatarUrl?.isNotEmpty ?? false)
                    ? null
                    : const Icon(Icons.person_outline),
              ),
              title: Text(
                user.displayName.isEmpty ? 'Игрок' : user.displayName,
              ),
              subtitle: Text(subtitleParts.join(' • ')),
              trailing: Wrap(
                spacing: 6,
                children: [
                  if (user.isAdmin)
                    const Chip(label: Text('Админ'))
                  else
                    const SizedBox.shrink(),
                  if (user.isBanned)
                    const Chip(label: Text('Бан'))
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.isBanned)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : () => controller.unban(user.id),
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Разбанить'),
                  )
                else
                  FilledButton.icon(
                    onPressed: isBusy
                        ? null
                        : () async {
                            final ok = await confirm(
                              title: 'Забанить игрока?',
                              message:
                                  'Игрок выйдет из приложения, не сможет войти, а его территории будут удалены с карты.',
                              actionLabel: 'Забанить',
                            );
                            if (ok) await controller.ban(user.id);
                          },
                    icon: const Icon(Icons.block),
                    label: const Text('Забанить'),
                  ),
                if (user.isAdmin)
                  OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () async {
                            final ok = await confirm(
                              title: 'Снять права администратора?',
                              message:
                                  'Игрок потеряет доступ к управлению пользователями.',
                              actionLabel: 'Снять',
                            );
                            if (ok) await controller.revokeAdmin(user.id);
                          },
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Снять админку'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () async {
                            final ok = await confirm(
                              title: 'Назначить администратором?',
                              message:
                                  'Игрок получит доступ к управлению банами и ролями.',
                              actionLabel: 'Назначить',
                            );
                            if (ok) await controller.grantAdmin(user.id);
                          },
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Назначить админом'),
                  ),
                if (isBusy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
