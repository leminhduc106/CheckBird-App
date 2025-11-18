import 'package:check_bird/screens/groups/models/groups_controller.dart';
import 'package:check_bird/screens/groups/widgets/create_group/create_group_screen.dart';
import 'package:check_bird/screens/groups/widgets/group_item.dart';
import 'package:check_bird/screens/groups/widgets/search_group/search_group_screen.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/widgets/focus/focus_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupScreen extends StatelessWidget {
  static const routeName = '/groups-screen';

  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon: const Icon(Icons.menu),
        ),
        title: const Text("Group"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen()));
              },
              icon: const Icon(Icons.group_add)),
          const FocusButton(),
        ],
      ),
      body: Center(
        child: Authentication.user == null
            ? const Text("You need to login to use this feature")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const SearchGroupScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Search for more groups...",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: StreamBuilder(
                      stream: GroupsController().usersGroupsStream(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                              snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final data = snapshot.data?.docs;
                        if (data == null || data.isEmpty) {
                          return const Center(
                            child: Text(
                                "Join some groups first! Or create one..."),
                          );
                        }
                        return ListView.separated(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            return GroupItem(
                              groupId: data[index].id,
                              size: size,
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
