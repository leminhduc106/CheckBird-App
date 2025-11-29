import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:check_bird/services/planning_service.dart';

class EveningReviewScreen extends StatefulWidget {
  const EveningReviewScreen({super.key});

  @override
  State<EveningReviewScreen> createState() => _EveningReviewScreenState();
}

class _EveningReviewScreenState extends State<EveningReviewScreen> {
  final PlanningService _planningService = PlanningService();
  final _reflectionController = TextEditingController();
  final List<TextEditingController> _gratitudeControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  int _dayRating = 3;
  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    try {
      await _planningService.initialize().timeout(
            const Duration(seconds: 5),
            onTimeout: () {},
          );
    } catch (e) {
      debugPrint('Error initializing: $e');
    }
    _loadExistingData();
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadExistingData() {
    final plan = _planningService.todaysPlan;
    if (plan != null) {
      _reflectionController.text = plan.eveningReflection ?? '';
      _dayRating = plan.dayRating > 0 ? plan.dayRating : 3;
      for (int i = 0; i < plan.gratitudeItems.length && i < 3; i++) {
        _gratitudeControllers[i].text = plan.gratitudeItems[i];
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reflectionController.dispose();
    for (var c in _gratitudeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                          value: (_currentStep + 1) / 3,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
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
                  _buildDayRatingStep(),
                  _buildGratitudeStep(),
                  _buildReflectionStep(),
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
                        onPressed: _isSaving ? null : _previousStep,
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _nextStep,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep == 2
                                  ? 'Complete Review'
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
        return '⭐ Rate Your Day';
      case 1:
        return '🙏 Gratitude';
      case 2:
        return '📝 Reflection';
      default:
        return 'Evening Review';
    }
  }

  Widget _buildDayRatingStep() {
    final theme = Theme.of(context);
    final plan = _planningService.todaysPlan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your day?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rate your overall satisfaction with today.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),

          // Day rating
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = _dayRating >= rating;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _dayRating = rating);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AnimatedScale(
                      scale: isSelected ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isSelected
                            ? Colors.amber
                            : theme.colorScheme.outline,
                        size: 48,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              _getRatingLabel(_dayRating),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getRatingColor(_dayRating),
              ),
            ),
          ),

          // Show today's accomplishments
          if (plan != null && plan.topPriorities.isNotEmpty) ...[
            const SizedBox(height: 48),
            Text(
              '📋 Today\'s Priorities',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...plan.topPriorities.map((priority) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(priority),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Show completed time blocks
          if (plan != null && plan.timeBlocks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '⏰ Time Blocks Completed',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${plan.timeBlocks.where((b) => b.completed).length} / ${plan.timeBlocks.length} completed',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGratitudeStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you grateful for today?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'List 3 things that made today meaningful.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _gratitudeControllers[index],
                      decoration: InputDecoration(
                        hintText: _getGratitudeHint(index),
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Research shows gratitude practice improves well-being and sleep quality.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.purple.shade900,
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

  Widget _buildReflectionStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reflect on your day',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What did you learn? What would you do differently?',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _reflectionController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Write your thoughts here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '💡 Reflection prompts:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPromptChip('What went well?'),
              _buildPromptChip('What was challenging?'),
              _buildPromptChip('What did I learn?'),
              _buildPromptChip('What\'s one win today?'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return ActionChip(
      label: Text(
        prompt,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () {
        if (_reflectionController.text.isNotEmpty) {
          _reflectionController.text += '\n\n$prompt\n';
        } else {
          _reflectionController.text = '$prompt\n';
        }
        _reflectionController.selection = TextSelection.fromPosition(
          TextPosition(offset: _reflectionController.text.length),
        );
      },
    );
  }

  String _getGratitudeHint(int index) {
    switch (index) {
      case 0:
        return 'e.g., A helpful colleague';
      case 1:
        return 'e.g., A moment of peace';
      case 2:
        return 'e.g., Something I accomplished';
      default:
        return 'Something you\'re grateful for';
    }
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Rough Day 😔';
      case 2:
        return 'Could Be Better';
      case 3:
        return 'Okay Day';
      case 4:
        return 'Good Day! 😊';
      case 5:
        return 'Amazing Day! 🌟';
      default:
        return 'Okay Day';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red.shade600;
      case 2:
        return Colors.orange.shade600;
      case 3:
        return Colors.grey.shade600;
      case 4:
        return Colors.green.shade600;
      case 5:
        return Colors.amber.shade600;
      default:
        return Colors.grey.shade600;
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
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      switch (_currentStep) {
        case 0:
          // Just save rating locally, will commit at end
          break;
        case 1:
          // Save gratitude items
          final items = _gratitudeControllers
              .map((c) => c.text)
              .where((t) => t.isNotEmpty)
              .toList();
          for (final item in items) {
            await _planningService.addGratitudeItem(item);
          }
          break;
        case 2:
          // Complete the evening review
          await _planningService.setEveningReflection(
            _reflectionController.text,
            _dayRating,
          );

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🌙 Evening review complete! Rest well.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
      }

      // Move to next step
      if (_currentStep < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      debugPrint('Error in evening review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
