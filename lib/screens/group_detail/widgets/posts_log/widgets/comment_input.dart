import 'dart:io';
import 'package:check_bird/screens/group_detail/models/comments_controller.dart';
import 'package:check_bird/screens/group_detail/models/comment.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CommentInput extends StatefulWidget {
  const CommentInput({
    Key? key,
    required this.groupId,
    required this.postId,
    this.controller,
    this.focusNode,
    this.replyTargetNotifier,
  }) : super(key: key);

  final String groupId;
  final String postId;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueNotifier<Comment?>? replyTargetNotifier;

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  late final bool _ownsFocusNode;
  bool _isSubmitting = false;
  File? _attachedImage;
  final ImagePicker _picker = ImagePicker();
  Comment? get _replyTarget => widget.replyTargetNotifier?.value;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    // Rebuild when reply target changes so quote block appears/disappears.
    if (widget.replyTargetNotifier != null) {
      widget.replyTargetNotifier!.addListener(_onReplyTargetChanged);
    }
  }

  void _onReplyTargetChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    widget.replyTargetNotifier?.removeListener(_onReplyTargetChanged);
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isSubmitting) return;
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _attachedImage = File(picked.path);
        });
      }
    } catch (e) {
      // Ignore for now or surface snack bar
    }
  }

  void _removeImage() {
    setState(() {
      _attachedImage = null;
    });
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    final hasImage = _attachedImage != null;
    if ((text.isEmpty && !hasImage) || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await CommentsController().addComment(
        groupId: widget.groupId,
        postId: widget.postId,
        text: text,
        imageFile: _attachedImage,
        parentCommentId: _replyTarget?.id,
        replyToUserName: _replyTarget?.userName,
        replyToText: _replyTarget?.text.isNotEmpty == true
            ? _replyTarget!.text
            : (_replyTarget?.imageUrl != null ? '[image]' : ''),
      );
      _controller.clear();
      _attachedImage = null;
      _focusNode.unfocus();
      widget.replyTargetNotifier?.value = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyTargetNotifier != null && _replyTarget != null)
            _ReplyQuote(
              author: _replyTarget!.userName,
              snippet: _replyTarget!.text.isNotEmpty
                  ? _replyTarget!.text
                  : (_replyTarget!.imageUrl != null ? '[image]' : ''),
              onClose: () => widget.replyTargetNotifier!.value = null,
            ),
          if (_attachedImage != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _attachedImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: _removeImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: _isSubmitting ? null : _pickImage,
                icon: Icon(
                  Icons.image_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Add image',
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({
    Key? key,
    required this.author,
    required this.snippet,
    required this.onClose,
  }) : super(key: key);

  final String author;
  final String snippet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final truncated =
        snippet.length > 90 ? '${snippet.substring(0, 90)}…' : snippet;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to $author',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  truncated,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
