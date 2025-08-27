
import 'dart:math' as math;
import '../models/spaced_word_pair.dart';


abstract class SpacedRepetitionAlgorithm {
  String get name;
  SpacedWordPair processReview(SpacedWordPair card, ReviewGrade grade, int responseTimeMs);
  double predictRetention(SpacedWordPair card, int daysFromNow);
}

class SM2Algorithm implements SpacedRepetitionAlgorithm {
  @override
  String get name => 'SM-2 (Classic)';

  @override
  SpacedWordPair processReview(SpacedWordPair card, ReviewGrade grade, int responseTimeMs) {
    final now = DateTime.now();
    final wasLate = card.getDaysOverdue() > 0;

    // Create review history entry
    final review = ReviewHistory(
      reviewDate: now,
      grade: grade,
      intervalDays: card.intervalDays,
      difficulty: card.difficulty,
      stability: card.stability,
      responseTimeMs: responseTimeMs,
      wasLate: wasLate,
    );

    card.history.add(review);
    card.totalReviews++;
    card.lastReviewed = now;

    if (card.state == CardState.new_card) {
      card.firstReviewed = now;
    }

    // Update average response time
    card.averageResponseTime = ((card.averageResponseTime * (card.totalReviews - 1)) + responseTimeMs) / card.totalReviews;

    if (grade == ReviewGrade.again) {
      // Failed review
      card.lapses++;
      card.state = CardState.relearning;
      card.learningStep = 0;
      card.intervalDays = 1;
      card.dueDate = now.add(Duration(minutes: card.relearningSteps[0]));
    } else {
      // Successful review
      card.correctReviews++;

      if (card.state == CardState.new_card || card.state == CardState.learning) {
        // Learning phase
        if (card.learningStep < card.learningSteps.length - 1) {
          card.learningStep++;
          card.state = CardState.learning;
          card.dueDate = now.add(Duration(minutes: card.learningSteps[card.learningStep]));
        } else {
          // Graduate to review
          card.state = CardState.review;
          card.repetitions = 1;
          card.intervalDays = 1;
          card.dueDate = now.add(Duration(days: 1));
        }
      } else if (card.state == CardState.relearning) {
        // Relearning phase
        if (card.learningStep < card.relearningSteps.length - 1) {
          card.learningStep++;
          card.dueDate = now.add(Duration(minutes: card.relearningSteps[card.learningStep]));
        } else {
          // Graduate back to review
          card.state = CardState.review;
          card.intervalDays = 1;
          card.dueDate = now.add(Duration(days: 1));
        }
      } else {
        // Review phase - SM-2 algorithm
        card.repetitions++;

        // Update ease factor based on grade
        final oldEF = card.easeFactor;
        final gradeValue = grade.index + 2; // Convert to 2-5 scale

        card.easeFactor = oldEF + (0.1 - (5 - gradeValue) * (0.08 + (5 - gradeValue) * 0.02));
        card.easeFactor = card.easeFactor.clamp(1.3, 3.0);

        // Calculate new interval
        if (card.repetitions == 1) {
          card.intervalDays = 1;
        } else if (card.repetitions == 2) {
          card.intervalDays = 6;
        } else {
          card.intervalDays = (card.intervalDays * card.easeFactor).round();
        }

        // Apply grade modifiers
        switch (grade) {
          case ReviewGrade.hard:
            card.intervalDays = (card.intervalDays * 1.2).round();
            break;
          case ReviewGrade.easy:
            card.intervalDays = (card.intervalDays * 1.3).round();
            break;
          default:
            break;
        }

        // Factor in lateness bonus
        if (wasLate) {
          final latenessMultiplier = 1.0 + (card.getDaysOverdue() * 0.05);
          card.intervalDays = (card.intervalDays * latenessMultiplier).round();
        }

        card.intervalDays = card.intervalDays.clamp(1, 36500); // Max 100 years
        card.dueDate = now.add(Duration(days: card.intervalDays));
      }
    }

    return card;
  }

  @override
  double predictRetention(SpacedWordPair card, int daysFromNow) {
    // Simple retention prediction based on ease factor
    final timeFactor = daysFromNow / card.intervalDays;
    return math.exp(-timeFactor / card.easeFactor).clamp(0.0, 1.0);
  }
}

class FSRSAlgorithm implements SpacedRepetitionAlgorithm {
  @override
  String get name => 'FSRS (Modern)';

  // FSRS parameters (can be optimized per user)
  final List<double> parameters = [
    0.5701, 1.4436, 4.1386, 10.9355, 5.1443, 1.2006,
    0.8627, 0.0362, 1.629, 0.1342, 1.0166, 2.1174,
    0.0839, 0.3204, 1.4676, 0.219, 2.8237
  ];

