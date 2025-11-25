import 'package:check_bird/screens/home/widgets/group_list.dart';
import 'package:check_bird/screens/home/widgets/list_todo_today.dart';
import 'package:check_bird/screens/home/widgets/quotes.dart';
import 'package:check_bird/screens/task/widgets/show_date.dart';
import 'package:check_bird/services/notification.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/widgets/focus/focus_widget.dart';
import 'package:check_bird/widgets/rewards/daily_reward_dialog.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home-screen';

  const HomeScreen({super.key, this.changeTab});
  final void Function(int index)? changeTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService().requestPermission();
    // Check for daily login rewards
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DailyRewardDialog.checkAndShow(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu_rounded),
          ),
          centerTitle: true,
          title: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/checkbird-logo.png',
              height: 32,
            ),
          ),
          actions: const [
            FocusButton(),
            SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QuotesAPI(),
              if (Authentication.user != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Groups",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: size.height * 0.12,
                  child: GroupList(changeTab: widget.changeTab!),
                ),
              ],
              const ShowDate(text: "Today's Tasks"),
              ToDoListToday(today: DateTime.now()),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ));
  }
}
