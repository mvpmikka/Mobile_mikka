import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'admin_place_form_screen.dart';
import 'widgets/admin_text_field.dart';

/// O'zbekiston viloyatlari va ularning asosiy tumanlari/shaharlari.
/// Sof UI maqsadida statik ro'yxat — hech qanday backend/API chaqiruvi yo'q.
const Map<String, List<String>> _regionsWithDistricts = {
  'Toshkent shahri': [
    'Bektemir', 'Chilonzor', 'Mirzo Ulug\'bek', 'Mirobod', 'Olmazor',
    'Sergeli', 'Shayxontohur', 'Uchtepa', 'Yakkasaroy', 'Yunusobod',
    'Yashnobod', 'Yangihayot',
  ],
  'Toshkent viloyati': [
    'Bekobod', 'Bo\'ka', 'Bo\'stonliq', 'Chinoz', 'Qibray', 'Ohangaron',
    'Oqqo\'rg\'on', 'Parkent', 'Piskent', 'Quyichirchiq', 'O\'rtachirchiq',
    'Yuqorichirchiq', 'Zangiota', 'Yangiyo\'l',
  ],
  'Andijon viloyati': [
    'Andijon shahri', 'Asaka', 'Baliqchi', 'Bo\'z', 'Izboskan', 'Jalaquduq',
    'Qo\'rg\'ontepa', 'Marhamat', 'Oltinko\'l', 'Paxtaobod', 'Shahrixon',
    'Ulug\'nor', 'Xo\'jaobod',
  ],
  'Farg\'ona viloyati': [
    'Farg\'ona shahri', 'Marg\'ilon', 'Qo\'qon', 'Beshariq', 'Bog\'dod',
    'Buvayda', 'Dang\'ara', 'Furqat', 'Oltiariq', 'Quva', 'Rishton',
    'So\'x', 'Toshloq', 'Uchko\'prik', 'O\'zbekiston', 'Yozyovon',
  ],
  'Namangan viloyati': [
    'Namangan shahri', 'Chortoq', 'Chust', 'Kosonsoy', 'Mingbuloq',
    'Norin', 'Pop', 'To\'raqo\'rg\'on', 'Uychi', 'Uchqo\'rg\'on',
    'Yangiqo\'rg\'on',
  ],
  'Samarqand viloyati': [
    'Samarqand shahri', 'Bulung\'ur', 'Ishtixon', 'Jomboy', 'Kattaqo\'rg\'on',
    'Konigil', 'Narpay', 'Nurobod', 'Oqdaryo', 'Pastdarg\'om', 'Payariq',
    'Paxtachi', 'Toyloq', 'Urgut',
  ],
  'Buxoro viloyati': [
    'Buxoro shahri', 'Kogon', 'Vobkent', 'G\'ijduvon', 'Jondor', 'Qorako\'l',
    'Qorovulbozor', 'Peshku', 'Romitan', 'Shofirkon', 'Olot',
  ],
  'Xorazm viloyati': [
    'Urganch shahri', 'Xiva', 'Bog\'ot', 'Gurlan', 'Hazorasp', 'Qo\'shko\'pir',
    'Shovot', 'Yangiariq', 'Yangibozor',
  ],
  'Navoiy viloyati': [
    'Navoiy shahri', 'Zarafshon', 'Karmana', 'Konimex', 'Navbahor',
    'Nurota', 'Qiziltepa', 'Tomdi', 'Uchquduq', 'Xatirchi',
  ],
  'Qashqadaryo viloyati': [
    'Qarshi shahri', 'Shahrisabz', 'G\'uzor', 'Kasbi', 'Kitob', 'Koson',
    'Mirishkor', 'Muborak', 'Nishon', 'Chiroqchi', 'Yakkabog\'',
  ],
  'Surxondaryo viloyati': [
    'Termiz shahri', 'Angor', 'Bandixon', 'Boysun', 'Denov', 'Jarqo\'rg\'on',
    'Qumqo\'rg\'on', 'Muzrabot', 'Oltinsoy', 'Sariosiyo', 'Sherobod',
    'Sho\'rchi', 'Uzun',
  ],
  'Jizzax viloyati': [
    'Jizzax shahri', 'Arnasoy', 'Baxmal', 'Do\'stlik', 'Forish', 'G\'allaorol',
    'Zomin', 'Zafarobod', 'Mirzachо\'l', 'Paxtakor', 'Yangiobod', 'Zarbdor',
  ],
  'Sirdaryo viloyati': [
    'Guliston shahri', 'Boyovut', 'Guliston tumani', 'Mirzaobod', 'Oqoltin',
    'Sayxunobod', 'Sardoba', 'Sirdaryo', 'Xovos',
  ],
  'Qoraqalpog\'iston Respublikasi': [
    'Nukus shahri', 'Amudaryo', 'Beruniy', 'Chimboy', 'Ellikqal\'a',
    'Kegeyli', 'Mo\'ynoq', 'Nukus tumani', 'Qanliko\'l', 'Qorao\'zak',
    'Qo\'ng\'irot', 'Shumanay', 'Taxtako\'pir', 'To\'rtko\'l', 'Xo\'jayli',
  ],
};

/// "Manzilni tanlash" — yangi joy qo'shish oqimining 1-bosqichi.
/// Figma dizayni asosida qurilgan sof UI ekrani: hech qanday backend/API
/// chaqiruvi qilmaydi, faqat manzilni yig'ib, mavjud [AdminPlaceFormScreen]
/// ga tayyor matn sifatida uzatadi.
class AdminLocationSelectScreen extends StatefulWidget {
  const AdminLocationSelectScreen({super.key});

