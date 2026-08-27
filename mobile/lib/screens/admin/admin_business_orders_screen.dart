import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/admin_section_topbar.dart';

const _statusColors = {
  OrderStatus.newOrder: Color(0xFFCB4B4B),
  OrderStatus.accepted: AppColors.adminGradientMid,
  OrderStatus.preparing: Color(0xFFC9922E),
  OrderStatus.ready: Color(0xFF3B6EA8),
  OrderStatus.completed: Color(0xFF3F9142),
  OrderStatus.cancelled: Color(0xFF8A7E72),
};

/// MIKKA Business mobil "Buyurtmalar" ekrani — [orderListProvider]/
/// [orderStatsProvider] orqali `/places/:placeId/orders` bilan ulangan.
class AdminBusinessOrdersScreen extends ConsumerStatefulWidget {
  const AdminBusinessOrdersScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<AdminBusinessOrdersScreen> createState() =>
      _AdminBusinessOrdersScreenState();
}

class _AdminBusinessOrdersScreenState extends ConsumerState<AdminBusinessOrdersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _refresh() {
    ref.invalidate(orderListProvider(widget.placeId));
    ref.invalidate(orderStatsProvider(widget.placeId));
  }

  Future<void> _advanceStatus(Order order) async {
    final next = order.status.next;
    if (next == null) return;
    try {
      await ref
          .read(orderServiceProvider)
          .updateStatus(widget.placeId, order.id, next);
      _refresh();
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _createOrder() async {
    final result = await showDialog<_NewOrderData>(
      context: context,
      builder: (_) => const _CreateOrderDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(orderServiceProvider).createOrder(
            widget.placeId,
            customerName: result.customerName,
            customerPhone: result.customerPhone,
            items: result.items,
          );
      _refresh();
      if (mounted) _showMessage('Buyurtma yaratildi');
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(orderQueryProvider);
    final ordersAsync = ref.watch(orderListProvider(widget.placeId));
    final statsAsync = ref.watch(orderStatsProvider(widget.placeId));
    final newCount = statsAsync.valueOrNull?.newCount;

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionTopBar(
                title: 'Buyurtmalar',
                onNotification: () => _showMessage('Bildirishnomalar tez orada qo\'shiladi'),
                searchController: _searchController,
                searchHint: 'Buyurtma ID, mijoz bo\'yicha qidirish...',
                onSearchChanged: (value) {
                  ref.read(orderQueryProvider.notifier).update(
                        (q) => q.copyWith(search: value),
                      );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Mijozlar buyurtmalarini boshqaring va kuzating.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.adminBrandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton.icon(
                    onPressed: _createOrder,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Yangi buyurtma',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatusChip(
                      label: 'Barchasi',
                      isSelected: query.status == null,
                      onTap: () => ref.read(orderQueryProvider.notifier).update(
                            (q) => q.copyWith(clearStatus: true),
                          ),
                    ),
                    for (final status in OrderStatus.values) ...[
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: status == OrderStatus.newOrder && newCount != null
                            ? '${status.label} ($newCount)'
                            : status.label,
                        isSelected: query.status == status,
                        color: _statusColors[status],
                        onTap: () => ref.read(orderQueryProvider.notifier).update(
                              (q) => q.copyWith(status: status),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ordersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorState(
                    message: error is ApiException ? error.message : 'Buyurtmalar yuklanmadi',
                    onRetry: _refresh,
                  ),
                  data: (page) {
                    if (page.items.isEmpty) {
                      return Center(
                        child: Text(
                          'Buyurtma topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: page.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _OrderCard(
                        order: page.items[index],
                        onTap: () => _showMessage('Buyurtma tafsilotlari tez orada'),
                        onAdvance: () => _advanceStatus(page.items[index]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  ordersAsync.valueOrNull != null
                      ? '${ordersAsync.value!.items.length} / ${ordersAsync.value!.total} buyurtma'
                      : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Qayta urinish')),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.adminGradientMid;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: chipColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? chipColor : AppColors.mutedText(context),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? chipColor : AppColors.fieldBorder(context)),
      backgroundColor: AppColors.surface(context),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap, required this.onAdvance});

  final Order order;
  final VoidCallback onTap;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[order.status] ?? AppColors.mutedText(context);
    final itemsLabel = order.items.map((i) => '${i.name} x${i.quantity}').join(', ');
    final next = order.status.next;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText(context)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
            if (order.customerPhone != null) ...[
              const SizedBox(height: 4),
              Text(
                order.customerPhone!,
                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              itemsLabel.isEmpty ? '—' : itemsLabel,
              style: TextStyle(fontSize: 13, color: AppColors.darkText(context)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${order.totalAmount} so\'m',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText(context)),
                ),
                const Spacer(),
                if (next != null)
                  OutlinedButton(
                    onPressed: onAdvance,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(next.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewOrderData {
  const _NewOrderData({required this.customerName, this.customerPhone, required this.items});

  final String customerName;
  final String? customerPhone;
  final List<OrderItem> items;
}

class _CreateOrderDialog extends StatefulWidget {
  const _CreateOrderDialog();

  @override
  State<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<_CreateOrderDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _itemNameControllers = [TextEditingController()];
  final _itemQtyControllers = [TextEditingController(text: '1')];
  final _itemPriceControllers = [TextEditingController()];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    for (final c in _itemNameControllers) {
      c.dispose();
    }
    for (final c in _itemQtyControllers) {
      c.dispose();
    }
    for (final c in _itemPriceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      _itemNameControllers.add(TextEditingController());
      _itemQtyControllers.add(TextEditingController(text: '1'));
      _itemPriceControllers.add(TextEditingController());
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      _itemNameControllers.removeAt(index).dispose();
      _itemQtyControllers.removeAt(index).dispose();
      _itemPriceControllers.removeAt(index).dispose();
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final items = <OrderItem>[];
    for (var i = 0; i < _itemNameControllers.length; i++) {
      final itemName = _itemNameControllers[i].text.trim();
      if (itemName.isEmpty) continue;
      final quantity = int.tryParse(_itemQtyControllers[i].text.trim()) ?? 0;
      final price = int.tryParse(_itemPriceControllers[i].text.trim()) ?? 0;
      if (quantity <= 0) continue;
      items.add(OrderItem(name: itemName, quantity: quantity, unitPrice: price));
    }
    if (items.isEmpty) return;

    Navigator.of(context).pop(
      _NewOrderData(
        customerName: name,
        customerPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yangi buyurtma'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Mijoz ismi'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefon (ixtiyoriy)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Mahsulotlar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (var i = 0; i < _itemNameControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _itemNameControllers[i],
                        decoration: const InputDecoration(labelText: 'Nomi'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _itemQtyControllers[i],
                        decoration: const InputDecoration(labelText: 'Soni'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _itemPriceControllers[i],
                        decoration: const InputDecoration(labelText: 'Narxi'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    if (_itemNameControllers.length > 1)
                      IconButton(
                        onPressed: () => _removeItemRow(i),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: _addItemRow,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Qator qo\'shish'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Yaratish')),
      ],
    );
  }
}
