import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../calendar/calendar_view.dart';
import '../statistics/statistics_view.dart';
import '../analysis/setup_analysis_view.dart';
import '../settings/settings_view.dart';
import 'dashboard_view.dart';
import '../../providers/account_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    DashboardView(),
    CalendarView(),
    StatisticsView(),
    SetupAnalysisView(),
    SettingsView(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today_rounded),
      label: 'Kalender',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics_rounded),
      label: 'Statistik',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights_rounded),
      label: 'Analisis',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Pengaturan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedAccount = ref.watch(selectedAccountProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 768;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  Icons.query_stats_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedAccount != null ? 'JurnalTrade (${selectedAccount.name})' : 'JurnalTrade',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [],
          ),
          body: Row(
            children: [
              // Show Left Navigation Rail for Desktop/Tablet Viewports
              if (isWide)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: NavigationRail(
                    selectedIndex: _currentIndex,
                    backgroundColor: AppColors.background,
                    labelType: NavigationRailLabelType.all,
                    selectedIconTheme: const IconThemeData(color: AppColors.primary),
                    unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
                    selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    unselectedLabelTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    destinations: _destinations.map((dest) {
                      return NavigationRailDestination(
                        icon: dest.icon,
                        selectedIcon: dest.selectedIcon,
                        label: Text(dest.label),
                      );
                    }).toList(),
                    onDestinationSelected: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                ),
              
              // View Content
              Expanded(
                child: _views[_currentIndex],
              ),
            ],
          ),
          
          // Show Bottom Navigation Bar for Mobile Viewports
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  destinations: _destinations,
                  backgroundColor: AppColors.surface,
                  indicatorColor: AppColors.primary.withOpacity(0.15),
                ),
        );
      },
    );
  }
}
