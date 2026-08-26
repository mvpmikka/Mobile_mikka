import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/admin_section_topbar.dart';

class _ProductItem {
  _ProductItem({
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.available,
    required this.stockLabel,
    required this.stockColor,
  });

  final String name;
  final String sku;
  final String category;
  final String price;
  bool available;
  final String stockLabel;
  final Color stockColor;
}

final _allProducts = [
  _ProductItem(
    name: 'Tovuq lavash',
    sku: 'FD-001',
    category: 'Ovqat',
    price: '35 000',
    available: true,
    stockLabel: 'Mavjud (120)',
    stockColor: const Color(0xFF3F9142),
  ),
  _ProductItem(
    name: 'Klassik burger',
    sku: 'FD-014',
    category: 'Ovqat',
    price: '45 000',
    available: true,
    stockLabel: 'Kam qoldi (8)',
    stockColor: const Color(0xFFC9922E),
  ),
  _ProductItem(
    name: 'Kapuchino',
    sku: 'BV-102',
    category: 'Ichimlik',
    price: '18 000',
    available: false,
    stockLabel: 'Mavjud emas',
    stockColor: const Color(0xFF8A7E72),
  ),
];

/// MIKKA Business mobil "Mahsulotlar va xizmatlar" ekrani — Figma dizayni
/// asosidagi sof UI. Mahsulotlar ro'yxati lokal namunaviy ma'lumot —
/// hech qanday backend/servis chaqiruvi yo'q.
class AdminBusinessProductsScreen extends StatefulWidget {
  const AdminBusinessProductsScreen({super.key});

  @override
  State<AdminBusinessProductsScreen> createState() => _AdminBusinessProductsScreenState();
}

class _AdminBusinessProductsScreenState extends State<AdminBusinessProductsScreen> {
  final _searchController = TextEditingController();
  String _filter = 'Barchasi';
  static const _filters = ['Barchasi', 'Ovqat', 'Ichimlik'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_ProductItem> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _allProducts.where((product) {
      final matchesFilter = _filter == 'Barchasi' || product.category == _filter;
      final matchesQuery = query.isEmpty || product.name.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;
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
                onSearchChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Katalog, narx va mavjudlikni boshqaring.',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.adminBrandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _showMessage('Mahsulot qo\'shish tez orada qo\'shiladi'),
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
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _filter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filter = filter),
                      selectedColor: AppColors.adminGradientMid.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.adminGradientMid
                            : AppColors.mutedText(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.adminGradientMid
                            : AppColors.fieldBorder(context),
                      ),
                      backgroundColor: AppColors.surface(context),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          'Mahsulot topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final product = products[index];
                          return _ProductCard(
                            product: product,
                            onAvailabilityChanged: (value) =>
                                setState(() => product.available = value),
                            onTap: () => _showMessage('${product.name} tafsilotlari tez orada'),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${products.length} / ${_allProducts.length} mahsulot ko\'rsatilmoqda',
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onAvailabilityChanged,
    required this.onTap,
  });

  final _ProductItem product;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText(context),
                    ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cream(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.fieldBorder(context)),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(fontSize: 10, color: AppColors.darkText(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: product.stockColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.stockLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: product.stockColor),
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
                  '${product.price} so\'m',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.darkText(context),
                  ),
                ),
                Switch(
                  value: product.available,
                  onChanged: onAvailabilityChanged,
                  activeThumbColor: AppColors.adminGradientMid,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
