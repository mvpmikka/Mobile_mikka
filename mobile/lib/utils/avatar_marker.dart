import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builds a circular, white-bordered avatar-photo [BitmapDescriptor] for map
/// markers — replaces the generic pin icon with the actual person's profile
/// photo. Falls back to a colored circle with their initial when there's no
/// avatar or the image can't be loaded.
class AvatarMarker {
  AvatarMarker._();

  static final _cache = <String, BitmapDescriptor>{};

  /// [displaySize] is the marker's on-map size in logical pixels.
  static Future<BitmapDescriptor> build({
    required String? avatarUrl,
    required String fallbackLabel,
    required Color fallbackColor,
    double displaySize = 56,
    Color borderColor = Colors.white,
  }) async {
    final cacheKey = '$avatarUrl|$fallbackLabel|$fallbackColor|$displaySize';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final renderSize = displaySize * 3;
    final photo = (avatarUrl == null || avatarUrl.isEmpty)
        ? null
        : await _loadImage(avatarUrl);

    final bytes = await _draw(
      photo: photo,
      label: fallbackLabel,
      fallbackColor: fallbackColor,
      borderColor: borderColor,
      renderSize: renderSize,
    );

    final descriptor = BitmapDescriptor.bytes(
      bytes,
      width: displaySize,
      height: displaySize,
    );
    _cache[cacheKey] = descriptor;
    return descriptor;
  }

  static Future<ui.Image?> _loadImage(String url) async {
    try {
      final completer = Completer<ui.Image?>();
      final stream = NetworkImage(url).resolve(const ImageConfiguration());
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) completer.complete(info.image);
          stream.removeListener(listener);
        },
        onError: (error, stackTrace) {
          if (!completer.isCompleted) completer.complete(null);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      return await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> _draw({
    required ui.Image? photo,
    required String label,
    required Color fallbackColor,
    required Color borderColor,
    required double renderSize,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, renderSize, renderSize),
    );
    final radius = renderSize / 2;
    final center = Offset(radius, radius);
    final borderWidth = renderSize * 0.08;
    final photoRadius = radius - borderWidth;

    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: photoRadius)),
      Colors.black.withValues(alpha: 0.35),
      renderSize * 0.05,
      true,
    );

    if (photo != null) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(
          Rect.fromCircle(center: center, radius: photoRadius),
        ),
      );
      paintImage(
        canvas: canvas,
        rect: Rect.fromCircle(center: center, radius: photoRadius),
        image: photo,
        fit: BoxFit.cover,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, photoRadius, Paint()..color = fallbackColor);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: renderSize * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    canvas.drawCircle(
      center,
      photoRadius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      renderSize.round(),
      renderSize.round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
