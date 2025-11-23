import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/group_provider.dart';
import '../../utils/group_id_encoder.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/app_bars/qr_scanner_app_bar.dart';

class QRScannerPage extends ConsumerStatefulWidget {
  const QRScannerPage({super.key});

  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends ConsumerState<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQRCodeDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    final scannedData = barcode.rawValue!;
    _processScannedData(scannedData);
  }

  Future<void> _processScannedData(String scannedData) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Şifrelenmiş grup ID'sini çöz
      final groupId = GroupIdEncoder.decodeGroupId(scannedData);

      if (groupId == null) {
        if (mounted) {
          ErrorSnackBar.show(context, 'Geçersiz QR kod. Lütfen grup QR kodunu tarayın.');
        }
        return;
      }

      // Gruba katıl
      await ref.read(groupNotifierProvider.notifier).joinGroupById(groupId);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Gruba başarıyla katıldınız!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Gruba katılma hatası: ';
        if (e.toString().contains('NotFoundException')) {
          errorMessage = 'Grup bulunamadı.';
        } else if (e.toString().contains('InvalidOperationException')) {
          errorMessage = 'Bu grubun zaten üyesisiniz.';
        } else {
          errorMessage = 'Gruba katılma hatası: ${e.toString()}';
        }

        ErrorSnackBar.show(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QRScannerAppBar(),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // QR Scanner
          MobileScanner(controller: _controller, onDetect: _onQRCodeDetect),

          // Overlay - Tarama alanı gösterimi
          _buildScannerOverlay(),

          // İşlem yapılıyor göstergesi
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: AppSpacing.sectionMargin),
                    Text('Gruba katılılıyor...', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return CustomPaint(painter: ScannerOverlayPainter(), child: Container());
  }
}

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
