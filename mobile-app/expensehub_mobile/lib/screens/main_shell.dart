import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'dashboard_screen.dart';
import 'groups_screen.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import '../widgets/eh_center_nav_bar.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  final PageController pageController = PageController();
  final GlobalKey<HomeScreenState> homeKey = GlobalKey<HomeScreenState>();

  final GlobalKey<TransactionsScreenState> transactionsKey =
      GlobalKey<TransactionsScreenState>();

  final GlobalKey<DashboardScreenState> dashboardKey =
      GlobalKey<DashboardScreenState>();

  void goToPage(int index) {
    setState(() {
      currentIndex = index;
    });

    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    if (index == 1) {
      dashboardKey.currentState?.refreshAll();
    }
  }

  void openTransactionFromHome(Expense expense) {
    goToPage(3);

    Future.delayed(const Duration(milliseconds: 300), () {
      transactionsKey.currentState?.openTransaction(expense);
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        children: [
          HomeScreen(
            key: homeKey,
            onTransactionSelected: openTransactionFromHome,
            onOpenGroups: () => goToPage(2),
            onOpenTransactions: () => goToPage(3),
          ),
          DashboardScreen(key: dashboardKey),
          const GroupsScreen(),
          TransactionsScreen(key: transactionsKey, initialFilter: ''),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: EhBottomNavBar(
        currentIndex: currentIndex,
        onTap: goToPage,
        onProfilePressed: () => goToPage(4),
      ),
    );
  }
}