import 'dart:math' as math;
import 'word_pair.dart';  // top of spaced_word_pair.dart


import 'package:flutter/foundation.dart';

enum CardState {
  new_card,      // Never studied
  learning,      // In initial learning phase
  review,        // In review phase
  relearning,    // Failed and relearning
  suspended      // User suspended
}

enum ReviewGrade {
  again,         // 0 - Complete failure
  hard,          // 1 - Difficult recall
  good,          // 2 - Normal recall
  easy           // 3 - Easy recall
}

class ReviewHistory {
  final DateTime reviewDate;
  final ReviewGrade grade;
  final int intervalDays;
  final double difficulty;
  final double stability;
  final int responseTimeMs;
  final bool wasLate;

  ReviewHistory({
    required this.reviewDate,
    required this.grade,
    required this.intervalDays,
    required this.difficulty,
    required this.stability,
    required this.responseTimeMs,
    this.wasLate = false,
  });

  Map<String, dynamic> toJson() => {
    'reviewDate': reviewDate.millisecondsSinceEpoch,
    'grade': grade.index,
    'intervalDays': intervalDays,
    'difficulty': difficulty,
    'stability': stability,
    'responseTimeMs': responseTimeMs,
    'wasLate': wasLate,
  };

  factory ReviewHistory.fromJson(Map<String, dynamic> json) => ReviewHistory(
    reviewDate: DateTime.fromMillisecondsSinceEpoch(json['reviewDate']),
    grade: ReviewGrade.values[json['grade']],
    intervalDays: json['intervalDays'],
    difficulty: json['difficulty'],
    stability: json['stability'],
    responseTimeMs: json['responseTimeMs'],
    wasLate: json['wasLate'] ?? false,
  );
}

class SpacedWordPair {
  // Basic word data
  final String word;
  final String synonym;

  // Spaced repetition data
  CardState state;
  DateTime dueDate;
  int intervalDays;
  double easeFactor;  // SM-2
  double difficulty;  // FSRS
  double stability;   // FSRS
  double retrievability; // FSRS
  int repetitions;
  int lapses;  // Times failed
  DateTime lastReviewed;
  DateTime firstReviewed;
  List<ReviewHistory> history;

  // Learning phase data
  int learningStep;
  List<int> learningSteps; // in minutes
  List<int> relearningSteps; // in minutes

  // Statistics
  int totalReviews;
  int correctReviews;
  double averageResponseTime;

  SpacedWordPair({
    required this.word,
    required this.synonym,
    this.state = CardState.new_card,
    DateTime? dueDate,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    this.difficulty = 5.0,
    this.stability = 1.0,
    this.retrievability = 0.9,
    this.repetitions = 0,
    this.lapses = 0,
    DateTime? lastReviewed,
    DateTime? firstReviewed,
    List<ReviewHistory>? history,
    this.learningStep = 0,
    List<int>? learningSteps,
    List<int>? relearningSteps,
    this.totalReviews = 0,
    this.correctReviews = 0,
    this.averageResponseTime = 0.0,
  }) : dueDate = dueDate ?? DateTime.now(),
        lastReviewed = lastReviewed ?? DateTime.now(),
        firstReviewed = firstReviewed ?? DateTime.now(),
        history = history ?? [],
        learningSteps = learningSteps ?? [1, 10, 60, 360], // 1m, 10m, 1h, 6h
        relearningSteps = relearningSteps ?? [10, 60]; // 10m, 1h

  // Calculate retrieval probability using forgetting curve
  double getRetrievability() {
    if (state == CardState.new_card) return 0.0;

    final daysSinceReview = DateTime.now().difference(lastReviewed).inDays;
    if (daysSinceReview <= 0) return retrievability;

    // Forgetting curve: R = e^(-t/S) where t=time, S=stability
    final timeDecay = daysSinceReview / stability;
    return math.exp(-timeDecay).clamp(0.0, 1.0);
  }

  // Check if card is due for review
  bool isDue() {
    return DateTime.now().isAfter(dueDate) || DateTime.now().isAtSameMomentAs(dueDate);
  }

  // Get days overdue (positive = overdue, negative = future)
  int getDaysOverdue() {
    return DateTime.now().difference(dueDate).inDays;
  }

  // Get maturity level based on interval
  String getMaturityLevel() {
    if (intervalDays < 7) return 'Young';
    if (intervalDays < 30) return 'Mature';
    return 'Mastered';
  }

  // Get difficulty level description
  String getDifficultyDescription() {
    if (difficulty <= 3) return 'Easy';
    if (difficulty <= 6) return 'Medium';
    if (difficulty <= 8) return 'Hard';
    return 'Very Hard';
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'synonym': synonym,
    'state': state.index,
    'dueDate': dueDate.millisecondsSinceEpoch,
    'intervalDays': intervalDays,
    'easeFactor': easeFactor,
    'difficulty': difficulty,
    'stability': stability,
    'retrievability': retrievability,
    'repetitions': repetitions,
    'lapses': lapses,
    'lastReviewed': lastReviewed.millisecondsSinceEpoch,
    'firstReviewed': firstReviewed.millisecondsSinceEpoch,
    'history': history.map((h) => h.toJson()).toList(),
    'learningStep': learningStep,
    'learningSteps': learningSteps,
    'relearningSteps': relearningSteps,
    'totalReviews': totalReviews,
    'correctReviews': correctReviews,
    'averageResponseTime': averageResponseTime,
  };

  factory SpacedWordPair.fromJson(Map<String, dynamic> json) => SpacedWordPair(
    word: json['word'],
    synonym: json['synonym'],
    state: CardState.values[json['state'] ?? 0],
    dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate']),
    intervalDays: json['intervalDays'] ?? 1,
    easeFactor: json['easeFactor'] ?? 2.5,
    difficulty: json['difficulty'] ?? 5.0,
    stability: json['stability'] ?? 1.0,
    retrievability: json['retrievability'] ?? 0.9,
    repetitions: json['repetitions'] ?? 0,
    lapses: json['lapses'] ?? 0,
    lastReviewed: DateTime.fromMillisecondsSinceEpoch(json['lastReviewed']),
    firstReviewed: DateTime.fromMillisecondsSinceEpoch(json['firstReviewed']),
    history: (json['history'] as List?)?.map((h) => ReviewHistory.fromJson(h)).toList() ?? [],
    learningStep: json['learningStep'] ?? 0,
    learningSteps: List<int>.from(json['learningSteps'] ?? [1, 10, 60, 360]),
    relearningSteps: List<int>.from(json['relearningSteps'] ?? [10, 60]),
    totalReviews: json['totalReviews'] ?? 0,
    correctReviews: json['correctReviews'] ?? 0,
    averageResponseTime: json['averageResponseTime'] ?? 0.0,
  );

  // Create from old WordPair for migration
  factory SpacedWordPair.fromWordPair(WordPair oldPair) => SpacedWordPair(
    word: oldPair.word,
    synonym: oldPair.synonym,
  );
}
