import 'package:flutter_test/flutter_test.dart';
import 'package:homeiq/core/constants/app_strings.dart';

void main() {
  group('AppStrings', () {
    // ─────────────────────────────────────────────────────────────────────
    // Brand / App identity
    // ─────────────────────────────────────────────────────────────────────
    group('brand constants', () {
      test('appName is non-empty', () {
        expect(AppStrings.appName, isNotEmpty);
      });

      test('appNameFull is non-empty', () {
        expect(AppStrings.appNameFull, isNotEmpty);
      });

      test('productBrand is non-empty', () {
        expect(AppStrings.productBrand, isNotEmpty);
      });

      test('aiName contains appName', () {
        expect(AppStrings.aiName, contains(AppStrings.appName));
      });

      test('walletName contains appName', () {
        expect(AppStrings.walletName, contains(AppStrings.appName));
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Common actions
    // ─────────────────────────────────────────────────────────────────────
    group('common action constants', () {
      test('ok is non-empty', () {
        expect(AppStrings.ok, isNotEmpty);
      });

      test('cancel is non-empty', () {
        expect(AppStrings.cancel, isNotEmpty);
      });

      test('save is non-empty', () {
        expect(AppStrings.save, isNotEmpty);
      });

      test('submit is non-empty', () {
        expect(AppStrings.submit, isNotEmpty);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Common messages
    // ─────────────────────────────────────────────────────────────────────
    group('common message constants', () {
      test('loading is non-empty', () {
        expect(AppStrings.loading, isNotEmpty);
      });

      test('error is non-empty', () {
        expect(AppStrings.error, isNotEmpty);
      });

      test('success is non-empty', () {
        expect(AppStrings.success, isNotEmpty);
      });

      test('retry is non-empty', () {
        expect(AppStrings.retry, isNotEmpty);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Validation messages
    // ─────────────────────────────────────────────────────────────────────
    group('validation constants', () {
      test('required is non-empty', () {
        expect(AppStrings.required, isNotEmpty);
      });

      test('invalidEmail is non-empty', () {
        expect(AppStrings.invalidEmail, isNotEmpty);
      });

      test('invalidPhone is non-empty', () {
        expect(AppStrings.invalidPhone, isNotEmpty);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Route error messages
    // ─────────────────────────────────────────────────────────────────────
    group('route error constants', () {
      test('serviceCategoryNotFound is non-empty', () {
        expect(AppStrings.serviceCategoryNotFound, isNotEmpty);
      });

      test('serviceNotFound is non-empty', () {
        expect(AppStrings.serviceNotFound, isNotEmpty);
      });

      test('assetNotFound is non-empty', () {
        expect(AppStrings.assetNotFound, isNotEmpty);
      });

      test('dataNotFound is non-empty', () {
        expect(AppStrings.dataNotFound, isNotEmpty);
      });

      test('productNotFound is non-empty', () {
        expect(AppStrings.productNotFound, isNotEmpty);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // routeError() method
    // ─────────────────────────────────────────────────────────────────────
    group('routeError()', () {
      test('returns string starting with Error:', () {
        final result = AppStrings.routeError('something went wrong');
        expect(result, startsWith('Error:'));
      });

      test('contains the input error message', () {
        final result = AppStrings.routeError('missing param');
        expect(result, contains('missing param'));
      });

      test('returns expected format', () {
        expect(AppStrings.routeError('test'), equals('Error: test'));
      });
    });
  });
}
