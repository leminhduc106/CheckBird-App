import 'package:check_bird/screens/group_detail/models/post.dart';
import 'package:check_bird/screens/group_detail/models/posts_controller.dart';
import 'package:check_bird/screens/group_detail/widgets/posts_log/post_card.dart';
import 'package:check_bird/screens/group_detail/widgets/posts_log/post_detail_screen.dart';
import 'package:flutter/material.dart';

class PostsLog extends StatefulWidget {
  const PostsLog({super.key, required this.groupId});
  final String groupId;

  @override
  State<PostsLog> createState() => _PostsLogState();
}

class _PostsLogState extends State<PostsLog> {
  final ScrollController _scrollController = ScrollController();

  Future<void> _refreshPosts() async {
    // The StreamBuilder will automatically refresh when the stream updates
    // No need to force a rebuild with setState
    return;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: StreamBuilder<List<Post>>(
        stream: PostsController().postsStream(widget.groupId),
        builder: (BuildContext context, AsyncSnapshot<List<Post>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("Error loading posts"),
                  ),
                ),
              ],
            );
          }

          final posts = snapshot.data;
          if (posts == null || posts.isEmpty) {
            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("There are no posts yet"),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            cacheExtent: 1000.0,
            itemCount: posts.length,
            itemBuilder: (BuildContext context, int index) {
              return OptimizedPostItem(
                post: posts[index],
                groupId: widget.groupId,
                key: ValueKey(posts[index].id!),
              );
            },
          );
        },
      ),
    );
  }
}

// Optimized post item that doesn't create individual streams
class OptimizedPostItem extends StatelessWidget {
  const OptimizedPostItem({
    super.key,
    required this.post,
    required this.groupId,
  });

  final Post post;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(
                groupId: groupId,
                postId: post.id!,
              ),
            ),
          );
        },
        child: PostCard(
          post: post,
          groupId: groupId,
          postId: post.id!,
          onCommentPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  groupId: groupId,
                  postId: post.id!,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
