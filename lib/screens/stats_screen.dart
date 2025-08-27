import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/quiz_state.dart';

class StatsScreen extends StatelessWidget {
      const StatsScreen({Key? key}) : super(key: key);

      @override
      Widget build(BuildContext context) {
            return Scaffold(
                  appBar: AppBar(
                        title: const Text('📊 Statistics'),
                        backgroundColor: Theme.of(context).primaryColor,
                  ),
                  body: Consumer<QuizState>(
                        builder: (context, quizState, _) {
                              final wrongWords = quizState.getWrongWordsStats();
                              final totalWords = quizState.allWords.length;
                              final totalMistakes = wrongWords.fold<int>(0, (sum, w) => sum + w.count);
                              final accuracyRate = totalWords == 0
                                  ? 100
                                  : ((totalWords - wrongWords.length) / totalWords * 100).clamp(0, 100);

                              return SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                                // Summary cards row #1
                                                Row(children: [
                                                      Expanded(child: _StatCard(
                                                            title: 'Total Words',
                                                            value: totalWords.toString(),
                                                            color: Colors.blue,
                                                            icon: Icons.book,
                                                      )),
                                                      const SizedBox(width: 12),
                                                      Expanded(child: _StatCard(
                                                            title: 'Wrong Words',
                                                            value: wrongWords.length.toString(),
                                                            color: Colors.red,
                                                            icon: Icons.error_outline,
                                                      )),
                                                ]),
                                                const SizedBox(height: 16),
                                                // Summary cards row #2
                                                Row(children: [
                                                      Expanded(child: _StatCard(
                                                            title: 'Total Mistakes',
                                                            value: totalMistakes.toString(),
                                                            color: Colors.orange,
                                                            icon: Icons.trending_down,
                                                      )),
                                                      const SizedBox(width: 12),
                                                      Expanded(child: _StatCard(
                                                            title: 'Accuracy Rate',
                                                            value: '${accuracyRate.toStringAsFixed(1)}%',
                                                            color: Colors.green,
                                                            icon: Icons.trending_up,
                                                      )),
                                                ]),
                                                const SizedBox(height: 24),

                                                // Top 10 bar chart
                                                if (wrongWords.isNotEmpty) ...[
                                                      Card(
                                                            child: Padding(
                                                                  padding: const EdgeInsets.all(16),
                                                                  child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                              const Text(
                                                                                    'Top 10 Most Difficult Words',
                                                                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                                              ),
                                                                              const SizedBox(height: 16),
                                                                              SizedBox(
                                                                                    height: 300,
                                                                                    child: BarChart(
                                                                                          BarChartData(
                                                                                                maxY: wrongWords.first.count.toDouble() + 1,
                                                                                                titlesData: FlTitlesData(
                                                                                                      leftTitles: AxisTitles(
                                                                                                            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                                                                                                      ),
                                                                                                      bottomTitles: AxisTitles(
                                                                                                            sideTitles: SideTitles(
                                                                                                                  showTitles: true,
                                                                                                                  getTitlesWidget: (value, meta) {
                                                                                                                        final i = value.toInt();
                                                                                                                        if (i >= 0 && i < wrongWords.length && i < 10) {
                                                                                                                              return Padding(
                                                                                                                                    padding: const EdgeInsets.only(top: 8),
                                                                                                                                    child: Text(
                                                                                                                                          wrongWords[i].word,
                                                                                                                                          style: const TextStyle(fontSize: 10),
                                                                                                                                    ),
                                                                                                                              );
                                                                                                                        }
                                                                                                                        return const Text('');
                                                                                                                  },
                                                                                                            ),
                                                                                                      ),
                                                                                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                                                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                                                                ),
                                                                                                borderData: FlBorderData(show: false),
                                                                                                gridData: FlGridData(show: true),
                                                                                                barGroups: wrongWords
                                                                                                    .take(10)
                                                                                                    .toList()
                                                                                                    .asMap()
                                                                                                    .entries
                                                                                                    .map((e) {
                                                                                                      return BarChartGroupData(
                                                                                                            x: e.key,
                                                                                                            barRods: [
                                                                                                                  BarChartRodData(
                                                                                                                        toY: e.value.count.toDouble(),
                                                                                                                        color: Colors.red.shade400,
                                                                                                                        width: 20,
                                                                                                                        borderRadius: const BorderRadius.only(
                                                                                                                              topLeft: Radius.circular(4),
                                                                                                                              topRight: Radius.circular(4),
                                                                                                                        ),
                                                                                                                  ),
                                                                                                            ],
                                                                                                      );
                                                                                                }).toList(),
                                                                                          ),
                                                                                    ),
                                                                              ),
                                                                        ],
                                                                  ),
                                                            ),
                                                      ),
                                                      const SizedBox(height: 16),
                                                ],

                                                // Detailed stats table
                                                Card(
                                                      child: Padding(
                                                            padding: const EdgeInsets.all(16),
                                                            child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                        const Text(
                                                                              'Detailed Statistics',
                                                                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                                        ),
                                                                        const SizedBox(height: 16),
                                                                        if (wrongWords.isEmpty)
                                                                              const Center(
                                                                                    child: Padding(
                                                                                          padding: EdgeInsets.all(32),
                                                                                          child: Column(
                                                                                                children: [
                                                                                                      Icon(Icons.emoji_events, size: 48, color: Colors.green),
                                                                                                      SizedBox(height: 16),
                                                                                                      Text(
                                                                                                            'Perfect Score!',
                                                                                                            style: TextStyle(
                                                                                                                  fontSize: 18,
                                                                                                                  fontWeight: FontWeight.bold,
                                                                                                                  color: Colors.green,
                                                                                                            ),
                                                                                                      ),
                                                                                                      Text(
                                                                                                            'No mistakes recorded yet.',
                                                                                                            style: TextStyle(color: Colors.grey),
                                                                                                      ),
                                                                                                ],
                                                                                          ),
                                                                                    ),
                                                                              )
                                                                        else
                                                                              Table(
                                                                                    border: TableBorder.all(color: Colors.grey.shade300),
                                                                                    children: [
                                                                                          TableRow(
                                                                                                decoration: BoxDecoration(color: Colors.grey.shade100),
                                                                                                children: const [
                                                                                                      Padding(
                                                                                                            padding: EdgeInsets.all(12),
                                                                                                            child: Text('Word', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                                                      ),
                                                                                                      Padding(
                                                                                                            padding: EdgeInsets.all(12),
                                                                                                            child: Text('Mistakes', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                                                      ),
                                                                                                ],
                                                                                          ),
                                                                                          ...wrongWords.map((w) {
                                                                                                return TableRow(children: [
                                                                                                      Padding(
                                                                                                            padding: const EdgeInsets.all(12),
                                                                                                            child: Text(w.word),
                                                                                                      ),
                                                                                                      Padding(
                                                                                                            padding: const EdgeInsets.all(12),
                                                                                                            child: Text(
                                                                                                                  w.count.toString(),
                                                                                                                  style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
                                                                                                            ),
                                                                                                      ),
                                                                                                ]);
                                                                                          }).toList(),
                                                                                    ],
                                                                              ),
                                                                  ],
                                                            ),
                                                      ),
                                                ),
                                          ],
                                    ),
                              );
                        },
                  ),
            );
      }
}

class _StatCard extends StatelessWidget {
      final String title;
      final String value;
      final Color color;
      final IconData icon;

      const _StatCard({
            Key? key,
            required this.title,
            required this.value,
            required this.color,
            required this.icon,
      }) : super(key: key);

      @override
      Widget build(BuildContext context) {
            return Card(
                  child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                              children: [
                                    Icon(icon, size: 32, color: color),
                                    const SizedBox(height: 8),
                                    Text(
                                          value,
                                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                                    ),
                                    Text(
                                          title,
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                              ],
                        ),
                  ),
            );
      }
}
