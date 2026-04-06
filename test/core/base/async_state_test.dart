import 'package:flutter_test/flutter_test.dart';
import 'package:homeiq/core/base/base_state.dart';

void main() {
  group('AsyncState', () {
    // ─────────────────────────────────────────────────────────────────────
    // AsyncLoading
    // ─────────────────────────────────────────────────────────────────────
    group('AsyncLoading', () {
      test('can be created via constructor', () {
        const state = AsyncLoading<int>();
        expect(state, isA<AsyncState<int>>());
        expect(state, isA<AsyncLoading<int>>());
      });

      test('can be created via factory', () {
        const state = AsyncState<int>.loading();
        expect(state, isA<AsyncLoading<int>>());
      });

      test('isLoading is true', () {
        const state = AsyncState<int>.loading();
        expect(state.isLoading, isTrue);
      });

      test('hasData is false', () {
        const state = AsyncState<int>.loading();
        expect(state.hasData, isFalse);
      });

      test('hasError is false', () {
        const state = AsyncState<int>.loading();
        expect(state.hasError, isFalse);
      });

      test('dataOrNull returns null', () {
        const state = AsyncState<int>.loading();
        expect(state.dataOrNull, isNull);
      });

      test('errorOrNull returns null', () {
        const state = AsyncState<int>.loading();
        expect(state.errorOrNull, isNull);
      });

      test('equality works', () {
        const a = AsyncLoading<int>();
        const b = AsyncLoading<int>();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('toString returns expected format', () {
        const state = AsyncLoading<int>();
        expect(state.toString(), contains('loading'));
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // AsyncData
    // ─────────────────────────────────────────────────────────────────────
    group('AsyncData', () {
      test('can be created via constructor', () {
        const state = AsyncData<int>(42);
        expect(state, isA<AsyncState<int>>());
        expect(state.data, 42);
      });

      test('can be created via factory', () {
        const state = AsyncState<String>.data('hello');
        expect(state, isA<AsyncData<String>>());
      });

      test('isLoading is false', () {
        const state = AsyncState<int>.data(1);
        expect(state.isLoading, isFalse);
      });

      test('hasData is true', () {
        const state = AsyncState<int>.data(1);
        expect(state.hasData, isTrue);
      });

      test('hasError is false', () {
        const state = AsyncState<int>.data(1);
        expect(state.hasError, isFalse);
      });

      test('dataOrNull returns the data', () {
        const state = AsyncState<int>.data(99);
        expect(state.dataOrNull, 99);
      });

      test('errorOrNull returns null', () {
        const state = AsyncState<int>.data(1);
        expect(state.errorOrNull, isNull);
      });

      test('equality works for equal data', () {
        const a = AsyncData<int>(42);
        const b = AsyncData<int>(42);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('inequality for different data', () {
        const a = AsyncData<int>(1);
        const b = AsyncData<int>(2);
        expect(a, isNot(equals(b)));
      });

      test('toString contains the data', () {
        const state = AsyncData<int>(42);
        expect(state.toString(), contains('42'));
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // AsyncError
    // ─────────────────────────────────────────────────────────────────────
    group('AsyncError', () {
      test('can be created with message only', () {
        const state = AsyncError<int>('oops');
        expect(state, isA<AsyncState<int>>());
        expect(state.message, 'oops');
        expect(state.error, isNull);
      });

      test('can be created with message and error object', () {
        final exception = Exception('fail');
        final state = AsyncError<int>('oops', exception);
        expect(state.message, 'oops');
        expect(state.error, exception);
      });

      test('can be created via factory', () {
        const state = AsyncState<int>.error('bad');
        expect(state, isA<AsyncError<int>>());
      });

      test('isLoading is false', () {
        const state = AsyncState<int>.error('err');
        expect(state.isLoading, isFalse);
      });

      test('hasData is false', () {
        const state = AsyncState<int>.error('err');
        expect(state.hasData, isFalse);
      });

      test('hasError is true', () {
        const state = AsyncState<int>.error('err');
        expect(state.hasError, isTrue);
      });

      test('dataOrNull returns null', () {
        const state = AsyncState<int>.error('err');
        expect(state.dataOrNull, isNull);
      });

      test('errorOrNull returns the message', () {
        const state = AsyncState<int>.error('something broke');
        expect(state.errorOrNull, 'something broke');
      });

      test('equality based on message', () {
        const a = AsyncError<int>('x');
        const b = AsyncError<int>('x');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('inequality for different messages', () {
        const a = AsyncError<int>('a');
        const b = AsyncError<int>('b');
        expect(a, isNot(equals(b)));
      });

      test('toString contains the message', () {
        const state = AsyncError<int>('oops');
        expect(state.toString(), contains('oops'));
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // when() pattern matching
    // ─────────────────────────────────────────────────────────────────────
    group('when()', () {
      test('calls loading branch for AsyncLoading', () {
        const state = AsyncState<int>.loading();
        final result = state.when(
          loading: () => 'loading',
          data: (d) => 'data:$d',
          error: (m, e) => 'error:$m',
        );
        expect(result, 'loading');
      });

      test('calls data branch for AsyncData', () {
        const state = AsyncState<int>.data(42);
        final result = state.when(
          loading: () => 'loading',
          data: (d) => 'data:$d',
          error: (m, e) => 'error:$m',
        );
        expect(result, 'data:42');
      });

      test('calls error branch for AsyncError', () {
        const state = AsyncState<int>.error('fail');
        final result = state.when(
          loading: () => 'loading',
          data: (d) => 'data:$d',
          error: (m, e) => 'error:$m',
        );
        expect(result, 'error:fail');
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // maybeWhen() with orElse
    // ─────────────────────────────────────────────────────────────────────
    group('maybeWhen()', () {
      test('calls loading handler when provided for AsyncLoading', () {
        const state = AsyncState<int>.loading();
        final result = state.maybeWhen(
          loading: () => 'loading',
          orElse: () => 'fallback',
        );
        expect(result, 'loading');
      });

      test(
        'calls orElse when loading handler is not provided for AsyncLoading',
        () {
          const state = AsyncState<int>.loading();
          final result = state.maybeWhen(
            data: (d) => 'data:$d',
            orElse: () => 'fallback',
          );
          expect(result, 'fallback');
        },
      );

      test('calls data handler when provided for AsyncData', () {
        const state = AsyncState<int>.data(7);
        final result = state.maybeWhen(
          data: (d) => 'data:$d',
          orElse: () => 'fallback',
        );
        expect(result, 'data:7');
      });

      test('calls orElse when data handler is not provided for AsyncData', () {
        const state = AsyncState<int>.data(7);
        final result = state.maybeWhen(
          error: (m, e) => 'error',
          orElse: () => 'fallback',
        );
        expect(result, 'fallback');
      });

      test('calls error handler when provided for AsyncError', () {
        const state = AsyncState<int>.error('bad');
        final result = state.maybeWhen(
          error: (m, e) => 'error:$m',
          orElse: () => 'fallback',
        );
        expect(result, 'error:bad');
      });

      test(
        'calls orElse when error handler is not provided for AsyncError',
        () {
          const state = AsyncState<int>.error('bad');
          final result = state.maybeWhen(
            loading: () => 'loading',
            orElse: () => 'fallback',
          );
          expect(result, 'fallback');
        },
      );
    });
  });
}
