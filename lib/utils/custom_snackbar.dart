import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required bool isError,
    IconData? customIcon,
    Color? customColor,
  }) {
    final theme = Theme.of(context);
    final isSinhala = message.contains(RegExp(r'[඀-෿]')); // Check if Sinhala characters exist

    final backgroundColor = customColor ?? (isError ? Colors.red.shade600 : Colors.green.shade600);
    final icon = customIcon ?? (isError ? Icons.error_outline : Icons.check_circle_outline);

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isSinhala ? 14 : 15, // Slightly smaller for Sinhala to prevent overflow
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: isSinhala ? 'හරි' : 'OK',
        textColor: Colors.white,
        onPressed: () {},
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, isError: false);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, isError: true);
  }

  static void showInfo(BuildContext context, String message) {
    show(
      context,
      message: message,
      isError: false,
      customColor: Colors.blue.shade600,
      customIcon: Icons.info_outline,
    );
  }
}
