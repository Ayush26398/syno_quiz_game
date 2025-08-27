import '../models/word_pair.dart';
import '../models/spaced_word_pair.dart';

import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
// removed duplicate import
import '../algorithms/sr_algorithms.dart';


enum StudyMode {
  review,        // Due cards only
  learning,      // New cards only
  mixed,         // Mix of new and due
  failed,        // Recently failed cards
  custom         // User-defined selection
}

class StudySession {
  final DateTime startTime;
  final StudyMode mode;
  final List<SpacedWordPair> cards;
  final List<ReviewGrade> grades;
  final List<int> responseTimes;
  int currentIndex;
  DateTime? endTime;

  StudySession({
    required this.startTime,
    required this.mode,
    required this.cards,
    this.currentIndex = 0,
  }) : grades = [], responseTimes = [];

  bool get isCompleted => currentIndex >= cards.length;
  double get progress => cards.isEmpty ? 0.0 : currentIndex / cards.length;
  int get remainingCards => math.max(0, cards.length - currentIndex);

  void addReview(ReviewGrade grade, int responseTimeMs) {
    grades.add(grade);
    responseTimes.add(responseTimeMs);
  }

  StudySessionStats getStats() {
    return StudySessionStats(
      totalCards: cards.length,
      completedCards: grades.length,
      correctAnswers: grades.where((g) => g != ReviewGrade.again).length,
      averageResponseTime: responseTimes.isEmpty ? 0.0 :
      responseTimes.reduce((a, b) => a + b) / responseTimes.length,
      studyTime: endTime != null ?
      endTime!.difference(startTime) : DateTime.now().difference(startTime),
    );
  }
}

class StudySessionStats {
  final int totalCards;
  final int completedCards;
  final int correctAnswers;
  final double averageResponseTime;
  final Duration studyTime;

  StudySessionStats({
    required this.totalCards,
    required this.completedCards,
    required this.correctAnswers,
    required this.averageResponseTime,
    required this.studyTime,
  });

  double get accuracy => completedCards == 0 ? 0.0 : correctAnswers / completedCards;
  double get cardsPerMinute => studyTime.inMinutes == 0 ? 0.0 :
  completedCards / studyTime.inMinutes;
}

class SpacedRepetitionService {
  static const String _cardsKey = 'spaced_cards';
  static const String _settingsKey = 'sr_settings';
  static const String _statsKey = 'sr_stats';

  late SpacedRepetitionAlgorithm _algorithm;
  List<SpacedWordPair> _cards = [];
  List<SpacedWordPair> get cards => _cards;
  StudySession? _currentSession;

  // Settings
  int newCardsPerDay = 20;
  int maxReviews = 200;
  double desiredRetention = 0.9;
  String algorithmType = 'FSRS';

  SpacedRepetitionService() {
    _algorithm = FSRSAlgorithm();
  }

  // Initialize service
  Future<void> initialize() async {
    await _loadCards();
    await _loadSettings();
  }

  // Card Management
  Future<void> addCards(List<SpacedWordPair> newCards) async {
    _cards.addAll(newCards);
    await _saveCards();
  }

  Future<void> updateCard(SpacedWordPair card) async {
    final index = cards.indexWhere((c) => c.word == card.word && c.synonym == card.synonym);
    if (index != -1) {
      cards[index] = card;
      await _saveCards();
    }
  }

