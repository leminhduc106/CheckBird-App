import 'package:check_bird/screens/group_detail/models/comment.dart';
import 'package:check_bird/screens/group_detail/models/comments_controller.dart';
import 'package:check_bird/screens/group_detail/widgets/posts_log/widgets/comment_item.dart';
import 'package:flutter/material.dart';

class CommentsSection extends StatefulWidget {
  const CommentsSection({
    Key? key,
    required this.groupId,
    required this.postId,
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    required this.replyTargetNotifier,
  }) : super(key: key);

  final String groupId;
  final String postId;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final ValueNotifier<Comment?> replyTargetNotifier;

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  void _onReply(Comment c) {
    widget.replyTargetNotifier.value = c;
    // Scroll to bottom? parent controls focus
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comment>>(
      stream:
          CommentsController().commentsStream(widget.groupId, widget.postId),
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

        // Group replies by parentId
        final Map<String, List<Comment>> repliesByParent = {};
        final List<Comment> topLevel = [];
        for (final c in comments) {
          if (c.parentId == null) {
            topLevel.add(c);
          } else {
            repliesByParent.putIfAbsent(c.parentId!, () => []).add(c);
          }
        }
        // Build thread widgets so replies stay visually grouped.
        final List<Widget> threads = [];
        for (final parent in topLevel) {
          final replies = repliesByParent[parent.id] ?? const [];
          threads.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommentItem(
                  comment: parent,
                  groupId: widget.groupId,
                  postId: widget.postId,
                  onReply: _onReply,
                ),
                if (replies.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (int i = 0; i < replies.length; i++) ...[
                    CommentItem(
                      comment: replies[i],
                      groupId: widget.groupId,
                      postId: widget.postId,
                      onReply: _onReply,
                      indent: 40,
                      isReply: true,
                    ),
                    if (i != replies.length - 1) const SizedBox(height: 6),
                  ],
                ],
              ],
            ),
          );
        }

        if (widget.shrinkWrap) {
          return Padding(
            padding: widget.padding,
            child: Column(
              children: [
                for (int i = 0; i < threads.length; i++) ...[
                  threads[i],
                  if (i != threads.length - 1) ...[
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          );
        }

        return ListView.separated(
          padding: widget.padding,
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) => threads[index],
          separatorBuilder: (_, __) => Column(
            children: [
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              const SizedBox(height: 12),
            ],
          ),
          itemCount: threads.length,
        );
      },
    );
  }
}
