import 'package:check_bird/screens/group_detail/models/comment.dart';
import 'package:check_bird/screens/group_detail/models/comments_controller.dart';
import 'package:check_bird/widgets/chat/widgets/image_view_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentItem extends StatefulWidget {
  const CommentItem({
    Key? key,
    required this.comment,
    required this.groupId,
    required this.postId,
    this.onReply,
    this.indent = 0,
    this.isReply = false,
  }) : super(key: key);

  final Comment comment;
  final String groupId;
  final String postId;
  final void Function(Comment comment)? onReply;
  final double indent; // for replies indentation
  final bool isReply;

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.comment.likeCount;
    if (!widget.comment.isLegacy) {
      _checkIfLiked();
    }
  }

  Future<void> _checkIfLiked() async {
    final isLiked = await CommentsController().isCommentLiked(
      groupId: widget.groupId,
      postId: widget.postId,
      commentId: widget.comment.id,
    );
    if (mounted) {
      setState(() {
        _isLiked = isLiked;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (widget.comment.isLegacy) return;
    await CommentsController().likeComment(
      groupId: widget.groupId,
      postId: widget.postId,
      commentId: widget.comment.id,
    );
    setState(() {
      if (_isLiked) {
        _likeCount--;
      } else {
        _likeCount++;
      }
      _isLiked = !_isLiked;
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat.yMMMd().format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final bool isReply = widget.isReply;
    final double indent = widget.indent;
    final double leftPadding = 16 + indent;
    final double rightPadding = 16;
    final double avatarRadius = isReply ? 14 : 16;
    final Color bubbleColor = isReply
        ? Theme.of(context).colorScheme.surface.withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.8)
        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);

    return Container(
      padding: EdgeInsets.fromLTRB(
          leftPadding, isReply ? 6 : 8, rightPadding, isReply ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundImage: comment.userAvatarUrl.isNotEmpty
                  ? NetworkImage(comment.userAvatarUrl)
                  : null,
              child: comment.userAvatarUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      size: avatarRadius,
                      color: Theme.of(context).colorScheme.onSurface,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment Bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Name
                      Text(
                        comment.userName,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      // Comment Text
                      if (comment.text.isNotEmpty)
                        Text(
                          comment.text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      if (comment.imageUrl != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ImageViewChatScreen(
                                  imageUrl: comment.imageUrl!,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              comment.imageUrl!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Comment Actions
                Row(
                  children: [
                    Text(
                      _formatTime(comment.createdAt.toDate()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(width: 16),
                    // Like Button / Legacy indicator
                    Opacity(
                      opacity: comment.isLegacy ? 0.4 : 1,
                      child: InkWell(
                        onTap: comment.isLegacy ? null : _toggleLike,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color: comment.isLegacy
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6)
                                    : _isLiked
                                        ? Colors.red
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                              ),
                              if (_likeCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  _likeCount.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!comment.isLegacy && comment.parentId == null)
                      InkWell(
                        onTap: widget.onReply == null
                            ? null
                            : () => widget.onReply!(widget.comment),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            'Reply',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
