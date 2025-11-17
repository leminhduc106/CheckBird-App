import 'package:check_bird/screens/group_detail/models/posts_controller.dart';
import 'package:flutter/material.dart';

class LikeButton extends StatefulWidget {
  const LikeButton(
      {super.key, required this.postId, required this.groupId});
  final String postId;
  final String groupId;

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  Widget buildLikeButton({required bool isLiked}){
    return TextButton.icon(
      onPressed: () async {
        await PostsController().likePost(groupId: widget.groupId, postId: widget.postId);
        setState(() {
        });
      },
      icon: Icon(
        isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
        size: 18,
        color: isLiked ? Colors.red : null,
      ),
      label: Text(
        "Like",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PostsController().isLiked(groupId: widget.groupId, postId: widget.postId),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting){
          return buildLikeButton(isLiked: false);
        }
        return buildLikeButton(isLiked: snapshot.data!);
      },
    );
  }
}

