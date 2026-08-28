import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/admin_section_topbar.dart';

String _fmtDate(DateTime d) {
  final now = DateTime.now();
  final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return 'Bugun, $time';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) {
    return 'Kecha, $time';
  }
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// MIKKA Business mobil "Ombor" ekrani — 1-bosqichda ulangan Mahsulot
/// backendining boshqa ko'rinishi. [productListProvider]/[productStatsProvider]
/// orqali `/places/:placeId/products` bilan ulangan.
class AdminBusinessInventoryScreen extends ConsumerStatefulWidget {
  const AdminBusinessInventoryScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<AdminBusinessInventoryScreen> createState() =>
      _AdminBusinessInventoryScreenState();
}

class _AdminBusinessInventoryScreenState extends ConsumerState<AdminBusinessInventoryScreen> {
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
    ref.invalidate(productListProvider(widget.placeId));
    ref.invalidate(productStatsProvider(widget.placeId));
  }

  Future<void> _restock(Product product) async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${product.name} to\'ldirish'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Qo\'shiladigan miqdor'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.of(dialogContext).pop(value != null && value > 0 ? value : null);
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    try {
      await ref.read(productServiceProvider).adjustStock(widget.placeId, product.id, amount);
      _refresh();
      if (mounted) _showMessage('Zaxira yangilandi');
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider(widget.placeId));
    final statsAsync = ref.watch(productStatsProvider(widget.placeId));
    final stats = statsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionTopBar(
                title: 'Ombor',
                onNotification: () => _showMessage('Bildirishnomalar tez orada qo\'shiladi'),
                searchController: _searchController,
                searchHint: 'Zaxirani qidirish...',
                onSearchChanged: (value) {
                  ref.read(productQueryProvider.notifier).update(
                        (q) => q.copyWith(search: value),
                      );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'JAMI MAHSULOT',
                      value: '${stats?.totalProducts ?? '—'}',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF3F9142),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'KAM QOLGAN',
                      value: '${stats?.lowStock ?? '—'}',
                      icon: Icons.warning_amber_outlined,
                      color: const Color(0xFFC9922E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'TUGAGAN',
                      value: '${stats?.outOfStock ?? '—'}',
                      icon: Icons.error_outline,
                      color: const Color(0xFFCB4B4B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatusChip(
                      label: 'Barchasi',
                      isSelected: ref.watch(productQueryProvider).status == null,
                      onTap: () => ref.read(productQueryProvider.notifier).update(
                            (q) => q.copyWith(clearStatus: true),
                          ),
                    ),
                    for (final status in ProductStatus.values) ...[
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: status.label,
                        isSelected: ref.watch(productQueryProvider).status == status,
                        onTap: () => ref.read(productQueryProvider.notifier).update(
                              (q) => q.copyWith(status: status),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: productsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorState(
                    message: error is ApiException ? error.message : 'Mahsulotlar yuklanmadi',
                    onRetry: _refresh,
                  ),
                  data: (page) {
                    if (page.items.isEmpty) {
                      return Center(
                        child: Text(
                          'Mahsulot topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: page.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _InventoryCard(
                        product: page.items[index],
                        onRestock: () => _restock(page.items[index]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  productsAsync.valueOrNull != null
                      ? '${productsAsync.value!.items.length} / ${productsAsync.value!.total} mahsulot'
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
  const _StatusChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipColor = AppColors.adminGradientMid;
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: color,
                  ),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.product, required this.onRestock});

  final Product product;
  final VoidCallback onRestock;

  (String, Color) _statusMeta() {
    switch (product.status) {
      case ProductStatus.inStock:
        return ('Mavjud', const Color(0xFF3F9142));
      case ProductStatus.lowStock:
        return ('Kam qoldi', const Color(0xFFC9922E));
      case ProductStatus.outOfStock:
        return ('Tugagan', const Color(0xFFCB4B4B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusMeta();
    final needsRestock = product.status != ProductStatus.inStock;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: needsRestock ? statusColor.withValues(alpha: 0.4) : AppColors.fieldBorder(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${product.sku} • Min: ${product.lowStockThreshold}',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fmtDate(product.updatedAt),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: statusColor,
                ),
              ),
              if (needsRestock) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: onRestock,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: statusColor,
                      side: BorderSide(color: statusColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('TO\'LDIRISH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
