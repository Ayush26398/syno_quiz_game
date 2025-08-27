import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_state.dart';
import '../widgets/option_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/score_card.dart';
import '../services/data_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<String> _options = [];
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestion();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadQuestion() {
    final quizState = Provider.of<QuizState>(context, listen: false);
    if (quizState.status == QuizStatus.results) {
      _showResults();
      return;
    }

    setState(() {
      _options = quizState.generateOptions();
      _selectedAnswer = null;
    });
    _animationController.forward(from: 0);
  }

  void _selectAnswer(String answer) {
    if (_selectedAnswer != null) return;

    setState(() {
      _selectedAnswer = answer;
    });

    final quizState = Provider.of<QuizState>(context, listen: false);
    quizState.selectAnswer(answer);

    // Save wrong counts
    DataService.saveWrongCounts(quizState.wrongCounts);
  }

  void _nextQuestion() {
    final quizState = Provider.of<QuizState>(context, listen: false);
    quizState.nextQuestion();

    if (quizState.status == QuizStatus.results) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<QuizState>(
        builder: (context, quizState, child) {
          if (quizState.currentWord == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ScoreCard(
                  currentQuestion: quizState.currentIndex + 1,
                  totalQuestions: quizState.currentQuiz.length,
                  accuracy: quizState.accuracy,
                ),
                const SizedBox(height: 16),
                ProgressBar(progress: quizState.progress),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quizState.currentWord!.word.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                if (quizState.statusMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: quizState.isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: quizState.isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Text(
                      quizState.statusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: quizState.isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
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

                      return OptionButton(
                        text: option,
                        onPressed: () => _selectAnswer(option),
                        isSelected: isSelected,
                        isCorrect: isCorrect,
                        isIncorrect: isIncorrect,
                        isDisabled: quizState.hasAnswered,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: quizState.hasAnswered ? _nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: Text(
                      quizState.currentIndex + 1 >= quizState.currentQuiz.length
                          ? 'View Results'
                          : 'Next Question',
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

class _ResultsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuizState>(
      builder: (context, quizState, child) {
        final accuracy = quizState.accuracy;

        return AlertDialog(
          title: const Text('🏆 Quiz Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Score: ${quizState.correctAnswers}/${quizState.totalAnswers}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Accuracy: ${accuracy.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                quizState.resetQuiz();
                Navigator.of(context).pop();
              },
              child: const Text('🔄 New Quiz'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final numQuestions = quizState.currentQuiz.length;
                quizState.startQuiz(numQuestions);
                Navigator.of(context).pushReplacementNamed('/quiz');
              },
              child: const Text('🎯 Retake'),
            ),
          ],
        );
      },
    );
  }
}