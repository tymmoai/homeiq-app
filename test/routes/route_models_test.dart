import 'package:flutter_test/flutter_test.dart';
import 'package:homeiq/routes/route_models.dart';

void main() {
  group('Route Models', () {
    // ─────────────────────────────────────────────────────────────────────
    // ServiceSubcategoryParams
    // ─────────────────────────────────────────────────────────────────────
    group('ServiceSubcategoryParams', () {
      test('constructor stores values', () {
        const params = ServiceSubcategoryParams(
          categoryName: 'Plumbing',
          services: [
            {'name': 'Leak Repair', 'price': 50},
          ],
        );
        expect(params.categoryName, 'Plumbing');
        expect(params.services, hasLength(1));
      });

      test('toMap() returns expected keys', () {
        const params = ServiceSubcategoryParams(
          categoryName: 'HVAC',
          services: [],
        );
        final map = params.toMap();
        expect(map, containsPair('categoryName', 'HVAC'));
        expect(map, contains('services'));
      });

      test('fromMap() round-trip preserves values', () {
        const original = ServiceSubcategoryParams(
          categoryName: 'Electric',
          services: [
            {'id': 1, 'name': 'Wiring'},
          ],
        );
        final rebuilt = ServiceSubcategoryParams.fromMap(original.toMap());
        expect(rebuilt.categoryName, original.categoryName);
        expect(rebuilt.services.length, original.services.length);
        expect(rebuilt.services.first['name'], 'Wiring');
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // AssetDetailParams
    // ─────────────────────────────────────────────────────────────────────
    group('AssetDetailParams', () {
      test('constructor stores values', () {
        const params = AssetDetailParams(
          asset: {'id': 'a1', 'name': 'Washer'},
          initialTab: 'details',
          skipPopup: true,
        );
        expect(params.asset['name'], 'Washer');
        expect(params.initialTab, 'details');
        expect(params.skipPopup, isTrue);
      });

      test('constructor defaults', () {
        const params = AssetDetailParams(asset: {'id': 'a2'});
        expect(params.initialTab, isNull);
        expect(params.skipPopup, isFalse);
      });

      test('toMap() returns expected keys', () {
        const params = AssetDetailParams(asset: {'id': 'a1'});
        final map = params.toMap();
        expect(map, contains('asset'));
        expect(map, contains('initialTab'));
        expect(map, contains('skipPopup'));
      });

      test('fromExtra() with full map round-trips', () {
        const original = AssetDetailParams(
          asset: {'id': 'a1', 'brand': 'LG'},
          initialTab: 'warranty',
          skipPopup: true,
        );
        final rebuilt = AssetDetailParams.fromExtra(original.toMap());
        expect(rebuilt.asset['brand'], 'LG');
        expect(rebuilt.initialTab, 'warranty');
        expect(rebuilt.skipPopup, isTrue);
      });

      test('fromExtra() with plain asset map', () {
        final assetMap = <String, dynamic>{'id': 'x', 'name': 'Dryer'};
        final params = AssetDetailParams.fromExtra(assetMap);
        expect(params.asset['name'], 'Dryer');
      });

      test('fromExtra() throws on invalid input', () {
        expect(
          () => AssetDetailParams.fromExtra('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // CheckoutAddressParams
    // ─────────────────────────────────────────────────────────────────────
    group('CheckoutAddressParams', () {
      test('constructor stores values', () {
        const params = CheckoutAddressParams(
          product: {'id': 'p1', 'name': 'TV'},
          tradeInValue: 100,
          quantity: 2,
          asset: {'id': 'a1'},
        );
        expect(params.product['name'], 'TV');
        expect(params.tradeInValue, 100);
        expect(params.quantity, 2);
        expect(params.asset, isNotNull);
      });

      test('constructor defaults', () {
        const params = CheckoutAddressParams(product: {'id': 'p1'});
        expect(params.tradeInValue, 0);
        expect(params.quantity, 1);
        expect(params.asset, isNull);
      });

      test('toMap() returns expected keys', () {
        const params = CheckoutAddressParams(product: {'id': 'p1'});
        final map = params.toMap();
        expect(map, contains('product'));
        expect(map, contains('tradeInValue'));
        expect(map, contains('quantity'));
        expect(map, contains('asset'));
      });

      test('fromMap() round-trip preserves values', () {
        const original = CheckoutAddressParams(
          product: {'id': 'p1', 'name': 'Fridge'},
          tradeInValue: 50,
          quantity: 3,
        );
        final rebuilt = CheckoutAddressParams.fromMap(original.toMap());
        expect(rebuilt.product['name'], 'Fridge');
        expect(rebuilt.tradeInValue, 50);
        expect(rebuilt.quantity, 3);
        expect(rebuilt.asset, isNull);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // ServiceBookingParams
    // ─────────────────────────────────────────────────────────────────────
    group('ServiceBookingParams', () {
      test('constructor stores values', () {
        const params = ServiceBookingParams(
          categoryName: 'Cleaning',
          service: {'id': 's1', 'name': 'Deep Clean'},
        );
        expect(params.categoryName, 'Cleaning');
        expect(params.service['name'], 'Deep Clean');
      });

      test('toMap() returns expected keys', () {
        const params = ServiceBookingParams(
          categoryName: 'Test',
          service: {'id': 's1'},
        );
        final map = params.toMap();
        expect(map, contains('categoryName'));
        expect(map, contains('service'));
      });

      test('fromMap() round-trip preserves values', () {
        const original = ServiceBookingParams(
          categoryName: 'Repair',
          service: {'id': 's2', 'price': 75},
        );
        final rebuilt = ServiceBookingParams.fromMap(original.toMap());
        expect(rebuilt.categoryName, original.categoryName);
        expect(rebuilt.service['price'], 75);
      });
    });
  });
}
