import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/data/admin_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQrCode(String qrData) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      final response = await repo.verifyQr(qrData);

      if (mounted) {
        _showResultDialog(
          title: 'Order Verified!',
          message: 'Token: ${response['order']['token']['token_number']}\nAmount: ₹${response['order']['total_amount']}',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(
          title: 'Verification Failed',
          message: e.toString(),
          isSuccess: false,
        );
      }
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    // Stop scanning while showing result dialog
    _scannerController.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.pop();
              setState(() => _isProcessing = false);
              // Restart scanning
              _scannerController.start();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Collection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          StatefulBuilder(
            builder: (context, setIconState) => IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: _isTorchOn ? AppColors.primaryNeon : Colors.grey,
              ),
              onPressed: () {
                _scannerController.toggleTorch();
                setIconState(() => _isTorchOn = !_isTorchOn);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _handleQrCode(barcodes.first.rawValue!);
              }
            },
          ),
          
          // Overlay framing guides
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryNeon, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
