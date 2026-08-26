import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/app_colors.dart';
import 'admin_business_dashboard_screen.dart';
import 'admin_business_verify_email_screen.dart';
import 'widgets/admin_brand_topbar.dart';
import 'widgets/admin_text_field.dart';

const _tashkentCenter = LatLng(41.311081, 69.240562);

const _industries = [
  'Restoran / Kafe',
  'Do\'kon / Chakana savdo',
  'Salon / Go\'zallik',
  'Xizmat ko\'rsatish',
  'Boshqa',
];

class _CategoryOption {
  const _CategoryOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _categoryOptions = [
  _CategoryOption('Restoran', Icons.restaurant_outlined),
  _CategoryOption('Do\'kon', Icons.storefront_outlined),
  _CategoryOption('Salon', Icons.content_cut_outlined),
  _CategoryOption('Xizmatlar', Icons.handshake_outlined),
];

/// MIKKA Business uchun 4 bosqichli "Biznesni ro'yxatdan o'tkazish" UI
/// wizard'i (Ma'lumot → Manzil → Xizmatlar → Tasdiqlash). Butunlay lokal
/// state bilan ishlaydi — hech qanday backend/servis/API chaqiruvi yo'q,
/// faqat Figma dizayni asosidagi mobil UI.
class AdminBusinessRegisterScreen extends StatefulWidget {
  const AdminBusinessRegisterScreen({super.key});

  @override
  State<AdminBusinessRegisterScreen> createState() =>
      _AdminBusinessRegisterScreenState();
}

class _AdminBusinessRegisterScreenState
    extends State<AdminBusinessRegisterScreen> {
  static const _stepLabels = ['Ma\'lumot', 'Manzil', 'Xizmatlar', 'Tasdiqlash'];

  int _currentStep = 0;

  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  String? _industry;

  final _searchController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  LatLng _markerPosition = _tashkentCenter;

  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _legalNameController.dispose();
    _taxIdController.dispose();
    _searchController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_ownerNameController.text.trim().isEmpty ||
            _legalNameController.text.trim().isEmpty) {
          _showMessage('Ism va biznes yuridik nomini kiriting');
          return false;
        }
        return true;
      case 1:
        if (_streetController.text.trim().isEmpty ||
            _cityController.text.trim().isEmpty) {
          _showMessage('Ko\'cha manzili va shaharni kiriting');
          return false;
        }
        return true;
      case 2:
        if (_selectedCategories.isEmpty) {
          _showMessage('Kamida bitta biznes turkumini tanlang');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _onBack() {
    if (_currentStep == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _currentStep -= 1);
  }

  void _onContinue() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep == _stepLabels.length - 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminBusinessVerifyEmailScreen()),
      );
      return;
    }
    setState(() => _currentStep += 1);
  }

  void _jumpToStep(int step) => setState(() => _currentStep = step);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: AdminBrandTopBar(
                title: 'Ro\'yxat',
                onHelp: () => _showMessage(
                  'Yordam kerakmi? Admin panel qo\'llab-quvvatlash bo\'limiga murojaat qiling.',
                ),
                onProfile: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.fieldBorder(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stepHeading(_currentStep),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _stepSubtitle(_currentStep),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText(context),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _WizardProgressBar(
                        fraction: (_currentStep + 1) / _stepLabels.length,
                      ),
                      const SizedBox(height: 14),
                      _WizardStepRow(
                        labels: _stepLabels,
                        currentStep: _currentStep,
                        onStepTap: (step) {
                          if (step < _currentStep) _jumpToStep(step);
                        },
                      ),
                      const SizedBox(height: 22),
                      IndexedStack(
                        index: _currentStep,
                        children: [
                          _InfoStep(
                            ownerNameController: _ownerNameController,
                            ownerEmailController: _ownerEmailController,
                            ownerPhoneController: _ownerPhoneController,
                            legalNameController: _legalNameController,
                            taxIdController: _taxIdController,
                            industry: _industry,
                            onIndustryChanged: (value) =>
                                setState(() => _industry = value),
                          ),
                          _LocationStep(
                            searchController: _searchController,
                            streetController: _streetController,
                            cityController: _cityController,
                            stateController: _stateController,
                            zipController: _zipController,
                            markerPosition: _markerPosition,
                            onMapTap: (position) =>
                                setState(() => _markerPosition = position),
                          ),
                          _ServicesStep(
                            selectedCategories: _selectedCategories,
                            onCategoryToggle: (label) {
                              setState(() {
                                if (_selectedCategories.contains(label)) {
                                  _selectedCategories.remove(label);
                                } else {
                                  _selectedCategories.add(label);
                                }
                              });
                            },
                            productNameController: _productNameController,
                            productPriceController: _productPriceController,
                          ),
                          _VerifyStep(
                            ownerName: _ownerNameController.text,
                            ownerEmail: _ownerEmailController.text,
                            ownerPhone: _ownerPhoneController.text,
                            legalName: _legalNameController.text,
                            industry: _industry,
                            taxId: _taxIdController.text,
                            street: _streetController.text,
                            city: _cityController.text,
                            state: _stateController.text,
                            zip: _zipController.text,
                            markerPosition: _markerPosition,
                            onEditInfo: () => _jumpToStep(0),
                            onEditLocation: () => _jumpToStep(1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: AppColors.cream(context),
                border: Border(top: BorderSide(color: AppColors.fieldBorder(context))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _onBack,
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
                          onPressed: _onContinue,
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
                            'Davom etish',
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
          ],
        ),
      ),
    );
  }

  String _stepHeading(int step) {
    switch (step) {
      case 0:
        return 'Asosiy ma\'lumotlar';
      case 1:
        return 'Manzilni tanlash';
      case 2:
        return 'Mahsulot va xizmatlar';
      default:
        return 'Yakuniy tekshiruv';
    }
  }

  String _stepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Hisobingiz va biznesingiz haqida ma\'lumot kiriting.';
      case 1:
        return 'Biznesingiz qayerda joylashgan? Bu mijozlarga sizni topishga yordam beradi.';
      case 2:
        return 'Taklif qilayotgan turkumlaringizni tanlang va birinchi mahsulotingizni qo\'shing.';
      default:
        return 'Sozlashni yakunlashdan oldin ma\'lumotlaringizni tekshirib chiqing.';
    }
  }
}

