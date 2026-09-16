import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int minCount;
  final int maxCount;

  const AnimatedCounter({
    Key? key,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
    this.minCount = 1,
    this.maxCount = 99,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: count > minCount ? onDecrement : null,
            color: Theme.of(context).colorScheme.primary,
            disabledColor: Colors.grey,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              '$count',
              key: ValueKey<int>(count),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: count < maxCount ? onIncrement : null,
            color: Theme.of(context).colorScheme.primary,
            disabledColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}
