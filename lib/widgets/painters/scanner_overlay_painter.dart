import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// QR Scanner overlay painter - Tarama alanını gösterir
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;

    // Dış alanı karart
    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaSize, scanAreaSize),
              const Radius.circular(12),
            ),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Tarama alanı köşeleri
    final cornerPaint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

    final cornerLength = 30.0;
    final cornerRadius = 12.0;

    // Sol üst köşe
    canvas.drawLine(
      Offset(scanAreaLeft + cornerRadius, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + cornerRadius),
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Sağ üst köşe
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop),
      Offset(scanAreaLeft + scanAreaSize - cornerRadius, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerRadius),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Sol alt köşe
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - cornerRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + cornerRadius, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaSize),
      cornerPaint,
    );

    // Sağ alt köşe
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + scanAreaSize - cornerRadius, scanAreaTop + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - cornerRadius),
      cornerPaint,
    );

    // Talimat metni
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'QR kodu tarama alanına yerleştirin',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: size.width - 40);
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, scanAreaTop + scanAreaSize + 30));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

