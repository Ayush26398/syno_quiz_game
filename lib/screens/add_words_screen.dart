import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_quiz_state.dart'; // Use enhanced state model
import '../models/spaced_word_pair.dart';  // Word pair model

class AddWordsScreen extends StatefulWidget {
  const AddWordsScreen({Key? key}) : super(key: key);

  @override
  State<AddWordsScreen> createState() => _AddWordsScreenState();
}

class _AddWordsScreenState extends State<AddWordsScreen> {
  final _wordController = TextEditingController();
  final _synonymController = TextEditingController();
  bool _adding = false;
  String? _error;

  @override
  void dispose() {
    _wordController.dispose();
    _synonymController.dispose();
    super.dispose();
  }

  Future<void> _addWord() async {
    final word = _wordController.text.trim();
    final synonym = _synonymController.text.trim();

    if (word.isEmpty || synonym.isEmpty) {
      setState(() {
        _error = "Both word and synonym are required.";
      });
      return;
    }

    setState(() {
      _adding = true;
      _error = null;
    });

    try {
      final newCard = SpacedWordPair(word: word, synonym: synonym);
      await context.read<EnhancedQuizState>().addCards([newCard]);

      _wordController.clear();
      _synonymController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Word "$word" added successfully!')),
      );
    } catch (e) {
      setState(() {
        _error = 'Error adding word: $e';
      });
    } finally {
      setState(() {
        _adding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Words'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _wordController,
              decoration: const InputDecoration(
                labelText: 'Word',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _synonymController,
              decoration: const InputDecoration(
                labelText: 'Synonym',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _adding ? null : _addWord,
              child: _adding
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Word'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
