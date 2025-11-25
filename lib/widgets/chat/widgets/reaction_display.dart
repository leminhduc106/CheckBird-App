import 'package:check_bird/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReactionDisplay extends StatelessWidget {
  const ReactionDisplay({
    super.key,
    required this.reactions,
    required this.isMe,
    required this.onReactionTap,
  });

  final Map<String, List<String>> reactions;
  final bool isMe;
  final Function(String emoji, List<String> userIds) onReactionTap;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Sort reactions by count (most popular first)
    final sortedReactions = reactions.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Container(
      margin: EdgeInsets.only(
        top: 4,
        left: isMe ? 0 : 50,
        right: isMe ? 8 : 0,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
        children: sortedReactions.map((entry) {
          final emoji = entry.key;
          final userIds = entry.value;
          final count = userIds.length;
          final currentUserId = Authentication.user?.uid;
          final hasCurrentUserReacted =
              currentUserId != null && userIds.contains(currentUserId);

          return _buildReactionChip(
            context,
            emoji,
            count,
            hasCurrentUserReacted,
            () => onReactionTap(emoji, userIds),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReactionChip(
    BuildContext context,
    String emoji,
    int count,
    bool hasCurrentUserReacted,
    VoidCallback onTap,
  ) {
    return Material(
      color: hasCurrentUserReacted
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      elevation: hasCurrentUserReacted ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: hasCurrentUserReacted
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              if (count > 1) ...[
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasCurrentUserReacted
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog to show who reacted
class ReactionDetailsDialog extends StatelessWidget {
  const ReactionDetailsDialog({
    super.key,
    required this.emoji,
    required this.userNames,
  });

  final String emoji;
  final List<String> userNames;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.reactions,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: userNames.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  userNames[index][0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(userNames[index]),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
