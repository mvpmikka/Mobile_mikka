import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';

/// Builds a solid-colored flag-icon [BitmapDescriptor] for a destination
/// marker — same circular-badge style as [AvatarMarker], so the user's own
/// position (their photo) and the destination (a flag) read as clearly
/// different things on the map instead of two look-alike pins.
class FlagMarker {
  FlagMarker._();

  static BitmapDescriptor? _cached;

  static Future<BitmapDescriptor> build({
    double displaySize = 56,
    Color backgroundColor = AppColors.orange,
    Color borderColor = Colors.white,
  }) async {
    if (_cached != null) return _cached!;

    final renderSize = displaySize * 3;
    final bytes = await _draw(
      renderSize: renderSize,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
    );
    final descriptor = BitmapDescriptor.bytes(
      bytes,
      width: displaySize,
      height: displaySize,
    );
    _cached = descriptor;
    return descriptor;
  }

  static Future<Uint8List> _draw({
    required double renderSize,
    required Color backgroundColor,
    required Color borderColor,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, renderSize, renderSize));
    final radius = renderSize / 2;
    final center = Offset(radius, radius);
    final borderWidth = renderSize * 0.08;
    final circleRadius = radius - borderWidth;

    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: circleRadius)),
      Colors.black.withValues(alpha: 0.35),
      renderSize * 0.05,
      true,
    );

    canvas.drawCircle(center, circleRadius, Paint()..color = backgroundColor);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.flag.codePoint),
        style: TextStyle(
          fontSize: renderSize * 0.46,
          fontFamily: Icons.flag.fontFamily,
          package: Icons.flag.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 1.9),
    );

    canvas.drawCircle(
      center,
      circleRadius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(renderSize.round(), renderSize.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
