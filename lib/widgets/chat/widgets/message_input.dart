import 'package:check_bird/models/chat/chat_screen_arguments.dart';
import 'package:check_bird/widgets/chat/models/messages_controller.dart';
import 'package:check_bird/widgets/chat/models/media_type.dart';
import 'package:check_bird/widgets/chat/widgets/preview_image_screen.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class MessageInput extends StatefulWidget {
  const MessageInput(
      {Key? key,
      required this.chatScreenArguments,
      required this.messagesLogController,
      required this.replyTargetNotifier})
      : super(key: key);
  final ChatScreenArguments chatScreenArguments;
  final ScrollController messagesLogController;
  final ValueNotifier<Message?> replyTargetNotifier;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  var _enteredMessages = "";
  var focused = false;
  Message? get _replyTarget => widget.replyTargetNotifier.value;

  Future<File?> _cropImage(File image) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 70,
      maxWidth: 700,
      maxHeight: 700,
    );

    if (croppedFile != null) {
      image = File(croppedFile.path);
      return image;
    }
    return null;
  }

  void _pickImages(ImageSource imageSource) async {
    var picker = ImagePicker();
    XFile? pickedImage =
        await picker.pickImage(source: imageSource, imageQuality: 50);
    if (pickedImage == null) return;
    File img = File(pickedImage.path);
    File? cropped = await _cropImage(img);
    if (cropped == null) return;

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewImageScreen(
            imagePath: cropped.path,
            groupId: widget.chatScreenArguments.groupId,
            topicId: widget.chatScreenArguments.topicId,
            chatType: widget.chatScreenArguments.chatType,
          ),
        ),
      );
    }
  }

  void _sendChat(String text) async {
    await MessagesController().sendChat(
      mediaType: MediaType.text,
      data: text,
      topicId: widget.chatScreenArguments.topicId,
      groupId: widget.chatScreenArguments.groupId,
      chatType: widget.chatScreenArguments.chatType,
      replyTo: _replyTarget,
    );
    await widget.messagesLogController.animateTo(
      widget.messagesLogController.position.minScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
    widget.replyTargetNotifier.value = null;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        if (_focusNode.hasFocus) {
          focused = true;
        } else {
          focused = false;
        }
      });
    });
    // Listen for reply target changes to show/hide quote immediately.
    widget.replyTargetNotifier.addListener(_onReplyTargetChanged);
  }

  void _onReplyTargetChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _focusNode.dispose();
    widget.replyTargetNotifier.removeListener(_onReplyTargetChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          if (_replyTarget != null)
            _ChatReplyQuote(
              author: _replyTarget!.userName,
              mediaType: _replyTarget!.mediaType,
              snippet: _replyTarget!.mediaType == MediaType.text
                  ? _replyTarget!.data
                  : '[image]',
              onClose: () => widget.replyTargetNotifier.value = null,
            ),
          Row(
            children: [
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
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _controller,
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                          minLines: 1,
                          onChanged: (text) {
                            setState(() {
                              _enteredMessages = text;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      if (!focused) ...[
                        IconButton(
                          onPressed: () {
                            _pickImages(ImageSource.camera);
                          },
                          icon: Icon(
                            Icons.camera_alt_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _pickImages(ImageSource.gallery);
                          },
                          icon: Icon(
                            Icons.image_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: (_enteredMessages.trim().isNotEmpty && focused)
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: focused
                      ? _enteredMessages.trim().isEmpty
                          ? null
                          : () {
                              _sendChat(_enteredMessages.trim());
                              _focusNode.unfocus();
                              _controller.clear();
                              setState(() {
                                _enteredMessages = "";
                              });
                            }
                      : () {
                          _sendChat('👍');
                          _focusNode.unfocus();
                          _controller.clear();
                          setState(() {
                            _enteredMessages = "";
                          });
                        },
                  icon: Icon(
                    focused ? Icons.send_rounded : Icons.thumb_up_rounded,
                    color: (_enteredMessages.trim().isNotEmpty && focused)
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatReplyQuote extends StatelessWidget {
  const _ChatReplyQuote({
    Key? key,
    required this.author,
    required this.snippet,
    required this.mediaType,
    required this.onClose,
  }) : super(key: key);

  final String author;
  final String snippet;
  final MediaType mediaType;
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
