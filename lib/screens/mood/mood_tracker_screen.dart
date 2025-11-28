import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:check_bird/models/mood/mood_entry.dart';
import 'package:check_bird/services/mood_service.dart';

/// Screen for mood tracking and insights
class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MoodService _moodService = MoodService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _moodService.initialize();
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
        title: const Text('Mood Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'Insights', icon: Icon(Icons.insights)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTab(moodService: _moodService),
          _InsightsTab(moodService: _moodService),
        ],
      ),
    );
  }
}

/// Today's mood logging tab
class _TodayTab extends StatefulWidget {
  final MoodService moodService;

  const _TodayTab({required this.moodService});

  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  MoodLevel? _selectedMood;
  EnergyLevel? _selectedEnergy;
  final Set<String> _selectedFactors = {};
  final _noteController = TextEditingController();
  bool _isLoading = false;
  MoodEntry? _todayEntry;

  @override
  void initState() {
    super.initState();
    _loadTodayEntry();
  }

  void _loadTodayEntry() {
    final entry = widget.moodService.getTodayEntry();
    if (entry != null) {
      setState(() {
        _todayEntry = entry;
        _selectedMood = entry.mood;
        _selectedEnergy = entry.energy;
        _selectedFactors.addAll(entry.factors);
        _noteController.text = entry.note ?? '';
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null || _selectedEnergy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both mood and energy')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_todayEntry == null) {
        await widget.moodService.logMood(
          mood: _selectedMood!,
          energy: _selectedEnergy!,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          factors: _selectedFactors.toList(),
        );
      } else {
        await widget.moodService.updateTodayMood(
          mood: _selectedMood,
          energy: _selectedEnergy,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          factors: _selectedFactors.toList(),
        );
      }

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(_todayEntry == null ? 'Mood logged!' : 'Mood updated!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadTodayEntry();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.moodService.getMoodLogStreak();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak badge
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$streak day streak!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Mood selection
          Text(
            'How are you feeling?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildMoodSelector(),

          const SizedBox(height: 24),

          // Energy selection
          Text(
            'What\'s your energy level?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildEnergySelector(),

          const SizedBox(height: 24),

          // Factors
          Text(
            'What affected your mood?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          _buildFactorSelector(),

          const SizedBox(height: 24),

          // Note
          Text(
            'Any notes? (optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'How was your day? What\'s on your mind?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveMood,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _todayEntry == null ? 'Log Mood' : 'Update Mood',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MoodLevel.values.map((mood) {
        final isSelected = _selectedMood == mood;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedMood = mood);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? mood.color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? mood.color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  mood.emoji,
                  style: TextStyle(fontSize: isSelected ? 36 : 28),
                ),
                const SizedBox(height: 4),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? mood.color : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnergySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: EnergyLevel.values.map((energy) {
        final isSelected = _selectedEnergy == energy;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedEnergy = energy);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? energy.color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? energy.color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  energy.emoji,
                  style: TextStyle(fontSize: isSelected ? 32 : 24),
                ),
                const SizedBox(height: 4),
                Text(
                  energy.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? energy.color : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFactorSelector() {
    final positiveFactors =
        MoodFactor.allFactors.where((f) => f.isPositive).toList();
    final negativeFactors =
        MoodFactor.allFactors.where((f) => !f.isPositive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Positive',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: positiveFactors.map((factor) {
            final isSelected = _selectedFactors.contains(factor.id);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(factor.emoji),
                  const SizedBox(width: 4),
                  Text(factor.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) {
                    _selectedFactors.add(factor.id);
                  } else {
                    _selectedFactors.remove(factor.id);
                  }
                });
              },
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green.shade700,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Challenges',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: negativeFactors.map((factor) {
            final isSelected = _selectedFactors.contains(factor.id);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(factor.emoji),
                  const SizedBox(width: 4),
                  Text(factor.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) {
                    _selectedFactors.add(factor.id);
                  } else {
                    _selectedFactors.remove(factor.id);
                  }
                });
              },
              selectedColor: Colors.orange.shade100,
              checkmarkColor: Colors.orange.shade700,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Insights and history tab
class _InsightsTab extends StatelessWidget {
  final MoodService moodService;

  const _InsightsTab({required this.moodService});

  @override
  Widget build(BuildContext context) {
    final insights = moodService.getMoodInsights();
    final weekSummary = moodService.getWeeklySummary();
    final last7Days = moodService.getLastNDays(7);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly summary card
          _buildWeeklySummaryCard(context, weekSummary),

          const SizedBox(height: 24),

          // Mood chart for last 7 days
          Text(
            'Last 7 Days',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildMoodChart(context, last7Days),

          const SizedBox(height: 24),

          // Insights
          Text(
            'Insights',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => _buildInsightCard(context, insight)),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard(
      BuildContext context, MoodWeeklySummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Avg Mood',
                    summary.averageMood > 0
                        ? MoodLevelExtension.fromValue(
                                summary.averageMood.round())
                            .emoji
                        : '—',
                    summary.averageMood.toStringAsFixed(1),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Avg Energy',
                    summary.averageEnergy > 0
                        ? EnergyLevelExtension.fromValue(
                                summary.averageEnergy.round())
                            .emoji
                        : '—',
                    summary.averageEnergy.toStringAsFixed(1),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Entries',
                    '📝',
                    '${summary.totalEntries}/7',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String label, String emoji, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodChart(BuildContext context, List<MoodEntry> entries) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateTime(date.year, date.month, date.day);
    });

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((date) {
          final entry = entries.cast<MoodEntry?>().firstWhere(
                (e) =>
                    e != null &&
                    e.date.year == date.year &&
                    e.date.month == date.month &&
                    e.date.day == date.day,
                orElse: () => null,
              );

          final dayName = [
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun'
          ][date.weekday - 1];
          final isToday = date.day == now.day && date.month == now.month;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (entry != null) ...[
                Text(entry.mood.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: (entry.mood.value / 5) * 40,
                  decoration: BoxDecoration(
                    color: entry.mood.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ] else ...[
                const Text('—',
                    style: TextStyle(fontSize: 24, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, String insight) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small widget to show mood check-in prompt
class MoodCheckInPrompt extends StatelessWidget {
  final VoidCallback onTap;

  const MoodCheckInPrompt({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final moodService = MoodService();
    final hasLogged = moodService.hasLoggedToday();

    if (hasLogged) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade100,
            Colors.blue.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🌈', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Tap to log your mood',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
