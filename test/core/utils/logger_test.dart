import 'package:flutter_test/flutter_test.dart';
import 'package:homeiq/core/utils/logger.dart';

void main() {
  group('AppLogger', () {
    test('debug does not throw', () {
      expect(() => AppLogger.debug('test message'), returnsNormally);
    });

    test('debug with tag does not throw', () {
      expect(() => AppLogger.debug('msg', tag: 'MyTag'), returnsNormally);
    });

    test('info does not throw', () {
      expect(() => AppLogger.info('info message'), returnsNormally);
    });

    test('info with tag does not throw', () {
      expect(() => AppLogger.info('msg', tag: 'Info'), returnsNormally);
    });

    test('warning does not throw', () {
      expect(() => AppLogger.warning('warn message'), returnsNormally);
    });

    test('warning with tag and error does not throw', () {
      expect(
        () => AppLogger.warning('warn', tag: 'W', error: Exception('e')),
        returnsNormally,
      );
    });

    test('error does not throw', () {
      expect(() => AppLogger.error('error message'), returnsNormally);
    });

    test('error with all optional params does not throw', () {
      expect(
        () => AppLogger.error(
          'err',
          tag: 'E',
          error: Exception('boom'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('api does not throw with method and url only', () {
      expect(() => AppLogger.api('GET', '/users'), returnsNormally);
    });

    test('api with statusCode and response does not throw', () {
      expect(
        () => AppLogger.api('POST', '/login', statusCode: 200, response: '{}'),
        returnsNormally,
      );
    });

    test('navigation does not throw', () {
      expect(
        () => AppLogger.navigation('/home', '/settings'),
        returnsNormally,
      );
    });

    test('userAction does not throw', () {
      expect(() => AppLogger.userAction('tap_button'), returnsNormally);
    });

    test('userAction with data does not throw', () {
      expect(
        () => AppLogger.userAction('tap', data: {'id': 1}),
        returnsNormally,
      );
    });
  });
}
