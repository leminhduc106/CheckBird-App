import 'package:flutter/material.dart';

class EmptyToDo extends StatelessWidget {
  const EmptyToDo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(32),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                "You have no tasks for today",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
