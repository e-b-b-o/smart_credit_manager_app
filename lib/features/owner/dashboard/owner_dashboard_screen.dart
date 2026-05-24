import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/supabase_service.dart';
import '../../../shared/utils/financial_calculator.dart';

import '../../../data/models/transaction_model.dart';

final dashboardStatsProvider = FutureProvider.autoDispose((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final customers = await supabaseService.getCustomers();
  final transactions = await supabaseService.getAllTransactions();

  final totalDebt = FinancialCalculator.calculateTotalCredits(transactions);
  final totalCollected = FinancialCalculator.calculateTotalPayments(
    transactions,
  );
  double totalOutstanding = 0;
  for (var customer in customers) {
    final customerTransactions = transactions
        .where((t) => t.customerId == customer.id)
        .toList();
    totalOutstanding += FinancialCalculator.calculateRemainingBalance(
      customerTransactions,
    );
  }

  int overdueCustomersCount = 0;
  double overdueBalance = 0;
  int overdueTransactionsCount = 0;

  for (var customer in customers) {
    final customerTransactions = transactions
        .where((t) => t.customerId == customer.id)
        .toList();
    final status = FinancialCalculator.calculatePaymentStatus(
      customerTransactions,
    );
    if (status == PaymentStatus.overdue) {
      overdueCustomersCount++;

      for (var tx in customerTransactions) {
        if (tx.type == 'credit') {
          final txStatus = FinancialCalculator.calculateSingleTransactionStatus(
            tx,
            customerTransactions,
          );
          if (txStatus == PaymentStatus.overdue) {
            overdueTransactionsCount++;
          }
        }
      }
      overdueBalance += FinancialCalculator.calculateRemainingBalance(
        customerTransactions,
      );
    }
  }

  // Aging Analysis
  final agingAnalysis = FinancialCalculator.calculateAgingAnalysis(
    transactions,
    customers.map((c) => c.id).toList(),
  );

  return {
    'customersCount': customers.length,
    'totalDebt': totalDebt,
    'totalCollected': totalCollected,
    'totalOutstanding': totalOutstanding,
    'overdueCustomersCount': overdueCustomersCount,
    'overdueBalance': overdueBalance,
    'overdueTransactionsCount': overdueTransactionsCount,
    'agingAnalysis': agingAnalysis,
    'recentTransactions': transactions.take(10).toList(),
    'recentPayments': transactions
        .where((t) => t.type == 'payment')
        .take(10)
        .toList(),
    'customers': customers,
  };
});

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCM Dashboard'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Consumer(
              builder: (context, ref, child) {
                final statsAsync = ref.watch(dashboardStatsProvider);
                return statsAsync.when(
                  data: (stats) => Column(
                    children: [
                      _buildGradientSummaryCard(
                        context,
                        'Total Outstanding',
                        FinancialCalculator.formatCurrency(
                          stats['totalOutstanding'] as double,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecondarySummaryCard(
                              context,
                              'Debt Given',
                              FinancialCalculator.formatCurrency(
                                stats['totalDebt'] as double,
                              ),
                              AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSecondarySummaryCard(
                              context,
                              'Repayments',
                              FinancialCalculator.formatCurrency(
                                stats['totalCollected'] as double,
                              ),
                              AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, st) => Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading dashboard: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Overdue Summary Card
            Consumer(
              builder: (context, ref, child) {
                final statsAsync = ref.watch(dashboardStatsProvider);
                return statsAsync.when(
                  data: (stats) {
                    final overdueCount = stats['overdueCustomersCount'] as int;
                    if (overdueCount == 0) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Overdue Summary',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildOverdueStat(
                                context,
                                'Customers',
                                overdueCount.toString(),
                              ),
                              _buildOverdueStat(
                                context,
                                'Balance',
                                FinancialCalculator.formatCurrency(
                                  stats['overdueBalance'] as double,
                                ),
                              ),
                              _buildOverdueStat(
                                context,
                                'Invoices',
                                stats['overdueTransactionsCount'].toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                );
              },
            ),
            // Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.people_alt_outlined,
                  title: 'Customers',
                  onTap: () => context.go('/owner/customers'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Transactions',
                  onTap: () => context.push('/owner/transactions'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.bar_chart_outlined,
                  title: 'Reports',
                  onTap: () => context.go('/owner/reports'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Complaints',
                  onTap: () => context.push('/owner/complaints'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Recent Activity
            Consumer(
              builder: (context, ref, child) {
                final statsAsync = ref.watch(dashboardStatsProvider);
                return statsAsync.when(
                  data: (stats) {
                    final recentTxs =
                        stats['recentTransactions'] as List<TransactionModel>;
                    if (recentTxs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Activity',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push('/owner/transactions'),
                              child: Text(
                                'View All',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...recentTxs.take(5).map((tx) {
                          final TransactionModel transaction = tx;
                          final isCredit = transaction.type == 'credit';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    (isCredit ? AppColors.error : AppColors.success)
                                        .withAlpha(25),
                                child: Icon(
                                  isCredit
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isCredit ? AppColors.error : AppColors.success,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                transaction.title ??
                                    (isCredit ? 'Credit' : 'Payment'),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                transaction.date.toString().split(' ')[0],
                                style: const TextStyle(color: AppColors.textLight),
                              ),
                              trailing: Text(
                                FinancialCalculator.formatCurrency(
                                  transaction.amount,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isCredit ? AppColors.error : AppColors.success,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientSummaryCard(BuildContext context, String label, String value) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white.withAlpha(200),
                ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondarySummaryCard(BuildContext context, String label, String value, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.red.shade900.withAlpha(180),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.red.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
