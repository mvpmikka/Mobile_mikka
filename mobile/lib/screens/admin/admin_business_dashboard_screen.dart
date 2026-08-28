import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../models/place.dart';
import '../../models/product.dart';
import '../../providers/order_provider.dart';
import '../../providers/place_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import 'admin_business_bookings_screen.dart';
import 'admin_business_customers_screen.dart';
import 'admin_business_inventory_screen.dart';
import 'admin_business_orders_screen.dart';
import 'admin_business_place_detail_screen.dart';
import 'admin_business_products_screen.dart';
import 'admin_business_reviews_screen.dart';
import 'admin_location_select_screen.dart';

/// MIKKA Business mobil boshqaruv paneli — Figma dizayni asosidagi UI,
/// [myPlacesProvider]/[orderStatsProvider]/[productStatsProvider] orqali
/// haqiqiy backend ma'lumotlariga ulangan. Backendda hali izlanmagan
/// ko'rsatkichlar (tashriflar, profil ko'rishlar, bandlar) shu bosqichda
/// ko'rsatilmaydi — soxta raqam qoldirmaslik uchun.
class AdminBusinessDashboardScreen extends ConsumerStatefulWidget {
  const AdminBusinessDashboardScreen({super.key});

  @override
  ConsumerState<AdminBusinessDashboardScreen> createState() =>
      _AdminBusinessDashboardScreenState();
}

