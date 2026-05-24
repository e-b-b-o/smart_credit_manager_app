import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/services/supabase_service.dart';
import '../../../shared/utils/financial_calculator.dart';
import '../../../core/theme/app_colors.dart';

final reportsDateRangeProvider = NotifierProvider<ReportsDateRangeNotifier, DateTimeRange?>(() {
  return ReportsDateRangeNotifier();
});

class ReportsDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void updateRange(DateTimeRange? range) {
    state = range;
  }
}

final reportsStatsProvider = FutureProvider.autoDispose((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final dateRange = ref.watch(reportsDateRangeProvider);

  final customers = await supabaseService.getCustomers();
  final allTransactions = await supabaseService.getAllTransactions();

  var periodTransactions = allTransactions;
  if (dateRange != null) {
    periodTransactions = allTransactions.where((t) {
      return t.date.isAfter(dateRange.start.subtract(const Duration(milliseconds: 1))) &&
          t.date.isBefore(dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  final periodDebt = FinancialCalculator.calculateTotalCredits(periodTransactions);
  final periodCollected = FinancialCalculator.calculateTotalPayments(periodTransactions);

  final totalOutstanding = allTransactions.isEmpty
      ? 0.0
      : customers.fold<double>(0.0, (sum, c) {
          final customerTxs = allTransactions.where((t) => t.customerId == c.id).toList();
          return sum + FinancialCalculator.calculateRemainingBalance(customerTxs);
        });

  // Overdue stats (always based on current snapshot, not period)
  int overdueCustomersCount = 0;
  double overdueBalance = 0;

  for (var customer in customers) {
    final customerTransactions = allTransactions.where((t) => t.customerId == customer.id).toList();
    final status = FinancialCalculator.calculatePaymentStatus(customerTransactions);
    if (status == PaymentStatus.overdue) {
      overdueCustomersCount++;
      overdueBalance += FinancialCalculator.calculateRemainingBalance(customerTransactions);
    }
  }

  // Aging Analysis (current snapshot)
  final agingAnalysis = FinancialCalculator.calculateAgingAnalysis(
    allTransactions,
    customers.map((c) => c.id).toList(),
  );

  return {
    'customersCount': customers.length,
    'periodDebt': periodDebt,
    'periodCollected': periodCollected,
    'totalOutstanding': totalOutstanding,
    'overdueCustomersCount': overdueCustomersCount,
    'overdueBalance': overdueBalance,
    'agingAnalysis': agingAnalysis,
  };
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(reportsDateRangeProvider);
    final initialDateRange = currentRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(reportsDateRangeProvider.notifier).updateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(reportsStatsProvider);
    final dateRange = ref.watch(reportsDateRangeProvider);

    String dateRangeText = 'All Time';
    if (dateRange != null) {
      final formatter = DateFormat('MMM d, y');
      dateRangeText = '${formatter.format(dateRange.start)} - ${formatter.format(dateRange.end)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context, ref),
          ),
          if (dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => ref.read(reportsDateRangeProvider.notifier).updateRange(null),
              tooltip: 'Clear Filter',
            ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          final aging = stats['agingAnalysis'] as List<AgingCategory>;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reportsStatsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Period Selector Chip
                  Center(
                    child: ActionChip(
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      label: Text(dateRangeText),
                      onPressed: () => _selectDateRange(context, ref),
                      backgroundColor: AppColors.primary.withAlpha(25),
                      side: BorderSide(color: AppColors.primary.withAlpha(50)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Business Overview
                  Text(
                    'Business Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                        context,
                        'Total Customers',
                        stats['customersCount'].toString(),
                        Icons.people_alt_outlined,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        'Debt Issued (Period)',
                        FinancialCalculator.formatCurrency(stats['periodDebt'] as double),
                        Icons.trending_up,
                        AppColors.error,
                      ),
                      _buildStatCard(
                        context,
                        'Repayments (Period)',
                        FinancialCalculator.formatCurrency(stats['periodCollected'] as double),
                        Icons.account_balance_wallet_outlined,
                        AppColors.success,
                      ),
                      _buildStatCard(
                        context,
                        'Current Outstanding',
                        FinancialCalculator.formatCurrency(stats['totalOutstanding'] as double),
                        Icons.account_balance,
                        AppColors.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Overdue Status
                  Text(
                    'Overdue Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withAlpha(50)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSimpleStat(
                            'Customers',
                            stats['overdueCustomersCount'].toString(),
                            AppColors.error,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.error.withAlpha(50),
                        ),
                        Expanded(
                          child: _buildSimpleStat(
                            'Amount',
                            FinancialCalculator.formatCurrency(stats['overdueBalance'] as double),
                            AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Aging Analysis
                  Text(
                    'Aging Analysis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...aging.map((category) => _buildAgingRow(context, category)),

                  const SizedBox(height: 24),

                  // 4. Payment Performance
                  Text(
                    'Collection Rate (Period)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildCollectionProgress(
                    context,
                    stats['periodDebt'] as double,
                    stats['periodCollected'] as double,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withAlpha(200),
          ),
        ),
      ],
    );
  }

  Widget _buildAgingRow(BuildContext context, AgingCategory category) {
    final bool isCurrent = category.label == 'Current';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: category.customerCount > 0
            ? () {
                final encodedCategory = Uri.encodeComponent(category.label);
                context.push('/owner/reports/aging/$encodedCategory', extra: category.customerIds);
              }
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          title: Text(
            category.label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            '${category.customerCount} Customers',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FinancialCalculator.formatCurrency(category.totalBalance),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? AppColors.success : AppColors.error,
                  fontSize: 14,
                ),
              ),
              if (category.customerCount > 0) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.textLight),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionProgress(
    BuildContext context,
    double totalDebt,
    double totalCollected,
  ) {
    final double percentage = totalDebt > 0 ? (totalCollected / totalDebt).clamp(0.0, 1.0) : 0;

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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Collection Progress', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 0.7 ? AppColors.success : AppColors.warning,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Collected ${FinancialCalculator.formatCurrency(totalCollected)} out of ${FinancialCalculator.formatCurrency(totalDebt)} debt issued.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
