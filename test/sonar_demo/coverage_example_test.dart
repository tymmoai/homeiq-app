// ================================================================
// SonarQube Coverage Demo — How coverage works
// ================================================================
//
// WHY THIS FILE EXISTS:
//   This test demonstrates how SonarQube measures code coverage.
//
//   CODE COVERAGE means:
//     "What percentage of your production code is executed
//      when your tests run?"
//
//   HOW IT FLOWS:
//     1. You run: flutter test --coverage
//     2. Dart traces every line executed during tests
//     3. It writes the results to: coverage/lcov.info
//     4. SonarScanner reads lcov.info and sends to SonarQube
//     5. SonarQube shows you which lines are tested vs. untested
//
//   In the SonarQube dashboard:
//     GREEN line = covered (tested)
//     RED line   = uncovered (not tested — potential risk!)
//
// ================================================================

import 'package:flutter_test/flutter_test.dart';

// ----------------------------------------------------------------
// Example: A simple utility class we want to test
// In a real project this would be in lib/utils/ or lib/core/
// ----------------------------------------------------------------

/// A simple validator class — the kind of code SonarQube will analyze.
///
/// SonarQube will look for:
///   - Bugs (e.g., null pointer issues)
///   - Code smells (e.g., overly complex methods)
///   - Security vulnerabilities (e.g., unvalidated input)
///   - Uncovered lines (no test exercises this path)
class InputValidator {
  /// Validates an email address format.
  /// Returns true if valid, false if not.
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false; // ← SonarQube will check: is this tested?

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validates a password meets minimum security requirements.
  /// - At least 8 characters
  /// - Contains uppercase letter
  /// - Contains number
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasUpperCase && hasNumber;
  }

  /// Formats a US phone number: (555) 123-4567
  /// Returns null if the input cannot be formatted.
  static String? formatPhoneNumber(String raw) {
    // Strip non-digits
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      // Handle +1 country code
      return '(${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }

    // If we reach here → SonarQube will show this as a possible code path.
    // If NO test covers a return-null path, SonarQube flags it as UNCOVERED.
    return null;
  }
}

// ================================================================
// TESTS
// ================================================================
void main() {
  // ----------------------------------------------------------------
  // GROUP: Email validation
  // Each test = one specific behavior we are verifying.
  // When tests pass, those lines in InputValidator are "covered".
  // ----------------------------------------------------------------
  group('InputValidator.isValidEmail', () {
    test('returns false for empty string', () {
      // This test covers the "if (email.isEmpty) return false" line
      expect(InputValidator.isValidEmail(''), isFalse);
    });

    test('returns true for valid email', () {
      expect(InputValidator.isValidEmail('user@example.com'), isTrue);
    });

    test('returns false for email without @', () {
      expect(InputValidator.isValidEmail('userexample.com'), isFalse);
    });

    test('returns false for email without domain', () {
      expect(InputValidator.isValidEmail('user@'), isFalse);
    });

    test('handles subdomains', () {
      expect(InputValidator.isValidEmail('user@mail.company.co'), isTrue);
    });
  });

  // ----------------------------------------------------------------
  // GROUP: Password validation
  // ----------------------------------------------------------------
  group('InputValidator.isStrongPassword', () {
    test('returns false for short password', () {
      expect(InputValidator.isStrongPassword('Ab1'), isFalse);
    });

    test('returns false for password without uppercase', () {
      expect(InputValidator.isStrongPassword('password123'), isFalse);
    });

    test('returns false for password without number', () {
      expect(InputValidator.isStrongPassword('Password'), isFalse);
    });

    test('returns true for strong password', () {
      expect(InputValidator.isStrongPassword('Password1'), isTrue);
    });
  });

  // ----------------------------------------------------------------
  // GROUP: Phone number formatting
  // NOTICE: We are NOT testing the `return null` case below.
  //
  // When you run the SonarQube scan, the dashboard will show:
  //   - The `return null` line is RED (uncovered)
  //   - This means: "no test ever hits that code path"
  //
  // This is exactly what SonarQube is designed to show you!
  // You would then write a test for it to turn it GREEN.
  // ----------------------------------------------------------------
  group('InputValidator.formatPhoneNumber', () {
    test('formats 10-digit US number', () {
      expect(
        InputValidator.formatPhoneNumber('5551234567'),
        equals('(555) 123-4567'),
      );
    });

    test('strips dashes before formatting', () {
      expect(
        InputValidator.formatPhoneNumber('555-123-4567'),
        equals('(555) 123-4567'),
      );
    });

    test('handles +1 country code (11 digits)', () {
      expect(
        InputValidator.formatPhoneNumber('15551234567'),
        equals('(555) 123-4567'),
      );
    });

    // ---------------------------------------------------------------
    // INTENTIONALLY MISSING: test for invalid/short phone number
    // This means the `return null` line will show as UNCOVERED
    // in SonarQube → demonstrating what "coverage gaps" look like.
    //
    // To fix it, uncomment this test:
    // ---------------------------------------------------------------
    // test('returns null for invalid number', () {
    //   expect(InputValidator.formatPhoneNumber('123'), isNull);
    // });
  });
}
