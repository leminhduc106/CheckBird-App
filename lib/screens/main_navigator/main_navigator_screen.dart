import 'package:animations/animations.dart';
import 'package:check_bird/screens/create_task/create_todo_screen.dart';
import 'package:check_bird/screens/groups/groups_screen.dart';
import 'package:check_bird/screens/home/home_screen.dart';
import 'package:check_bird/screens/shop/shop_screen.dart';
import 'package:check_bird/screens/task/task_screen.dart';
import 'package:check_bird/widgets/app_drawer.dart';
import 'package:flutter/material.dart';

class MainNavigatorScreen extends StatefulWidget {
  static const routeName = '/main-navigation-screen';

  const MainNavigatorScreen({super.key});

  @override
  State<MainNavigatorScreen> createState() => _MainNavigatorScreenState();
}

class _MainNavigatorScreenState extends State<MainNavigatorScreen>
    with TickerProviderStateMixin {
  late List<Widget> _screen;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _screen = [
      HomeScreen(changeTab: changeTag),
      const TaskScreen(),
      const GroupScreen(),
      const ShopScreen(),
    ];
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void changeTag(int index) {
    setState(() {
      _selectedScreenIndex = index;
    });
  }

  int _selectedScreenIndex = 0;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist_rounded),
      label: 'Tasks',
    ),
    const NavigationDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups_rounded),
      label: 'Groups',
    ),
    const NavigationDestination(
      icon: Icon(Icons.shopping_bag_outlined),
      selectedIcon: Icon(Icons.shopping_bag_rounded),
      label: 'Shop',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: PageTransitionSwitcher(
        transitionBuilder: (Widget child, Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation) {
          return FadeTransition(
            opacity: primaryAnimation,
            child: child,
          );
        },
        child: _screen[_selectedScreenIndex],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          heroTag: "mainFAB",
          backgroundColor: const Color(0xFFE3F2FD),
          foregroundColor: const Color(0xFF1976D2),
          elevation: 3,
          child: const Icon(
            Icons.add_task,
            size: 28,
          ),
          onPressed: () {
            _fabAnimationController.forward().then((_) {
              _fabAnimationController.reverse();
            });
            Navigator.of(context).push(
              PageRouteBuilder(
                  pageBuilder: (BuildContext context, Animation<double> animation,
                          Animation<double> secondaryAnimation) =>
                      const CreateTodoScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    final begin = Offset(0.0, 1.0);
                    final end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  }),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedScreenIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedScreenIndex = index;
          });
        },
        destinations: _destinations,
        animationDuration: const Duration(milliseconds: 300),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: 0,
      ),
    );
  }
}