class _WizardProgressBar extends StatelessWidget {
  const _WizardProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(height: 6, color: AppColors.fieldBorder(context)),
              Container(
                height: 6,
                width: constraints.maxWidth * fraction.clamp(0, 1),
                decoration: const BoxDecoration(gradient: AppColors.adminBrandGradient),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WizardStepRow extends StatelessWidget {
  const _WizardStepRow({
    required this.labels,
    required this.currentStep,
    required this.onStepTap,
  });

  final List<String> labels;
  final int currentStep;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(labels.length * 2 - 1, (index) {
        if (index.isOdd) {
          final beforeStep = index ~/ 2;
          final lineDone = beforeStep < currentStep;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Container(
                height: 2,
                color: lineDone
                    ? AppColors.adminGradientMid
                    : AppColors.fieldBorder(context),
              ),
            ),
          );
        }
        final step = index ~/ 2;
        final isDone = step < currentStep;
        final isCurrent = step == currentStep;
        return GestureDetector(
          onTap: () => onStepTap(step),
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCurrent ? AppColors.adminBrandGradient : null,
                  color: isCurrent
                      ? null
                      : (isDone
                          ? AppColors.adminGradientMid.withValues(alpha: 0.12)
                          : AppColors.surface(context)),
                  border: isCurrent
                      ? null
                      : Border.all(
                          color: isDone
                              ? AppColors.adminGradientMid
                              : AppColors.fieldBorder(context),
                        ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 15, color: AppColors.adminGradientMid)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCurrent
                                ? Colors.white
                                : AppColors.mutedText(context),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[step],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent || isDone
                      ? AppColors.adminGradientMid
                      : AppColors.mutedText(context),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.icon});

  final String title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF5D4038)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({
    required this.ownerNameController,
    required this.ownerEmailController,
    required this.ownerPhoneController,
    required this.legalNameController,
    required this.taxIdController,
    required this.industry,
    required this.onIndustryChanged,
  });

  final TextEditingController ownerNameController;
  final TextEditingController ownerEmailController;
  final TextEditingController ownerPhoneController;
  final TextEditingController legalNameController;
  final TextEditingController taxIdController;
  final String? industry;
  final ValueChanged<String?> onIndustryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Hisob egasi',
          icon: Icons.person_outline,
          child: Column(
            children: [
              AdminTextField(label: 'Ism va familiya', controller: ownerNameController),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Email',
                controller: ownerEmailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Telefon',
                controller: ownerPhoneController,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Biznes ma\'lumotlari',
          icon: Icons.storefront_outlined,
          child: Column(
            children: [
              AdminTextField(label: 'Yuridik nomi', controller: legalNameController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: industry,
                decoration: InputDecoration(
                  labelText: 'Soha',
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.fieldBorder(context)),
                  ),
                ),
                items: _industries
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: onIndustryChanged,
              ),
              const SizedBox(height: 12),
              AdminTextField(label: 'STIR (soliq raqami)', controller: taxIdController),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.searchController,
    required this.streetController,
    required this.cityController,
    required this.stateController,
    required this.zipController,
    required this.markerPosition,
    required this.onMapTap,
  });

