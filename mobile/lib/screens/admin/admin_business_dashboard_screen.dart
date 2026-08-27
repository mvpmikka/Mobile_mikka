import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'admin_business_bookings_screen.dart';
import 'admin_business_inventory_screen.dart';
import 'admin_business_orders_screen.dart';
import 'admin_business_place_detail_screen.dart';
import 'admin_business_products_screen.dart';
import 'admin_location_select_screen.dart';

class _DashboardPlace {
  const _DashboardPlace({
    required this.name,
    required this.address,
    required this.initials,
    required this.color,
    required this.isOpen,
  });

  final String name;
  final String address;
  final String initials;
  final Color color;
  final bool isOpen;
}

const _places = [
  _DashboardPlace(
    name: 'Coffee Lab',
    address: '124-uy, Markaziy ko\'cha, Markaz',
    initials: 'CL',
    color: Color(0xFF8A5A3B),
    isOpen: true,
  ),
  _DashboardPlace(
    name: 'Coffee Lab',
    address: '800-uy, Mega Mall, 2-qavat',
    initials: 'CM',
    color: Color(0xFF3B6EA8),
    isOpen: true,
  ),
  _DashboardPlace(
    name: 'Bella Italia',
    address: '45-uy, Shimoliy ko\'cha, Chekka hudud',
    initials: 'BI',
    color: Color(0xFF6B6B6B),
    isOpen: false,
  ),
];

const _weeklyTrend = [700.0, 700.0, 700.0, 950.0, 1300.0, 1450.0, 1400.0];
const _weekDayLabels = ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];

/// MIKKA Business mobil boshqaruv paneli — Figma dizayni asosidagi sof UI.
/// Barcha ma'lumotlar (statistika, bandlar, ombor, buyurtmalar) lokal
/// namunaviy qiymatlar — hech qanday backend/servis chaqiruvi yo'q.
class AdminBusinessDashboardScreen extends StatefulWidget {
  const AdminBusinessDashboardScreen({super.key});

  @override
  State<AdminBusinessDashboardScreen> createState() =>
      _AdminBusinessDashboardScreenState();
}

