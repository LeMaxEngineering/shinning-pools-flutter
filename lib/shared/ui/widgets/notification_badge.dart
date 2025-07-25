import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/notification_service.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
    this.padding,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final unreadCount = notificationService.unreadCount;

        if (unreadCount == 0) {
          return GestureDetector(onTap: onTap, child: this.child);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(onTap: onTap, child: this.child),
            Positioned(
              right: padding?.right ?? -8,
              top: padding?.top ?? -8,
              child: Container(
                width: badgeSize ?? 20,
                height: badgeSize ?? 20,
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular((badgeSize ?? 20) / 2),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontSize: (badgeSize ?? 20) * 0.6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class NotificationIconButton extends StatelessWidget {
  final IconData icon;
  final double? iconSize;
  final Color? iconColor;
  final VoidCallback? onPressed;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final double? badgeSize;

  const NotificationIconButton({
    Key? key,
    required this.icon,
    this.iconSize,
    this.iconColor,
    this.onPressed,
    this.badgeColor,
    this.badgeTextColor,
    this.badgeSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      badgeColor: badgeColor,
      textColor: badgeTextColor,
      badgeSize: badgeSize,
      onTap: onPressed,
      child: IconButton(
        icon: Icon(icon, size: iconSize, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }
}
