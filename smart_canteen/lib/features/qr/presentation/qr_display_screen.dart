import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';

class QrDisplayScreen extends StatefulWidget {
  final String orderId;
  final String tokenNumber;
  final String qrData;

  const QrDisplayScreen({Key? key, required this.orderId, required this.tokenNumber, required this.qrData}) : super(key: key);

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Token: ${widget.tokenNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Order ID: ${widget.orderId}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 30),

                GlassmorphicCard(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // QR with scan-line animation
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: QrImageView(data: widget.qrData, version: QrVersions.auto, size: 240.0, gapless: false),
                          ),
                          // Scan-line
                          AnimatedBuilder(
                            animation: _scanAnim,
                            builder: (_, __) => Positioned(
                              top: 12 + _scanAnim.value * 240,
                              left: 12, right: 12,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, AppColors.primaryNeon, Colors.transparent],
                                  ),
                                  boxShadow: [BoxShadow(color: AppColors.primaryNeon.withOpacity(0.6), blurRadius: 6)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Show this QR code at the canteen collection counter to verify your order.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNeon.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryNeon.withOpacity(0.15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.primaryNeon, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Secure verification: This QR contains a cryptographic signature to prevent counterfeiting.',
                          style: TextStyle(color: AppColors.accentCyan, fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
