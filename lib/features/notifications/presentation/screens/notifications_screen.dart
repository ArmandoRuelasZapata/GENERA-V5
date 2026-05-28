import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:theoriginallab_v2/shared/widgets/app_animated_background.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/notifications/presentation/widgets/notification_card.dart';
import 'package:theoriginallab_v2/features/notifications/presentation/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final hasNotifications = notifications.isNotEmpty;

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              backgroundColor: Colors.transparent,
              title: Text(
                'Notificaciones',
                style: AppTypography.displaySmall.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              actions: [
                // Marcar todo como leído
                if (hasNotifications)
                  IconButton(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier).markAllAsRead();
                    },
                    icon: const Icon(Icons.done_all),
                    tooltip: 'Marcar todo como leído',
                    color: colorScheme.primary,
                  ),
                // Eliminar todas
                if (hasNotifications)
                  IconButton(
                    onPressed: () => _confirmClearAll(context, ref),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Eliminar todas',
                    color: colorScheme.error,
                  ),
              ],
            ),
            if (!hasNotifications)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes notificaciones',
                        style: AppTypography.bodyLarge.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 500.ms).scale(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: ValueKey(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.gap),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (_) {
                          ref
                              .read(notificationsProvider.notifier)
                              .deleteNotification(notification.id);
                        },
                        child: NotificationCard(
                          notification: notification,
                          onTap: () {
                            ref
                                .read(notificationsProvider.notifier)
                                .markAsRead(notification.id);
                          },
                        )
                            .animate()
                            .fade(duration: 400.ms, delay: (50 * index).ms)
                            .slideX(
                                begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                      );
                    },
                    childCount: notifications.length,
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar notificaciones'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar todas las notificaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).clearAll();
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar todas'),
          ),
        ],
      ),
    );
  }
}
