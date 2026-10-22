import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class EhButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;

  const EhButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? buttonColor : Colors.white,
              ),
            ),
          )
        else if (icon != null)
          Icon(
            icon,
            size: 20,
            color: isOutlined ? buttonColor : Colors.white,
          ),
        if (icon != null || isLoading) const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isOutlined ? buttonColor : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.button,
    );

    final style = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: shape,
          )
        : FilledButton.styleFrom(
            backgroundColor: buttonColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: shape,
          );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: child,
    );
  }
}