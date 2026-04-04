import 'package:flutter/services.dart';

/// Formats text input as an expiry date in MM/YY format.
class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 4) {
      return oldValue;
    }

    String formatted = text;
    if (text.length >= 3 && !text.contains('/')) {
      formatted = '${text.substring(0, 2)}/${text.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
