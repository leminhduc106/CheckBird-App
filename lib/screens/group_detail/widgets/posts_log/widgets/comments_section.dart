import 'package:check_bird/screens/group_detail/models/comment.dart';
import 'package:check_bird/screens/group_detail/models/comments_controller.dart';
import 'package:check_bird/screens/group_detail/widgets/posts_log/widgets/comment_item.dart';
import 'package:flutter/material.dart';

class CommentsSection extends StatelessWidget {
  const CommentsSection({
    Key? key,
    required this.groupId,
    required this.postId,
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(key: key);

  final String groupId;
  final String postId;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comment>>(
      stream: CommentsController().commentsStream(groupId, postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading comments',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }

        final comments = snapshot.data ?? [];

        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'No comments yet. Be the first to comment!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          );
        }

        final widgets = comments
            .map((comment) => CommentItem(
                  comment: comment,
                  groupId: groupId,
                  postId: postId,
                ))
            .toList();

        if (shrinkWrap) {
          return Padding(
            padding: padding,
            child: Column(
              children: [
                for (int i = 0; i < widgets.length; i++) ...[
                  widgets[i],
                  if (i != widgets.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          );
        }

        return ListView.separated(
          padding: padding,
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) => widgets[index],
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: widgets.length,
        );
      },
    );
  }
}
