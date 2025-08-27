import '../models/word_pair.dart';


import 'package:flutter/foundation.dart';
import '../models/spaced_word_pair.dart';
import '../services/sr_service.dart';

import 'dart:async';

enum QuizMode {
  classic,           // Original quiz mode
  spacedRepetition,  // Spaced repetition mode
  practice,          // Practice mode (no SRS updates)
  cram              // Cram mode (rapid review)
}

class EnhancedQuizState extends ChangeNotifier {
  final SpacedRepetitionService _srService = SpacedRepetitionService();

  // Quiz session data
  List<SpacedWordPair> _currentQuiz = [];
  StudySession? _studySession;
  QuizMode _mode = QuizMode.spacedRepetition;
  int _currentIndex = 0;
  bool _hasAnswered = false;
  String _statusMessage = '';
  bool _isCorrect = false;

  // Performance tracking
  DateTime? _questionStartTime;
  List<int> _responseTimes = [];
  int _correctAnswers = 0;
  int _totalAnswers = 0;

  // Advanced features
  Timer? _studyTimer;
  Duration _totalStudyTime = Duration.zero;
  bool _showHints = false;
  bool _showRetention = false;

  // Getters
  SpacedRepetitionService get srService => _srService;
  List<SpacedWordPair> get currentQuiz => _currentQuiz;
  StudySession? get studySession => _studySession;
  QuizMode get mode => _mode;
  int get currentIndex => _currentIndex;
  bool get hasAnswered => _hasAnswered;
  String get statusMessage => _statusMessage;
  bool get isCorrect => _isCorrect;
  int get correctAnswers => _correctAnswers;
  int get totalAnswers => _totalAnswers;
  Duration get totalStudyTime => _totalStudyTime;
  bool get showHints => _showHints;
  bool get showRetention => _showRetention;

  double get accuracy => _totalAnswers > 0 ? (_correctAnswers / _totalAnswers) * 100 : 0;
  double get progress => _currentQuiz.isNotEmpty ? (_currentIndex + 1) / _currentQuiz.length : 0;

  SpacedWordPair? get currentWord =>
      _currentIndex < _currentQuiz.length ? _currentQuiz[_currentIndex] : null;

  // Initialize the service
  Future<void> initialize() async {
    await _srService.initialize();
    notifyListeners();
  }

  // Start different types of study sessions
  Future<void> startSpacedRepetitionSession({int maxCards = 20}) async {
    _mode = QuizMode.spacedRepetition;
    _studySession = _srService.createStudySession(StudyMode.mixed, maxCards);
    _currentQuiz = _studySession!.cards;
    _resetSessionState();
    _startTimer();
    notifyListeners();
  }

  Future<void> startReviewSession({int maxCards = 50}) async {
    _mode = QuizMode.spacedRepetition;
    _studySession = _srService.createStudySession(StudyMode.review, maxCards);
    _currentQuiz = _studySession!.cards;
    _resetSessionState();
    _startTimer();
    notifyListeners();
  }

  Future<void> startLearningSession({int maxCards = 10}) async {
    _mode = QuizMode.spacedRepetition;
    _studySession = _srService.createStudySession(StudyMode.learning, maxCards);
    _currentQuiz = _studySession!.cards;
    _resetSessionState();
    _startTimer();
    notifyListeners();
  }

  Future<void> startFailedCardsSession() async {
    _mode = QuizMode.spacedRepetition;
    final failedCards = _srService.getFailedCards();
    _studySession = _srService.createStudySession(StudyMode.failed, failedCards.length);
    _currentQuiz = _studySession!.cards;
    _resetSessionState();
    _startTimer();
    notifyListeners();
  }

  Future<void> startClassicQuiz(int numberOfQuestions) async {
    _mode = QuizMode.classic;
    final allCards = _srService.cards;
    if (allCards.isEmpty) return;

    _currentQuiz = List.from(allCards)..shuffle();
    _currentQuiz = _currentQuiz.take(numberOfQuestions.clamp(1, allCards.length)).toList();
    _resetSessionState();
    _startTimer();
    notifyListeners();
  }

