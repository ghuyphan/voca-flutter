import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/services/toast_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ToastService shows minimal floating SnackBar with message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: ToastService.messengerKey,
        theme: VocaTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ToastService.success(context, 'Word saved!'),
              child: const Text('Show Toast'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Toast'));
    await tester.pump(); // Start SnackBar animation

    expect(find.text('Word saved!'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
  });

  testWidgets('ToastService renders action button and executes callback', (tester) async {
    bool actionClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: ToastService.messengerKey,
        theme: VocaTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ToastService.show(
                context,
                'Card removed',
                actionLabel: 'Undo',
                onAction: () => actionClicked = true,
              ),
              child: const Text('Remove Card'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Remove Card'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Card removed'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsOneWidget);

    final SnackBarAction actionWidget = tester.widget(find.byType(SnackBarAction));
    actionWidget.onPressed();
    expect(actionClicked, isTrue);

    expect(actionClicked, isTrue);
  });
}
