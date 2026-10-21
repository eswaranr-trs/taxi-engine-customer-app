import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import '../../../config/themes/app_colors.dart' show AppColors;

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color textColor;
  final Gradient? gradient;
  final IconData? icon;
  final bool enabled;
  final bool loading;
  final Border? border;
  final double? fontsize;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor = AppColors.normalText,
    this.gradient,
    this.icon,
    this.enabled = true,
    this.loading = false,
    this.border,
    this.fontsize,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && !widget.loading;

  void _setPressed(bool v) {
    if (!_interactive) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool dim = !widget.enabled;

    return GestureDetector(
      onTap: _interactive ? widget.onPressed : null,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: dim ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              color: widget.gradient == null ? (widget.color ?? AppColors.lightGrey) : null,
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(15),
              border: widget.border,
              boxShadow: (widget.gradient != null && !dim)
                  ? [
                      BoxShadow(
                        color: (widget.gradient!.colors.last).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: widget.loading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: widget.textColor),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        text: widget.text,
                        fontSize: widget.fontsize ?? 16,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                      ),
                      if (widget.icon != null) ...[10.width, Icon(widget.icon, color: widget.textColor, size: 20)],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
