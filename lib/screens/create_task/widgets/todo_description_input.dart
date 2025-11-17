import 'package:flutter/material.dart';

class TodoDescriptionInput extends StatelessWidget {
  const TodoDescriptionInput(
      {super.key, required this.onSaved, required this.todoDescription});
  final void Function(String value) onSaved;
  final String todoDescription;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey("todo-description"),
      initialValue: todoDescription,
      expands: true,
      maxLines: null,
      textAlign: TextAlign.start,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        labelText: "Description",
        hintText: "Add details about your task...",
        alignLabelWithHint: true,
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
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      onSaved: (value) {
        onSaved(value!);
      },
    );
  }
}
