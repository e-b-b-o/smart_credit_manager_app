import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/supabase_service.dart';

final agingCustomersProvider = FutureProvider.autoDispose.family<List<CustomerModel>, List<String>>((ref, customerIds) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final allCustomers = await supabaseService.getCustomers();
  return allCustomers.where((c) => customerIds.contains(c.id)).toList();
});

class AgingDrilldownScreen extends ConsumerWidget {
  final String categoryLabel;
  final List<String> customerIds;
  
  const AgingDrilldownScreen({
    super.key,
    required this.categoryLabel,
    required this.customerIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCustomers = ref.watch(agingCustomersProvider(customerIds));

    return Scaffold(
      appBar: AppBar(
        title: Text('Aging: $categoryLabel'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: asyncCustomers.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No customers in this category.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(25),
                    foregroundColor: AppColors.primary,
                    child: Text(customer.name[0].toUpperCase()),
                  ),
                  title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(customer.phone),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/owner/customers/${customer.id}', extra: customer);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
