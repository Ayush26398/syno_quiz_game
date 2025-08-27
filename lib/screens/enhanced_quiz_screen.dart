
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_quiz_state.dart';
import '../models/spaced_word_pair.dart';
import '../widgets/enhanced_option_button.dart';
import '../widgets/enhanced_progress_bar.dart';
import '../widgets/memory_strength_indicator.dart';
import 'dart:async';

class EnhancedQuizScreen extends StatefulWidget {
  const EnhancedQuizScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedQuizScreen> createState() => _EnhancedQuizScreenState();
}

class _EnhancedQuizScreenState extends State<EnhancedQuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _feedbackAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _feedbackAnimation;

  List<String> _options = [];
  String? _selectedAnswer;
  DateTime? _questionStartTime;
  Timer? _responseTimer;
  int _responseTimeMs = 0;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadQuestion();
    _startResponseTimer();
  }

  void _setupAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _feedbackAnimationController.dispose();
    _responseTimer?.cancel();
    super.dispose();
  }

  void _loadQuestion() {
    final quizState = Provider.of<EnhancedQuizState>(context, listen: false);
    if (quizState.currentWord == null) {
      _showResults();
      return;
    }

    setState(() {
      _options = quizState.generateOptions();
      _selectedAnswer = null;
      _showHint = false;
    });

    _cardAnimationController.forward(from: 0);
    _startResponseTimer();
  }

  void _startResponseTimer() {
    _questionStartTime = DateTime.now();
    _responseTimer?.cancel();
    _responseTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_questionStartTime != null) {
        setState(() {
          _responseTimeMs = DateTime.now().difference(_questionStartTime!).inMilliseconds;
        });
      }
    });
  }

  void _selectAnswer(String answer) async {
    if (_selectedAnswer != null) return;

    _responseTimer?.cancel();
    setState(() {
      _selectedAnswer = answer;
    });

    final quizState = Provider.of<EnhancedQuizState>(context, listen: false);
    await quizState.selectAnswer(answer);

    _feedbackAnimationController.forward(from: 0);
  }

  void _nextQuestion() {
    _feedbackAnimationController.reset();
    final quizState = Provider.of<EnhancedQuizState>(context, listen: false);
    quizState.nextQuestion();

    if (quizState.currentWord == null) {
      _showResults();
    } else {
      _loadQuestion();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultsDialog(),
    );
  }

  void _toggleHint() {
    setState(() {
      _showHint = !_showHint;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Quiz'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<EnhancedQuizState>(
            builder: (context, quizState, child) {
              if (quizState.currentWord == null) return const SizedBox();

              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'hint':
                      _toggleHint();
                      break;
                    case 'skip':
                      _nextQuestion();
                      break;
                    case 'suspend':
                      _suspendCard(quizState);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'hint',
                    child: Row(
                      children: [
                        Icon(_showHint ? Icons.visibility_off : Icons.lightbulb_outline),
                        const SizedBox(width: 8),
                        Text(_showHint ? 'Hide Hint' : 'Show Hint'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'skip',
                    child: Row(
                      children: [
                        Icon(Icons.skip_next),
                        SizedBox(width: 8),
                        Text('Skip Card'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'suspend',
                    child: Row(
                      children: [
                        Icon(Icons.pause_circle_outline),
                        SizedBox(width: 8),
                        Text('Suspend Card'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<EnhancedQuizState>(
        builder: (context, quizState, child) {
          if (quizState.currentWord == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Enhanced Progress Section
                  _buildEnhancedProgressSection(quizState),
                  const SizedBox(height: 16),

                  // Memory Information Card
                  _buildMemoryInfoCard(quizState.currentWord!),
                  const SizedBox(height: 16),

                  // Main Question Card
                  Expanded(
                    flex: 2,
                    child: _buildQuestionCard(quizState),
                  ),
                  const SizedBox(height: 16),

                  // Feedback Section
                  if (quizState.hasAnswered) ...[
                    _buildFeedbackSection(quizState),
                    const SizedBox(height: 16),
                  ],

                  // Options Section
                  Expanded(
                    flex: 3,
                    child: _buildOptionsSection(quizState),
                  ),
                  const SizedBox(height: 16),

                  // Action Button
                  _buildActionButton(quizState),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedProgressSection(EnhancedQuizState quizState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${quizState.currentIndex + 1} of ${quizState.currentQuiz.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Accuracy: ${quizState.accuracy.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getAccuracyColor(quizState.accuracy),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            EnhancedProgressBar(
              progress: quizState.progress,
              correctAnswers: quizState.correctAnswers,
              totalAnswers: quizState.totalAnswers,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Response Time: ${(_responseTimeMs / 1000).toStringAsFixed(1)}s',
                  style: TextStyle(
                    color: _getResponseTimeColor(_responseTimeMs),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Study Time: ${_formatDuration(quizState.totalStudyTime)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryInfoCard(SpacedWordPair card) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMemoryStatChip(
                  'Difficulty',
                  card.getDifficultyDescription(),
                  _getDifficultyColor(card.difficulty),
                ),
                _buildMemoryStatChip(
                  'Maturity',
                  card.getMaturityLevel(),
                  _getMaturityColor(card.intervalDays),
                ),
                _buildMemoryStatChip(
                  'Interval',
                  '${card.intervalDays}d',
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 8),
            MemoryStrengthIndicator(
              retrievability: card.getRetrievability(),
              stability: card.stability,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(EnhancedQuizState quizState) {
    return ScaleTransition(
      scale: _cardAnimation,
      child: Card(
        elevation: 8,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Find the synonym for:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  quizState.currentWord!.word.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_showHint) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Hint: Starts with "${quizState.currentWord!.synonym[0].toUpperCase()}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(EnhancedQuizState quizState) {
    return ScaleTransition(
      scale: _feedbackAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: quizState.isCorrect ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: quizState.isCorrect ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  quizState.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: quizState.isCorrect ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quizState.statusMessage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: quizState.isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (!quizState.isCorrect) ...[
              const SizedBox(height: 8),
              _buildGradeButtons(quizState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradeButtons(EnhancedQuizState quizState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildGradeButton('Again', Colors.red, ReviewGrade.again),
        _buildGradeButton('Hard', Colors.orange, ReviewGrade.hard),
        _buildGradeButton('Good', Colors.blue, ReviewGrade.good),
        _buildGradeButton('Easy', Colors.green, ReviewGrade.easy),
      ],
    );
  }

  Widget _buildGradeButton(String label, Color color, ReviewGrade grade) {
    return ElevatedButton(
      onPressed: () {
        // This would allow manual grading for failed cards
        final quizState = Provider.of<EnhancedQuizState>(context, listen: false);
        // Implementation for manual grading
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(60, 30),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildOptionsSection(EnhancedQuizState quizState) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: _options.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrect = quizState.hasAnswered &&
            option == quizState.currentWord!.synonym;
        final isIncorrect = quizState.hasAnswered &&
            isSelected && option != quizState.currentWord!.synonym;

        return EnhancedOptionButton(
          text: option,
          onPressed: () => _selectAnswer(option),
          isSelected: isSelected,
          isCorrect: isCorrect,
          isIncorrect: isIncorrect,
          isDisabled: quizState.hasAnswered,
          responseTime: _responseTimeMs,
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(EnhancedQuizState quizState) {
    if (!quizState.hasAnswered) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _toggleHint,
              icon: Icon(_showHint ? Icons.visibility_off : Icons.lightbulb_outline),
              label: Text(_showHint ? 'Hide Hint' : 'Show Hint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
        child: Text(
          quizState.currentIndex + 1 >= quizState.currentQuiz.length
              ? 'View Results'
              : 'Next Question',
        ),
      ),
    );
  }

  Widget _buildMemoryStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 85) return Colors.green;
    if (accuracy >= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getResponseTimeColor(int timeMs) {
    if (timeMs < 3000) return Colors.green;
    if (timeMs < 8000) return Colors.orange;
    return Colors.red;
  }

  Color _getDifficultyColor(double difficulty) {
    if (difficulty <= 3) return Colors.green;
    if (difficulty <= 6) return Colors.orange;
    if (difficulty <= 8) return Colors.red;
    return Colors.deepPurple;
  }

  Color _getMaturityColor(int intervalDays) {
    if (intervalDays < 7) return Colors.red;
    if (intervalDays < 30) return Colors.orange;
    return Colors.green;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _suspendCard(EnhancedQuizState quizState) async {
    await quizState.suspendCard(quizState.currentWord!);
    _nextQuestion();
  }
}

class _ResultsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedQuizState>(
      builder: (context, quizState, child) {
        final accuracy = quizState.accuracy;
        final studyTime = quizState.totalStudyTime;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                accuracy >= 85 ? Icons.emoji_events :
                accuracy >= 70 ? Icons.thumb_up : Icons.school,
                color: accuracy >= 85 ? Colors.gold :
                accuracy >= 70 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text('Session Complete!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Score:'),
                        Text('${quizState.correctAnswers}/${quizState.totalAnswers}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Accuracy:'),
                        Text('${accuracy.toStringAsFixed(1)}%'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Study Time:'),
                        Text(_formatStudyTime(studyTime)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPerformanceMessage(accuracy),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                quizState.resetQuiz();
                Navigator.of(context).pop();
              },
              child: const Text('🏠 Home'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startNewSession(context, quizState);
              },
              child: const Text('🔄 Study More'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceMessage(double accuracy) {
    String message;
    Color color;
    IconData icon;

    if (accuracy >= 90) {
      message = "Outstanding! Your memory is getting stronger! 🧠💪";
      color = Colors.green;
      icon = Icons.psychology;
    } else if (accuracy >= 80) {
      message = "Great progress! Keep up the excellent work! 🌟";
      color = Colors.green;
      icon = Icons.trending_up;
    } else if (accuracy >= 70) {
      message = "Good effort! You're on the right track! 👍";
      color = Colors.orange;
      icon = Icons.thumb_up;
    } else {
      message = "Keep practicing! Every attempt makes you stronger! 💪";
      color = Colors.blue;
      icon = Icons.fitness_center;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStudyTime(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  void _startNewSession(BuildContext context, EnhancedQuizState quizState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Continue Studying?'),
          content: const Text('Which type of study session would you like?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                quizState.startReviewSession();
              },
              child: const Text('Review'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                quizState.startLearningSession();
              },
              child: const Text('New Cards'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                quizState.startSpacedRepetitionSession();
              },
              child: const Text('Mixed'),
            ),
          ],
        );
      },
    );
  }
}
