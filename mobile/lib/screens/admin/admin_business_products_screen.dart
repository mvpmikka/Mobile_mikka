import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/admin_section_topbar.dart';

const _statusColors = {
  ProductStatus.inStock: Color(0xFF3F9142),
  ProductStatus.lowStock: Color(0xFFC9922E),
  ProductStatus.outOfStock: Color(0xFF8A7E72),
};

/// MIKKA Business mobil "Mahsulotlar" ekrani — [productListProvider]/
/// [productStatsProvider] orqali `/places/:placeId/products` bilan ulangan.
///
/// Backend `Product` modelida narx/kategoriya/mavjudlik-o'chirish maydonlari
/// yo'q (faqat name/sku/quantity/lowStockThreshold/status) — shu sababli bu
/// ekranda ular ko'rsatilmaydi, o'rniga real zaxira holati (status) va
/// zaxirani +/- tuzatish mavjud.
class AdminBusinessProductsScreen extends ConsumerStatefulWidget {
  const AdminBusinessProductsScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<AdminBusinessProductsScreen> createState() =>
      _AdminBusinessProductsScreenState();
}

class _AdminBusinessProductsScreenState extends ConsumerState<AdminBusinessProductsScreen> {
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

  Future<void> _adjustStock(Product product, int delta) async {
    try {
      await ref.read(productServiceProvider).adjustStock(widget.placeId, product.id, delta);
      _refresh();
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mahsulotni o\'chirish'),
        content: Text('"${product.name}" o\'chirilsinmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(productServiceProvider).deleteProduct(widget.placeId, product.id);
      _refresh();
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _createProduct() async {
    final result = await showDialog<_NewProductData>(
      context: context,
      builder: (_) => const _CreateProductDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(productServiceProvider).createProduct(
            widget.placeId,
            name: result.name,
            sku: result.sku,
            quantity: result.quantity,
            lowStockThreshold: result.lowStockThreshold,
          );
      _refresh();
      if (mounted) _showMessage('Mahsulot qo\'shildi');
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(productQueryProvider);
    final productsAsync = ref.watch(productListProvider(widget.placeId));

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionTopBar(
                title: 'Mahsulotlar',
                onNotification: () => _showMessage('Bildirishnomalar tez orada qo\'shiladi'),
                searchController: _searchController,
                searchHint: 'Mahsulot qidirish...',
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
                    child: Text(
                      'Katalog va zaxirani boshqaring.',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.adminBrandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton.icon(
                      onPressed: _createProduct,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Qo\'shish', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      isSelected: query.status == null,
                      onTap: () => ref.read(productQueryProvider.notifier).update(
                            (q) => q.copyWith(clearStatus: true),
                          ),
                    ),
                    for (final status in ProductStatus.values) ...[
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: status.label,
                        isSelected: query.status == status,
                        color: _statusColors[status],
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
                      itemBuilder: (_, index) {
                        final product = page.items[index];
                        return _ProductCard(
                          product: product,
                          onIncrement: () => _adjustStock(product, 1),
                          onDecrement: () => _adjustStock(product, -1),
                          onDelete: () => _deleteProduct(product),
                        );
                      },
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[product.status] ?? AppColors.mutedText(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood_outlined, color: AppColors.orange, size: 22),
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
                  'SKU: ${product.sku}',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.status.label} (${product.quantity})',
                      style: TextStyle(fontSize: 11, color: statusColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onDecrement,
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFCB4B4B)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewProductData {
  const _NewProductData({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.lowStockThreshold,
  });

  final String name;
  final String sku;
  final int quantity;
  final int lowStockThreshold;
}

class _CreateProductDialog extends StatefulWidget {
  const _CreateProductDialog();

  @override
  State<_CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<_CreateProductDialog> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _lowStockController = TextEditingController(text: '5');

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final sku = _skuController.text.trim();
    if (name.isEmpty || sku.isEmpty) return;
    Navigator.of(context).pop(
      _NewProductData(
        name: name,
        sku: sku,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        lowStockThreshold: int.tryParse(_lowStockController.text.trim()) ?? 5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yangi mahsulot'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nomi'),
            ),
            TextField(
              controller: _skuController,
              decoration: const InputDecoration(labelText: 'SKU'),
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Boshlang\'ich miqdor'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _lowStockController,
              decoration: const InputDecoration(labelText: 'Kam-qoldi chegarasi'),
              keyboardType: TextInputType.number,
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
