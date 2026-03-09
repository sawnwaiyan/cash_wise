import 'package:flutter/material.dart';

import 'home_screen.dart';
// Placeholder imports — replace with real screens in later phases
// import 'history_screen.dart';
// import 'budget_screen.dart';
// import 'export_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Screens are kept alive with IndexedStack so state is preserved
  // when switching tabs. Replace placeholders as phases complete.
  final List<Widget> _screens = const [
    HomeScreen(),
    _PlaceholderScreen(label: 'History',  icon: Icons.history),
    _PlaceholderScreen(label: 'Budget',   icon: Icons.account_balance_wallet),
    _PlaceholderScreen(label: 'Export',   icon: Icons.picture_as_pdf),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf_rounded),
            label: 'Export',
          ),
        ],
      ),
    );
  }
}

// ── Placeholder ───────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderScreen({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '$label screen coming soon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}