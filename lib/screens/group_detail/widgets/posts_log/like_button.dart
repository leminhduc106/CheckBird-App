import 'package:check_bird/screens/group_detail/models/posts_controller.dart';
import 'package:flutter/material.dart';

class LikeButton extends StatefulWidget {
  const LikeButton({
    super.key,
    required this.postId,
    required this.groupId,
    this.initialLikeState = false,
  });
  final String postId;
  final String groupId;
  final bool initialLikeState;

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late bool _isLiked;
  bool _isLoading = false;
  bool _hasCheckedInitialState = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLikeState;
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    if (_hasCheckedInitialState) return;

    try {
      final isLiked = await PostsController().isLiked(
        groupId: widget.groupId,
        postId: widget.postId,
      );
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _hasCheckedInitialState = true;
        });
      }
    } catch (e) {
      // Handle error silently, keep current state
      if (mounted) {
        setState(() {
          _hasCheckedInitialState = true;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isLiked = !_isLiked; // Optimistic update
    });

    try {
      await PostsController().likePost(
        groupId: widget.groupId,
        postId: widget.postId,
      );
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _isLoading ? null : _toggleLike,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(
              _isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              size: 18,
              color: _isLiked ? Colors.red : null,
            ),
      label: Text(
        "Like",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _isLoading
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
              : null,
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
}
