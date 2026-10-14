import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

import '../core/api_exception.dart';
import '../models/place.dart';
import '../providers/short_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/coming_soon.dart';
import '../widgets/place_picker_sheet.dart';

const _maxRecordSeconds = 60;

class ShortsCaptureScreen extends ConsumerStatefulWidget {
  const ShortsCaptureScreen({super.key});

  @override
  ConsumerState<ShortsCaptureScreen> createState() => _ShortsCaptureScreenState();
}

class _ShortsCaptureScreenState extends ConsumerState<ShortsCaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  String? _setupError;
  bool _flashOn = false;

  bool _isRecording = false;
  double _recordProgress = 0;
  Timer? _recordTimer;

  XFile? _videoFile;
  VideoPlayerController? _videoController;

  final _captionController = TextEditingController();
  Place? _selectedPlace;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _cameraController?.dispose();
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      setState(() {
        _isInitializing = false;
        _setupError = 'Kamera va mikrofonga ruxsat berilmadi';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _setupError = 'Kamera topilmadi';
        });
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameras = cameras;
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _setupError = 'Kamerani ishga tushirib bo\'lmadi';
      });
    }
  }

  void _showCaptureError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFCB4B4B)),
    );
  }

  Future<void> _startRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isRecording) {
      return;
    }
    try {
      await controller.startVideoRecording();
    } catch (e) {
      _showCaptureError("Yozishni boshlab bo'lmadi: $e");
      return;
    }
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordProgress = 0;
    });

    final start = DateTime.now();
    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final elapsedSeconds = DateTime.now().difference(start).inMilliseconds / 1000;
      final progress = (elapsedSeconds / _maxRecordSeconds).clamp(0.0, 1.0);
      setState(() => _recordProgress = progress);
      if (progress >= 1.0) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    final controller = _cameraController;
    if (controller == null || !_isRecording) return;
    _recordTimer?.cancel();
    _recordTimer = null;

    final XFile file;
    try {
      file = await controller.stopVideoRecording();
    } catch (e) {
      if (mounted) setState(() => _isRecording = false);
      _showCaptureError("Yozishni tugatib bo'lmadi: $e");
      return;
    }
    setState(() {
      _isRecording = false;
      _recordProgress = 0;
    });

    await _loadVideoForPreview(file);
  }

  Future<void> _loadVideoForPreview(XFile file) async {
    try {
      final videoController = VideoPlayerController.file(File(file.path));
      await videoController.initialize();
      await videoController.setLooping(true);
      await videoController.play();
      if (!mounted) {
        await videoController.dispose();
        return;
      }
      setState(() {
        _videoFile = file;
        _videoController = videoController;
      });
    } catch (e) {
      _showCaptureError("Videoni ko'rsatib bo'lmadi: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isRecording) return;
    final XFile? file;
    try {
      file = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: _maxRecordSeconds),
      );
    } catch (e) {
      _showCaptureError("Video tanlab bo'lmadi");
      return;
    }
    if (file == null) return;
    await _loadVideoForPreview(file);
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || _isRecording) return;
    final next = !_flashOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() => _flashOn = next);
    } catch (e) {
      _showCaptureError("Chiroqni almashtirib bo'lmadi");
    }
  }

  Future<void> _switchCamera() async {
    if (_isRecording || _cameras.length < 2) return;
    final current = _cameraController;
    final currentDirection = current?.description.lensDirection;
    final nextCamera = _cameras.firstWhere(
      (c) => c.lensDirection != currentDirection,
      orElse: () => _cameras.first,
    );
    setState(() => _isInitializing = true);
    await current?.dispose();
    final newController = CameraController(
      nextCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );
    try {
      await newController.initialize();
      if (!mounted) {
        await newController.dispose();
        return;
      }
      setState(() {
        _cameraController = newController;
        _isInitializing = false;
        _flashOn = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitializing = false);
      _showCaptureError("Kamerani almashtirib bo'lmadi");
    }
  }

  void _retake() {
    _videoController?.dispose();
    setState(() {
      _videoController = null;
      _videoFile = null;
      _captionController.clear();
      _selectedPlace = null;
    });
  }

  Future<void> _pickPlace() async {
    final place = await showPlacePicker(context);
    if (place != null) setState(() => _selectedPlace = place);
  }

  Future<void> _submit() async {
    final videoFile = _videoFile;
    if (videoFile == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(shortServiceProvider);
      final videoUrl = await service.uploadVideo(videoFile.path);

      String? thumbnailUrl;
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await vt.VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 480,
        quality: 70,
      );
      if (thumbPath != null) {
        thumbnailUrl = await service.uploadThumbnail(thumbPath);
      }

      await service.create(
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        placeId: _selectedPlace?.id,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
      );

      ref.invalidate(shortFeedProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoController != null
          ? _buildPreview(context)
          : _buildCamera(context),
    );
  }

  Widget _buildCamera(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (_setupError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _setupError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Orqaga', style: TextStyle(color: AppColors.orange)),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraController;
    if (controller == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoundIconButton(
                  icon: Icons.close,
                  onTap: _isRecording ? null : () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: _TopLocationPill(
                      label: _selectedPlace?.name ?? 'Joylashuvni belgilash',
                      onTap: _isRecording ? null : _pickPlace,
                    ),
                  ),
                ),
                Column(
                  children: [
                    _RoundIconButton(
                      icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                      onTap: _isRecording ? null : _toggleFlash,
                    ),
                    const SizedBox(height: 10),
                    _RoundIconButton(
                      icon: Icons.more_horiz,
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _captionController,
                    maxLines: 2,
                    maxLength: 2000,
                    enabled: !_isRecording,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Bu lahzani tasvirlang...',
                      hintStyle: TextStyle(color: Colors.white60, fontSize: 14),
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                  Row(
                    children: [
                      _CapturePillButton(
                        icon: Icons.music_note_outlined,
                        label: 'Musiqa qo\'shish',
                        onTap: _isRecording ? null : () => showComingSoon(context),
                      ),
                      const SizedBox(width: 10),
                      _CapturePillButton(
                        icon: Icons.place_outlined,
                        label: _selectedPlace?.name ?? 'Joyni belgilash',
                        onTap: _isRecording ? null : _pickPlace,
                      ),
                      const SizedBox(width: 10),
                      _CapturePillButton(
                        icon: Icons.auto_fix_high_outlined,
                        label: 'Effektlar',
                        onTap: _isRecording ? null : () => showComingSoon(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        child: _RoundIconButton(
                          icon: Icons.photo_library_outlined,
                          size: 46,
                          onTap: _isRecording ? null : _pickFromGallery,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onLongPressStart: (_) => _startRecording(),
                            onLongPressEnd: (_) => _stopRecording(),
                            child: SizedBox(
                              width: 82,
                              height: 82,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 82,
                                    height: 82,
                                    child: CircularProgressIndicator(
                                      value: _isRecording ? _recordProgress : 0,
                                      strokeWidth: 4,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: _isRecording ? 34 : 64,
                                    height: _isRecording ? 34 : 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.orange,
                                      borderRadius: BorderRadius.circular(_isRecording ? 8 : 32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: _RoundIconButton(
                          icon: Icons.cameraswitch_outlined,
                          size: 46,
                          onTap: (_isRecording || _cameras.length < 2) ? null : _switchCamera,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final videoController = _videoController!;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: videoController.value.aspectRatio,
            child: VideoPlayer(videoController),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _RoundIconButton(icon: Icons.close, onTap: _isSubmitting ? null : _retake),
                const Spacer(),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_captionController.text.trim().isNotEmpty) ...[
                    Text(
                      _captionController.text.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_selectedPlace != null) ...[
                    _TopLocationPill(label: _selectedPlace!.name, onTap: null),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Joylash',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
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
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.size = 38});

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

class _TopLocationPill extends StatelessWidget {
  const _TopLocationPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: AppColors.orange, size: 14),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturePillButton extends StatelessWidget {
  const _CapturePillButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
