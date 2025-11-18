import 'package:check_bird/screens/group_detail/group_detail_screen.dart';
import 'package:check_bird/screens/groups/models/groups_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupItem extends StatelessWidget {
  const GroupItem({super.key, required this.groupId, required this.size});
  final String groupId;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: GroupsController().groupStream(groupId: groupId),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data()!;
        // TODO: put data in groups class
        final group = Group(
          groupName: data['groupName'],
          groupId: groupId,
          numOfMember: data['numOfMember'],
          createdAt: data['createdAt'],
          numOfTasks: data['numOfTasks'],
          groupDescription: data['groupDescription'],
          groupsAvtUrl: data['groupsAvtUrl'],
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            elevation: 2,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => GroupDetailScreen(group: group)));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        backgroundImage: group.groupsAvtUrl != null
                            ? Image.network(group.groupsAvtUrl!).image
                            : null,
                        child: group.groupsAvtUrl == null
                            ? Icon(Icons.group,
                                color: Theme.of(context).colorScheme.onSurface)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  group.groupName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              FutureBuilder(
                                future: GroupsController()
                                    .isJoined(groupId: groupId),
                                builder: (context, snapshot) {
                                  final joined = snapshot.data == true;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: joined
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: joined
                                          ? null
                                          : Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withOpacity(0.4),
                                            ),
                                    ),
                                    child: Icon(
                                      joined
                                          ? Icons.check_rounded
                                          : Icons.add_rounded,
                                      size: 18,
                                      color: joined
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (group.groupDescription != null &&
                              group.groupDescription!.isNotEmpty)
                            Text(
                              group.groupDescription!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _StatChip(
                                icon: Icons.group,
                                label: '${group.numOfMember}',
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                icon: Icons.checklist_rtl,
                                label: '${group.numOfTasks} task(s)',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
