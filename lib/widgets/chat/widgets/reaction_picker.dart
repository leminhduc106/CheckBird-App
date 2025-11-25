import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReactionPicker extends StatefulWidget {
  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
  });

  final Function(String emoji) onReactionSelected;

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // Popular reactions like Facebook Messenger/iMessage
  // These are just the quick access ones, full emoji keyboard comes from the package
  static const List<String> quickReactions = [
    '👍', // Like
    '❤️', // Love
    '😂', // Haha
    '😮', // Wow
    '😢', // Sad
    '🙏', // Care
  ];

  bool _showAllEmojis = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectReaction(String emoji) {
    widget.onReactionSelected(emoji);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Quick reactions
            _buildQuickReactions(),

            const SizedBox(height: 12),

            // Expand button
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllEmojis = !_showAllEmojis;
                });
              },
              icon: Icon(
                _showAllEmojis ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(
                _showAllEmojis
                    ? AppLocalizations.of(context)!.showLess
                    : AppLocalizations.of(context)!.moreReactions,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

            // Extended emoji picker - using professional emoji picker package
            if (_showAllEmojis) ...[
              const SizedBox(height: 8),
              _buildEmojiPicker(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReactions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: quickReactions.map((emoji) {
          return _buildReactionButton(emoji);
        }).toList(),
      ),
    );
  }

  Widget _buildReactionButton(String emoji) {
    return InkWell(
      onTap: () => _selectReaction(emoji),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 280,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _selectReaction(emoji.emoji);
        },
        config: Config(
          height: 256,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28,
            verticalSpacing: 0,
            horizontalSpacing: 0,
            gridPadding: EdgeInsets.zero,
            backgroundColor: Theme.of(context).colorScheme.surface,
            columns: 8,
            buttonMode: ButtonMode.MATERIAL,
          ),
          skinToneConfig: const SkinToneConfig(
            enabled: true,
            dialogBackgroundColor: Colors.white,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: Theme.of(context).colorScheme.primary,
            iconColorSelected: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            categoryIcons: const CategoryIcons(),
          ),
          bottomActionBarConfig: const BottomActionBarConfig(
            showBackspaceButton: false,
            showSearchViewButton: false,
          ),
        ),
      ),
    );
  }
}

// Helper function to show reaction picker
void showReactionPicker(
    BuildContext context, Function(String) onReactionSelected) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ReactionPicker(
      onReactionSelected: onReactionSelected,
    ),
  );
}
