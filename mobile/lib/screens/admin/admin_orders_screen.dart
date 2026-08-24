import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/order.dart';
import '../../models/place.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';

String _formatUzs(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}${buffer.toString()} so\'m';
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
}

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key, required this.place});

  final Place place;

  void _invalidate(WidgetRef ref) {
    ref.invalidate(orderStatsProvider(place.id));
    ref.invalidate(orderListProvider(place.id));
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return const Color(0xFF3B6FE0);
      case OrderStatus.accepted:
        return const Color(0xFF6C4FD6);
      case OrderStatus.preparing:
        return const Color(0xFFC98A2C);
      case OrderStatus.ready:
        return const Color(0xFF2CA5A0);
      case OrderStatus.completed:
        return const Color(0xFF3F9142);
      case OrderStatus.cancelled:
        return const Color(0xFFCB4B4B);
    }
  }

  Future<void> _advanceStatus(BuildContext context, WidgetRef ref, Order order) async {
    final next = order.status.next;
    if (next == null) return;
    try {
      await ref.read(orderServiceProvider).updateStatus(place.id, order.id, next);
      _invalidate(ref);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buyurtmani bekor qilish'),
        content: Text('#${order.id.substring(0, 8)} buyurtmasi bekor qilinsinmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Yo\'q'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFCB4B4B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bekor qilish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(orderServiceProvider)
          .updateStatus(place.id, order.id, OrderStatus.cancelled);
      _invalidate(ref);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    }
  }

  Future<void> _showNewOrderSheet(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final items = <(TextEditingController name, TextEditingController qty, TextEditingController price)>[
      (TextEditingController(), TextEditingController(text: '1'), TextEditingController()),
    ];

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yangi buyurtma',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText(sheetContext),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Mijoz ismi'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Mijoz ismi kerak' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Telefon (ixtiyoriy)'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mahsulotlar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText(sheetContext),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < items.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: items[i].$1,
                                  decoration: const InputDecoration(labelText: 'Nomi'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? '?' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: items[i].$2,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Soni'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: items[i].$3,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Narx'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? '?' : null,
                                ),
                              ),
                              if (items.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() => items.removeAt(i)),
                                ),
                            ],
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => setState(() => items.add(
                              (
                                TextEditingController(),
                                TextEditingController(text: '1'),
                                TextEditingController(),
                              ),
                            )),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Mahsulot qo\'shish'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            final orderItems = <OrderItem>[];
                            for (final row in items) {
                              final name = row.$1.text.trim();
                              final qty = int.tryParse(row.$2.text) ?? 0;
                              final price = int.tryParse(row.$3.text) ?? 0;
                              if (name.isEmpty || qty <= 0) continue;
                              orderItems.add(OrderItem(name: name, quantity: qty, unitPrice: price));
                            }
                            if (orderItems.isEmpty) return;
                            try {
                              await ref.read(orderServiceProvider).createOrder(
                                    place.id,
                                    customerName: nameController.text.trim(),
                                    customerPhone: phoneController.text.trim().isEmpty
                                        ? null
                                        : phoneController.text.trim(),
                                    items: orderItems,
                                  );
                              if (sheetContext.mounted) Navigator.of(sheetContext).pop(true);
                            } on ApiException catch (e) {
                              if (!sheetContext.mounted) return;
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                  content: Text(e.message),
                                  backgroundColor: const Color(0xFFCB4B4B),
                                ),
                              );
                            }
                          },
                          child: const Text('Yaratish'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (created == true) _invalidate(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(orderStatsProvider(place.id));
    final ordersAsync = ref.watch(orderListProvider(place.id));
    final query = ref.watch(orderQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        foregroundColor: AppColors.darkText(context),
        title: Text(
          '${place.name} — Buyurtmalar',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText(context)),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async => _invalidate(ref),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Mijoz, telefon yoki ID bo\'yicha qidirish',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.fieldBorder(context)),
                  ),
                ),
                onChanged: (value) {
                  ref.read(orderQueryProvider.notifier).state =
                      query.copyWith(search: value.trim().isEmpty ? null : value.trim());
                },
              ),
              const SizedBox(height: 10),
              statsAsync.when(
                loading: () => const SizedBox(
                  height: 36,
                  child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (stats) {
                  int countFor(OrderStatus? status) {
                    switch (status) {
                      case null:
                        return stats.newCount +
                            stats.acceptedCount +
                            stats.preparingCount +
                            stats.readyCount +
                            stats.completedCount +
                            stats.cancelledCount;
                      case OrderStatus.newOrder:
                        return stats.newCount;
                      case OrderStatus.accepted:
                        return stats.acceptedCount;
                      case OrderStatus.preparing:
                        return stats.preparingCount;
                      case OrderStatus.ready:
                        return stats.readyCount;
                      case OrderStatus.completed:
                        return stats.completedCount;
                      case OrderStatus.cancelled:
                        return stats.cancelledCount;
                    }
                  }

                  return SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _StatusChip(
                          label: 'Barchasi (${countFor(null)})',
                          selected: query.status == null,
                          onTap: () => ref.read(orderQueryProvider.notifier).state =
                              query.copyWith(clearStatus: true),
                        ),
                        const SizedBox(width: 8),
                        for (final status in OrderStatus.values) ...[
                          _StatusChip(
                            label: '${status.label} (${countFor(status)})',
                            selected: query.status == status,
                            onTap: () => ref.read(orderQueryProvider.notifier).state =
                                query.copyWith(status: status),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ordersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      e is ApiException ? e.message : 'Xatolik yuz berdi',
                      style: TextStyle(color: AppColors.mutedText(context)),
                    ),
                  ),
                ),
                data: (page) {
                  if (page.items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Text(
                        'Buyurtma topilmadi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final order in page.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.fieldBorder(context)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '#${order.id.substring(0, 8)}  •  ${order.customerName}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.darkText(context),
                                            ),
                                          ),
                                          if (order.customerPhone != null)
                                            Text(
                                              order.customerPhone!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.mutedText(context),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(order.status).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        order.status.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _statusColor(order.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  order.items.map((i) => '${i.name} x${i.quantity}').join(', '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _formatUzs(order.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDateTime(order.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.mutedText(context),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!order.status.isTerminal) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (order.status.next != null)
                                        Expanded(
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.orange,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => _advanceStatus(context, ref, order),
                                            child: Text(order.status.next!.label),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFCB4B4B),
                                          side: const BorderSide(color: Color(0xFFCB4B4B)),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        onPressed: () => _cancelOrder(context, ref, order),
                                        child: const Text('Bekor qilish'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        onPressed: () => _showNewOrderSheet(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.orange.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? AppColors.orange : AppColors.mutedText(context),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: AppColors.surface(context),
      side: BorderSide(color: AppColors.fieldBorder(context)),
    );
  }
}
