import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/visual_state_provider.dart';
import 'dashboard_tabs/home_tab.dart';
import 'dashboard_tabs/focus_forest_tab.dart';
// Keeping for now if needed, or maybe NotesTab placeholder
import 'settings_screen.dart'; // Using Settings as Profile tab
import 'notes_summary_screen.dart'; // Placeholder for Notes Tab

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Access the current theme data
    final theme = Theme.of(context);
    final visualState = context.watch<VisualStateProvider>();
    final appConfig = AppTheme.getConfig(visualState.theme);

    final List<Widget> screens = [
      const HomeTab(), 
      const FocusForestTab(),
      const NotesSummaryScreen(), // Replaces Chat
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor, 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          currentIndex: _currentIndex,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: appConfig.textSecondary,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forest_outlined),
              activeIcon: Icon(Icons.forest),
              label: 'Forest',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
