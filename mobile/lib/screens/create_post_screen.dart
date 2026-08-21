import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../services/post_service.dart';
import '../theme/app_colors.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  final List<XFile> _images = [];
  bool _isUploading = false;
  int _uploadedCount = 0;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(limit: 10);
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked);
      if (_images.length > 10) {
        _images.removeRange(10, _images.length);
      }
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamida bitta rasm tanlang')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
    });

    try {
      final service = ref.read(postServiceProvider);
      final uploaded = <UploadedImage>[];
      for (final image in _images) {
        final result = await service.uploadImage(image.path);
        uploaded.add(result);
        if (!mounted) return;
        setState(() => _uploadedCount++);
      }
      await service.create(
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        images: uploaded,
      );
      final username = ref.read(authControllerProvider).value?.user?.username;
      if (username != null) {
        ref.invalidate(postsByUsernameProvider(username));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkText(context)),
        title: Text(
          'Yangi post',
          style: TextStyle(
            color: AppColors.darkText(context),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _submit,
            child: _isUploading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.orange,
                    ),
                  )
                : const Text(
                    'Ulashish',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(context),
              const SizedBox(height: 20),
              TextField(
                controller: _captionController,
                maxLines: 4,
                maxLength: 2000,
                style: TextStyle(color: AppColors.darkText(context)),
                decoration: InputDecoration(
                  hintText: 'Izoh yozing...',
                  hintStyle: TextStyle(color: AppColors.mutedText(context)),
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.fieldBorder(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.fieldBorder(context)),
                  ),
                ),
              ),
              if (_isUploading) ...[
                const SizedBox(height: 16),
                Text(
                  'Yuklanmoqda: $_uploadedCount/${_images.length}',
                  style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _images.isEmpty ? 0 : _uploadedCount / _images.length,
                    color: AppColors.orange,
                    backgroundColor: AppColors.fieldBorder(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _images.length; i++)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_images[i].path),
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _isUploading ? null : () => _removeImage(i),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        if (_images.length < 10)
          GestureDetector(
            onTap: _isUploading ? null : _pickImages,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fieldBorder(context)),
                color: AppColors.surface(context),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.mutedText(context),
              ),
            ),
          ),
      ],
    );
  }
}
