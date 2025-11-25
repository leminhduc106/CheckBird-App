import 'package:check_bird/screens/groups/models/groups_controller.dart';
import 'package:check_bird/screens/groups/widgets/create_group/create_group_screen.dart';
import 'package:check_bird/screens/groups/widgets/discover_groups/discover_groups_screen.dart';
import 'package:check_bird/screens/groups/widgets/group_item.dart';
import 'package:check_bird/screens/groups/widgets/search_group/search_group_screen.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/widgets/focus/focus_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GroupScreen extends StatelessWidget {
  static const routeName = '/groups-screen';

  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon: const Icon(Icons.menu),
        ),
        title: Text(l10n?.groupTitle ?? 'Group'),
        actions: [
          // Only show buttons if user is authenticated
          if (Authentication.user != null) ...[
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DiscoverGroupsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.explore_rounded),
              tooltip: 'Discover Groups',
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.group_add),
              tooltip: 'Create Group',
            ),
          ],
          const FocusButton(),
        ],
      ),
      body: Center(
        child: Authentication.user == null
            ? Text(
                l10n?.loginRequired ?? 'You need to login to use this feature')
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
                                l10n?.searchGroupsPlaceholder ??
                                    'Search for more groups...',
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
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.explore_rounded,
                                  size: 80,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  l10n?.noGroupsMessage ??
                                      'Join some groups first!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Discover groups to connect with others',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DiscoverGroupsScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.explore_rounded),
                                  label: Text(
                                      l10n?.browseGroups ?? 'Browse Groups'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
