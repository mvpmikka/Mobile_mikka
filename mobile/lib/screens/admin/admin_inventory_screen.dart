import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/place.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/admin_gradient_button.dart';
import 'widgets/admin_loading_indicator.dart';
import 'widgets/admin_text_field.dart';

class AdminInventoryScreen extends ConsumerWidget {
  const AdminInventoryScreen({super.key, required this.place});

  final Place place;

  void _invalidate(WidgetRef ref) {
    ref.invalidate(productStatsProvider(place.id));
    ref.invalidate(productListProvider(place.id));
  }

  Future<void> _showAddProductSheet(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final quantityController = TextEditingController(text: '0');
    final thresholdController = TextEditingController(text: '5');
    final formKey = GlobalKey<FormState>();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yangi mahsulot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText(sheetContext),
                  ),
                ),
                const SizedBox(height: 16),
                AdminTextField(
                  label: 'Nomi',
                  controller: nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nomi kerak' : null,
                ),
                const SizedBox(height: 12),
                AdminTextField(
                  label: 'SKU',
                  controller: skuController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'SKU kerak' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AdminTextField(
                        label: 'Miqdor',
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminTextField(
                        label: 'Kam qolish chegarasi',
                        controller: thresholdController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AdminGradientButton(
                  label: 'Qo\'shish',
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    try {
                      await ref.read(productServiceProvider).createProduct(
                            place.id,
                            name: nameController.text.trim(),
                            sku: skuController.text.trim(),
                            quantity: int.tryParse(quantityController.text) ?? 0,
                            lowStockThreshold: int.tryParse(thresholdController.text) ?? 5,
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
                ),
              ],
            ),
          ),
        );
      },
    );

    if (created == true) _invalidate(ref);
  }

  Future<void> _showAdjustStockSheet(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final amountController = TextEditingController(text: '1');

    Future<void> submit(BuildContext sheetContext, int sign) async {
      final amount = int.tryParse(amountController.text);
      if (amount == null || amount <= 0) return;
      try {
        await ref
            .read(productServiceProvider)
            .adjustStock(place.id, product.id, amount * sign);
        if (sheetContext.mounted) Navigator.of(sheetContext).pop(true);
      } on ApiException catch (e) {
        if (!sheetContext.mounted) return;
        ScaffoldMessenger.of(sheetContext).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
        );
      }
    }

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText(sheetContext),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hozirgi miqdor: ${product.quantity}',
                style: TextStyle(color: AppColors.mutedText(sheetContext)),
              ),
              const SizedBox(height: 16),
              AdminTextField(
                label: 'Miqdor',
                controller: amountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => submit(sheetContext, -1),
                      child: const Text('Kamaytirish'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminGradientButton(
                      label: 'Restock',
                      height: 40,
                      onPressed: () => submit(sheetContext, 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (changed == true) _invalidate(ref);
  }

  Color _statusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.inStock:
        return const Color(0xFF3F9142);
      case ProductStatus.lowStock:
        return const Color(0xFFC98A2C);
      case ProductStatus.outOfStock:
        return const Color(0xFFCB4B4B);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(productStatsProvider(place.id));
    final productsAsync = ref.watch(productListProvider(place.id));
    final query = ref.watch(productQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        foregroundColor: AppColors.darkText(context),
        title: Text(
          place.name,
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
              statsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: AdminLoadingIndicator(),
                  ),
                ),
                error: (e, _) => Text(
                  e is ApiException ? e.message : 'Statistikani yuklab bo\'lmadi',
                  style: TextStyle(color: AppColors.mutedText(context)),
                ),
                data: (stats) => Row(
                  children: [
                    _StatCard(label: 'Jami mahsulot', value: stats.totalProducts),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Kam qoldi',
                      value: stats.lowStock,
                      color: const Color(0xFFC98A2C),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Tugagan',
                      value: stats.outOfStock,
                      color: const Color(0xFFCB4B4B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Nomi yoki SKU bo\'yicha qidirish',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.fieldBorder(context)),
                  ),
                ),
                onChanged: (value) {
                  ref.read(productQueryProvider.notifier).state =
                      query.copyWith(search: value.trim().isEmpty ? null : value.trim());
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatusChip(
                      label: 'Barchasi',
                      selected: query.status == null,
                      onTap: () => ref.read(productQueryProvider.notifier).state =
                          query.copyWith(clearStatus: true),
                    ),
                    const SizedBox(width: 8),
                    for (final status in ProductStatus.values) ...[
                      _StatusChip(
                        label: status.label,
                        selected: query.status == status,
                        onTap: () => ref.read(productQueryProvider.notifier).state =
                            query.copyWith(status: status),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              productsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: AdminLoadingIndicator(),
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
                        'Mahsulot topilmadi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final product in page.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showAdjustStockSheet(context, ref, product),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.fieldBorder(context)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.darkText(context),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'SKU: ${product.sku} • Miqdor: ${product.quantity}',
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
                                      color: _statusColor(product.status).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      product.status.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(product.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
        onPressed: () => _showAddProductSheet(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color = AppColors.orange});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
            ),
          ],
        ),
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