class _AdminBusinessDashboardScreenState
    extends State<AdminBusinessDashboardScreen> {
  int _selectedPlace = 0;
  int _bottomNavIndex = 0;

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature tez orada qo\'shiladi')),
    );
  }

  void _openPlaceSwitcher() {
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
                itemCount: _places.length,
                itemBuilder: (_, index) {
                  final place = _places[index];
                  final isCurrent = index == _selectedPlace;
                  return ListTile(
                    onTap: () {
                      setState(() => _selectedPlace = index);
                      Navigator.of(sheetContext).pop();
                    },
                    leading: CircleAvatar(
                      backgroundColor: place.color,
                      child: Text(
                        place.initials,
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
                      place.address,
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(sheetContext)),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: place.isOpen
                                    ? const Color(0xFF3F9142)
                                    : AppColors.mutedText(sheetContext),
                              ),
                            ),
                            Text(
                              place.isOpen ? 'Ochiq' : 'Yopiq',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText(sheetContext),
                              ),
                            ),
                          ],
                        ),
                        if (isCurrent)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle, size: 16, color: Color(0xFF3F9142)),
                          ),
                      ],
                    ),
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

  @override
  Widget build(BuildContext context) {
    final place = _places[_selectedPlace];
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () => _showSoon('Bildirishnomalar'),
                        icon: Icon(Icons.notifications_outlined, color: AppColors.darkText(context)),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFCB4B4B),
                          ),
                        ),
                      ),
                    ],
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _openPlaceSwitcher,
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
                              backgroundColor: place.color,
                              radius: 16,
                              child: Text(
                                place.initials,
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
                                    place.address,
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
                          onTap: () => _showSoon('Sana filtri'),
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
                      'Bugun joyingizda nima sodir bo\'lyapti.',
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
                      children: const [
                        _StatCard(
                          label: 'Bugungi tashriflar',
                          value: '1,284',
                          delta: '+12%',
                          icon: Icons.groups_outlined,
                        ),
                        _StatCard(
                          label: 'Profil ko\'rishlar',
                          value: '3,421',
                          delta: '+8%',
                          icon: Icons.visibility_outlined,
                        ),
                        _StatCard(
                          label: 'Buyurtmalar',
                          value: '187',
                          delta: '+4%',
                          icon: Icons.receipt_long_outlined,
                        ),
                        _StatCard(
                          label: 'Bandlar',
                          value: '42',
                          delta: 'Faol',
                          icon: Icons.event_available_outlined,
                          deltaIsNeutral: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'Tendentsiya',
                      icon: Icons.show_chart,
                      child: SizedBox(
                        height: 160,
                        child: _TrendChart(values: _weeklyTrend, labels: _weekDayLabels),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'Yaqinlashib kelayotgan bandlar',
                      icon: Icons.event_note_outlined,
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminBusinessBookingsScreen()),
                        ),
                        child: const Text('Barchasini ko\'rish'),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cream(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '19:00',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.adminGradientMid,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Aziz',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.darkText(context),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline,
                                              size: 13, color: AppColors.mutedText(context)),
                                          const SizedBox(width: 3),
                                          Text('4 kishi',
                                              style: TextStyle(
                                                  fontSize: 12, color: AppColors.mutedText(context))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => _showSoon('Band tafsilotlari'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.darkText(context),
                                    side: BorderSide(color: AppColors.fieldBorder(context)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                  child: const Text('Ko\'rish'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bugun boshqa bandlar yo\'q',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'Ombor ogohlantirishlari',
                      icon: Icons.warning_amber_outlined,
                      titleColor: const Color(0xFFCB4B4B),
                      child: Column(
                        children: [
                          _InventoryAlertRow(
                            icon: Icons.restaurant_outlined,
                            label: 'Kartoshka fri',
                            badge: 'Tugagan',
                            badgeColor: const Color(0xFFCB4B4B),
                          ),
                          const SizedBox(height: 10),
                          _InventoryAlertRow(
                            icon: Icons.local_drink_outlined,
                            label: 'Kola',
                            badge: 'Kam qoldi',
                            badgeColor: AppColors.mutedText(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'So\'nggi buyurtmalar',
                      icon: Icons.receipt_long_outlined,
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminBusinessOrdersScreen()),
                        ),
                        child: const Text('Barchasini ko\'rish'),
                      ),
                      child: Column(
                        children: [
                          _OrderRow(
                            orderId: '#1024',
                            items: 'Lavash',
                            status: 'Tayyorlanmoqda',
                            statusColor: AppColors.adminGradientMid,
                            time: '14 daqiqa oldin',
                            price: '65 000 so\'m',
                          ),
                          const SizedBox(height: 10),
                          _OrderRow(
                            orderId: '#1023',
                            items: 'Burger Combo, Kola',
                            status: 'Tayyor',
                            statusColor: const Color(0xFF3F9142),
                            time: '28 daqiqa oldin',
                            price: '85 000 so\'m',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminBusinessOrdersScreen()),
            );
            return;
          }
          setState(() => _bottomNavIndex = index);
          if (index != 0) _showSoon(['', '', 'Bandlar', 'Chat'][index]);
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminBusinessProductsScreen(),
                        ),
                      );
                    case 'Ombor':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminBusinessInventoryScreen(),
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
              if (!deltaIsNeutral)
                const Icon(Icons.arrow_upward, size: 12, color: Color(0xFF3F9142)),
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
  const _OrderRow({
    required this.orderId,
    required this.items,
    required this.status,
    required this.statusColor,
    required this.time,
    required this.price,
  });

  final String orderId;
  final String items;
  final String status;
  final Color statusColor;
  final String time;
  final String price;

  @override
  Widget build(BuildContext context) {
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
                orderId,
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
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            items,
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(time, style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
              const Spacer(),
              Text(
                price,
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _TrendChartPainter(values: values),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map((label) => Text(
                    label,
                    style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final stepX = size.width / (values.length - 1);

    Offset pointAt(int index) {
      final x = stepX * index;
      final y = size.height - (values[index] / maxValue) * size.height;
      return Offset(x, y);
    }

    final linePath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      linePath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(pointAt(values.length - 1).dx, size.height)
      ..lineTo(pointAt(0).dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.adminGradientMid.withValues(alpha: 0.25),
          AppColors.adminGradientMid.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.adminGradientMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = AppColors.adminGradientMid;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(pointAt(i), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
