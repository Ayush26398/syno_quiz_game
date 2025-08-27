import 'package:flutter/foundation.dart';
import 'word_pair.dart';

enum QuizStatus { setup, playing, results }

class QuizState extends ChangeNotifier {
  List<WordPair> _allWords = [];
  List<WordPair> _currentQuiz = [];
  Map<String, int> _wrongCounts = {};

  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  QuizStatus _status = QuizStatus.setup;
  bool _hasAnswered = false;
  String _statusMessage = '';
  bool _isCorrect = false;

  // Getters
  List<WordPair> get allWords => _allWords;
  List<WordPair> get currentQuiz => _currentQuiz;
  Map<String, int> get wrongCounts => _wrongCounts;
  int get currentIndex => _currentIndex;
  int get correctAnswers => _correctAnswers;
  int get totalAnswers => _totalAnswers;
  QuizStatus get status => _status;
  bool get hasAnswered => _hasAnswered;
  String get statusMessage => _statusMessage;
  bool get isCorrect => _isCorrect;

  double get accuracy => _totalAnswers > 0 ? (_correctAnswers / _totalAnswers) * 100 : 0;
  double get progress => _currentQuiz.isNotEmpty ? (_currentIndex + 1) / _currentQuiz.length : 0;

  WordPair? get currentWord => _currentIndex < _currentQuiz.length ? _currentQuiz[_currentIndex] : null;

  void setAllWords(List<WordPair> words) {
    _allWords = words;
    notifyListeners();
  }

  void setWrongCounts(Map<String, int> counts) {
    _wrongCounts = counts;
    notifyListeners();
  }

  void addWords(List<WordPair> newWords) {
    _allWords.addAll(newWords);
    notifyListeners();
  }

  void startQuiz(int numberOfQuestions) {
    if (_allWords.isEmpty) return;

    _currentQuiz = List.from(_allWords)..shuffle();
    _currentQuiz = _currentQuiz.take(numberOfQuestions.clamp(1, _allWords.length)).toList();
    _currentIndex = 0;
    _correctAnswers = 0;
    _totalAnswers = 0;
    _status = QuizStatus.playing;
    _hasAnswered = false;
    _statusMessage = '';
    notifyListeners();
  }

  void selectAnswer(String selectedAnswer) {
    if (_hasAnswered || currentWord == null) return;

    _hasAnswered = true;
    _totalAnswers++;
    _isCorrect = selectedAnswer == currentWord!.synonym;

    if (_isCorrect) {
      _correctAnswers++;
      _statusMessage = '🎉 Excellent! Correct!';
    } else {
      _statusMessage = '❌ Correct answer: ${currentWord!.synonym}';
      _wrongCounts[currentWord!.word] = (_wrongCounts[currentWord!.word] ?? 0) + 1;
    }

    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex + 1 >= _currentQuiz.length) {
      _status = QuizStatus.results;
    } else {
      _currentIndex++;
      _hasAnswered = false;
      _statusMessage = '';
    }
    notifyListeners();
  }

  void resetQuiz() {
    _status = QuizStatus.setup;
    _currentIndex = 0;
    _correctAnswers = 0;
    _totalAnswers = 0;
    _hasAnswered = false;
    _statusMessage = '';
    _currentQuiz.clear();
    notifyListeners();
  }

  void resetWrongWord(String word) {
    _wrongCounts.remove(word);
    notifyListeners();
  }

  List<String> generateOptions() {
    if (currentWord == null || _allWords.length < 4) return [];

    final correctAnswer = currentWord!.synonym;
    final otherWords = _allWords.where((w) => w.synonym != correctAnswer).toList();
    otherWords.shuffle();

    final distractors = otherWords.take(3).map((w) => w.synonym).toList();
    final options = [correctAnswer, ...distractors];
    options.shuffle();

    return options;
  }

  List<WrongWordStat> getWrongWordsStats() {
    return _wrongCounts.entries
        .map((entry) => WrongWordStat(word: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }
}
