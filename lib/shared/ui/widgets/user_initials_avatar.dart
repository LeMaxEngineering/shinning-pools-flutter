import 'package:flutter/material.dart';

class UserInitialsAvatar extends StatelessWidget {
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final double radius;
  final double fontSize;

  const UserInitialsAvatar({
    Key? key,
    this.displayName,
    this.email,
    this.photoUrl,
    this.radius = 20,
    this.fontSize = 18,
  }) : super(key: key);

  String _getInitials() {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length == 1) {
        return parts[0][0].toUpperCase();
      } else if (parts.length > 1) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
    } else if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blue,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue,
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
} 