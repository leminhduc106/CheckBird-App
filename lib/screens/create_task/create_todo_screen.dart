import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/models/todo/todo_list_controller.dart';
import 'package:check_bird/models/todo/todo_type.dart';
import 'package:check_bird/screens/create_task/widgets/create_todo_appbar.dart';
import 'package:check_bird/screens/create_task/widgets/habit_custom.dart';
import 'package:check_bird/screens/create_task/widgets/pick_color.dart';
import 'package:check_bird/screens/create_task/widgets/task_custom.dart';
import 'package:check_bird/screens/create_task/widgets/todo_description_input.dart';
import 'package:check_bird/screens/create_task/widgets/todo_name_input.dart';
import 'package:check_bird/screens/create_task/widgets/toggle_habit_task.dart';
import 'package:check_bird/screens/groups/models/groups_controller.dart';
import 'package:flutter/material.dart';

class CreateTodoScreen extends StatefulWidget {
  const CreateTodoScreen({super.key, this.todo, this.initialGroupId});
  static const routeName = 'create-todo-screen';
  final Todo? todo;
  final String? initialGroupId;

  @override
  State<CreateTodoScreen> createState() => _CreateTodoScreenState();
}

class _CreateTodoScreenState extends State<CreateTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  String _todoName = "";
  String _todoDescription = "";
  TodoType _todoType = TodoType.task;
  var _backgroundColor = Colors.white;
  var _textColor = Colors.black;
  DateTime? _dueDate;
  DateTime? _notification;
  List<bool> _habitLoop = List.filled(7, true);
  var _habitError = false; //
  bool _showWarning = false;
  String? _groupId;
  List<Group> _availableGroups = [];
  bool _groupsLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _todoName = widget.todo!.todoName;
      _todoDescription = widget.todo!.todoDescription;
      _backgroundColor = Color(widget.todo!.backgroundColor);
      _textColor = Color(widget.todo!.textColor);
      _todoType = widget.todo!.type;
      _dueDate = widget.todo!.deadline;
      _habitLoop = (widget.todo!.type == TodoType.habit)
          ? widget.todo!.weekdays!
          : _habitLoop;
      _groupId = widget.todo!.groupId;
    } else {
      _groupId = widget.initialGroupId;
    }
    _loadAvailableGroups();
  }

  Future<void> _loadAvailableGroups() async {
    try {
      final groups = await GroupsController().usersGroupFuture();
      setState(() {
        _availableGroups = groups;
        _groupsLoaded = true;
      });
    } catch (e) {
      setState(() {
        _groupsLoaded = true;
      });
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    var isValid = _formKey.currentState!.validate();
    if (!isValid) return;
    var hasVal = false;
    for (var i = 0; i < _habitLoop.length; i++) {
      if (_habitLoop[i]) {
        hasVal = true;
        break;
      }
    }
    if (!hasVal) {
      setState(() {
        _habitError = true;
      });
      if (!_showWarning) {
        _showWarning = true;
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _habitError = false;
            _showWarning = false;
          });
        });
      }
      return;
    }
    _formKey.currentState!.save();
    if (widget.todo != null) {
      widget.todo!.editTodo(
        newName: _todoName,
        newDescription: _todoDescription,
        newBackgroundColor: _backgroundColor.value,
        newTextColor: _textColor.value,
        newDeadline: widget.todo!.type == TodoType.habit ? null : _dueDate,
        newNotification:
            widget.todo!.type == TodoType.habit ? null : _notification,
        newWeekdays: widget.todo!.type == TodoType.task ? null : _habitLoop,
      );
    } else {
      if (_todoType == TodoType.habit) {
        TodoListController().addTodo(
          Todo.habit(
            todoName: _todoName,
            todoDescription: _todoDescription,
            textColor: _textColor.value,
            backgroundColor: _backgroundColor.value,
            weekdays: _habitLoop,
            groupId: _groupId,
          ),
        );
      }
      if (_todoType == TodoType.task) {
        TodoListController().addTodo(
          Todo.task(
              todoName: _todoName,
              todoDescription: _todoDescription,
              textColor: _textColor.value,
              backgroundColor: _backgroundColor.value,
              deadline: _dueDate,
              notification: _notification,
              groupId: _groupId),
        );
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: CreateTodoAppbar(
          todoName: _todoName.isEmpty ? null : _todoName,
          appBar: AppBar(),
        ),
        body: SingleChildScrollView(
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TodoNameInput(
                      todoName: _todoName,
                      onSaved: (value) {
                        _todoName = value;
                      }),
                  SizedBox(
                    height: size.height * 0.02,
                  ),
                  SizedBox(
                    height: size.height * 0.25,
                    child: TodoDescriptionInput(
                        todoDescription: _todoDescription,
                        onSaved: (value) {
                          _todoDescription = value;
                        }),
                  ),
                  PickColor(
                    backgroundColor: _backgroundColor,
                    textColor: _textColor,
                    setBackgroundColor: (color) {
                      setState(() {
                        _backgroundColor = color;
                      });
                    },
                    setTextColor: (color) {
                      setState(() {
                        _textColor = color;
                      });
                    },
                  ),
                  ToggleHabitTask(
                    todoType: _todoType,
                    onChanged: widget.todo != null
                        ? null
                        : (_) {
                            setState(() {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (_todoType == TodoType.habit) {
                                _todoType = TodoType.task;
                              } else {
                                _todoType = TodoType.habit;
                              }
                            });
                          },
                  ),
                  // Group Selection
                  _buildGroupSelector(),
                  if (_todoType == TodoType.task)
                    TaskCustom(
                      initialDate: _dueDate,
                      onChangedDue: (value) {
                        setState(() {
                          _dueDate = DateTime.parse(value);
                        });
                      },
                      onChangedNotification: (value) {
                        _notification = value;
                      },
                    ),
                  if (_todoType == TodoType.habit)
                    HabitCustom(
                      habitDays: widget.todo == null ? null : _habitLoop,
                      onChanged: (values) {
                        _habitLoop = values;
                      },
                    ),
                  if (_todoType == TodoType.habit && _habitError)
                    Text(
                      "Habit required to have at least 1 day",
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  SizedBox(
                    height: size.height * 0.05,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _submit();
                    },
                    child: widget.todo == null
                        ? const Text("Add todo")
                        : const Text("Save"),
                  ),
                  SizedBox(
                    height: size.height * 0.05,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign to Group (Optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 12),

          // Show loading state
          if (!_groupsLoaded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading groups...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            )

          // Show message when no groups available
          else if (_availableGroups.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You haven\'t joined any groups yet. This will be a personal task.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ),
                ],
              ),
            )

          // Show dropdown when groups are available
          else
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String?>(
                value: _groupId,
                isExpanded: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: 'Select a group',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  size: 28,
                ),
                items: [
                  // Personal task option
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Personal Task',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Group options
                  ..._availableGroups.map((group) {
                    return DropdownMenuItem<String?>(
                      value: group.groupId,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage: group.groupsAvtUrl != null &&
                                    group.groupsAvtUrl!.isNotEmpty
                                ? NetworkImage(group.groupsAvtUrl!)
                                : null,
                            child: group.groupsAvtUrl == null ||
                                    group.groupsAvtUrl!.isEmpty
                                ? Icon(
                                    Icons.groups_rounded,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              group.groupName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _groupId = value;
                  });
                },
              ),
            ),

          // Show info message when a group is selected
          if (_groupId != null && _groupsLoaded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiaryContainer
                    .withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This task will be shared with the group! It will appear in the group\'s Tasks tab and create a completion post when you finish it.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
