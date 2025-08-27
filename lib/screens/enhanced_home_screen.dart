
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_quiz_state.dart';
import '../models/spaced_word_pair.dart';


class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showQuickStats = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final quizState = Provider.of<EnhancedQuizState>(context, listen: false);
    await quizState.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Syno SRS'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showQuickStats ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showQuickStats = !_showQuickStats;
              });
            },
            tooltip: 'Toggle Quick Stats',
          ),
        ],
      ),
      body: Consumer<EnhancedQuizState>(
        builder: (context, quizState, child) {
          final stats = quizState.getStudyStats();

          return RefreshIndicator(
            onRefresh: () async {
              await quizState.initialize();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showQuickStats) ...[
                    _buildQuickStatsSection(stats),
                    const SizedBox(height: 24),
                  ],

                  _buildStudyModesSection(quizState, stats),
                  const SizedBox(height: 24),

                  _buildTodayOverviewSection(stats, quizState),
                  const SizedBox(height: 24),

                  _buildQuickActionsSection(quizState),
                  const SizedBox(height: 24),

                  _buildProgressSection(stats, quizState),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStudyModeDialog(context),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Study'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildQuickStatsSection(StudyStats stats) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          )),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quick Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildRetentionBadge(stats.retention),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildQuickStatItem(
                        'Due Today',
                        stats.dueToday.toString(),
                        Icons.schedule,
                        _getDueCountColor(stats.dueToday),
                      )),
                      Expanded(child: _buildQuickStatItem(
                        'New Cards',
                        stats.newCards.toString(),
                        Icons.fiber_new,
                        Colors.blue,
                      )),
                      Expanded(child: _buildQuickStatItem(
                        'Learning',
                        stats.learningCards.toString(),
                        Icons.school,
                        Colors.orange,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudyModesSection(EnhancedQuizState quizState, StudyStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Study Modes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildStudyModeCard(
              'Review',
              '${stats.dueToday} due',
              Icons.refresh,
              Colors.green,
              stats.dueToday > 0,
                  () => _startReviewSession(context, quizState),
            ),
            _buildStudyModeCard(
              'Learn New',
              '${stats.newCards} available',
              Icons.add_circle,
              Colors.blue,
              stats.newCards > 0,
                  () => _startLearningSession(context, quizState),
            ),
            _buildStudyModeCard(
              'Mixed Study',
              'Review + New',
              Icons.shuffle,
              Colors.purple,
              stats.dueToday > 0 || stats.newCards > 0,
                  () => _startMixedSession(context, quizState),
            ),
            _buildStudyModeCard(
              'Practice Failed',
              '${quizState.getFailedCards().length} cards',
              Icons.error_outline,
              Colors.red,
              quizState.getFailedCards().isNotEmpty,
                  () => _startFailedSession(context, quizState),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayOverviewSection(StudyStats stats, EnhancedQuizState quizState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Today\'s Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Progress bars for different card types
            _buildProgressRow('Due Cards Completed', 0.7, Colors.green),
            const SizedBox(height: 8),
            _buildProgressRow('New Cards Learned', 0.4, Colors.blue),
            const SizedBox(height: 8),
            _buildProgressRow('Overall Study Goal', 0.6, Colors.purple),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTodayStatChip('Study Time', '23m', Icons.access_time),
                _buildTodayStatChip('Cards Studied', '47', Icons.library_books),
                _buildTodayStatChip('Accuracy', '89%', Icons.target),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(EnhancedQuizState quizState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add Words'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/enhanced_stats'),
                icon: const Icon(Icons.analytics),
                label: const Text('Analytics'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showSettingsDialog(context, quizState),
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportData(quizState),
                icon: const Icon(Icons.download),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection(StudyStats stats, EnhancedQuizState quizState) {
    final analytics = quizState.getDetailedAnalytics();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📈 Learning Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/enhanced_stats'),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Circular progress indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularProgress(
                  'Retention',
                  stats.retention,
                  '${(stats.retention * 100).toStringAsFixed(0)}%',
                  _getRetentionColor(stats.retention),
                ),
                _buildCircularProgress(
                  'Mastery',
                  stats.reviewCards / stats.totalCards,
                  '${((stats.reviewCards / stats.totalCards) * 100).toStringAsFixed(0)}%',
                  Colors.purple,
                ),
                _buildCircularProgress(
                  'Study Streak',
                  (analytics['studyStreak'] as int) / 30,
                  '${analytics['studyStreak']}d',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRetentionBadge(double retention) {
    String label;
    Color color;

    if (retention >= 0.9) {
      label = 'Excellent';
      color = Colors.green;
    } else if (retention >= 0.8) {
      label = 'Good';
      color = Colors.orange;
    } else {
      label = 'Needs Work';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStudyModeCard(String title, String subtitle, IconData icon,
      Color color, bool enabled, VoidCallback onTap) {
    return Card(
      elevation: enabled ? 4 : 1,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: enabled ? color : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.black87 : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildTodayStatChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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

  Widget _buildCircularProgress(String label, double progress, String text, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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

  Color _getDueCountColor(int dueCount) {
    if (dueCount == 0) return Colors.green;
    if (dueCount <= 20) return Colors.orange;
    return Colors.red;
  }

  Color _getRetentionColor(double retention) {
    if (retention >= 0.9) return Colors.green;
    if (retention >= 0.8) return Colors.orange;
    return Colors.red;
  }

  void _startReviewSession(BuildContext context, EnhancedQuizState quizState) async {
    await quizState.startReviewSession();
    if (quizState.currentQuiz.isNotEmpty) {
      Navigator.pushNamed(context, '/enhanced_quiz');
    } else {
      _showNoCardsDialog(context, 'No cards are due for review right now!');
    }
  }

  void _startLearningSession(BuildContext context, EnhancedQuizState quizState) async {
    await quizState.startLearningSession();
    if (quizState.currentQuiz.isNotEmpty) {
      Navigator.pushNamed(context, '/enhanced_quiz');
    } else {
      _showNoCardsDialog(context, 'No new cards available to learn!');
    }
  }

  void _startMixedSession(BuildContext context, EnhancedQuizState quizState) async {
    await quizState.startSpacedRepetitionSession();
    if (quizState.currentQuiz.isNotEmpty) {
      Navigator.pushNamed(context, '/enhanced_quiz');
    } else {
      _showNoCardsDialog(context, 'No cards available for study right now!');
    }
  }

  void _startFailedSession(BuildContext context, EnhancedQuizState quizState) async {
    await quizState.startFailedCardsSession();
    if (quizState.currentQuiz.isNotEmpty) {
      Navigator.pushNamed(context, '/enhanced_quiz');
    } else {
      _showNoCardsDialog(context, 'No recently failed cards to practice!');
    }
  }

  void _showStudyModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Study Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.green),
                title: const Text('Review Due Cards'),
                subtitle: const Text('Study cards that are due for review'),
                onTap: () {
                  Navigator.pop(context);
                  _startReviewSession(context, Provider.of<EnhancedQuizState>(context, listen: false));
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.blue),
                title: const Text('Learn New Cards'),
                subtitle: const Text('Study new vocabulary'),
                onTap: () {
                  Navigator.pop(context);
                  _startLearningSession(context, Provider.of<EnhancedQuizState>(context, listen: false));
                },
              ),
              ListTile(
                leading: const Icon(Icons.shuffle, color: Colors.purple),
                title: const Text('Mixed Study'),
                subtitle: const Text('Combination of new and due cards'),
                onTap: () {
                  Navigator.pop(context);
                  _startMixedSession(context, Provider.of<EnhancedQuizState>(context, listen: false));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNoCardsDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Cards Available'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context, EnhancedQuizState quizState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Study Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('New Cards Per Day'),
                subtitle: Text('${quizState.srService.newCardsPerDay} cards'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // Implementation for editing new cards per day
                },
              ),
              ListTile(
                title: const Text('Algorithm'),
                subtitle: Text(quizState.srService.algorithmType),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // Implementation for changing algorithm
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _exportData(EnhancedQuizState quizState) {
    // Implementation for exporting study data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
      ),
    );
  }
}