  // Get cards by status
  List<SpacedWordPair> getDueCards() {
    return cards.where((card) => card.isDue()).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<SpacedWordPair> getNewCards() {
    return cards.where((card) => card.state == CardState.new_card).toList();
  }

  List<SpacedWordPair> getFailedCards() {
    final oneWeekAgo = DateTime.now().subtract(Duration(days: 7));
    return cards.where((card) =>
    card.history.isNotEmpty &&
        card.history.last.reviewDate.isAfter(oneWeekAgo) &&
        card.history.last.grade == ReviewGrade.again
    ).toList();
  }

  List<SpacedWordPair> getMatureCards() {
    return cards.where((card) =>
    card.state == CardState.review && card.intervalDays >= 21
    ).toList();
  }

  // Study Session Management
  StudySession createStudySession(StudyMode mode, int maxCards) {
    List<SpacedWordPair> sessionCards = [];

    switch (mode) {
      case StudyMode.review:
        sessionCards = getDueCards().take(maxCards).toList();
        break;
      case StudyMode.learning:
        sessionCards = getNewCards().take(maxCards).toList();
        break;
      case StudyMode.mixed:
        final dueCards = getDueCards();
        final newCards = getNewCards();
        final reviewCount = math.min(dueCards.length, (maxCards * 0.7).round());
        final newCount = math.min(newCards.length, maxCards - reviewCount);

        sessionCards.addAll(dueCards.take(reviewCount));
        sessionCards.addAll(newCards.take(newCount));
        sessionCards.shuffle();
        break;
      case StudyMode.failed:
        sessionCards = getFailedCards().take(maxCards).toList();
        break;
      case StudyMode.custom:
      // This would be handled by the caller
        break;
    }

    _currentSession = StudySession(
      startTime: DateTime.now(),
      mode: mode,
      cards: sessionCards,
    );

    return _currentSession!;
  }

  // Review a card
  Future<SpacedWordPair> reviewCard(SpacedWordPair card, ReviewGrade grade, int responseTimeMs) async {
    final updatedCard = _algorithm.processReview(card, grade, responseTimeMs);
    await updateCard(updatedCard);

    if (_currentSession != null) {
      _currentSession!.addReview(grade, responseTimeMs);
      if (grade != ReviewGrade.again) {
        _currentSession!.currentIndex++;
      }
    }

    return updatedCard;
  }

  // Complete current study session
  Future<StudySessionStats> completeStudySession() async {
    if (_currentSession == null) throw StateError('No active study session');

    _currentSession!.endTime = DateTime.now();
    final stats = _currentSession!.getStats();

    // Save session stats
    await _saveSessionStats(stats);

    _currentSession = null;
    return stats;
  }

  // Statistics
  StudyStats getOverallStats() {
    final now = DateTime.now();
    final total = cards.length;
    final newCards = cards.where((c) => c.state == CardState.new_card).length;
    final learning = cards.where((c) => c.state == CardState.learning).length;
    final review = cards.where((c) => c.state == CardState.review).length;
    final suspended = cards.where((c) => c.state == CardState.suspended).length;

    final dueToday = cards.where((c) =>
    c.isDue() && c.dueDate.isBefore(now.add(Duration(days: 1)))
    ).length;

    final overdue = cards.where((c) => c.getDaysOverdue() > 0).length;

    // Calculate retention rates
    final recentReviews = cards
        .expand((c) => c.history)
        .where((h) => h.reviewDate.isAfter(now.subtract(Duration(days: 30))))
        .toList();

    final retention = recentReviews.isEmpty ? 0.0 :
    recentReviews.where((r) => r.grade != ReviewGrade.again).length / recentReviews.length;

    return StudyStats(
      totalCards: total,
      newCards: newCards,
      learningCards: learning,
      reviewCards: review,
      suspendedCards: suspended,
      dueToday: dueToday,
      overdueCards: overdue,
      retention: retention,
      averageInterval: review > 0 ?
      cards.where((c) => c.state == CardState.review)
          .map((c) => c.intervalDays)
          .reduce((a, b) => a + b) / review : 0.0,
    );
  }

  List<RetentionPoint> getRetentionCurve(int days) {
    final points = <RetentionPoint>[];
    final reviewCards = cards.where((c) => c.state == CardState.review).toList();

    if (reviewCards.isEmpty) return points;

    for (int i = 0; i <= days; i++) {
      double totalRetention = 0.0;
      int cardCount = 0;

      for (final card in reviewCards) {
        final retention = _algorithm.predictRetention(card, i);
        totalRetention += retention;
        cardCount++;
      }

      if (cardCount > 0) {
        points.add(RetentionPoint(
          days: i,
          retention: totalRetention / cardCount,
        ));
      }
    }

    return points;
  }

  // Data persistence
  Future<void> _loadCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = prefs.getString(_cardsKey);
      if (cardsJson != null) {
        final List<dynamic> cardsList = json.decode(cardsJson);
        _cards = cardsList.map((json) => SpacedWordPair.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading spaced cards: $e');
    }
  }

  Future<void> _saveCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = json.encode(_cards.map((c) => c.toJson()).toList());
      await prefs.setString(_cardsKey, cardsJson);
    } catch (e) {
      print('Error saving spaced cards: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      newCardsPerDay = prefs.getInt('newCardsPerDay') ?? 20;
      maxReviews = prefs.getInt('maxReviews') ?? 200;
      desiredRetention = prefs.getDouble('desiredRetention') ?? 0.9;
      algorithmType = prefs.getString('algorithmType') ?? 'FSRS';

      // Set algorithm based on type
      switch (algorithmType) {
        case 'SM2':
          _algorithm = SM2Algorithm();
          break;
        case 'FSRS':
          _algorithm = FSRSAlgorithm();
          break;
        case 'Hybrid':
          _algorithm = HybridAlgorithm();
          break;
      }
    } catch (e) {
      print('Error loading SR settings: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('newCardsPerDay', newCardsPerDay);
      await prefs.setInt('maxReviews', maxReviews);
      await prefs.setDouble('desiredRetention', desiredRetention);
      await prefs.setString('algorithmType', algorithmType);
    } catch (e) {
      print('Error saving SR settings: $e');
    }
  }

  Future<void> _saveSessionStats(StudySessionStats stats) async {
    // Implementation for saving session statistics
    // This could be used for learning analytics
  }

  // Migration from old WordPair format
  Future<void> migrateFromWordPairs(List<WordPair> oldPairs, Map<String, int> wrongCounts) async {
    final spacedCards = <SpacedWordPair>[];

    for (final pair in oldPairs) {
      final spacedCard = SpacedWordPair.fromWordPair(pair);

      // If card has been wrong before, adjust difficulty
      final wrongCount = wrongCounts[pair.word] ?? 0;
      if (wrongCount > 0) {
        spacedCard.difficulty = math.min(10.0, 5.0 + wrongCount);
        spacedCard.lapses = wrongCount;
        spacedCard.state = CardState.review;
        spacedCard.intervalDays = math.max(1, 7 - wrongCount);
      }

      spacedCards.add(spacedCard);
    }

    _cards = spacedCards;
    await _saveCards();
  }
}

class StudyStats {
  final int totalCards;
  final int newCards;
  final int learningCards;
  final int reviewCards;
  final int suspendedCards;
  final int dueToday;
  final int overdueCards;
  final double retention;
  final double averageInterval;

  StudyStats({
    required this.totalCards,
    required this.newCards,
    required this.learningCards,
    required this.reviewCards,
    required this.suspendedCards,
    required this.dueToday,
    required this.overdueCards,
    required this.retention,
    required this.averageInterval,
  });
}

class RetentionPoint {
  final int days;
  final double retention;

  RetentionPoint({required this.days, required this.retention});
}
