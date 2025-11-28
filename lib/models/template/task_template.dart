import 'package:flutter/material.dart';

/// Template category for organization
enum TemplateCategory {
  productivity,
  health,
  learning,
  work,
  personal,
  social,
}

/// A task template that can be quickly applied
class TaskTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final TemplateCategory category;
  final List<TemplateTask> tasks;
  final bool isPremium;

  const TaskTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.tasks,
    this.isPremium = false,
  });

  /// Get all predefined templates
  static List<TaskTemplate> get allTemplates => [
        // === PRODUCTIVITY ===
        TaskTemplate(
          id: 'morning_routine',
          name: 'Morning Routine',
          description: 'Start your day with energy and focus',
          icon: Icons.wb_sunny,
          color: Colors.orange,
          category: TemplateCategory.productivity,
          tasks: [
            TemplateTask(
              name: 'Wake up early',
              description: 'Get up at your planned time',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Drink water',
              description: 'Hydrate first thing in the morning',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Morning exercise',
              description: '10-15 minutes of stretching or workout',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Healthy breakfast',
              description: 'Eat a nutritious breakfast',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Plan your day',
              description: 'Review tasks and set priorities',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
          ],
        ),
        TaskTemplate(
          id: 'evening_routine',
          name: 'Evening Routine',
          description: 'Wind down and prepare for quality sleep',
          icon: Icons.nightlight_round,
          color: Colors.indigo,
          category: TemplateCategory.productivity,
          tasks: [
            TemplateTask(
              name: 'Review completed tasks',
              description: 'Reflect on what you accomplished today',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
            TemplateTask(
              name: 'Prepare tomorrow\'s tasks',
              description: 'Write down 3 most important tasks',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, false],
            ),
            TemplateTask(
              name: 'No screens 1 hour before bed',
              description: 'Put away phone and laptop',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Read for 20 minutes',
              description: 'Read a book or educational content',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Sleep by 11 PM',
              description: 'Get to bed on time for quality rest',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
          ],
        ),
        TaskTemplate(
          id: 'pomodoro_session',
          name: 'Pomodoro Focus Session',
          description: 'Deep work with structured breaks',
          icon: Icons.timer,
          color: Colors.red,
          category: TemplateCategory.productivity,
          tasks: [
            TemplateTask(
              name: 'Focus Session 1 (25 min)',
              description: 'First focused work block',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Short Break (5 min)',
              description: 'Stretch and rest your eyes',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Focus Session 2 (25 min)',
              description: 'Second focused work block',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Short Break (5 min)',
              description: 'Hydrate and move around',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Focus Session 3 (25 min)',
              description: 'Third focused work block',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Long Break (15 min)',
              description: 'Take a proper break, snack if needed',
              isHabit: false,
            ),
          ],
        ),

        // === HEALTH ===
        TaskTemplate(
          id: 'fitness_beginner',
          name: 'Beginner Fitness',
          description: 'Start your fitness journey',
          icon: Icons.fitness_center,
          color: Colors.green,
          category: TemplateCategory.health,
          tasks: [
            TemplateTask(
              name: 'Morning stretch (5 min)',
              description: 'Light stretching to wake up your body',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Walk 10,000 steps',
              description: 'Stay active throughout the day',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Strength training',
              description: '20-30 min bodyweight exercises',
              isHabit: true,
              weekdays: [true, false, true, false, true, false, false],
            ),
            TemplateTask(
              name: 'Drink 8 glasses of water',
              description: 'Stay hydrated all day',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
          ],
        ),
        TaskTemplate(
          id: 'mental_wellness',
          name: 'Mental Wellness',
          description: 'Take care of your mental health',
          icon: Icons.self_improvement,
          color: Colors.teal,
          category: TemplateCategory.health,
          tasks: [
            TemplateTask(
              name: 'Morning meditation (10 min)',
              description: 'Start with mindfulness',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Gratitude journal',
              description: 'Write 3 things you\'re grateful for',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Digital detox hour',
              description: '1 hour without social media',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Nature walk',
              description: 'Spend time outdoors',
              isHabit: true,
              weekdays: [true, false, true, false, true, false, true],
            ),
          ],
        ),

        // === LEARNING ===
        TaskTemplate(
          id: 'language_learning',
          name: 'Language Learning',
          description: 'Master a new language consistently',
          icon: Icons.language,
          color: Colors.blue,
          category: TemplateCategory.learning,
          tasks: [
            TemplateTask(
              name: 'Duolingo/Language app (15 min)',
              description: 'Daily practice on your language app',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Learn 10 new words',
              description: 'Expand your vocabulary',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
            TemplateTask(
              name: 'Listen to podcast in target language',
              description: 'Improve listening comprehension',
              isHabit: true,
              weekdays: [true, false, true, false, true, false, false],
            ),
            TemplateTask(
              name: 'Watch movie/show with subtitles',
              description: 'Immerse yourself in the language',
              isHabit: true,
              weekdays: [false, false, false, false, false, true, true],
            ),
          ],
        ),
        TaskTemplate(
          id: 'study_session',
          name: 'Study Session',
          description: 'Effective studying routine',
          icon: Icons.school,
          color: Colors.purple,
          category: TemplateCategory.learning,
          tasks: [
            TemplateTask(
              name: 'Review yesterday\'s notes',
              description: 'Quick revision of previous material',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
            TemplateTask(
              name: 'Study new material (45 min)',
              description: 'Focus on learning new concepts',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
            TemplateTask(
              name: 'Practice problems/exercises',
              description: 'Apply what you learned',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
            TemplateTask(
              name: 'Create flashcards',
              description: 'Make study aids for key concepts',
              isHabit: true,
              weekdays: [true, false, true, false, true, false, false],
            ),
          ],
        ),

        // === WORK ===
        TaskTemplate(
          id: 'workday_kickstart',
          name: 'Workday Kickstart',
          description: 'Start your workday right',
          icon: Icons.work,
          color: Colors.blueGrey,
          category: TemplateCategory.work,
          tasks: [
            TemplateTask(
              name: 'Check calendar for meetings',
              description: 'Review today\'s schedule',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
            TemplateTask(
              name: 'Process inbox',
              description: 'Clear emails and messages',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
            TemplateTask(
              name: 'Identify top 3 priorities',
              description: 'What must get done today?',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
            TemplateTask(
              name: 'Deep work block (2 hours)',
              description: 'Work on most important task',
              isHabit: true,
              weekdays: [true, true, true, true, true, false, false],
            ),
          ],
        ),
        TaskTemplate(
          id: 'weekly_review',
          name: 'Weekly Review',
          description: 'Reflect and plan for success',
          icon: Icons.rate_review,
          color: Colors.amber,
          category: TemplateCategory.work,
          tasks: [
            TemplateTask(
              name: 'Review completed tasks this week',
              description: 'Celebrate your wins',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Review incomplete tasks',
              description: 'Reschedule or delete if not needed',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Clear inbox and notes',
              description: 'Process all captured items',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Plan next week\'s priorities',
              description: 'Set goals for the upcoming week',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Review long-term goals',
              description: 'Ensure alignment with bigger picture',
              isHabit: false,
            ),
          ],
        ),

        // === PERSONAL ===
        TaskTemplate(
          id: 'self_care_sunday',
          name: 'Self-Care Sunday',
          description: 'Dedicate time to yourself',
          icon: Icons.spa,
          color: Colors.pink,
          category: TemplateCategory.personal,
          tasks: [
            TemplateTask(
              name: 'Sleep in or slow morning',
              description: 'No alarms, wake naturally',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Skincare routine',
              description: 'Take care of your skin',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Prepare healthy meals for week',
              description: 'Meal prep for busy days',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Clean and organize space',
              description: 'Tidy living area',
              isHabit: false,
            ),
            TemplateTask(
              name: 'Hobby time (1+ hour)',
              description: 'Do something you love',
              isHabit: false,
            ),
          ],
        ),
        TaskTemplate(
          id: 'reading_habit',
          name: 'Reading Challenge',
          description: 'Build a consistent reading habit',
          icon: Icons.menu_book,
          color: Colors.brown,
          category: TemplateCategory.personal,
          tasks: [
            TemplateTask(
              name: 'Read for 20 minutes',
              description: 'Daily reading practice',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Take reading notes',
              description: 'Write key insights or quotes',
              isHabit: true,
              weekdays: [true, false, true, false, true, false, false],
            ),
            TemplateTask(
              name: 'Update reading list',
              description: 'Add books you want to read',
              isHabit: true,
              weekdays: [false, false, false, false, false, false, true],
            ),
          ],
        ),

        // === SOCIAL ===
        TaskTemplate(
          id: 'stay_connected',
          name: 'Stay Connected',
          description: 'Nurture your relationships',
          icon: Icons.favorite,
          color: Colors.red,
          category: TemplateCategory.social,
          tasks: [
            TemplateTask(
              name: 'Message a friend or family member',
              description: 'Check in with someone you care about',
              isHabit: true,
              weekdays: [true, true, true, true, true, true, true],
            ),
            TemplateTask(
              name: 'Plan a social activity',
              description: 'Schedule time with friends',
              isHabit: true,
              weekdays: [false, false, false, false, true, false, false],
            ),
            TemplateTask(
              name: 'Call family member',
              description: 'Weekly catch-up call',
              isHabit: true,
              weekdays: [false, false, false, false, false, true, false],
            ),
          ],
        ),
      ];

  static List<TaskTemplate> getByCategory(TemplateCategory category) {
    return allTemplates.where((t) => t.category == category).toList();
  }

  static TaskTemplate? getById(String id) {
    try {
      return allTemplates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// A single task within a template
class TemplateTask {
  final String name;
  final String description;
  final bool isHabit;
  final List<bool>? weekdays; // For habits: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]

  const TemplateTask({
    required this.name,
    this.description = '',
    this.isHabit = false,
    this.weekdays,
  });
}

/// Extension to get category display info
extension TemplateCategoryExtension on TemplateCategory {
  String get name {
    switch (this) {
      case TemplateCategory.productivity:
        return 'Productivity';
      case TemplateCategory.health:
        return 'Health & Fitness';
      case TemplateCategory.learning:
        return 'Learning';
      case TemplateCategory.work:
        return 'Work';
      case TemplateCategory.personal:
        return 'Personal';
      case TemplateCategory.social:
        return 'Social';
    }
  }

  IconData get icon {
    switch (this) {
      case TemplateCategory.productivity:
        return Icons.trending_up;
      case TemplateCategory.health:
        return Icons.favorite;
      case TemplateCategory.learning:
        return Icons.school;
      case TemplateCategory.work:
        return Icons.work;
      case TemplateCategory.personal:
        return Icons.person;
      case TemplateCategory.social:
        return Icons.groups;
    }
  }

  Color get color {
    switch (this) {
      case TemplateCategory.productivity:
        return Colors.blue;
      case TemplateCategory.health:
        return Colors.green;
      case TemplateCategory.learning:
        return Colors.purple;
      case TemplateCategory.work:
        return Colors.blueGrey;
      case TemplateCategory.personal:
        return Colors.pink;
      case TemplateCategory.social:
        return Colors.red;
    }
  }
}
