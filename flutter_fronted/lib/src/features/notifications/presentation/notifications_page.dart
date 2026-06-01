import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../application/last_notification_provider.dart';
import '../application/notification_read_state_provider.dart';
import '../domain/last_notification.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsHistoryProvider);
    final dtf = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Пока нет уведомлений о захвате территории'),
            );
          }
          // Mark newest notification as read when feed is opened.
          ref
              .read(notificationsReadStateProvider.notifier)
              .markAsRead(items.first.id);
          final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsHistoryProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = items[i];
                return _NotificationTile(
                  item: n,
                  timestamp: dtf.format(n.createdAt.toLocal()),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            toUserFriendlyError(
              e,
              fallbackMessage:
                  'Не удалось загрузить уведомления. Попробуйте снова.',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.timestamp});

  final LastNotification item;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final attacker = (item.attackerDisplayName ?? '').trim().isEmpty
        ? 'Игрок'
        : item.attackerDisplayName!;
    final area = formatAreaM2(item.affectedAreaM2);
    final isStolen = item.kind == 'territory_stolen';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text(
          isStolen
              ? '$attacker захватил уязвимую часть территории'
              : '$attacker оспаривает часть вашей территории',
        ),
        subtitle: Text(
          isStolen ? 'Потеряно: $area\n$timestamp' : 'Спорная область: $area\n$timestamp',
        ),
        isThreeLine: true,
      ),
    );
  }
}
