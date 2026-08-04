import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildLogo(),
            const SizedBox(height: 24),
            const Text(
              'Discover places.\nMake moments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
                height: 1.4,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: CustomPaint(
                  size: const Size.fromHeight(double.infinity),
                  painter: _CityscapePainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.darkText,
                        side: const BorderSide(color: Color(0xFFE5DCCB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  Widget _buildLogo() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(size: 6, opacity: 0.35),
            SizedBox(width: 4),
            _Dot(size: 8, opacity: 0.6),
            SizedBox(width: 4),
            _Dot(size: 10, opacity: 1),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'mikka',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.orange,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CityscapePainter extends CustomPainter {
  static const _backHeights = [
    0.28, 0.22, 0.34, 0.20, 0.30, 0.24, 0.18, 0.32, 0.26, 0.22, 0.30, 0.20,
  ];
  static const _midHeights = [
    0.40, 0.30, 0.48, 0.34, 0.26, 0.44, 0.32, 0.38, 0.28, 0.42, 0.30, 0.36,
  ];
  static const _frontHeights = [
    0.20, 0.32, 0.24, 0.40, 0.28, 0.22, 0.36, 0.26, 0.30, 0.24, 0.34, 0.20,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height;

    _drawLayer(
      canvas,
      size,
      _backHeights,
      const Color(0xFFEFC49A),
      groundY,
    );
    _drawTower(canvas, size);
    _drawLayer(
      canvas,
      size,
      _midHeights,
      const Color(0xFFD98D50),
      groundY,
    );
    _drawLayer(
      canvas,
      size,
      _frontHeights,
      const Color(0xFF2B1D15),
      groundY,
    );
  }

  void _drawLayer(
    Canvas canvas,
    Size size,
    List<double> heights,
    Color color,
    double groundY,
  ) {
    final paint = Paint()..color = color;
    final columnWidth = size.width / heights.length;
    for (var i = 0; i < heights.length; i++) {
      final buildingHeight = size.height * heights[i];
      final left = i * columnWidth;
      final rect = Rect.fromLTRB(
        left,
        groundY - buildingHeight,
        left + columnWidth * 0.86,
        groundY,
      );
      canvas.drawRect(rect, paint);
    }
  }

  void _drawTower(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE29A5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final baseX = size.width * 0.52;
    final baseY = size.height * 0.62;
    final tipY = size.height * 0.05;

    final path = Path()
      ..moveTo(baseX - 22, baseY)
      ..lineTo(baseX, tipY)
      ..lineTo(baseX + 22, baseY);
    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(baseX - 14, baseY - (baseY - tipY) * 0.35),
      Offset(baseX + 14, baseY - (baseY - tipY) * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(baseX - 7, baseY - (baseY - tipY) * 0.65),
      Offset(baseX + 7, baseY - (baseY - tipY) * 0.65),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CityscapePainter oldDelegate) => false;
}
