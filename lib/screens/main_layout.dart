import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_background.dart';
import '../screens/stats_screen.dart';
import 'home_page.dart';
import 'gioca_screen.dart';
import 'profilo_screen.dart';

/// Layout principale che mantiene la bottom navigation sempre visibile
class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<MainTab> _tabs = [
    MainTab(
      label: 'Home',
      icon: Icons.home,
      page: const HomePage(),
    ),
    MainTab(
      label: 'Stats',
      icon: Icons.bar_chart,
      page: const StatsScreen(),
    ),
    MainTab(
      label: 'Gioca',
      icon: Icons.sports_soccer,
      page: const GiocaScreen(),
    ),
    MainTab(
      label: 'Profilo',
      icon: Icons.person,
      page: const ProfiloScreen(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GradientBackground(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: _tabs.map((tab) => tab.page).toList(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: _tabs.map((tab) => BottomNavigationBarItem(
          icon: Icon(tab.icon),
          label: tab.label,
        )).toList(),
        onTap: _onTabSelected,
      ),
    );
  }
}

/// Modello per rappresentare una tab
class MainTab {
  final String label;
  final IconData icon;
  final Widget page;

  MainTab({
    required this.label,
    required this.icon,
    required this.page,
  });
}