import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerLoader({
    Key? key,
    this.width = double.infinity,
    this.height = 20.0,
    this.borderRadius = 8.0,
    this.shape = BoxShape.rectangle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF212529) : const Color(0xFFE9ECEF);
    final highlightColor = isDark ? const Color(0xFF343A40) : const Color(0xFFF8F9FA);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(borderRadius)
              : null,
        ),
      ),
    );
  }
}

class ShimmerFoodCard extends StatelessWidget {
  const ShimmerFoodCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const ShimmerLoader(
            width: 80,
            height: 80,
            borderRadius: 12,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoader(width: 120, height: 16, borderRadius: 4),
                const SizedBox(width: 4, height: 8),
                const ShimmerLoader(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(width: 4, height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerLoader(width: 60, height: 16, borderRadius: 4),
                    ShimmerLoader(width: 40, height: 24, borderRadius: 12),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
