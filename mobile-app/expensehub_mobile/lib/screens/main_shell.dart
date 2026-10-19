import 'package:flutter/material.dart';

import '../models/expense.dart';
import 'dashboard_screen.dart';
import 'groups_screen.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';


class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  final PageController pageController = PageController();

  final GlobalKey<TransactionsScreenState> transactionsKey =
      GlobalKey<TransactionsScreenState>();

  void goToPage(int index) {
    setState(() {
      currentIndex = index;
    });

    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
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
            onTransactionSelected: openTransactionFromHome,
          ),
          const DashboardScreen(),
          const GroupsScreen(),
          TransactionsScreen(
            key: transactionsKey,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: goToPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}