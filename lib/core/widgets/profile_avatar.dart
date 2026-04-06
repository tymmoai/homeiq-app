// ignore_for_file: unnecessary_underscores

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_profile_provider.dart';

/// A reusable profile avatar widget that reads from the [userProfileProvider].
///
/// Shows the user's profile image if available, otherwise shows initials.
/// Supports both local file paths (ImagePicker) and remote HTTP URLs
/// (backend avatarUrl). Must be placed inside a [ProviderScope] ancestor.
class ProfileAvatar extends ConsumerWidget {
  /// Diameter of the avatar circle.
  final double size;

  /// Font size for the initials text.
  final double fontSize;

  /// Background color when showing initials.
  final Color backgroundColor;

  /// Text color for the initials.
  final Color textColor;

  const ProfileAvatar({
    super.key,
    required this.size,
    this.fontSize = 16.0,
    this.backgroundColor = const Color(0x3DFFFFFF),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    Widget initialsWidget = Center(
      child: Text(
        profile.getInitials(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );

    Widget imageWidget;
    if (profile.hasProfileImage) {
      final path = profile.profileImagePath!;
      final isNetwork =
          path.startsWith('http://') || path.startsWith('https://');
      if (isNetwork) {
        imageWidget = Image.network(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => initialsWidget,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return initialsWidget;
          },
        );
      } else {
        imageWidget = Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => initialsWidget,
        );
      }
    } else {
      imageWidget = initialsWidget;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
      clipBehavior: Clip.antiAlias,
      child: imageWidget,
    );
  }
}