  @override
  State<AdminLocationSelectScreen> createState() =>
      _AdminLocationSelectScreenState();
}

class _AdminLocationSelectScreenState
    extends State<AdminLocationSelectScreen> {
  final _mahallaController = TextEditingController();
  final _streetController = TextEditingController();

  String? _region;
  String? _district;

  @override
  void dispose() {
    _mahallaController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _pickRegion() async {
    final selected = await _showOptionsSheet(
      title: 'Viloyatni tanlang',
      options: _regionsWithDistricts.keys.toList(),
      current: _region,
    );
    if (selected == null) return;
    setState(() {
      _region = selected;
      _district = null;
    });
  }

  Future<void> _pickDistrict() async {
    final region = _region;
    if (region == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avval viloyatni tanlang')),
      );
      return;
    }
    final selected = await _showOptionsSheet(
      title: 'Tuman yoki shaharni tanlang',
      options: _regionsWithDistricts[region]!,
      current: _district,
    );
    if (selected == null) return;
    setState(() => _district = selected);
  }

  Future<String?> _showOptionsSheet({
    required String title,
    required List<String> options,
    required String? current,
  }) {
    return showModalBottomSheet<String>(
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
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText(sheetContext),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (_, index) {
                    final option = options[index];
                    final isSelected = option == current;
                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(
                          color: AppColors.darkText(sheetContext),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check,
                              color: AppColors.adminGradientMid)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(option),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onNext() async {
    if (_region == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viloyat va tumanni tanlang')),
      );
      return;
    }
    if (_mahallaController.text.trim().isEmpty ||
        _streetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mahalla va ko\'cha manzilini kiriting')),
      );
      return;
    }

    final composedAddress = [
      _streetController.text.trim(),
      _mahallaController.text.trim(),
      _district,
      _region,
    ].join(', ');

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminPlaceFormScreen(initialAddress: composedAddress),
      ),
    );
    if (created == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        foregroundColor: AppColors.darkText(context),
        title: Text(
          'Manzilni tanlash',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.darkText(context),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Text(
              'Do\'koningiz qayerda joylashgan?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText(context),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aniq manzil mijozlaringizga do\'koningizni topishga yordam beradi.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            const _OnboardingStepIndicator(activeIndex: 0),
            const SizedBox(height: 24),
            Divider(color: AppColors.fieldBorder(context), height: 1),
            const SizedBox(height: 20),
            _LocationSelectRow(
              icon: Icons.map_outlined,
              label: 'Viloyat',
              value: _region,
              onTap: _pickRegion,
            ),
            const SizedBox(height: 12),
            _LocationSelectRow(
              icon: Icons.location_city_outlined,
              label: 'Tuman / shahar',
              value: _district,
              onTap: _pickDistrict,
            ),
            const SizedBox(height: 12),
            AdminTextField(label: 'Mahalla nomi', controller: _mahallaController),
            const SizedBox(height: 12),
            AdminTextField(
              label: 'Ko\'cha, uy raqami',
              controller: _streetController,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: AppColors.cream(context),
            border: Border(
              top: BorderSide(color: AppColors.fieldBorder(context)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkText(context),
                      backgroundColor: AppColors.surface(context),
                      side: BorderSide(color: AppColors.fieldBorder(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Orqaga'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.adminBrandGradient,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.adminGradientMid.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      icon: const Text(
                        'Keyingisi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      label: const Icon(Icons.arrow_forward, size: 18),
                    ),
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

/// Figma dizayndagi 5 bosqichli step-indikator (joy qo'shish oqimi):
/// Manzil → Biznes → Turkum → Ish vaqti → Rasmlar. Faqat 1 va 2-bosqich
/// hozircha bosib o'tiladigan, qolganlari kelgusi bosqichlar sifatida
/// vizual ko'rsatiladi.
class _OnboardingStepIndicator extends StatelessWidget {
  const _OnboardingStepIndicator({required this.activeIndex});

  final int activeIndex;

  static const _icons = [
    Icons.location_on_outlined,
    Icons.storefront_outlined,
    Icons.category_outlined,
    Icons.schedule_outlined,
    Icons.photo_camera_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_icons.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: AppColors.fieldBorder(context),
            ),
          );
        }
        final stepIndex = index ~/ 2;
        final isActive = stepIndex == activeIndex;
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive ? AppColors.adminBrandGradient : null,
            color: isActive ? null : AppColors.surface(context),
            border: isActive
                ? null
                : Border.all(color: AppColors.fieldBorder(context)),
          ),
          child: Icon(
            _icons[stepIndex],
            size: 18,
            color: isActive ? Colors.white : AppColors.mutedText(context),
          ),
        );
      }),
    );
  }
}

/// Bosqichli manzil tanlash uchun tanlanadigan qator — Figma dizaynidagi
/// oq fon + ramka + chapda ikonka + o'ngda chevron ko'rinishini takrorlaydi.
class _LocationSelectRow extends StatelessWidget {
  const _LocationSelectRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF5D4038)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
                  color: value == null
                      ? AppColors.mutedText(context)
                      : AppColors.darkText(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.mutedText(context)),
          ],
        ),
      ),
    );
  }
}
