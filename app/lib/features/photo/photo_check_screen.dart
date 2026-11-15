import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'photo_matcher.dart';
import 'photo_result_screen.dart';

/// Takes a photo of an item, tap to capture (no live frame analysis), or
/// takes one from the gallery, then checks it on the phone.
class PhotoCheckScreen extends StatefulWidget {
  const PhotoCheckScreen({super.key});

  @override
  State<PhotoCheckScreen> createState() => _PhotoCheckScreenState();
}

enum _CameraState { starting, ready, denied, unavailable }

class _PhotoCheckScreenState extends State<PhotoCheckScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  _CameraState _state = _CameraState.starting;

  /// The photo being reviewed (Retake or Use this photo).
  XFile? _photo;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    // A photo being checked now belongs to the result screen, which deletes
    // it; one left in review was never used.
    final photo = _photo;
    if (photo != null && !_checking) File(photo.path).delete().ignore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera must be released in the background and opened again after.
    final camera = _camera;
    if (state == AppLifecycleState.inactive && camera != null) {
      setState(() {
        _camera = null;
        _state = _CameraState.starting;
      });
      camera.dispose();
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      // Also retries after camera access was turned on in Settings.
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (cameras.isEmpty) {
        if (mounted) setState(() => _state = _CameraState.unavailable);
        return;
      }
      final controller = CameraController(
        back.firstOrNull ?? cameras.first,
        // About 1280 × 720: plenty for labeling and text, quick to process.
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _state = _CameraState.ready;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _state =
            e.code.contains('AccessDenied') ||
                e.code.contains('AccessRestricted')
            ? _CameraState.denied
            : _CameraState.unavailable,
      );
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || camera.value.isTakingPicture) return;
    try {
      final photo = await camera.takePicture();
      if (mounted) setState(() => _photo = photo);
    } on CameraException catch (e) {
      debugPrint('Photo capture failed: ${e.code}');
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked != null && mounted) await _check(picked.path);
  }

  void _retake() {
    final photo = _photo;
    setState(() => _photo = null);
    if (photo != null) File(photo.path).delete().ignore();
  }

  Future<void> _check(String path) async {
    final services = AppServices.of(context);
    final bundle = services.sync.bundle;
    final message = AppLocalizations.of(context).photoCheckFailed;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (bundle == null) return;
    setState(() => _checking = true);
    try {
      final signals = await services.photoAnalyzer.analyze(path);
      final match = await PhotoMatcher(
        services.db,
        clock: services.clock,
      ).match(bundle.municipalityId, signals);
      if (!mounted) return;
      await navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PhotoResultScreen(
            photoPath: path,
            signals: signals,
            match: match,
          ),
        ),
      );
    } on Object catch (e) {
      debugPrint('Photo check failed: $e');
      if (!mounted) return;
      setState(() {
        _checking = false;
        _photo = null;
      });
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final photo = _photo;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.photoTitle,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(l10n.photoSubtitle, style: text.bodyLarge),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: ColoredBox(
                    color: AppColors.ink,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photo != null)
                          Image.file(File(photo.path), fit: BoxFit.cover)
                        else
                          _Viewfinder(camera: _camera, state: _state),
                        if (_checking) const _Checking(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.photoPrivacy,
                style: text.bodySmall?.copyWith(color: AppColors.secondaryInk),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (photo != null)
                _ReviewButtons(
                  enabled: !_checking,
                  onRetake: _retake,
                  onUse: () => _check(photo.path),
                )
              else
                _CaptureButtons(
                  canCapture: _state == _CameraState.ready && !_checking,
                  onCancel: () => Navigator.of(context).pop(),
                  onCapture: _capture,
                  onGallery: _checking ? null : _pickFromGallery,
                ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.camera, required this.state});

  final CameraController? camera;
  final _CameraState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final camera = this.camera;
    if (state == _CameraState.ready && camera != null) {
      // Fill the frame, cropping the preview rather than letterboxing it.
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: camera.value.previewSize?.height ?? 720,
          height: camera.value.previewSize?.width ?? 1280,
          child: CameraPreview(camera),
        ),
      );
    }
    if (state == _CameraState.starting) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: AppColors.surface,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              state == _CameraState.denied
                  ? l10n.photoCameraDenied
                  : l10n.photoCameraUnavailable,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.surface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Checking extends StatelessWidget {
  const _Checking();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink.withValues(alpha: 0.55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.surface),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context).photoChecking,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppColors.surface),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButtons extends StatelessWidget {
  const _CaptureButtons({
    required this.canCapture,
    required this.onCancel,
    required this.onCapture,
    required this.onGallery,
  });

  final bool canCapture;
  final VoidCallback onCancel;
  final VoidCallback onCapture;
  final VoidCallback? onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          l10n.photoGalleryHint,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(onPressed: onCancel, child: Text(l10n.photoCancel)),
            Semantics(
              button: true,
              label: l10n.photoTake,
              child: InkResponse(
                onTap: canCapture ? onCapture : null,
                radius: 40,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: canCapture ? AppColors.primary : AppColors.outline,
                      width: 4,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canCapture ? AppColors.primary : AppColors.outline,
                    ),
                  ),
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: l10n.photoGallery,
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewButtons extends StatelessWidget {
  const _ReviewButtons({
    required this.enabled,
    required this.onRetake,
    required this.onUse,
  });

  final bool enabled;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: enabled ? onRetake : null,
            child: Text(l10n.photoRetake),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: enabled ? onUse : null,
            child: Text(l10n.photoUse),
          ),
        ),
      ],
    );
  }
}
