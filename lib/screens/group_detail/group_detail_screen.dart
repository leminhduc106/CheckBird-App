import 'package:check_bird/screens/group_detail/widgets/group_chat_tab.dart';
import 'package:check_bird/screens/group_detail/widgets/group_info_tab.dart';
import 'package:check_bird/screens/group_detail/widgets/group_topic_tab.dart';
import 'package:check_bird/screens/group_detail/widgets/group_tasks_tab.dart';
import 'package:check_bird/screens/groups/models/groups_controller.dart';
import 'package:check_bird/screens/create_task/create_todo_screen.dart';
import 'package:flutter/material.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);
  static const routeName = '/chat-detail-screen';
  final Group group;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 4,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(group.groupName),
            actions: [
              IconButton(
                icon: const Icon(Icons.checklist_rounded),
                tooltip: 'Add task for this group',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateTodoScreen(
                        initialGroupId: group.groupId,
                      ),
                    ),
                  );
                },
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.library_books_rounded),
                  text: "Posts",
                ),
                Tab(
                  icon: Icon(Icons.checklist_rounded),
                  text: "Tasks",
                ),
                Tab(
                  icon: Icon(Icons.chat_bubble_rounded),
                  text: "Chat",
                ),
                Tab(
                  icon: Icon(Icons.info_rounded),
                  text: "Info",
                ),
              ],
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ),
          body: TabBarView(
            children: [
              GroupTopicTab(
                groupId: group.groupId,
              ),
              GroupTasksTab(
                groupId: group.groupId,
              ),
              GroupChatTab(
                groupId: group.groupId,
              ),
              GroupInfoTab(
                group: group,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