  void _resetSessionState() {
    _currentIndex = 0;
    _correctAnswers = 0;
    _totalAnswers = 0;
    _hasAnswered = false;
    _statusMessage = '';
    _responseTimes.clear();
    _questionStartTime = DateTime.now();
    _totalStudyTime = Duration.zero;
  }

  void _startTimer() {
    _studyTimer?.cancel();
    _studyTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _totalStudyTime = _totalStudyTime + Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _stopTimer() {
    _studyTimer?.cancel();
  }

  // Answer selection and processing
  Future<void> selectAnswer(String selectedAnswer) async {
    if (_hasAnswered || currentWord == null) return;

    _hasAnswered = true;
    _totalAnswers++;

    final responseTime = _questionStartTime != null ?
    DateTime.now().difference(_questionStartTime!).inMilliseconds : 0;
    _responseTimes.add(responseTime);

    _isCorrect = selectedAnswer == currentWord!.synonym;

    // Determine review grade based on correctness and speed
    ReviewGrade grade;
    if (!_isCorrect) {
      grade = ReviewGrade.again;
      _statusMessage = '❌ Incorrect! The answer is: ${currentWord!.synonym}';
    } else {
      _correctAnswers++;
      // Grade based on response time (basic implementation)
      if (responseTime < 3000) {
        grade = ReviewGrade.easy;
        _statusMessage = '🎉 Excellent! Quick and correct!';
      } else if (responseTime < 8000) {
        grade = ReviewGrade.good;
        _statusMessage = '✅ Correct! Well done!';
      } else {
        grade = ReviewGrade.hard;
        _statusMessage = '✅ Correct, but took some time.';
      }
    }

    // Update card with spaced repetition algorithm (except in practice mode)
    if (_mode == QuizMode.spacedRepetition) {
      await _srService.reviewCard(currentWord!, grade, responseTime);
    }

         notifyListeners();
   }

   // Manual grade update for failed cards
   Future<void> updateCardGrade(ReviewGrade grade) async {
     if (currentWord == null) return;
     
     final responseTime = _questionStartTime != null ?
         DateTime.now().difference(_questionStartTime!).inMilliseconds : 0;
     
     // Update card with the selected grade
     await _srService.reviewCard(currentWord!, grade, responseTime);
     
     // Update status message based on grade
     switch (grade) {
       case ReviewGrade.again:
         _statusMessage = '❌ Marked as Again - Will review soon';
         break;
       case ReviewGrade.hard:
         _statusMessage = '🟠 Marked as Hard - Will review later';
         break;
       case ReviewGrade.good:
         _statusMessage = '🔵 Marked as Good - Will review in a few days';
         break;
       case ReviewGrade.easy:
         _statusMessage = '🟢 Marked as Easy - Will review much later';
         break;
     }
     
     notifyListeners();
   }
 
   // Navigate to next question
  void nextQuestion() {
    if (_currentIndex + 1 >= _currentQuiz.length) {
      _completeSession();
    } else {
      _currentIndex++;
      _hasAnswered = false;
      _statusMessage = '';
      _questionStartTime = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> _completeSession() async {
    _stopTimer();

    if (_mode == QuizMode.spacedRepetition && _studySession != null) {
      await _srService.completeStudySession();
    }

    notifyListeners();
  }

  // Generate answer options
  List<String> generateOptions() {
    if (currentWord == null || _currentQuiz.length < 4) return [];

    final correctAnswer = currentWord!.synonym;
    final otherWords = _currentQuiz.where((w) => w.synonym != correctAnswer).toList();
    otherWords.shuffle();

    final distractors = otherWords.take(3).map((w) => w.synonym).toList();
    final options = [correctAnswer, ...distractors];
    options.shuffle();

    return options;
  }

  // Statistics and insights
  StudyStats getStudyStats() => _srService.getOverallStats();

  List<RetentionPoint> getRetentionCurve(int days) =>
      _srService.getRetentionCurve(days);

  List<SpacedWordPair> getDueCards() => _srService.getDueCards();
  List<SpacedWordPair> getNewCards() => _srService.getNewCards();
  List<SpacedWordPair> getFailedCards() => _srService.getFailedCards();
  List<SpacedWordPair> getMatureCards() => _srService.getMatureCards();

  // Card management
  Future<void> addCards(List<SpacedWordPair> cards) async {
    await _srService.addCards(cards);
    notifyListeners();
  }

  Future<void> suspendCard(SpacedWordPair card) async {
    card.state = CardState.suspended;
    await _srService.updateCard(card);
    notifyListeners();
  }

  Future<void> unsuspendCard(SpacedWordPair card) async {
    card.state = CardState.review;
    await _srService.updateCard(card);
    notifyListeners();
  }

  Future<void> resetCard(SpacedWordPair card) async {
    card.state = CardState.new_card;
    card.repetitions = 0;
    card.intervalDays = 1;
    card.dueDate = DateTime.now();
    card.history.clear();
    await _srService.updateCard(card);
    notifyListeners();
  }

  // Settings
  void toggleHints() {
    _showHints = !_showHints;
    notifyListeners();
  }

  void toggleRetentionDisplay() {
    _showRetention = !_showRetention;
    notifyListeners();
  }

  Future<void> updateSettings({
    int? newCardsPerDay,
    int? maxReviews,
    double? desiredRetention,
    String? algorithmType,
  }) async {
    if (newCardsPerDay != null) _srService.newCardsPerDay = newCardsPerDay;
    if (maxReviews != null) _srService.maxReviews = maxReviews;
    if (desiredRetention != null) _srService.desiredRetention = desiredRetention;
    if (algorithmType != null) _srService.algorithmType = algorithmType;

    await _srService.saveSettings();
    notifyListeners();
  }

  // Reset quiz
  void resetQuiz() {
    _stopTimer();
    _currentIndex = 0;
    _correctAnswers = 0;
    _totalAnswers = 0;
    _hasAnswered = false;
    _statusMessage = '';
    _currentQuiz.clear();
    _studySession = null;
    _responseTimes.clear();
    _totalStudyTime = Duration.zero;
    notifyListeners();
  }

  // Migration helper
  Future<void> migrateFromOldFormat(List<WordPair> oldPairs, Map<String, int> wrongCounts) async {
    await _srService.migrateFromWordPairs(oldPairs, wrongCounts);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  // Advanced analytics
  Map<String, dynamic> getDetailedAnalytics() {
    final stats = _srService.getOverallStats();
    final cards = _srService.cards;

    // Calculate difficulty distribution
    final difficultyBuckets = <String, int>{};
    for (final card in cards) {
      final level = card.getDifficultyDescription();
      difficultyBuckets[level] = (difficultyBuckets[level] ?? 0) + 1;
    }

    // Calculate maturity distribution
    final maturityBuckets = <String, int>{};
    for (final card in cards) {
      final level = card.getMaturityLevel();
      maturityBuckets[level] = (maturityBuckets[level] ?? 0) + 1;
    }

    // Recent performance
    final recentReviews = cards
        .expand((c) => c.history)
        .where((h) => h.reviewDate.isAfter(DateTime.now().subtract(Duration(days: 7))))
        .toList();

    final recentAccuracy = recentReviews.isEmpty ? 0.0 :
    recentReviews.where((r) => r.grade != ReviewGrade.again).length / recentReviews.length;

    return {
      'basicStats': stats,
      'difficultyDistribution': difficultyBuckets,
      'maturityDistribution': maturityBuckets,
      'recentAccuracy': recentAccuracy,
      'averageResponseTime': _responseTimes.isEmpty ? 0.0 :
      _responseTimes.reduce((a, b) => a + b) / _responseTimes.length,
      'studyStreak': _calculateStudyStreak(),
      'predictedWorkload': _predictUpcomingWorkload(),
    };
  }

  int _calculateStudyStreak() {
    final cards = _srService.cards;
    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final hasStudied = cards.any((card) =>
          card.history.any((review) =>
          review.reviewDate.year == date.year &&
              review.reviewDate.month == date.month &&
              review.reviewDate.day == date.day));

      if (hasStudied) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  List<int> _predictUpcomingWorkload() {
    final workload = <int>[];
    final today = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      final dueCount = _srService.cards.where((card) =>
      card.dueDate.year == date.year &&
          card.dueDate.month == date.month &&
          card.dueDate.day == date.day).length;

      workload.add(dueCount);
    }

    return workload;
  }
}
