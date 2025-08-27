import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_state.dart';
import '../services/data_service.dart';

class AddWordsScreen extends StatefulWidget {
  const AddWordsScreen({Key? key}) : super(key: key);

  @override
  State<AddWordsScreen> createState() => _AddWordsScreenState();
}

class _AddWordsScreenState extends State<AddWordsScreen> {
  final TextEditingController _csvController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  Future<void> _addWords() async {
    if (_csvController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter word pairs')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newWords = DataService.parseCSV(_csvController.text);

      if (newWords.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid word pairs found')),
        );
        return;
      }

      await DataService.addWords(newWords);

      // Update quiz state
      final quizState = Provider.of<QuizState>(context, listen: false);
      final allWords = await DataService.loadWords();
      quizState.setAllWords(allWords);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${newWords.length} word pairs successfully')),
      );

      _csvController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding words: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ Add Words'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter word pairs in CSV format (word,synonym):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Example:\nhappy,joyful\nfast,quick\nbig,large',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _csvController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'happy,joyful\nfast,quick\nbig,large',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addWords,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text('Add Words'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _csvController.clear();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
