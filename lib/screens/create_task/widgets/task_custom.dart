import 'package:check_bird/widgets/date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';

int daysBetween(DateTime from, DateTime to) {
  from = DateTime(from.year, from.month, from.day);
  to = DateTime(to.year, to.month, to.day);
  return (to.difference(from).inHours / 24).round();
}

int minutesBetween(DateTime from, DateTime to) {
  return to.difference(from).inMinutes;
}

enum NotificationType {
  none, // not set notification
  min5, // 5 minutes before
  min15, // 15 minutes before
  min30, // 30 minutes before
  hour1, // 1 hour before
  att, // at that time
  db1, // 1 day before
  db2, // 2 day before
  db3, // 3 day before
}

class TaskCustom extends StatefulWidget {
  const TaskCustom(
      {super.key,
      required this.initialDate,
      required this.onChangedDue,
      required this.onChangedNotification});
  final DateTime? initialDate;
  final void Function(String value) onChangedDue;
  final void Function(DateTime? dateTime) onChangedNotification;

  @override
  State<TaskCustom> createState() => _TaskCustomState();
}

class _TaskCustomState extends State<TaskCustom> {
  static final Map<NotificationType, String> _notificationType = {
    NotificationType.none: "Don't remind me",
    NotificationType.min5: "5 minutes before",
    NotificationType.min15: "15 minutes before",
    NotificationType.min30: "30 minutes before",
    NotificationType.hour1: "1 hour before",
    NotificationType.att: "At the time",
    NotificationType.db1: "1 day before",
    NotificationType.db2: "2 days before",
    NotificationType.db3: "3 days before",
  };

  DateTime _pickedDay = DateTime.now().add(const Duration(minutes: 30));
  NotificationType _pickedNotificationType = NotificationType.none;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _pickedDay = widget.initialDate!;
    }
    // Notify parent of the initial due date on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChangedDue(_pickedDay.toString());
    });
  }

  List<DropdownMenuItem<NotificationType>> _buildDropdownItems() {
    final items = <DropdownMenuItem<NotificationType>>[];
    final now = DateTime.now();
    final minutesToDeadline = minutesBetween(now, _pickedDay);
    final daysToDeadline = daysBetween(now, _pickedDay);

    // Always add "Don't remind me"
    items.add(DropdownMenuItem(
      value: NotificationType.none,
      child: Text(_notificationType[NotificationType.none]!),
    ));

    // Add time-based options based on how far the deadline is
    if (minutesToDeadline >= 5) {
      items.add(DropdownMenuItem(
        value: NotificationType.min5,
        child: Text(_notificationType[NotificationType.min5]!),
      ));
    }

    if (minutesToDeadline >= 15) {
      items.add(DropdownMenuItem(
        value: NotificationType.min15,
        child: Text(_notificationType[NotificationType.min15]!),
      ));
    }

    if (minutesToDeadline >= 30) {
      items.add(DropdownMenuItem(
        value: NotificationType.min30,
        child: Text(_notificationType[NotificationType.min30]!),
      ));
    }

    if (minutesToDeadline >= 60) {
      items.add(DropdownMenuItem(
        value: NotificationType.hour1,
        child: Text(_notificationType[NotificationType.hour1]!),
      ));
    }

    // "At the time" - only if deadline is at least 1 minute in future
    if (minutesToDeadline >= 1) {
      items.add(DropdownMenuItem(
        value: NotificationType.att,
        child: Text(_notificationType[NotificationType.att]!),
      ));
    }

    // Day-based options
    if (daysToDeadline >= 1) {
      items.add(DropdownMenuItem(
        value: NotificationType.db1,
        child: Text(_notificationType[NotificationType.db1]!),
      ));
    }

    if (daysToDeadline >= 2) {
      items.add(DropdownMenuItem(
        value: NotificationType.db2,
        child: Text(_notificationType[NotificationType.db2]!),
      ));
    }

    if (daysToDeadline >= 3) {
      items.add(DropdownMenuItem(
        value: NotificationType.db3,
        child: Text(_notificationType[NotificationType.db3]!),
      ));
    }

    return items;
  }

  DateTime? _calculateNotificationTime(NotificationType type) {
    switch (type) {
      case NotificationType.none:
        return null;
      case NotificationType.min5:
        return _pickedDay.subtract(const Duration(minutes: 5));
      case NotificationType.min15:
        return _pickedDay.subtract(const Duration(minutes: 15));
      case NotificationType.min30:
        return _pickedDay.subtract(const Duration(minutes: 30));
      case NotificationType.hour1:
        return _pickedDay.subtract(const Duration(hours: 1));
      case NotificationType.att:
        return _pickedDay;
      case NotificationType.db1:
        return _pickedDay.subtract(const Duration(days: 1));
      case NotificationType.db2:
        return _pickedDay.subtract(const Duration(days: 2));
      case NotificationType.db3:
        return _pickedDay.subtract(const Duration(days: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(
          title: Text(
            "Due date",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DateTimePicker(
          initialValue: widget.initialDate == null
              ? _pickedDay.toString()
              : widget.initialDate.toString(),
          type: DateTimePickerType.dateTimeSeparate,
          firstDate: DateTime.now(),
          lastDate: DateTime(DateTime.now().year + 5),
          onChanged: (value) {
            setState(() {
              _pickedDay = DateTime.parse(value);
              // Check if current selection is still valid
              final validItems = _buildDropdownItems();
              if (!validItems
                  .any((item) => item.value == _pickedNotificationType)) {
                _pickedNotificationType = NotificationType.none;
                widget.onChangedNotification(null);
              } else if (_pickedNotificationType != NotificationType.none) {
                // Recalculate notification time for new due date
                final newNotificationTime =
                    _calculateNotificationTime(_pickedNotificationType);
                debugPrint(
                    'TaskCustom: Due date changed, recalculating notification time: $newNotificationTime');
                widget.onChangedNotification(newNotificationTime);
              }
            });
            widget.onChangedDue(value);
          },
          validator: (value) {
            final pickedValue = DateTime.parse(value!);
            if (pickedValue.isBefore(DateTime.now())) {
              return "Can't schedule a task in the past!";
            }
            return null;
          },
          onSaved: (value) {
            widget.onChangedDue(value!);
          },
        ),
        const ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: Text(
            "Reminder",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButtonFormField<NotificationType>(
            value: _pickedNotificationType,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _buildDropdownItems(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _pickedNotificationType = value;
                });
                final notificationTime = _calculateNotificationTime(value);
                debugPrint('TaskCustom: Selected notification type: $value');
                debugPrint('TaskCustom: Due date: $_pickedDay');
                debugPrint(
                    'TaskCustom: Calculated notification time: $notificationTime');
                widget.onChangedNotification(notificationTime);
              }
            },
          ),
        ),
        if (_pickedNotificationType != NotificationType.none) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will be reminded at ${_formatNotificationTime()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatNotificationTime() {
    final notificationTime =
        _calculateNotificationTime(_pickedNotificationType);
    if (notificationTime == null) return '';

    final now = DateTime.now();
    final isToday = notificationTime.day == now.day &&
        notificationTime.month == now.month &&
        notificationTime.year == now.year;

    final timeStr =
        '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}';

    if (isToday) {
      return 'Today at $timeStr';
    }

    final isTomorrow = notificationTime.day == now.day + 1 &&
        notificationTime.month == now.month &&
        notificationTime.year == now.year;

    if (isTomorrow) {
      return 'Tomorrow at $timeStr';
    }

    return '${notificationTime.day}/${notificationTime.month}/${notificationTime.year} at $timeStr';
  }
}
