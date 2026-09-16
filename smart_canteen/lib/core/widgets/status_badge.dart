import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'placed':
        color = AppColors.info.withOpacity(0.15);
        textColor = AppColors.info;
        label = 'PLACED';
        break;
      case 'accepted':
        color = AppColors.primaryNeon.withOpacity(0.15);
        textColor = AppColors.primaryNeon;
        label = 'ACCEPTED';
        break;
      case 'preparing':
        color = AppColors.warning.withOpacity(0.15);
        textColor = AppColors.warning;
        label = 'PREPARING';
        break;
      case 'ready':
        color = AppColors.success.withOpacity(0.15);
        textColor = AppColors.success;
        label = 'READY TO COLLECT';
        break;
      case 'completed':
        color = Colors.green.withOpacity(0.15);
        textColor = Colors.green;
        label = 'COMPLETED';
        break;
      case 'cancelled':
        color = AppColors.error.withOpacity(0.15);
        textColor = AppColors.error;
        label = 'CANCELLED';
        break;
      default:
        color = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
