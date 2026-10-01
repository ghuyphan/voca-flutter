// lib/ui/shell/main_shell.dart

import 'package:flutter/material.dart';
import '../explore/explore_screen.dart';
import '../study/study_deck_screen.dart';
import '../vocabulary/vocabulary_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExploreScreen(),
    StudyDeckScreen(),
    VocabularyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF6366F1).withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.explore, color: Color(0xFF6366F1)),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.style, color: Color(0xFF6366F1)),
            label: 'Study Deck',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.menu_book, color: Color(0xFF6366F1)),
            label: 'Vocabulary',
          ),
        ],
      ),
    );
  }
}
