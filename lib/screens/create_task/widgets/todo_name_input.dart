import 'package:flutter/material.dart';

class TodoNameInput extends StatelessWidget {
  const TodoNameInput({super.key, required this.onSaved, required this.todoName});
  final void Function(String value) onSaved;
  final String todoName;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: todoName,
      key: const ValueKey("todo-name"),
      maxLines: 1,
      maxLength: 50,
      decoration: InputDecoration(
        labelText: "Task Name",
        hintText: "Enter your task name...",
        prefixIcon: const Icon(Icons.task_alt_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      onSaved: (value) {
        onSaved(value!);
      },
      validator: (value) {
        if (value!.trim().isEmpty) {
          return "Task name is required";
        } else if (value.trim().length < 3) {
          return "Task name must be at least 3 characters";
        }
        return null;
      },
    );
  }
}
