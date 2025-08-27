
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/enhanced_quiz_state.dart';
import '../models/spaced_word_pair.dart';

class EnhancedStatsScreen extends StatefulWidget {
  const EnhancedStatsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedStatsScreen> createState() => _EnhancedStatsScreenState();
}

class _EnhancedStatsScreenState extends State<EnhancedStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTimeRange = 30; // days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('📊 Advanced Statistics'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Retention'),
            Tab(text: 'Performance'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: Consumer<EnhancedQuizState>(
        builder: (context, quizState, child) {
          final analytics = quizState.getDetailedAnalytics();
          final stats = analytics['basicStats'] as StudyStats;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(stats, analytics),
              _buildRetentionTab(quizState, stats),
              _buildPerformanceTab(quizState, analytics),
              _buildInsightsTab(analytics, quizState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(StudyStats stats, Map<String, dynamic> analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Total Cards',
                stats.totalCards.toString(),
                Icons.library_books,
                Colors.blue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Due Today',
                stats.dueToday.toString(),
                Icons.schedule,
                stats.dueToday > 50 ? Colors.orange : Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Retention',
                '${(stats.retention * 100).toStringAsFixed(1)}%',
                Icons.trending_up,
                _getRetentionColor(stats.retention),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Study Streak',
                '${analytics['studyStreak']} days',
                Icons.local_fire_department,
                Colors.deepOrange,
              )),
            ],
          ),

          const SizedBox(height: 24),

          // Card Distribution
          _buildSectionHeader('Card Distribution'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDistributionRow('New Cards', stats.newCards, stats.totalCards, Colors.blue),
                  _buildDistributionRow('Learning', stats.learningCards, stats.totalCards, Colors.orange),
                  _buildDistributionRow('Review', stats.reviewCards, stats.totalCards, Colors.green),
                  _buildDistributionRow('Suspended', stats.suspendedCards, stats.totalCards, Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Difficulty Distribution Pie Chart
          _buildSectionHeader('Difficulty Distribution'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _buildDifficultyPieChart(analytics['difficultyDistribution']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionTab(EnhancedQuizState quizState, StudyStats stats) {
    final retentionData = quizState.getRetentionCurve(_selectedTimeRange);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Range Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeRangeButton(7),
              _buildTimeRangeButton(30),
              _buildTimeRangeButton(90),
              _buildTimeRangeButton(365),
            ],
          ),

          const SizedBox(height: 24),

          // Retention Curve
          _buildSectionHeader('Forgetting Curve Prediction'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: _buildRetentionChart(retentionData),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Shows predicted retention over $_selectedTimeRange days based on current memory strength',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Retention Stats
          _buildSectionHeader('Retention Statistics'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Current Retention',
                '${(stats.retention * 100).toStringAsFixed(1)}%',
                Icons.psychology,
                _getRetentionColor(stats.retention),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Avg Interval',
                '${stats.averageInterval.toStringAsFixed(1)} days',
                Icons.access_time,
                Colors.purple,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(EnhancedQuizState quizState, Map<String, dynamic> analytics) {
    final workload = analytics['predictedWorkload'] as List<int>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Performance
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Recent Accuracy',
                '${(analytics['recentAccuracy'] * 100).toStringAsFixed(1)}%',
                Icons.target,
                _getAccuracyColor(analytics['recentAccuracy']),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Avg Response Time',
                '${(analytics['averageResponseTime'] / 1000).toStringAsFixed(1)}s',
                Icons.speed,
                Colors.indigo,
              )),
            ],
          ),

          const SizedBox(height: 24),

          // Upcoming Workload
          _buildSectionHeader('30-Day Workload Forecast'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: _buildWorkloadChart(workload),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Predicted daily review load based on current scheduling',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Maturity Distribution
          _buildSectionHeader('Card Maturity Levels'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _buildMaturityChart(analytics['maturityDistribution']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(Map<String, dynamic> analytics, EnhancedQuizState quizState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Insights
          _buildSectionHeader('Key Insights'),
          const SizedBox(height: 16),

          ..._generateInsights(analytics).map((insight) => Card(
            child: ListTile(
              leading: Icon(insight.icon, color: insight.color),
              title: Text(insight.title),
              subtitle: Text(insight.description),
            ),
          )),

          const SizedBox(height: 24),

          // Learning Recommendations
          _buildSectionHeader('Recommendations'),
          const SizedBox(height: 16),

          ..._generateRecommendations(analytics).map((rec) => Card(
            color: rec.priority == 'high' ? Colors.red.shade50 :
            rec.priority == 'medium' ? Colors.orange.shade50 : Colors.blue.shade50,
            child: ListTile(
              leading: Icon(
                rec.priority == 'high' ? Icons.priority_high :
                rec.priority == 'medium' ? Icons.warning : Icons.info,
                color: rec.priority == 'high' ? Colors.red :
                rec.priority == 'medium' ? Colors.orange : Colors.blue,
              ),
              title: Text(rec.title),
              subtitle: Text(rec.description),
            ),
          )),

          const SizedBox(height: 24),

          // Study Settings Quick Access
          _buildSectionHeader('Quick Settings'),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('New Cards Per Day'),
                  subtitle: Text('${quizState.srService.newCardsPerDay} cards'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showNewCardsDialog(context, quizState),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Desired Retention'),
                  subtitle: Text('${(quizState.srService.desiredRetention * 100).toStringAsFixed(0)}%'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showRetentionDialog(context, quizState),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Algorithm'),
                  subtitle: Text(quizState.srService.algorithmType),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showAlgorithmDialog(context, quizState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDistributionRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$count (${percentage.toStringAsFixed(1)}%)'),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(int days) {
    final isSelected = _selectedTimeRange == days;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTimeRange = days;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text('${days}d'),
    );
  }

  Widget _buildDifficultyPieChart(Map<String, int> difficultyData) {
    if (difficultyData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final sections = difficultyData.entries.map((entry) {
      final colors = {
        'Easy': Colors.green,
        'Medium': Colors.orange,
        'Hard': Colors.red,
        'Very Hard': Colors.deepPurple,
      };

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: entry.key,
        color: colors[entry.key] ?? Colors.grey,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    return PieChart(PieChartData(sections: sections));
  }

  Widget _buildRetentionChart(List<RetentionPoint> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No retention data available'));
    }

    final spots = data.map((point) => FlSpot(
      point.days.toDouble(),
      point.retention * 100,
    )).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}d'),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }

  Widget _buildWorkloadChart(List<int> workload) {
    final spots = workload.asMap().entries.map((entry) => FlSpot(
      entry.key.toDouble(),
      entry.value.toDouble(),
    )).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.orange,
            barWidth: 2,
          ),
        ],
        minY: 0,
      ),
    );
  }

  Widget _buildMaturityChart(Map<String, int> maturityData) {
    if (maturityData.isEmpty) {
      return const Center(child: Text('No maturity data available'));
    }

    final barGroups = maturityData.entries.asMap().entries.map((entry) {
      final colors = {
        'Young': Colors.red,
        'Mature': Colors.orange,
        'Mastered': Colors.green,
      };

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: colors[entry.value.key] ?? Colors.grey,
            width: 40,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final labels = maturityData.keys.toList();
                if (value.toInt() < labels.length) {
                  return Text(labels[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  Color _getRetentionColor(double retention) {
    if (retention >= 0.9) return Colors.green;
    if (retention >= 0.8) return Colors.orange;
    return Colors.red;
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.85) return Colors.green;
    if (accuracy >= 0.7) return Colors.orange;
    return Colors.red;
  }

  List<InsightItem> _generateInsights(Map<String, dynamic> analytics) {
    final insights = <InsightItem>[];
    final stats = analytics['basicStats'] as StudyStats;

    if (stats.retention > 0.9) {
      insights.add(InsightItem(
        icon: Icons.emoji_events,
        color: Colors.green,
        title: 'Excellent Retention!',
        description: 'Your retention rate is above 90%. Great job!',
      ));
    }

    if (analytics['studyStreak'] >= 7) {
      insights.add(InsightItem(
        icon: Icons.local_fire_department,
        color: Colors.orange,
        title: 'Study Streak',
        description: 'You\'ve studied for ${analytics['studyStreak']} consecutive days!',
      ));
    }

    if (stats.overdueCards > 20) {
      insights.add(InsightItem(
        icon: Icons.warning,
        color: Colors.red,
        title: 'Overdue Cards',
        description: 'You have ${stats.overdueCards} overdue cards. Consider a review session.',
      ));
    }

    return insights;
  }

  List<RecommendationItem> _generateRecommendations(Map<String, dynamic> analytics) {
    final recommendations = <RecommendationItem>[];
    final stats = analytics['basicStats'] as StudyStats;

    if (stats.retention < 0.8) {
      recommendations.add(RecommendationItem(
        priority: 'high',
        title: 'Improve Retention',
        description: 'Consider reducing daily new cards or increasing review frequency.',
      ));
    }

    if (stats.overdueCards > stats.dueToday * 2) {
      recommendations.add(RecommendationItem(
        priority: 'medium',
        title: 'Clear Overdue Backlog',
        description: 'Focus on overdue cards before learning new ones.',
      ));
    }

    if (analytics['averageResponseTime'] > 5000) {
      recommendations.add(RecommendationItem(
        priority: 'low',
        title: 'Speed Up Reviews',
        description: 'Try to answer more quickly to improve study efficiency.',
      ));
    }

    return recommendations;
  }

  void _showNewCardsDialog(BuildContext context, EnhancedQuizState quizState) {
    // Implementation for new cards dialog
  }

  void _showRetentionDialog(BuildContext context, EnhancedQuizState quizState) {
    // Implementation for retention dialog
  }

  void _showAlgorithmDialog(BuildContext context, EnhancedQuizState quizState) {
    // Implementation for algorithm selection dialog
  }
}

class InsightItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  InsightItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class RecommendationItem {
  final String priority;
  final String title;
  final String description;

  RecommendationItem({
    required this.priority,
    required this.title,
    required this.description,
  });
}
