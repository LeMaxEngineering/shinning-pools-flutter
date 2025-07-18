import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.textColor,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? AppColors.primary;
    
    // Use theme-aware text color with better contrast logic
    final buttonTextColor = textColor ?? _getContrastingTextColor(buttonColor, theme);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: _buildButtonContent(buttonColor, theme), // For outlined, use button color for content
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: buttonTextColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: _buildButtonContent(buttonTextColor, theme),
    );
  }

  // Helper method to determine contrasting text color
  Color _getContrastingTextColor(Color backgroundColor, ThemeData theme) {
    // For dark backgrounds, use white/light text
    // For light backgrounds, use dark text
    final luminance = backgroundColor.computeLuminance();
    if (luminance > 0.5) {
      return theme.colorScheme.onSurface; // Dark text on light background
    } else {
      return theme.colorScheme.onPrimary; // Light text on dark background
    }
  }

  Widget _buildButtonContent(Color textColor, ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          // Use theme-aware color for loading indicator
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.button.copyWith(color: textColor),
          ),
        ],
      );
    }

    return Text(
      label,
      style: AppTextStyles.button.copyWith(color: textColor),
    );
  }
} 