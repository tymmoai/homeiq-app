import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper class for widget testing
class WidgetTestHelper {
  /// Wrap widget with MaterialApp and ProviderScope
  static Widget wrapWithApp(
    Widget child, {
    List<Override>? overrides,
    ThemeData? theme,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(theme: theme, home: child),
    );
  }

  /// Wrap widget with Scaffold
  static Widget wrapWithScaffold(Widget child) {
    return Scaffold(body: child);
  }

  /// Find widget by type
  static Finder findByType<T>() {
    return find.byType(T);
  }

  /// Find widget by key
  static Finder findByTestKey(String key) {
    return find.byKey(Key(key));
  }

  /// Find text widget
  static Finder findText(String text) {
    return find.text(text);
  }

  /// Tap on widget
  static Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scroll until visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder,
    Finder scrollable, {
    double delta = 100,
  }) async {
    await tester.scrollUntilVisible(finder, delta, scrollable: scrollable);
    await tester.pumpAndSettle();
  }

  /// Drag widget
  static Future<void> drag(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  /// Wait for widget to appear
  static Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    throw TimeoutException('Widget not found within timeout', timeout);
  }

  /// Verify widget exists
  static void verifyExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify widget doesn't exist
  static void verifyNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verify text exists
  static void verifyText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verify multiple widgets exist
  static void verifyCount(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (${timeout.inSeconds}s)';
}
