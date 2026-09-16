import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum _BtnState { idle, loading, done }

class MorphAddButton extends StatefulWidget {
  final Future<bool> Function() onAdd;
  const MorphAddButton({Key? key, required this.onAdd}) : super(key: key);
  @override
  State<MorphAddButton> createState() => _MorphAddButtonState();
}

class _MorphAddButtonState extends State<MorphAddButton>
    with SingleTickerProviderStateMixin {
  _BtnState _state = _BtnState.idle;
  late AnimationController _ctrl;
  late Animation<double> _rotAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat();
    _rotAnim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_state != _BtnState.idle) return;
    setState(() => _state = _BtnState.loading);
    final ok = await widget.onAdd();
    if (!mounted) return;
    setState(() => _state = ok ? _BtnState.done : _BtnState.idle);
    if (ok) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _state = _BtnState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = _state == _BtnState.loading;
    final bool isDone = _state == _BtnState.done;

    return GestureDetector(
      onTap: _tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isDone ? 44 : (isLoading ? 44 : 44),
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone
              ? AppColors.success
              : isLoading
                  ? Colors.transparent
                  : AppColors.primaryNeon,
          border: isLoading
              ? Border.all(color: AppColors.primaryNeon, width: 2)
              : null,
        ),
        child: Center(
          child: isLoading
              ? RotationTransition(
                  turns: _rotAnim,
                  child: const Icon(Icons.refresh, color: AppColors.primaryNeon, size: 20),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isDone ? Icons.check : Icons.add,
                    key: ValueKey(_state),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
        ),
      ),
    );
  }
}
