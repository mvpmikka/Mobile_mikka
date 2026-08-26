import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/place.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/admin_gradient_button.dart';
import 'widgets/admin_text_field.dart';

class AdminPlaceFormScreen extends ConsumerStatefulWidget {
  const AdminPlaceFormScreen({super.key, this.initialAddress});

  /// [AdminLocationSelectScreen]dan kelgan tayyor manzil matni (bo'lsa).
  /// Faqat manzil maydonini oldindan to'ldirish uchun ishlatiladi — hech
  /// qanday backend/servis chaqiruviga aloqasi yo'q.
  final String? initialAddress;

  @override
  ConsumerState<AdminPlaceFormScreen> createState() =>
      _AdminPlaceFormScreenState();
}

class _AdminPlaceFormScreenState extends ConsumerState<AdminPlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final _addressController =
      TextEditingController(text: widget.initialAddress ?? '');
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  PlaceCategoryRef? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategoriyani tanlang'),
          backgroundColor: Color(0xFFCB4B4B),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminServiceProvider).createPlace(
            name: _nameController.text.trim(),
            categoryId: _selectedCategory!.id,
            description: _descriptionController.text.trim(),
            address: _addressController.text.trim(),
            latitude: double.tryParse(_latController.text.trim()),
            longitude: double.tryParse(_lngController.text.trim()),
            phone: _phoneController.text.trim(),
            website: _websiteController.text.trim(),
          );
      ref.invalidate(adminPlacesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        foregroundColor: AppColors.darkText(context),
        title: Text(
          'Yangi joy qo\'shish',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText(context)),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AdminTextField(label: 'Nomi *', controller: _nameController, required: true),
              const SizedBox(height: 14),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(color: AppColors.orange),
                error: (e, _) => Text(
                  'Kategoriyalarni yuklab bo\'lmadi',
                  style: const TextStyle(color: Color(0xFFCB4B4B)),
                ),
                data: (categories) => DropdownButtonFormField<PlaceCategoryRef>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategoriya *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
              ),
              const SizedBox(height: 14),
              AdminTextField(
                label: 'Tavsif',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              AdminTextField(label: 'Manzil (address)', controller: _addressController),
              const SizedBox(height: 4),
              Text(
                'Manzil yoki lat+lng dan kamida bittasini kiriting.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AdminTextField(
                      label: 'Latitude',
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminTextField(
                      label: 'Longitude',
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AdminTextField(
                label: 'Telefon',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              AdminTextField(
                label: 'Veb-sayt',
                controller: _websiteController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              AdminGradientButton(
                label: 'Qo\'shish',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
