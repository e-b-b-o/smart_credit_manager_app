import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/financial_calculator.dart';
import '../dashboard/owner_dashboard_screen.dart' show dashboardStatsProvider;
import '../transactions/transaction_screen.dart' show allTransactionsProvider;

class CustomerListItem {
  final CustomerModel customer;
  final PaymentStatus status;
  final double totalDebt;
  final double totalPaid;
  final double outstanding;

  CustomerListItem({
    required this.customer,
    required this.status,
    required this.totalDebt,
    required this.totalPaid,
    required this.outstanding,
  });
}

final customersProvider = FutureProvider.autoDispose<List<CustomerModel>>((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return supabaseService.getCustomers();
});

final customerListStatsProvider = FutureProvider.autoDispose<List<CustomerListItem>>((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final customers = await supabaseService.getCustomers();
  final transactions = await supabaseService.getAllTransactions();

  return customers.map((customer) {
    final customerTxs = transactions.where((t) => t.customerId == customer.id).toList();
    final debt = FinancialCalculator.calculateTotalCredits(customerTxs);
    final paid = FinancialCalculator.calculateTotalPayments(customerTxs);
    final outstanding = FinancialCalculator.calculateRemainingBalance(customerTxs);
    final status = FinancialCalculator.calculatePaymentStatus(customerTxs);

    return CustomerListItem(
      customer: customer,
      status: status,
      totalDebt: debt,
      totalPaid: paid,
      outstanding: outstanding,
    );
  }).toList();
});

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Fully Paid, Partially Paid, Overdue

  void _showCreateCredentialsDialog(
    BuildContext context,
    WidgetRef ref,
    CustomerModel customer,
  ) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Login Credentials'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (emailController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          return;
                        }
                        setState(() => isLoading = true);
                        try {
                          await ref
                              .read(supabaseServiceProvider)
                              .createCustomerCredentials(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                                customer.id,
                              );
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Credentials created successfully'),
                            ),
                          );
                          ref.invalidate(customersProvider);
                          ref.invalidate(customerListStatsProvider);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Error: $e')));
                          setState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final creditLimitController = TextEditingController(text: '0');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Customer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: creditLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Credit Limit (ETB)',
                      hintText: 'e.g. 5000',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty ||
                            phoneController.text.trim().isEmpty) {
                          return;
                        }
                        final creditLimit =
                            double.tryParse(creditLimitController.text) ?? 0.0;

                        setState(() => isLoading = true);
                        try {
                          final customer = await ref
                              .read(supabaseServiceProvider)
                              .addCustomer(
                                nameController.text.trim(),
                                phoneController.text.trim(),
                                creditLimit: creditLimit,
                              );
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ref.invalidate(customersProvider);
                          ref.invalidate(customerListStatsProvider);
                          ref.invalidate(dashboardStatsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer added successfully'),
                            ),
                          );

                          // Prompt to create login
                          _showCreateCredentialsDialog(context, ref, customer);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Error: $e')));
                          setState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdateLimitDialog(
    BuildContext context,
    WidgetRef ref,
    CustomerModel customer,
  ) {
    final limitController = TextEditingController(
      text: customer.creditLimit.toString(),
    );
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update Credit Limit'),
            content: TextField(
              controller: limitController,
              decoration: const InputDecoration(
                labelText: 'Credit Limit (ETB)',
                hintText: 'e.g. 5000',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final limit = double.tryParse(limitController.text);
                        if (limit == null || limit < 0) return;

                        setState(() => isLoading = true);
                        try {
                          await ref
                              .read(supabaseServiceProvider)
                              .updateCustomerCreditLimit(customer.id, limit);
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ref.invalidate(customersProvider);
                          ref.invalidate(customerListStatsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Credit limit updated'),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Error: $e')));
                          setState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.textLight.withAlpha(50)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.textLight.withAlpha(50)),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          // Filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Fully Paid'),
                const SizedBox(width: 8),
                _buildFilterChip('Partially Paid'),
                const SizedBox(width: 8),
                _buildFilterChip('Overdue'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: customersAsync.when(
              data: (items) {
                // Apply filters
                final filtered = items.where((item) {
                  // Search
                  final matchesSearch = item.customer.name.toLowerCase().contains(_searchQuery) ||
                                        item.customer.phone.contains(_searchQuery);
                  if (!matchesSearch) return false;

                  // Status Filter
                  if (_selectedFilter == 'All') return true;
                  if (_selectedFilter == 'Fully Paid' && item.status == PaymentStatus.paid) return true;
                  if (_selectedFilter == 'Partially Paid' && item.status == PaymentStatus.partial) return true;
                  if (_selectedFilter == 'Overdue' && item.status == PaymentStatus.overdue) return true;
                  
                  return false;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No customers match your criteria.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildCustomerCard(item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddCustomerDialog(context, ref),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      backgroundColor: AppColors.card,
      selectedColor: AppColors.primary.withAlpha(30),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textLight,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.textLight.withAlpha(50),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerListItem item) {
    Color statusColor;
    String statusText;

    switch (item.status) {
      case PaymentStatus.paid:
        statusColor = AppColors.success;
        statusText = 'PAID';
        break;
      case PaymentStatus.partial:
        statusColor = AppColors.warning;
        statusText = 'PARTIAL';
        break;
      case PaymentStatus.overdue:
        statusColor = AppColors.error;
        statusText = 'OVERDUE';
        break;
      case PaymentStatus.pending:
      default:
        statusColor = AppColors.textLight;
        statusText = 'PENDING';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/owner/customers/${item.customer.id}', extra: item.customer);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(25),
                    foregroundColor: AppColors.primary,
                    child: Text(item.customer.name[0].toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          item.customer.phone,
                          style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withAlpha(100)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textLight, size: 20),
                    onSelected: (value) async {
                      if (value == 'create_login') {
                        _showCreateCredentialsDialog(context, ref, item.customer);
                      } else if (value == 'set_limit') {
                        _showUpdateLimitDialog(context, ref, item.customer);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Customer'),
                            content: const Text(
                              'Are you sure you want to permanently delete this customer and all related records?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(supabaseServiceProvider).deleteCustomer(item.customer.id);
                          ref.invalidate(customersProvider);
                          ref.invalidate(customerListStatsProvider);
                          ref.invalidate(dashboardStatsProvider);
                          ref.invalidate(allTransactionsProvider);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      if (item.customer.authUserId == null)
                        const PopupMenuItem(value: 'create_login', child: Text('Create Login')),
                      const PopupMenuItem(value: 'set_limit', child: Text('Set Credit Limit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFinancialStat('Outstanding', item.outstanding, AppColors.error),
                  _buildFinancialStat('Paid', item.totalPaid, AppColors.success),
                  _buildFinancialStat('Credit', item.totalDebt, AppColors.text),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialStat(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textLight, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          FinancialCalculator.formatCurrency(amount),
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
        ),
      ],
    );
  }
}
