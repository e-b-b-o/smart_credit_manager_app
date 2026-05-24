import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../customer/dashboard/customer_dashboard_screen.dart';
import '../../../shared/utils/financial_calculator.dart';

class CustomerHistoryScreen extends ConsumerWidget {
  const CustomerHistoryScreen({super.key});

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(customerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final transactions = data['transactions'] as List<TransactionModel>;

          if (transactions.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(customerDashboardProvider),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No transactions yet.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customerDashboardProvider),
            child: ListView.builder(
              itemCount: transactions.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isCredit = tx.type == 'credit';
                final isRefund = tx.type == 'refund';
                final color = isCredit
                    ? AppColors.error
                    : (isRefund ? AppColors.primary : AppColors.success);
                final icon = isRefund ? Icons.local_offer_rounded : (isCredit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded);
                final titleText = isRefund ? 'Refund Issued' : (isCredit ? 'Credit' : 'Payment');

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withAlpha(25),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      tx.title?.isNotEmpty == true
                          ? tx.title!
                          : titleText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tx.note?.isNotEmpty == true)
                          Text(tx.note!, style: const TextStyle(fontSize: 12)),
                        Text(
                          _formatDate(tx.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (tx.dueDate != null &&
                            tx.dueDate!.isBefore(DateTime.now()) &&
                            isCredit)
                          const Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: tx.note?.isNotEmpty == true,
                    trailing: Text(
                      FinancialCalculator.formatCurrency(tx.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
