import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Native Material NavigationBar with 5 items including center create button', (tester) async {
    int currentIndex = 0;
    bool isMoreSheetOpen = false;
    bool newVideoOpened = false;

    int getNavSelectedIndex() {
      if (isMoreSheetOpen) return 4;
      switch (currentIndex) {
        case 0:
          return 0; // Watch
        case 1:
          return 1; // Review
        case 2:
          return 3; // Vocab (index 3 in nav bar)
        case 3: // Playlists
        case 4: // History
          return 4; // More (index 4 in nav bar)
        default:
          return 0;
      }
    }

    Widget buildTestBar(StateSetter setState) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(child: Text('Current Screen: $currentIndex')),
          bottomNavigationBar: NavigationBar(
            selectedIndex: getNavSelectedIndex(),
            onDestinationSelected: (navIndex) {
              if (navIndex == 0) {
                setState(() => currentIndex = 0);
              } else if (navIndex == 1) {
                setState(() => currentIndex = 1);
              } else if (navIndex == 2) {
                newVideoOpened = true;
              } else if (navIndex == 3) {
                setState(() => currentIndex = 2); // Vocab is screen 2
              } else if (navIndex == 4) {
                setState(() => isMoreSheetOpen = true);
              }
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.play_circle_outline),
                selectedIcon: Icon(Icons.play_circle),
                label: 'Watch',
              ),
              const NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Review',
              ),
              // Center create button
              Center(
                child: GestureDetector(
                  key: const Key('bottom-nav__item--create'),
                  onTap: () => newVideoOpened = true,
                  child: Container(
                    width: 48,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Vocab',
              ),
              const NavigationDestination(
                icon: Icon(Icons.more_horiz),
                label: 'More',
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => buildTestBar(setState),
      ),
    );

    // Initial state: Watch selected (navIndex 0)
    expect(find.text('Current Screen: 0'), findsOneWidget);
    expect(find.text('Watch'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Vocab'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.byKey(const Key('bottom-nav__item--create')), findsOneWidget);

    // Tap Review
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Current Screen: 1'), findsOneWidget);

    // Tap Vocab
    await tester.tap(find.text('Vocab'));
    await tester.pumpAndSettle();
    expect(find.text('Current Screen: 2'), findsOneWidget);

    // Tap Create button
    await tester.tap(find.byKey(const Key('bottom-nav__item--create')));
    await tester.pumpAndSettle();
    expect(newVideoOpened, isTrue);
    expect(find.text('Current Screen: 2'), findsOneWidget); // still on Vocab

    // Tap More
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(isMoreSheetOpen, isTrue);
  });
}