  final TextEditingController searchController;
  final TextEditingController streetController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipController;
  final LatLng markerPosition;
  final ValueChanged<LatLng> onMapTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminTextField(
          label: 'Biznes manzilini qidiring...',
          controller: searchController,
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: markerPosition, zoom: 15),
              markers: {
                Marker(markerId: const MarkerId('selected'), position: markerPosition),
              },
              onTap: onMapTap,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 14),
        AdminTextField(label: 'Ko\'cha manzili', controller: streetController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: AdminTextField(label: 'Shahar', controller: cityController),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminTextField(label: 'Viloyat', controller: stateController),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdminTextField(
          label: 'Pochta indeksi',
          controller: zipController,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

class _ServicesStep extends StatelessWidget {
  const _ServicesStep({
    required this.selectedCategories,
    required this.onCategoryToggle,
    required this.productNameController,
    required this.productPriceController,
  });

  final Set<String> selectedCategories;
  final ValueChanged<String> onCategoryToggle;
  final TextEditingController productNameController;
  final TextEditingController productPriceController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biznes turkumlari',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText(context),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: _categoryOptions.map((option) {
            final isSelected = selectedCategories.contains(option.label);
            return InkWell(
              onTap: () => onCategoryToggle(option.label),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cream(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.adminGradientMid
                        : AppColors.fieldBorder(context),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(option.icon, size: 26, color: const Color(0xFF5D4038)),
                          const SizedBox(height: 8),
                          Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.adminBrandGradient,
                          ),
                          child: const Icon(Icons.check, size: 13, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Birinchi mahsulotingizni qo\'shing',
          icon: Icons.add_circle_outline,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: AdminTextField(
                  label: 'Mahsulot nomi',
                  controller: productNameController,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminTextField(
                  label: 'Narxi (so\'m)',
                  controller: productPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerifyStep extends StatelessWidget {
  const _VerifyStep({
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.legalName,
    required this.industry,
    required this.taxId,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.markerPosition,
    required this.onEditInfo,
    required this.onEditLocation,
  });

  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String legalName;
  final String? industry;
  final String taxId;
  final String street;
  final String city;
  final String state;
  final String zip;
  final LatLng markerPosition;
  final VoidCallback onEditInfo;
  final VoidCallback onEditLocation;

  String _fallback(String value) => value.trim().isEmpty ? '—' : value.trim();

  @override
  Widget build(BuildContext context) {
    final addressLine = [street, city, state, zip]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');
    return Column(
      children: [
        _ReviewCard(
          title: 'Hisob egasi',
          icon: Icons.person_outline,
          onEdit: onEditInfo,
          rows: [
            ('Ism', _fallback(ownerName)),
            ('Email', _fallback(ownerEmail)),
            ('Telefon', _fallback(ownerPhone)),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: 'Biznes ma\'lumotlari',
          icon: Icons.storefront_outlined,
          onEdit: onEditInfo,
          rows: [
            ('Yuridik nomi', _fallback(legalName)),
            ('Soha', industry ?? '—'),
            ('STIR', _fallback(taxId)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cream(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fieldBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF5D4038)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Asosiy manzil',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText(context),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onEditLocation,
                    child: const Text('Tahrirlash'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 120,
                  child: IgnorePointer(
                    child: GoogleMap(
                      initialCameraPosition:
                          CameraPosition(target: markerPosition, zoom: 15),
                      markers: {
                        Marker(markerId: const MarkerId('preview'), position: markerPosition),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      scrollGesturesEnabled: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                addressLine.isEmpty ? '—' : addressLine,
                style: TextStyle(fontSize: 13, color: AppColors.darkText(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF5D4038)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText(context),
                  ),
                ),
              ),
              TextButton(onPressed: onEdit, child: const Text('Tahrirlash')),
            ],
          ),
          const Divider(height: 20),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${row.$1}:',
                    style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                  ),
                  Text(
                    row.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText(context),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Ro'yxatdan o'tish wizard'i yakunlangach ko'rsatiladigan muvaffaqiyat
/// ekrani. Sof UI — hech qanday backend chaqiruvi yo'q.
class AdminBusinessRegisterSuccessScreen extends StatelessWidget {
  const AdminBusinessRegisterSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            children: [
              const AdminBrandTopBar(title: 'Ro\'yxat', showIcons: false),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fieldBorder(context)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.adminBrandGradient,
                          ),
                          child: const Icon(Icons.check, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Tabriklaymiz!\nBiznesingiz tayyor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText(context),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mikka Business hisobingiz tasdiqlandi. Endi joyingizni, '
                          'mahsulotlaringizni va mijozlaringizni boshqarishingiz mumkin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.adminBrandGradient,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const AdminBusinessDashboardScreen(),
                                ),
                                (route) => false,
                              ),
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
                                'Boshqaruv paneliga o\'tish',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              label: const Icon(Icons.arrow_forward, size: 18),
                            ),
                          ),
                        ),
                      ],
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
