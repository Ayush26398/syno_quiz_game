import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_state.dart';
import '../services/data_service.dart';

class WrongWordsScreen extends StatelessWidget {
  const WrongWordsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('❌ Wrong Words'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<QuizState>(
        builder: (context, quizState, child) {
          final wrongWords = quizState.getWrongWordsStats();

          if (wrongWords.isEmpty) {
            return const Center(
              child: Card(
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Wrong Words!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Great job! You haven\'t made any mistakes yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Words to Practice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These are the words you\'ve gotten wrong. Practice them to improve!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: wrongWords.length,
                  itemBuilder: (context, index) {
                    final wrongWord = wrongWords[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              wrongWord.count.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          wrongWord.word,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          'Incorrect ${wrongWord.count} time${wrongWord.count > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.green),
                          onPressed: () async {
                            quizState.resetWrongWord(wrongWord.word);
                            await DataService.saveWrongCounts(quizState.wrongCounts);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Reset ${wrongWord.word}')),
                            );
                          },
                          tooltip: 'Reset this word',
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: wrongWords.isEmpty
                        ? null
                        : () {
                      // Create a practice quiz with wrong words
                      final wrongWordPairs = wrongWords
                          .map((w) => quizState.allWords.firstWhere(
                            (pair) => pair.word == w.word,
                        orElse: () => throw StateError('Word not found'),
                      ))
                          .toList();

                      // Start practice quiz
                      quizState.setAllWords([...quizState.allWords]); // Refresh
                      quizState.startQuiz(wrongWordPairs.length.clamp(1, 20));
                      Navigator.pushNamed(context, '/quiz');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Practice Wrong Words'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
