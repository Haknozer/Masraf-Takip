import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/group_provider.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/app_bars/qr_scanner_app_bar.dart';
import '../../widgets/painters/scanner_overlay_painter.dart';

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
      // QR kod içinde invite code var (direkt kullan)
      final inviteCode = scannedData.trim().toUpperCase();

      if (inviteCode.isEmpty || inviteCode.length < 4 || inviteCode.length > 5) {
        if (mounted) {
          ErrorSnackBar.show(context, 'Geçersiz QR kod. Lütfen grup QR kodunu tarayın.');
        }
        return;
      }

      // Invite code ile gruba katıl
      await ref.read(groupNotifierProvider.notifier).joinGroupByInviteCode(inviteCode);

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
