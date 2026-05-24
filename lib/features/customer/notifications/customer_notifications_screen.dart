import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/supabase_service.dart';
import '../dashboard/customer_dashboard_screen.dart'; // To reuse notificationsProvider

class CustomerNotificationsScreen extends ConsumerWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Reminders'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(notificationsProvider),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No alerts yet.', style: TextStyle(color: AppColors.textLight))),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              itemCount: notifications.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = !notification.isRead;
                final isAlert = notification.type == 'alert';

                return Card(
                  elevation: isUnread ? 2 : 0,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isUnread ? Colors.transparent : Colors.grey.shade200),
                  ),
                  color: isUnread ? AppColors.card : Colors.grey.shade50,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: isAlert ? AppColors.error.withAlpha(25) : AppColors.primary.withAlpha(25),
                      child: Icon(
                        isAlert ? Icons.warning_rounded : Icons.notifications_rounded,
                        color: isAlert ? AppColors.error : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                        color: isUnread ? AppColors.text : AppColors.textLight,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.message, style: TextStyle(color: isUnread ? AppColors.text : AppColors.textLight)),
                        const SizedBox(height: 6),
                        Text(
                          '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (isUnread) {
                        ref.read(supabaseServiceProvider).markNotificationAsRead(notification.id);
                        ref.invalidate(notificationsProvider);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
