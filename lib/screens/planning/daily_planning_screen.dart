import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:check_bird/models/planning/daily_plan.dart';
import 'package:check_bird/services/planning_service.dart';

class DailyPlanningScreen extends StatefulWidget {
  const DailyPlanningScreen({super.key});

  @override
  State<DailyPlanningScreen> createState() => _DailyPlanningScreenState();
}

class _DailyPlanningScreenState extends State<DailyPlanningScreen> {
  final PlanningService _planningService = PlanningService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers
  final _intentionController = TextEditingController();
  final List<TextEditingController> _priorityControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _energyLevel = 3;
  String? _focusArea;

  @override
  void initState() {
    super.initState();
    _planningService.initialize();
    _planningService.addListener(_onUpdate);
    _loadExistingData();
  }

  void _loadExistingData() {
    final plan = _planningService.todaysPlan;
    if (plan != null) {
      _intentionController.text = plan.morningIntention ?? '';
      for (int i = 0; i < plan.topPriorities.length && i < 3; i++) {
        _priorityControllers[i].text = plan.topPriorities[i];
      }
      _energyLevel = plan.energyLevel;
      _focusArea = plan.focusArea;
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _planningService.removeListener(_onUpdate);
    _pageController.dispose();
    _intentionController.dispose();
    for (var c in _priorityControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _getStepTitle(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (_currentStep + 1) / _totalSteps,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance close button
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildIntentionStep(),
                  _buildPrioritiesStep(),
                  _buildEnergyStep(),
                  _buildTimeBlocksStep(),
                ],
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _nextStep,
                      child: Text(
                        _currentStep == _totalSteps - 1
                            ? 'Complete Plan'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return '🌅 Morning Intention';
      case 1:
        return '🎯 Top Priorities';
      case 2:
        return '⚡ Energy Check';
      case 3:
        return '📅 Time Blocks';
      default:
        return 'Daily Planning';
    }
  }

  Widget _buildIntentionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your intention for today?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a guiding theme for your day. This helps maintain focus when things get busy.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _intentionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'e.g., "Stay focused on deep work" or "Be patient and present"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Affirmation suggestions
          Text(
            '✨ Need inspiration?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AffirmationTemplate.templates.take(4).map((template) {
              return ActionChip(
                label: Text(
                  template.template,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  _intentionController.text = template.template;
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritiesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are your top 3 priorities?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'If you could only accomplish 3 things today, what would make the biggest impact?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priorityControllers[index],
                      decoration: InputDecoration(
                        hintText: index == 0
                            ? 'Most important task'
                            : 'Priority ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Focus on outcomes, not just activities. What results do you want?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
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

  Widget _buildEnergyStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How\'s your energy today?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Understanding your energy helps plan your day realistically.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Energy level selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final level = index + 1;
              final isSelected = _energyLevel == level;
              final emoji = _getEnergyEmoji(level);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _energyLevel = level);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                          ),
                  ),
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: isSelected ? 36 : 28),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              _getEnergyLabel(_energyLevel),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          const SizedBox(height: 40),

          // Focus area
          Text(
            'What\'s your focus area today?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: FocusAreaPreset.presets.map((preset) {
              final isSelected = _focusArea == preset.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _focusArea = isSelected ? null : preset.id;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(preset.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlocksStep() {
    final plan = _planningService.todaysPlan;
    final timeBlocks = plan?.timeBlocks ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan your time blocks',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Block out dedicated time for your priorities and important activities.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Existing time blocks
          if (timeBlocks.isNotEmpty) ...[
            ...timeBlocks.map((block) => _buildTimeBlockCard(block)),
            const SizedBox(height: 16),
          ],

          // Add time block button
          OutlinedButton.icon(
            onPressed: _showAddTimeBlockDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Time Block'),
          ),

          const SizedBox(height: 24),

          // Quick add suggestions
          Text(
            '💡 Quick add:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _planningService.getSuggestedTimeBlocks().map((block) {
              return ActionChip(
                avatar: Icon(block.icon, size: 18),
                label: Text(block.title),
                onPressed: () async {
                  await _planningService.addTimeBlock(block.copyWith(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                  ));
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlockCard(TimeBlock block) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: block.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(block.icon, color: block.color),
        ),
        title: Text(
          block.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${_formatTime(block.startTime)} - ${_formatTime(block.endTime)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _planningService.removeTimeBlock(block.id),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showAddTimeBlockDialog() {
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(
      hour: (startTime.hour + 1) % 24,
      minute: startTime.minute,
    );
    String title = '';
    TimeBlockType type = TimeBlockType.work;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Time Block',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'What will you work on?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 16),

                  // Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Start'),
                          subtitle: Text(_formatTime(startTime)),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (time != null) {
                              setSheetState(() => startTime = time);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('End'),
                          subtitle: Text(_formatTime(endTime)),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (time != null) {
                              setSheetState(() => endTime = time);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Type selector
                  const Text('Type:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TimeBlockType.values.map((t) {
                      final isSelected = type == t;
                      final block = TimeBlock(
                        id: '',
                        startTime: startTime,
                        endTime: endTime,
                        title: '',
                        type: t,
                      );
                      return ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(block.icon, size: 16),
                            const SizedBox(width: 4),
                            Text(t.name),
                          ],
                        ),
                        onSelected: (_) {
                          setSheetState(() => type = t);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: title.isNotEmpty
                          ? () async {
                              final block = TimeBlock(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                startTime: startTime,
                                endTime: endTime,
                                title: title,
                                type: type,
                              );
                              await _planningService.addTimeBlock(block);
                              if (mounted) Navigator.pop(context);
                            }
                          : null,
                      child: const Text('Add Block'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getEnergyEmoji(int level) {
    switch (level) {
      case 1:
        return '😴';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '🔥';
      default:
        return '🙂';
    }
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 1:
        return 'Running on Empty';
      case 2:
        return 'Low Energy';
      case 3:
        return 'Average';
      case 4:
        return 'Feeling Good';
      case 5:
        return 'Peak Energy!';
      default:
        return 'Average';
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() async {
    // Save current step data
    switch (_currentStep) {
      case 0:
        if (_intentionController.text.isNotEmpty) {
          await _planningService.setMorningIntention(_intentionController.text);
        }
        break;
      case 1:
        final priorities = _priorityControllers
            .map((c) => c.text)
            .where((t) => t.isNotEmpty)
            .toList();
        await _planningService.setTopPriorities(priorities);
        break;
      case 2:
        await _planningService.setEnergyLevel(_energyLevel);
        if (_focusArea != null) {
          await _planningService.setFocusArea(_focusArea);
        }
        break;
      case 3:
        // Complete and exit
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Daily plan created! Have a productive day!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
    }

    // Move to next step
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
