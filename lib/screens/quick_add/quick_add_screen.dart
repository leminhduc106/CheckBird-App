import 'package:flutter/material.dart';
import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/services/quick_add_parser.dart';
import 'package:check_bird/services/priority_service.dart';
import 'package:check_bird/widgets/priority_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Quick Add Screen - Natural language task creation
/// Similar to Todoist's quick add feature
class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  /// Show as a bottom sheet
  static Future<Todo?> show(BuildContext context) {
    return showModalBottomSheet<Todo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddScreen(),
    );
  }

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _parser = QuickAddParser();
  final _priorityService = PriorityService();

  ParsedTaskInput? _parsed;
  List<String> _suggestions = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    if (text.isEmpty) {
      setState(() {
        _parsed = null;
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _parsed = _parser.parse(text);
      _suggestions = _parser.getSuggestions(text);
    });
  }

  Future<void> _createTask() async {
    if (_parsed == null || _parsed!.taskName.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final todo = _parsed!.isHabit
          ? Todo.habit(
              todoName: _parsed!.taskName,
              todoDescription: _parsed!.description ?? '',
              textColor: Colors.white.value,
              backgroundColor: Colors.blue.value,
              weekdays: _parsed!.weekdays,
            )
          : Todo.task(
              todoName: _parsed!.taskName,
              todoDescription: _parsed!.description ?? '',
              deadline: _parsed!.deadline,
              notification: _parsed!.reminder,
              textColor: Colors.white.value,
              backgroundColor: Colors.blue.value,
            );

      // Generate ID
      todo.id = const Uuid().v4();
      todo.createdDate = DateTime.now();
      todo.lastModified = DateTime.now();

      // Save to Hive
      final box = Hive.box<Todo>('todos');
      await box.add(todo);

      // Set priority
      await _priorityService.setPriorityForTodo(todo, _parsed!.priority);

      if (mounted) {
        Navigator.of(context).pop(todo);

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _parsed!.isHabit ? Icons.repeat : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_parsed!.isHabit ? 'Habit' : 'Task'} created: ${_parsed!.taskName}',
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Add',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Type naturally to create tasks',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Text input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'e.g., "Buy groceries tomorrow at 3pm p1"',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.add_task),
                  suffixIcon: _isProcessing
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed:
                              _parsed != null && _parsed!.taskName.isNotEmpty
                                  ? _createTask
                                  : null,
                          icon: Icon(
                            Icons.send,
                            color:
                                _parsed != null && _parsed!.taskName.isNotEmpty
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                          ),
                        ),
                ),
                onSubmitted: (_) => _createTask(),
                textInputAction: TextInputAction.done,
                maxLines: 2,
                minLines: 1,
              ),
            ),

            // Parsed preview
            if (_parsed != null && _parsed!.taskName.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPreview(),
            ],

            // Suggestions
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSuggestions(),
            ],

            // Quick tips
            if (_parsed == null || _parsed!.taskName.isEmpty) ...[
              const SizedBox(height: 16),
              _buildTips(),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _parsed!.isHabit ? Icons.repeat : Icons.task_alt,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _parsed!.taskName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              PriorityBadge(priority: _parsed!.priority),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_parsed!.deadline != null)
                _buildChip(
                  Icons.event,
                  _formatDeadline(_parsed!.deadline!),
                  Colors.blue,
                ),
              if (_parsed!.isHabit && _parsed!.weekdays != null)
                _buildChip(
                  Icons.repeat,
                  _formatWeekdays(_parsed!.weekdays!),
                  Colors.purple,
                ),
              if (_parsed!.tags.isNotEmpty)
                ...(_parsed!.tags.map((tag) => _buildChip(
                      Icons.tag,
                      tag,
                      Colors.orange,
                    ))),
              _buildChip(
                _parsed!.isHabit ? Icons.repeat : Icons.check_box,
                _parsed!.isHabit ? 'Habit' : 'Task',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              _suggestions[index].length > 30
                  ? '${_suggestions[index].substring(0, 30)}...'
                  : _suggestions[index],
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () {
              _textController.text = _suggestions[index];
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _suggestions[index].length),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick tips:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildTipRow('📅', '"tomorrow", "next monday", "Dec 25"'),
          _buildTipRow('⏰', '"at 3pm", "10:30am"'),
          _buildTipRow('🚩', '"p1" or "!!!" for urgent'),
          _buildTipRow('🔄', '"every day", "weekdays" for habits'),
          _buildTipRow('🏷️', '"#work #important" for tags'),
        ],
      ),
    );
  }

  Widget _buildTipRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

    String dateStr;
    if (deadlineDate == today) {
      dateStr = 'Today';
    } else if (deadlineDate == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      dateStr =
          '${weekdays[deadline.weekday - 1]}, ${months[deadline.month - 1]} ${deadline.day}';
    }

    if (deadline.hour != 23 || deadline.minute != 59) {
      final hour = deadline.hour.toString().padLeft(2, '0');
      final minute = deadline.minute.toString().padLeft(2, '0');
      dateStr += ' at $hour:$minute';
    }

    return dateStr;
  }

  String _formatWeekdays(List<bool> weekdays) {
    if (weekdays.every((d) => d)) return 'Every day';
    if (weekdays.take(5).every((d) => d) && !weekdays[5] && !weekdays[6]) {
      return 'Weekdays';
    }
    if (!weekdays.take(5).any((d) => d) && weekdays[5] && weekdays[6]) {
      return 'Weekends';
    }

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final activeDays = <String>[];
    for (int i = 0; i < 7; i++) {
      if (weekdays[i]) {
        activeDays.add(dayNames[i]);
      }
    }
    return activeDays.join(', ');
  }
}

/// Floating action button for quick add
class QuickAddFAB extends StatelessWidget {
  const QuickAddFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => QuickAddScreen.show(context),
      icon: const Icon(Icons.flash_on),
      label: const Text('Quick Add'),
      heroTag: 'quick_add_fab',
    );
  }
}
