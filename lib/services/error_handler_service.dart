import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorHandlerService {
  static void showErrorDialog(BuildContext context, {String? title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title ?? 'Terjadi Kesalahan',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static String handle(BuildContext context, dynamic error) {
    String errorMessage;
    if (error is String) {
      errorMessage = error;
    } else if (error is Map && error.containsKey('message')) {
      errorMessage = error['message'];
    } else {
      errorMessage = 'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi.';
    }

    // For developers, log the raw error to the console
    debugPrint('Raw Error: $error');

    return errorMessage;
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}