class _AdminBusinessDashboardScreenState
    extends ConsumerState<AdminBusinessDashboardScreen> {
  int _selectedPlaceIndex = 0;
  int _bottomNavIndex = 0;

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature tez orada qo\'shiladi')),
    );
  }

  void _openPlaceSwitcher(List<BusinessPlace> places) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'JOYNI ALMASHTIRISH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.mutedText(sheetContext),
                    ),
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: places.length,
                itemBuilder: (_, index) {
                  final place = places[index];
                  final isCurrent = index == _selectedPlaceIndex;
                  return ListTile(
                    onTap: () {
                      setState(() => _selectedPlaceIndex = index);
                      Navigator.of(sheetContext).pop();
                    },
                    leading: CircleAvatar(
                      backgroundColor: AppColors.adminGradientMid,
                      child: Text(
                        _initialsFor(place.name),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(
                      place.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText(sheetContext),
                      ),
                    ),
                    subtitle: Text(
                      place.address ?? '',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(sheetContext)),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, size: 18, color: Color(0xFF3F9142))
                        : null,
                  );
                },
              ),
              const Padding(padding: EdgeInsets.only(top: 4)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminLocationSelectScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkText(context),
                      side: BorderSide(color: AppColors.fieldBorder(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Yangi joy qo\'shish'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _initialsFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(myPlacesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.adminBrandGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mikka Business',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.darkText(context),
                          ),
                        ),
                        Text(
                          'Boshqaruv platformasi',
                          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showSoon('Bildirishnomalar'),
                    icon: Icon(Icons.notifications_outlined, color: AppColors.darkText(context)),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.adminGradientMid,
                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: placesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: 'Joylar yuklanmadi: $error',
                  onRetry: () => ref.invalidate(myPlacesProvider),
                ),
                data: (places) {
                  if (places.isEmpty) {
                    return _EmptyPlacesState(
                      onAddPlace: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminLocationSelectScreen()),
                      ),
                    );
                  }
                  final index = _selectedPlaceIndex.clamp(0, places.length - 1);
                  final place = places[index];
                  return _DashboardBody(
                    place: place,
                    onSwitchPlace: () => _openPlaceSwitcher(places),
                    onOpenOrders: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminBusinessOrdersScreen(placeId: place.id),
                      ),
                    ),
                    onOpenProducts: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminBusinessProductsScreen(placeId: place.id),
                      ),
                    ),
                    onDateFilter: () => _showSoon('Sana filtri'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (index) {
          if (index == 4) {
            _openMoreMenu();
            return;
          }
          if (index == 1) {
            final places = placesAsync.valueOrNull;
            if (places == null || places.isEmpty) return;
            final place = places[_selectedPlaceIndex.clamp(0, places.length - 1)];
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminBusinessOrdersScreen(placeId: place.id),
              ),
            );
            return;
          }
          if (index == 2) {
            final places = placesAsync.valueOrNull;
            if (places == null || places.isEmpty) return;
            final place = places[_selectedPlaceIndex.clamp(0, places.length - 1)];
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminBusinessBookingsScreen(placeId: place.id),
              ),
            );
            return;
          }
          setState(() => _bottomNavIndex = index);
          if (index != 0) _showSoon(['', '', '', 'Chat'][index]);
        },
        backgroundColor: AppColors.surface(context),
        indicatorColor: AppColors.adminGradientMid.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Bosh sahifa'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Buyurtmalar'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Bandlar'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Ko\'proq'),
        ],
      ),
    );
  }

  void _openMoreMenu() {
    const items = [
      (Icons.storefront_outlined, 'Joy'),
      (Icons.inventory_2_outlined, 'Mahsulotlar'),
      (Icons.warehouse_outlined, 'Ombor'),
      (Icons.people_outline, 'Mijozlar'),
      (Icons.star_border, 'Sharhlar'),
      (Icons.article_outlined, 'Kontent'),
      (Icons.bar_chart_outlined, 'Analitika'),
      (Icons.groups_2_outlined, 'Jamoa'),
      (Icons.extension_outlined, 'Integratsiyalar'),
      (Icons.settings_outlined, 'Sozlamalar'),
      (Icons.account_circle_outlined, 'Profil'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: items.map((item) {
              return InkWell(
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  switch (item.$2) {
                    case 'Joy':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminBusinessPlaceDetailScreen(),
                        ),
                      );
                    case 'Mahsulotlar':
                      final places = ref.read(myPlacesProvider).valueOrNull;
                      if (places == null || places.isEmpty) {
                        _showSoon('Mahsulotlar');
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminBusinessProductsScreen(
                            placeId: places[_selectedPlaceIndex.clamp(0, places.length - 1)].id,
                          ),
                        ),
                      );
                    case 'Ombor':
                      final places = ref.read(myPlacesProvider).valueOrNull;
                      if (places == null || places.isEmpty) {
                        _showSoon('Ombor');
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminBusinessInventoryScreen(
                            placeId: places[_selectedPlaceIndex.clamp(0, places.length - 1)].id,
                          ),
                        ),
                      );
                    case 'Mijozlar':
                      final places = ref.read(myPlacesProvider).valueOrNull;
                      if (places == null || places.isEmpty) {
                        _showSoon('Mijozlar');
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminBusinessCustomersScreen(
                            placeId: places[_selectedPlaceIndex.clamp(0, places.length - 1)].id,
                          ),
                        ),
                      );
                    case 'Sharhlar':
                      final places = ref.read(myPlacesProvider).valueOrNull;
                      if (places == null || places.isEmpty) {
                        _showSoon('Sharhlar');
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminBusinessReviewsScreen(
                            placeId: places[_selectedPlaceIndex.clamp(0, places.length - 1)].id,
                          ),
                        ),
                      );
                    default:
                      _showSoon(item.$2);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.$1, color: AppColors.orange),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.darkText(sheetContext)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _EmptyPlacesState extends StatelessWidget {
  const _EmptyPlacesState({required this.onAddPlace});

  final VoidCallback onAddPlace;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 48, color: AppColors.mutedText(context)),
            const SizedBox(height: 12),
            Text(
              'Sizda hali joy yo\'q',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Boshqaruv panelidan foydalanish uchun avval biznesingizga tegishli joyni qo\'shing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAddPlace,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Yangi joy qo\'shish'),
            ),
          ],
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

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.place,
    required this.onSwitchPlace,
    required this.onOpenOrders,
    required this.onOpenProducts,
    required this.onDateFilter,
  });

  final BusinessPlace place;
  final VoidCallback onSwitchPlace;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenProducts;
  final VoidCallback onDateFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderStatsAsync = ref.watch(orderStatsProvider(place.id));
    final productStatsAsync = ref.watch(productStatsProvider(place.id));
    final recentOrdersAsync = ref.watch(orderListProvider(place.id));
    final lowStockAsync = ref.watch(
      productListProvider(place.id).select((value) => value),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onSwitchPlace,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder(context)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.adminGradientMid,
                    radius: 16,
                    child: Text(
                      _AdminBusinessDashboardScreenState._initialsFor(place.name),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.darkText(context),
                          ),
                        ),
                        Text(
                          place.address ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: AppColors.mutedText(context)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.unfold_more, size: 18, color: AppColors.mutedText(context)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Umumiy ko\'rinish',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText(context),
                  ),
                ),
              ),
              InkWell(
                onTap: onDateFilter,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.fieldBorder(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.darkText(context)),
                      const SizedBox(width: 6),
                      Text('Bugun',
                          style: TextStyle(fontSize: 12, color: AppColors.darkText(context))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Joyingizda nima sodir bo\'lyapti.',
            style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              orderStatsAsync.when(
                loading: () => const _StatCardLoading(
                  label: 'Buyurtmalar',
                  icon: Icons.receipt_long_outlined,
                ),
                error: (_, _) => const _StatCardError(
                  label: 'Buyurtmalar',
                  icon: Icons.receipt_long_outlined,
                ),
                data: (stats) {
                  final total = stats.newCount +
                      stats.acceptedCount +
                      stats.preparingCount +
                      stats.readyCount +
                      stats.completedCount +
                      stats.cancelledCount;
                  return _StatCard(
                    label: 'Buyurtmalar',
                    value: '$total',
                    delta: '${stats.newCount} yangi',
                    icon: Icons.receipt_long_outlined,
                    deltaIsNeutral: true,
                  );
                },
              ),
              productStatsAsync.when(
                loading: () => const _StatCardLoading(
                  label: 'Ombor ogohlantirishlari',
                  icon: Icons.warning_amber_outlined,
                ),
                error: (_, _) => const _StatCardError(
                  label: 'Ombor ogohlantirishlari',
                  icon: Icons.warning_amber_outlined,
                ),
                data: (stats) => _StatCard(
                  label: 'Ombor ogohlantirishlari',
                  value: '${stats.lowStock + stats.outOfStock}',
                  delta: '${stats.outOfStock} tugagan',
                  icon: Icons.warning_amber_outlined,
                  deltaIsNeutral: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Ombor ogohlantirishlari',
            icon: Icons.warning_amber_outlined,
            titleColor: const Color(0xFFCB4B4B),
            trailing: TextButton(
              onPressed: onOpenProducts,
              child: const Text('Barchasini ko\'rish'),
            ),
            child: lowStockAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (error, _) => Text(
                'Ombor holatini yuklab bo\'lmadi',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              data: (page) {
                final alerts = page.items
                    .where((p) => p.status != ProductStatus.inStock)
                    .take(3)
                    .toList();
                if (alerts.isEmpty) {
                  return Text(
                    'Ombor ogohlantirishlari yo\'q',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < alerts.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _InventoryAlertRow(
                        icon: Icons.inventory_2_outlined,
                        label: alerts[i].name,
                        badge: alerts[i].status.label,
                        badgeColor: alerts[i].status == ProductStatus.outOfStock
                            ? const Color(0xFFCB4B4B)
                            : AppColors.mutedText(context),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'So\'nggi buyurtmalar',
            icon: Icons.receipt_long_outlined,
            trailing: TextButton(
              onPressed: onOpenOrders,
              child: const Text('Barchasini ko\'rish'),
            ),
            child: recentOrdersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (error, _) => Text(
                'Buyurtmalarni yuklab bo\'lmadi',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              data: (page) {
                final orders = page.items.take(3).toList();
                if (orders.isEmpty) {
                  return Text(
                    'Hali buyurtmalar yo\'q',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < orders.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _OrderRow(order: orders[i]),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    this.titleColor,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color? titleColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: titleColor ?? const Color(0xFF5D4038)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? AppColors.darkText(context),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    this.deltaIsNeutral = false,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final bool deltaIsNeutral;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: AppColors.orange),
              ),
              const Spacer(),
              Text(
                delta,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: deltaIsNeutral ? AppColors.mutedText(context) : const Color(0xFF3F9142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }
}

class _StatCardLoading extends StatelessWidget {
  const _StatCardLoading({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.mutedText(context)),
          const SizedBox(height: 10),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }
}

class _StatCardError extends StatelessWidget {
  const _StatCardError({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.mutedText(context)),
          const SizedBox(height: 10),
          Text(
            '—',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }
}

class _InventoryAlertRow extends StatelessWidget {
  const _InventoryAlertRow({
    required this.icon,
    required this.label,
    required this.badge,
    required this.badgeColor,
  });

  final IconData icon;
  final String label;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5D4038)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.darkText(context)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
          ),
        ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  static const _statusColors = {
    OrderStatus.newOrder: Color(0xFFCB4B4B),
    OrderStatus.accepted: Color(0xFF3B6EA8),
    OrderStatus.preparing: AppColors.adminGradientMid,
    OrderStatus.ready: Color(0xFF3F9142),
    OrderStatus.completed: Color(0xFF3F9142),
    OrderStatus.cancelled: Color(0xFF6B6B6B),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[order.status] ?? AppColors.mutedText(context);
    final itemsLabel = order.items.map((i) => i.name).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cream(context),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${order.id.substring(0, order.id.length.clamp(0, 6))}',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            itemsLabel.isEmpty ? order.customerName : itemsLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                order.customerName,
                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
              ),
              const Spacer(),
              Text(
                '${order.totalAmount} so\'m',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
