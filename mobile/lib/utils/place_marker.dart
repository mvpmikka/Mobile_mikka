import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builds a teardrop-pin [BitmapDescriptor] — an orange circle with a white
/// category icon (fork/knife for restaurants, cup for cafes, etc.) and a
/// pointed tail, matching the Figma map mockup. Replaces the default red
/// Google Maps marker used for places.
class PlaceMarker {
  PlaceMarker._();

  static final _cache = <String, BitmapDescriptor>{};

  static const double _heightRatio = 1.3;

  /// [displaySize] is the pin's on-map width in logical pixels; the pin
  /// renders taller than wide to leave room for the tail.
  static Future<BitmapDescriptor> build({
    required IconData icon,
    Color color = const Color(0xFFE8622C),
    double displaySize = 40,
  }) async {
    final cacheKey = '${icon.codePoint}|${icon.fontFamily}|$color|$displaySize';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final renderWidth = displaySize * 3;
    final bytes = await _draw(icon: icon, color: color, renderWidth: renderWidth);

    final descriptor = BitmapDescriptor.bytes(
      bytes,
      width: displaySize,
      height: displaySize * _heightRatio,
    );
    _cache[cacheKey] = descriptor;
    return descriptor;
  }

  static Future<Uint8List> _draw({
    required IconData icon,
    required Color color,
    required double renderWidth,
  }) async {
    final renderHeight = renderWidth * _heightRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, renderWidth, renderHeight),
    );

    final circleRadius = renderWidth / 2 - renderWidth * 0.06;
    final center = Offset(renderWidth / 2, circleRadius + renderWidth * 0.06);
    final tailWidth = circleRadius * 0.55;
    final tailTop = center.dy + circleRadius * 0.65;

    final tailPath = Path()
      ..moveTo(center.dx - tailWidth, tailTop)
      ..quadraticBezierTo(
        center.dx,
        renderHeight * 0.94,
        center.dx,
        renderHeight,
      )
      ..quadraticBezierTo(
        center.dx,
        renderHeight * 0.94,
        center.dx + tailWidth,
        tailTop,
      )
      ..close();

    final fillPaint = Paint()..color = color;
    canvas.drawShadow(
      Path()
        ..addOval(Rect.fromCircle(center: center, radius: circleRadius))
        ..addPath(tailPath, Offset.zero),
      Colors.black.withValues(alpha: 0.35),
      renderWidth * 0.06,
      true,
    );
    canvas.drawPath(tailPath, fillPaint);
    canvas.drawCircle(center, circleRadius, fillPaint);
    canvas.drawCircle(
      center,
      circleRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = renderWidth * 0.045,
    );

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: circleRadius * 0.95,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      center - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      renderWidth.round(),
      renderHeight.round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
