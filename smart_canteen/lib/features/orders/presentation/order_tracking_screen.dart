import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/order_provider.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingVal = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () { ref.invalidate(activeOrdersProvider); context.pop(); },
        ),
      ),
      body: trackingVal.when(
        data: (order) {
          final status = order['status']?.toString().toLowerCase() ?? 'placed';
          final token = order['token']?['token_number'] ?? 'N/A';
          final qrData = order['token']?['qr_data'] ?? '';
          final steps = ['placed', 'accepted', 'preparing', 'ready', 'completed'];
          int currentStep = steps.indexOf(status);
          if (status == 'cancelled') currentStep = -1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Token callout
                _ReadyGlowCard(isReady: status == 'ready', child: Column(
                  children: [
                    const Text('Your Token Code', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(token,
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryNeon, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(_getStatusMessage(status), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                )),
                const SizedBox(height: 30),

                // Animated stepper
                if (status == 'cancelled')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Center(child: Text('Order Cancelled: ${order['cancel_reason'] ?? "N/A"}',
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
                  )
                else
                  _AnimatedStepper(currentStep: currentStep),

                const SizedBox(height: 35),

                if (status != 'cancelled' && status != 'completed')
                  GradientButton(
                    text: 'View Collection QR Code',
                    icon: Icons.qr_code,
                    onPressed: () => context.push('/qr-display', extra: {
                      'order_id': order['order_id'],
                      'token_number': token,
                      'qr_data': qrData,
                    }),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/order-detail/${order['order_id']}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.darkBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('View Bill Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon)),
        error: (_, __) => const Center(child: Text('Error loading order tracking')),
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'placed': return 'We are waiting for the canteen to accept your order.';
      case 'accepted': return 'Your order has been approved and is queued.';
      case 'preparing': return 'Our chef is preparing your fresh meal now.';
      case 'ready': return 'Please go to the counter and show your QR code to collect!';
      case 'completed': return 'Thank you! Enjoy your meal.';
      case 'cancelled': return 'This order has been cancelled.';
      default: return 'Processing your order...';
    }
  }
}

// -- Animated vertical stepper --------------------------------------
class _AnimatedStepper extends StatefulWidget {
  final int currentStep;
  const _AnimatedStepper({required this.currentStep});
  @override
  State<_AnimatedStepper> createState() => _AnimatedStepperState();
}

class _AnimatedStepperState extends State<_AnimatedStepper> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final stepLabels = ['Order Placed', 'Order Accepted', 'Preparing Food', 'Ready for Collection', 'Completed'];
    final stepDescs = [
      'We have received your order request.',
      'Canteen staff approved your request.',
      'Kitchen is currently preparing items.',
      'Bring QR code to counter to collect.',
      'Food collected successfully.',
    ];
    final n = stepLabels.length;
    return Column(
      children: List.generate(n * 2 - 1, (i) {
        if (i.isOdd) {
          // Connecting line
          final stepIdx = i ~/ 2;
          final isActive = widget.currentStep > stepIdx;
          return _AnimatedLine(isActive: isActive, animCtrl: _ctrl, delay: stepIdx / n);
        }
        final stepIdx = i ~/ 2;
        final isCompleted = widget.currentStep > stepIdx;
        final isActive = widget.currentStep == stepIdx;
        return _AnimatedStep(
          title: stepLabels[stepIdx],
          desc: stepDescs[stepIdx],
          isActive: isActive,
          isCompleted: isCompleted,
          delay: stepIdx / n,
          animCtrl: _ctrl,
        );
      }),
    );
  }
}

class _AnimatedStep extends StatelessWidget {
  final String title, desc;
  final bool isActive, isCompleted;
  final double delay;
  final AnimationController animCtrl;

  const _AnimatedStep({required this.title, required this.desc, required this.isActive, required this.isCompleted, required this.delay, required this.animCtrl});

  @override
  Widget build(BuildContext context) {
    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animCtrl, curve: Interval(delay, (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut)),
    );
    final Color iconColor = isCompleted ? AppColors.success : isActive ? AppColors.primaryNeon : AppColors.darkBorder;
    final Color titleColor = (isCompleted || isActive) ? Colors.white : Colors.grey;

    return FadeTransition(
      opacity: fade,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.15),
              border: Border.all(color: iconColor, width: 2),
              boxShadow: isActive ? [BoxShadow(color: iconColor.withOpacity(0.4), blurRadius: 12)] : [],
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: AppColors.success, size: 14)
                  : isActive
                      ? Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryNeon))
                      : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLine extends StatelessWidget {
  final bool isActive;
  final double delay;
  final AnimationController animCtrl;

  const _AnimatedLine({required this.isActive, required this.delay, required this.animCtrl});

  @override
  Widget build(BuildContext context) {
    final heightAnim = Tween<double>(begin: 0, end: 36).animate(
      CurvedAnimation(parent: animCtrl, curve: Interval(delay, (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut)),
    );
    return AnimatedBuilder(
      animation: heightAnim,
      builder: (_, __) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
          width: 2,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive ? [AppColors.primaryNeon, AppColors.success] : [AppColors.darkBorder, AppColors.darkBorder],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}

// -- Ready glow pulsing card -----------------------------------------
class _ReadyGlowCard extends StatefulWidget {
  final bool isReady;
  final Widget child;
  const _ReadyGlowCard({required this.isReady, required this.child});
  @override
  State<_ReadyGlowCard> createState() => _ReadyGlowCardState();
}

class _ReadyGlowCardState extends State<_ReadyGlowCard> with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 4, end: 24).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _glowCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isReady ? AppColors.success : AppColors.darkBorder,
            width: widget.isReady ? 1.5 : 1,
          ),
          boxShadow: widget.isReady
              ? [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: _glowAnim.value, spreadRadius: 2)]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}
