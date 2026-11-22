import 'package:material_ui/material_ui.dart';

import '../services/feedback_service.dart';

/// Envolve qualquer widget com feedback de toque: encolhe ao pressionar e volta com mola.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double escala;
  final bool vibrar;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.escala = 0.94,
    this.vibrar = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressionado = false;

  void _set(bool v) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_pressionado != v) setState(() => _pressionado = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onLongPress: widget.onLongPress,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.vibrar) FeedbackService.instancia.vibrarLeve();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressionado ? widget.escala : 1,
        duration: Duration(milliseconds: _pressionado ? 80 : 260),
        curve: _pressionado ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}
