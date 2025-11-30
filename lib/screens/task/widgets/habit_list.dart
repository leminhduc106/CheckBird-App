import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/models/todo/todo_list_controller.dart';
import 'package:check_bird/screens/task/widgets/todo_item_remove.dart';
import 'package:check_bird/widgets/week_day_picker/week_day_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HabitListScreen extends StatefulWidget {
  static const routeName = '/habit-list-screen';

  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final TodoListController _controller = TodoListController();
  late final ValueNotifier<List<Todo>> _selectedHabit;
  List<bool> _selectedDays = [true, false, false, false, false, false, false];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedHabit = ValueNotifier([]);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final boxReady = await _controller.ensureBoxOpen();
    if (boxReady && mounted) {
      setState(() {
        _isInitialized = true;
        _selectedHabit.value = _controller.getHabitForMultiDays(_selectedDays);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final box = _controller.getTodoListSafe();
    if (box == null) {
      return const Center(child: Text('Unable to load habits'));
    }

    return Scaffold(
        body: Column(
      children: [
        const SizedBox(height: 12),
        const Text(
          "Select days of week",
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 4),
        WeekDayPicker(
            onChanged: (days) {
              _selectedDays = days;
              _selectedHabit.value =
                  _controller.getHabitForMultiDays(_selectedDays);
            },
            initialValues: _selectedDays),
        const SizedBox(height: 10.0),
        Expanded(
            child: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box<Todo> _, __) {
            // Refresh the list when box changes
            final todos = _controller.getHabitForMultiDays(_selectedDays);
            return ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                return ToDoItemRemove(
                    todos: todos, index: index, isCheck: false);
              },
            );
          },
        ))
      ],
    ));
  }
}
