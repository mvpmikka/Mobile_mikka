import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/admin_section_topbar.dart';

enum _StockStatus { available, low, out }

class _InventoryItem {
  const _InventoryItem({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.unit,
    required this.minQty,
    required this.status,
    required this.updatedAt,
  });

  final String name;
  final String sku;
  final num quantity;
  final String unit;
  final num minQty;
  final _StockStatus status;
  final String updatedAt;
}

const _inventory = [
  _InventoryItem(
    name: 'An\'anaviy non',
    sku: 'BRD-001',
    quantity: 24,
    unit: 'dona',
    minQty: 10,
    status: _StockStatus.available,
    updatedAt: 'Bugun, 08:30',
  ),
  _InventoryItem(
    name: 'To\'liq yog\'li sut',
    sku: 'MLK-002',
    quantity: 18,
    unit: 'l',
    minQty: 5,
    status: _StockStatus.available,
    updatedAt: 'Kecha, 18:00',
  ),
  _InventoryItem(
    name: 'Espresso donlari',
    sku: 'COF-001',
    quantity: 2.5,
    unit: 'kg',
    minQty: 5,
    status: _StockStatus.low,
    updatedAt: 'Bugun, 11:45',
  ),
  _InventoryItem(
    name: 'Pomidor',
    sku: 'VEG-012',
    quantity: 12,
    unit: 'kg',
    minQty: 4,
    status: _StockStatus.available,
    updatedAt: 'Kecha, 07:15',
  ),
  _InventoryItem(
    name: 'Dudlangan kurka go\'shti',
    sku: 'MEA-004',
    quantity: 0,
    unit: 'kg',
    minQty: 2.5,
    status: _StockStatus.out,
    updatedAt: 'Bugun, 14:10',
  ),
];

/// MIKKA Business mobil "Ombor" ekrani — Figma dizayni asosidagi sof UI.
/// Barcha zaxira ma'lumotlari lokal namunaviy qiymatlar — hech qanday
/// backend/servis chaqiruvi yo'q.
class AdminBusinessInventoryScreen extends StatefulWidget {
  const AdminBusinessInventoryScreen({super.key});

  @override
  State<AdminBusinessInventoryScreen> createState() => _AdminBusinessInventoryScreenState();
}

class _AdminBusinessInventoryScreenState extends State<AdminBusinessInventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_InventoryItem> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _inventory;
    return _inventory.where((item) => item.name.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = _inventory.where((item) => item.status == _StockStatus.low).length;
    final outCount = _inventory.where((item) => item.status == _StockStatus.out).length;
    final items = _filtered;

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
                onSearchChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'JAMI MAHSULOT',
                      value: '${_inventory.length}',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF3F9142),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'KAM QOLGAN',
                      value: '$lowCount',
                      icon: Icons.warning_amber_outlined,
                      color: const Color(0xFFC9922E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'TUGAGAN',
                      value: '$outCount',
                      icon: Icons.error_outline,
                      color: const Color(0xFFCB4B4B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMessage('Filtr tez orada qo\'shiladi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkText(context),
                        side: BorderSide(color: AppColors.fieldBorder(context)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.filter_list, size: 16),
                      label: const Text('Filtr'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.adminBrandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: () => _showMessage('Zaxirani sozlash tez orada qo\'shiladi'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Zaxirani sozlash',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'Mahsulot topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _InventoryCard(
                          item: items[index],
                          onRestock: () => _showMessage('${items[index].name} to\'ldirish tez orada qo\'shiladi'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
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
  const _InventoryCard({required this.item, required this.onRestock});

  final _InventoryItem item;
  final VoidCallback onRestock;

  (String, Color) _statusMeta(BuildContext context) {
    switch (item.status) {
      case _StockStatus.available:
        return ('Mavjud', const Color(0xFF3F9142));
      case _StockStatus.low:
        return ('Kam qoldi', const Color(0xFFC9922E));
      case _StockStatus.out:
        return ('Tugagan', const Color(0xFFCB4B4B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusMeta(context);
    final needsRestock = item.status != _StockStatus.available;
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
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${item.sku} • Min: ${item.minQty} ${item.unit}',
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
                        item.updatedAt,
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
                '${item.quantity} ${item.unit}',
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
