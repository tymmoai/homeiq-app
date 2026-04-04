import 'package:flutter_test/flutter_test.dart';
import 'package:homeiq/core/errors/failures.dart';
import 'package:homeiq/core/utils/result.dart';

void main() {
  group('Result', () {
    // ─────────────────────────────────────────────────────────────────────
    // Success
    // ─────────────────────────────────────────────────────────────────────
    group('Success', () {
      test('can be created with data', () {
        const result = Success<int>(42);
        expect(result, isA<Result<int>>());
        expect(result.data, 42);
      });

      test('isSuccess is true', () {
        const result = Success<String>('hello');
        expect(result.isSuccess, isTrue);
      });

      test('isFailure is false', () {
        const result = Success<String>('hello');
        expect(result.isFailure, isFalse);
      });

      test('dataOrNull returns the data', () {
        const result = Success<int>(99);
        expect(result.dataOrNull, 99);
      });

      test('failureOrNull returns null', () {
        const result = Success<int>(1);
        expect(result.failureOrNull, isNull);
      });

      test('equality works for equal values', () {
        const a = Success<int>(10);
        const b = Success<int>(10);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('inequality for different values', () {
        const a = Success<int>(1);
        const b = Success<int>(2);
        expect(a, isNot(equals(b)));
      });

      test('toString contains data', () {
        const result = Success<int>(42);
        expect(result.toString(), contains('42'));
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Failed
    // ─────────────────────────────────────────────────────────────────────
    group('Failed', () {
      test('can be created with a Failure', () {
        const failure = ServerFailure('Server error', 500);
        const result = Failed<int>(failure);
        expect(result, isA<Result<int>>());
        expect(result.failure, failure);
        expect(result.failure.message, 'Server error');
      });

      test('isSuccess is false', () {
        const result = Failed<int>(NetworkFailure());
        expect(result.isSuccess, isFalse);
      });

      test('isFailure is true', () {
        const result = Failed<int>(NetworkFailure());
        expect(result.isFailure, isTrue);
      });

      test('dataOrNull returns null', () {
        const result = Failed<int>(NetworkFailure());
        expect(result.dataOrNull, isNull);
      });

      test('failureOrNull returns the failure', () {
        const failure = CacheFailure('cache miss');
        const result = Failed<int>(failure);
        expect(result.failureOrNull, failure);
      });

      test('equality works', () {
        const a = Failed<int>(NetworkFailure());
        const b = Failed<int>(NetworkFailure());
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('toString contains failure info', () {
        const result = Failed<int>(ServerFailure('bad', 404));
        expect(result.toString(), contains('Failed'));
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // when() pattern matching
    // ─────────────────────────────────────────────────────────────────────
    group('when()', () {
      test('calls success branch for Success', () {
        const Result<int> result = Success(42);
        final output = result.when(
          success: (data) => 'got:$data',
          failure: (f) => 'fail:${f.message}',
        );
        expect(output, 'got:42');
      });

      test('calls failure branch for Failed', () {
        const Result<int> result = Failed(ServerFailure('oops'));
        final output = result.when(
          success: (data) => 'got:$data',
          failure: (f) => 'fail:${f.message}',
        );
        expect(output, 'fail:oops');
      });
    });
  });
}
