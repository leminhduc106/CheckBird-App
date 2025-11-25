import 'package:check_bird/models/chat/chat_type.dart';
import 'package:check_bird/widgets/chat/models/media_type.dart';
import 'package:check_bird/widgets/chat/models/messages_controller.dart';
import 'package:check_bird/widgets/chat/widgets/image_view_chat_screen.dart';
import 'package:check_bird/widgets/chat/widgets/reaction_display.dart';
import 'package:check_bird/widgets/chat/widgets/reaction_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.messageId,
    required this.message,
    required this.photoUrl,
    required this.isMe,
    required this.senderName,
    required this.sendAt,
    required this.mediaType,
    required this.chatType,
    required this.groupId,
    this.topicId,
    this.replyToUserName,
    this.replyToText,
    this.replyToMediaType,
    this.onReply,
    this.reactions = const {},
  });

  final String messageId;
  final MediaType mediaType;
  final Timestamp sendAt;
  final String senderName;
  final String message;
  final bool isMe;
  final String photoUrl;
  final ChatType chatType;
  final String groupId;
  final String? topicId;
  final String? replyToUserName;
  final String? replyToText;
  final MediaType? replyToMediaType;
  final VoidCallback? onReply;
  final Map<String, List<String>> reactions;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool showTime = false;
  double _slideOffset = 0;
  static const double _replyTriggerOffset = 48;
  static const double _maxSlideOffset = 56;

  String get _sendAtString {
    final sendTime = widget.sendAt.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sendDate = DateTime(sendTime.year, sendTime.month, sendTime.day);
    DateFormat sendTimeFormat = DateFormat.Hm();
    if (today == sendDate) {
      return sendTimeFormat.format(sendTime);
    }
    return sendTimeFormat.add_yMMMd().format(sendTime);
  }

  void _showReactionPicker(BuildContext context) {
    showReactionPicker(context, (emoji) {
      MessagesController().addReaction(
        messageId: widget.messageId,
        emoji: emoji,
        chatType: widget.chatType,
        groupId: widget.groupId,
        topicId: widget.topicId,
      );
    });
  }

  void _showReactionDetails(String emoji, List<String> userIds) async {
    final userNames = await MessagesController().getUserNamesForReaction(
      messageId: widget.messageId,
      emoji: emoji,
      chatType: widget.chatType,
      groupId: widget.groupId,
      topicId: widget.topicId,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => ReactionDetailsDialog(
        emoji: emoji,
        userNames: userNames,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return Column(
          children: [
            if (showTime)
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                child: Text(
                  _sendAtString,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                _slideOffset = 0;
              },
              onHorizontalDragUpdate: (details) {
                final directionMultiplier = widget.isMe ? -1 : 1;
                final delta = details.delta.dx * directionMultiplier;
                if (delta <= 0) {
                  return;
                }
                setState(() {
                  _slideOffset = (delta).clamp(0, _maxSlideOffset);
                });
              },
              onHorizontalDragEnd: (_) {
                final shouldTriggerReply = _slideOffset >= _replyTriggerOffset;
                if (shouldTriggerReply && widget.onReply != null) {
                  widget.onReply!();
                }
                setState(() {
                  _slideOffset = 0;
                });
              },
              onHorizontalDragCancel: () {
                setState(() {
                  _slideOffset = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(
                  widget.isMe ? -_slideOffset : _slideOffset,
                  0,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: widget.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: widget.isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!widget.isMe)
                          Container(
                            margin: const EdgeInsets.all(10),
                            child: CircleAvatar(
                              backgroundImage: (widget.photoUrl.isNotEmpty)
                                  ? NetworkImage(widget.photoUrl)
                                  : null,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: widget.isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!widget.isMe)
                                Text(
                                  widget.senderName,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground,
                                      fontSize: 13),
                                ),
                              if (widget.mediaType == MediaType.text)
                                TextMedia(
                                  constraints: constraint,
                                  text: widget.message,
                                  onPress: () {
                                    setState(() {
                                      showTime = !showTime;
                                    });
                                  },
                                  onLongPress: () =>
                                      _showReactionPicker(context),
                                  isMe: widget.isMe,
                                  showTime: showTime,
                                  replyPreview: _replyPreview(context),
                                )
                              else if (widget.mediaType == MediaType.image)
                                ImageMedia(
                                  isMe: widget.isMe,
                                  onPress: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ImageViewChatScreen(
                                          imageUrl: widget.message,
                                        ),
                                      ),
                                    );
                                  },
                                  constraints: constraint,
                                  imageUrl: widget.message,
                                  onLongPress: () =>
                                      _showReactionPicker(context),
                                  replyPreview: _replyPreview(context),
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Display reactions below message
                    ReactionDisplay(
                      reactions: widget.reactions,
                      isMe: widget.isMe,
                      onReactionTap: _showReactionDetails,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget? _replyPreview(BuildContext context) {
    if (widget.replyToUserName == null) return null;
    final text = widget.replyToText ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              '${widget.replyToUserName}: $text',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class ImageMedia extends StatelessWidget {
  const ImageMedia(
      {super.key,
      required this.isMe,
      required this.onPress,
      required this.constraints,
      required this.imageUrl,
      this.onLongPress,
      this.replyPreview});
  final String imageUrl;
  final bool isMe;
  final Function() onPress;
  final VoidCallback? onLongPress;
  final BoxConstraints constraints;
  final Widget? replyPreview;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isMe ? 20 : 6),
        bottomRight: Radius.circular(isMe ? 6 : 20),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: constraints.maxWidth * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (replyPreview != null) replyPreview!,
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 20),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextMedia extends StatelessWidget {
  const TextMedia(
      {super.key,
      required this.constraints,
      required this.text,
      required this.onPress,
      required this.isMe,
      required this.showTime,
      this.onLongPress,
      this.replyPreview});
  final BoxConstraints constraints;
  final String text;
  final Function() onPress;
  final VoidCallback? onLongPress;
  final bool isMe;
  final bool showTime;
  final Widget? replyPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Material(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 6),
          bottomRight: Radius.circular(isMe ? 6 : 20),
        ),
        color: isMe
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant,
        elevation: 0,
        child: InkWell(
          onTap: onPress,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 20),
          ),
          child: Container(
              constraints:
                  BoxConstraints(maxWidth: constraints.maxWidth * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (replyPreview != null) replyPreview!,
                  Text(
                    text,
                    softWrap: true,
                    style: TextStyle(
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
