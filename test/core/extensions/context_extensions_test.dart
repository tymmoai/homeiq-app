import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeiq/core/extensions/context_extensions.dart';

void main() {
  group('ContextExtensions', () {
    // ─────────────────────────────────────────────────────────────────────
    // Theme shortcuts
    // ─────────────────────────────────────────────────────────────────────
    group('theme shortcuts', () {
      testWidgets('context.theme returns ThemeData', (tester) async {
        late ThemeData capturedTheme;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedTheme = context.theme;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(capturedTheme, isA<ThemeData>());
      });

      testWidgets('context.colorScheme returns ColorScheme', (tester) async {
        late ColorScheme capturedScheme;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedScheme = context.colorScheme;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(capturedScheme, isA<ColorScheme>());
      });

      testWidgets('context.textTheme returns TextTheme', (tester) async {
        late TextTheme capturedTextTheme;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedTextTheme = context.textTheme;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(capturedTextTheme, isA<TextTheme>());
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Media query shortcuts
    // ─────────────────────────────────────────────────────────────────────
    group('media query shortcuts', () {
      testWidgets('context.screenSize returns non-zero Size', (tester) async {
        late Size capturedSize;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedSize = context.screenSize;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(capturedSize.width, greaterThan(0));
        expect(capturedSize.height, greaterThan(0));
      });

      testWidgets('context.mediaQuery returns MediaQueryData',
          (tester) async {
        late MediaQueryData capturedMq;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedMq = context.mediaQuery;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(capturedMq, isA<MediaQueryData>());
      });

      testWidgets('context.viewPadding returns EdgeInsets', (tester) async {
        late EdgeInsets capturedPadding;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedPadding = context.viewPadding;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(capturedPadding, isA<EdgeInsets>());
      });

      testWidgets('context.platformBrightness returns Brightness',
          (tester) async {
        late Brightness capturedBrightness;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedBrightness = context.platformBrightness;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(capturedBrightness, isA<Brightness>());
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Snackbar helpers
    // ─────────────────────────────────────────────────────────────────────
    group('snackbar helpers', () {
      testWidgets('showSnackBar displays a snackbar with message',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => context.showSnackBar('Hello Test'),
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Hello Test'), findsOneWidget);
      });

      testWidgets('showErrorSnackBar displays an error snackbar',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => context.showErrorSnackBar('Error!'),
                    child: const Text('Error'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Error'));
        await tester.pumpAndSettle();

        expect(find.text('Error!'), findsOneWidget);
      });

      testWidgets('showSuccessSnackBar displays a success snackbar',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => context.showSuccessSnackBar('Done!'),
                    child: const Text('Success'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Success'));
        await tester.pumpAndSettle();

        expect(find.text('Done!'), findsOneWidget);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Navigation helpers
    // ─────────────────────────────────────────────────────────────────────
    group('navigation helpers', () {
      testWidgets('context.canPop returns false on root', (tester) async {
        late bool canPop;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                canPop = context.canPop;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(canPop, isFalse);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Focus helpers
    // ─────────────────────────────────────────────────────────────────────
    group('focus helpers', () {
      testWidgets('dismissKeyboard does not throw', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => context.dismissKeyboard(),
                    child: const Text('Dismiss'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();
        // No exception means success
      });
    });
  });
}
