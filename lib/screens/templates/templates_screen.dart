import 'package:check_bird/models/template/task_template.dart';
import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/models/todo/todo_list_controller.dart';
import 'package:check_bird/models/todo/todo_type.dart';
import 'package:flutter/material.dart';

class TemplatesScreen extends StatefulWidget {
  static const routeName = '/templates-screen';

  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TodoListController _todoController = TodoListController();

  final List<TemplateCategory> _categories = TemplateCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Templates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _categories
              .map((category) => Tab(
                    icon: Icon(category.icon),
                    text: category.name,
                  ))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose a template to quickly add tasks and habits to your list!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Template list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories
                  .map((category) => _buildTemplateList(
                        TaskTemplate.getByCategory(category),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(List<TaskTemplate> templates) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        return _buildTemplateCard(templates[index]);
      },
    );
  }

  Widget _buildTemplateCard(TaskTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: template.color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: template.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    template.icon,
                    color: template.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: template.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.list,
                        size: 16,
                        color: template.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${template.tasks.length}',
                        style: TextStyle(
                          color: template.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Task preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...template.tasks.take(3).map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              task.isHabit
                                  ? Icons.repeat
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                task.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            if (task.isHabit)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Habit',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                if (template.tasks.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${template.tasks.length - 3} more tasks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _previewTemplate(template),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Preview'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _applyTemplate(template),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Use'),
                    style: FilledButton.styleFrom(
                      backgroundColor: template.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _previewTemplate(TaskTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: template.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        template.icon,
                        color: template.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${template.tasks.length} tasks',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Task list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: template.tasks.length,
                  itemBuilder: (context, index) {
                    final task = template.tasks[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (task.isHabit ? Colors.blue : Colors.green)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          task.isHabit
                              ? Icons.repeat
                              : Icons.check_circle_outline,
                          color: task.isHabit ? Colors.blue : Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(task.name),
                      subtitle: task.description.isNotEmpty
                          ? Text(
                              task.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            )
                          : null,
                      trailing: task.isHabit && task.weekdays != null
                          ? _buildWeekdayIndicator(task.weekdays!)
                          : null,
                    );
                  },
                ),
              ),
              // Apply button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyTemplate(template);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Apply Template'),
                      style: FilledButton.styleFrom(
                        backgroundColor: template.color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayIndicator(List<bool> weekdays) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final isActive = weekdays[index];
        return Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blue.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              days[index],
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _applyTemplate(TaskTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply "${template.name}"?'),
        content: Text(
          'This will add ${template.tasks.length} tasks and habits to your list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Ensure Hive box is open
    final boxReady = await _todoController.ensureBoxOpen();
    if (!boxReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save tasks. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    int addedCount = 0;

    for (final templateTask in template.tasks) {
      final todo = Todo(
        todoName: templateTask.name,
        todoDescription: templateTask.description,
        type: templateTask.isHabit ? TodoType.habit : TodoType.task,
        weekdays:
            templateTask.weekdays ?? [true, true, true, true, true, true, true],
        deadline: templateTask.isHabit
            ? null
            : DateTime.now().add(const Duration(days: 7)),
        backgroundColor: template.color.value,
        textColor: Colors.white.value,
      );

      await _todoController.addTodo(todo);
      addedCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Added $addedCount tasks from "${template.name}"'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context); // Go back to task screen
    }
  }
}