  @override
  SpacedWordPair processReview(SpacedWordPair card, ReviewGrade grade, int responseTimeMs) {
    final now = DateTime.now();
    final wasLate = card.getDaysOverdue() > 0;

    // Calculate current retrievability
    card.retrievability = card.getRetrievability();

    // Create review history entry
    final review = ReviewHistory(
      reviewDate: now,
      grade: grade,
      intervalDays: card.intervalDays,
      difficulty: card.difficulty,
      stability: card.stability,
      responseTimeMs: responseTimeMs,
      wasLate: wasLate,
    );

    card.history.add(review);
    card.totalReviews++;
    card.lastReviewed = now;

    if (card.state == CardState.new_card) {
      card.firstReviewed = now;
    }

    // Update average response time
    card.averageResponseTime = ((card.averageResponseTime * (card.totalReviews - 1)) + responseTimeMs) / card.totalReviews;

    if (grade == ReviewGrade.again) {
      // Failed review
      card.lapses++;
      card.state = CardState.relearning;
      card.learningStep = 0;

      // Update difficulty (make it harder)
      card.difficulty = _updateDifficulty(card.difficulty, ReviewGrade.again);

      // Reset stability for relearning
      card.stability = _calculateNewStability(card, ReviewGrade.again);
      card.intervalDays = 1;
      card.dueDate = now.add(Duration(minutes: card.relearningSteps[0]));
    } else {
      // Successful review
      card.correctReviews++;

      if (card.state == CardState.new_card || card.state == CardState.learning) {
        // Learning phase
        if (card.learningStep < card.learningSteps.length - 1) {
          card.learningStep++;
          card.state = CardState.learning;
          card.dueDate = now.add(Duration(minutes: card.learningSteps[card.learningStep]));
        } else {
          // Graduate to review
          card.state = CardState.review;
          card.repetitions = 1;
          card.difficulty = _updateDifficulty(card.difficulty, grade);
          card.stability = _calculateNewStability(card, grade);
          card.intervalDays = _calculateInterval(card.stability, 0.9);
          card.dueDate = now.add(Duration(days: card.intervalDays));
        }
      } else if (card.state == CardState.relearning) {
        // Relearning phase
        if (card.learningStep < card.relearningSteps.length - 1) {
          card.learningStep++;
          card.dueDate = now.add(Duration(minutes: card.relearningSteps[card.learningStep]));
        } else {
          // Graduate back to review
          card.state = CardState.review;
          card.difficulty = _updateDifficulty(card.difficulty, grade);
          card.stability = _calculateNewStability(card, grade);
          card.intervalDays = _calculateInterval(card.stability, 0.9);
          card.dueDate = now.add(Duration(days: card.intervalDays));
        }
      } else {
        // Review phase - FSRS algorithm
        card.repetitions++;

        // Update difficulty and stability
        card.difficulty = _updateDifficulty(card.difficulty, grade);
        card.stability = _calculateNewStability(card, grade);

        // Calculate new interval based on desired retention (90%)
        card.intervalDays = _calculateInterval(card.stability, 0.9);

        // Apply grade-specific adjustments
        switch (grade) {
          case ReviewGrade.hard:
            card.intervalDays = (card.intervalDays * 0.8).round();
            break;
          case ReviewGrade.easy:
            card.intervalDays = (card.intervalDays * 1.3).round();
            break;
          default:
            break;
        }

        // Factor in lateness
        if (wasLate && card.getDaysOverdue() > 0) {
          final latenessBonus = 1.0 + math.log(1 + card.getDaysOverdue()) * 0.1;
          card.intervalDays = (card.intervalDays * latenessBonus).round();
        }

        card.intervalDays = card.intervalDays.clamp(1, 36500);
        card.dueDate = now.add(Duration(days: card.intervalDays));
      }
    }

    return card;
  }

  double _updateDifficulty(double currentDifficulty, ReviewGrade grade) {
    // Update difficulty based on review grade
    final gradeValue = grade.index; // 0=again, 1=hard, 2=good, 3=easy
    final deltaD = -parameters[6] * (gradeValue - 2.0);

    return (currentDifficulty + deltaD).clamp(1.0, 10.0);
  }

  double _calculateNewStability(SpacedWordPair card, ReviewGrade grade) {
    if (card.repetitions == 0) {
      // First time learning
      return parameters[grade.index];
    }

    // Calculate stability based on previous stability, difficulty, and retrievability
    final gradeValue = grade.index;
    final S = card.stability;
    final D = card.difficulty;
    final R = card.retrievability;

    final SInc = math.exp(parameters[8]) *
        (11 - D) *
        math.pow(S, -parameters[9]) *
        (math.exp((1 - R) * parameters[10]) - 1) *
        parameters[15 + gradeValue];

    return S + SInc;
  }

  int _calculateInterval(double stability, double desiredRetention) {
    // Calculate interval for desired retention using forgetting curve
    // I = S * ln(desiredRetention) / ln(0.9)
    final interval = stability * math.log(desiredRetention) / math.log(0.9);
    return math.max(1, interval.round());
  }

  @override
  double predictRetention(SpacedWordPair card, int daysFromNow) {
    // Forgetting curve: R = e^(-t/S)
    final timeDecay = daysFromNow / card.stability;
    return math.exp(-timeDecay).clamp(0.0, 1.0);
  }
}

class HybridAlgorithm implements SpacedRepetitionAlgorithm {
  @override
  String get name => 'Hybrid (SM-2 + FSRS)';

  final SM2Algorithm sm2 = SM2Algorithm();
  final FSRSAlgorithm fsrs = FSRSAlgorithm();

  @override
  SpacedWordPair processReview(SpacedWordPair card, ReviewGrade grade, int responseTimeMs) {
    // Use FSRS for cards with enough history, SM-2 for new cards
    if (card.history.length >= 3) {
      return fsrs.processReview(card, grade, responseTimeMs);
    } else {
      return sm2.processReview(card, grade, responseTimeMs);
    }
  }

  @override
  double predictRetention(SpacedWordPair card, int daysFromNow) {
    if (card.history.length >= 3) {
      return fsrs.predictRetention(card, daysFromNow);
    } else {
      return sm2.predictRetention(card, daysFromNow);
    }
  }
}
