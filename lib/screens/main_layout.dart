import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../shared_providers.dart' show mainTabIndexProvider;
import '../widgets/gradient_background.dart';
import 'home_page.dart';
import 'stats_screen.dart';
import 'gioca_screen.dart';
import 'profilo_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  late final PageController _pageController;

  static const _tabs = <_TabDef>[
    _TabDef(label: 'Home', icon: Icons.home_rounded),
    _TabDef(label: 'Stats', icon: Icons.bar_chart_rounded),
    _TabDef(label: 'Gioca', icon: Icons.sports_soccer_rounded),
    _TabDef(label: 'Profilo', icon: Icons.person_rounded),
  ];

  static const _pages = <Widget>[
    HomePage(),
    StatsScreen(),
    GiocaScreen(),
    ProfiloScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    final current = ref.read(mainTabIndexProvider);
    if (index == current) return;
    ref.read(mainTabIndexProvider.notifier).state = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to external tab changes (e.g. from Home's GIOCA ORA button)
    ref.listen<int>(mainTabIndexProvider, (prev, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final currentIndex = ref.watch(mainTabIndexProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GradientBackground(
        useSafeArea: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (i) =>
              ref.read(mainTabIndexProvider.notifier).state = i,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(currentIndex),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final selected = i == currentIndex;
              return Expanded(
                child: _NavItem(
                  icon: tab.icon,
                  label: tab.label,
                  selected: selected,
                  onTap: () => _onTabSelected(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryRed.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppTheme.primaryRed
                  : Colors.white.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppTheme.primaryRed
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  const _TabDef({required this.label, required this.icon});
}
