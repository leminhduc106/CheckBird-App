import 'package:check_bird/screens/group_detail/models/post.dart';
import 'package:check_bird/screens/group_detail/models/posts_controller.dart';
import 'package:check_bird/screens/group_detail/widgets/posts_log/post_card.dart';
import 'package:check_bird/screens/group_detail/widgets/posts_log/post_detail_screen.dart';
import 'package:flutter/material.dart';

class PostItem extends StatelessWidget {
  const PostItem({Key? key, required this.postId, required this.groupId})
      : super(key: key);

  final String postId;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return StreamBuilder<Post>(
        stream: PostsController().postStream(groupId: groupId, postId: postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Card(
                child: SizedBox(
                  height: 400,
                  width: constraints.maxWidth * 0.9,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }

          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final post = snapshot.data!;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: PostCard(
              post: post,
              groupId: groupId,
              postId: postId,
              onCommentPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(
                      groupId: groupId,
                      postId: postId,
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }
}
