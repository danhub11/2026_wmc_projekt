import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/settings_manager.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IronLogApp());
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class IronLogApp extends StatelessWidget {
  const IronLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsManager,
      builder: (context, child) {
        return MaterialApp(
          title: 'IronLog',
          scaffoldMessengerKey: scaffoldMessengerKey,
          theme: AppConstants.getTheme(
            primaryColor:
                AppConstants.themeColors[settingsManager.themeColorIndex],
            isDarkMode: settingsManager.isDarkMode,
          ),
          home: const MainNavigation(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
    WorkoutScreen(onRestTimerDone: _onRestTimerDone),
    const ProgressScreen(),
    const SettingsScreen(),
  ];

  void _onRestTimerDone() {
    if (_currentIndex != 2) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.timer, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Satzpause abgelaufen – weiter gehts!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor:
              AppConstants.themeColors[settingsManager.themeColorIndex],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Zum Workout',
            textColor: Colors.white,
            onPressed: () => setState(() => _currentIndex = 2),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
