import 'package:check_bird/screens/group_detail/models/post.dart';
import 'package:check_bird/screens/group_detail/models/posts_controller.dart';
import 'package:check_bird/screens/group_detail/widgets/posts_log/post_card.dart';
import 'package:check_bird/screens/group_detail/widgets/posts_log/widgets/comment_input.dart';
import 'package:check_bird/screens/group_detail/widgets/posts_log/widgets/comments_section.dart';
import 'package:flutter/material.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen(
      {Key? key, required this.groupId, required this.postId})
      : super(key: key);

  final String groupId;
  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  void _focusComposer() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    _commentFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post details'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<Post>(
                stream: PostsController()
                    .postStream(groupId: widget.groupId, postId: widget.postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: Text('Post unavailable'));
                  }

                  final post = snapshot.data!;
                  return ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: PostCard(
                          post: post,
                          groupId: widget.groupId,
                          postId: widget.postId,
                          onCommentPressed: _focusComposer,
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Comments',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      CommentsSection(
                        groupId: widget.groupId,
                        postId: widget.postId,
                        shrinkWrap: true,
                      ),
                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ),
            CommentInput(
              groupId: widget.groupId,
              postId: widget.postId,
              focusNode: _commentFocusNode,
            ),
          ],
        ),
      ),
    );
  }
}
