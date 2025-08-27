import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_pair.dart';

class DataService {
  static const String _wordsKey = 'words';
  static const String _wrongCountsKey = 'wrong_counts';

  static List<WordPair> getDefaultWords() {
    return [
      WordPair(word: 'happy', synonym: 'joyful'),
      WordPair(word: 'fast', synonym: 'quick'),
      WordPair(word: 'big', synonym: 'large'),
      WordPair(word: 'smart', synonym: 'intelligent'),
      WordPair(word: 'angry', synonym: 'mad'),
      WordPair(word: 'cold', synonym: 'chilly'),
      WordPair(word: 'pretty', synonym: 'beautiful'),
      WordPair(word: 'hard', synonym: 'difficult'),
      WordPair(word: 'easy', synonym: 'simple'),
      WordPair(word: 'bright', synonym: 'brilliant'),
      WordPair(word: 'dark', synonym: 'dim'),
      WordPair(word: 'old', synonym: 'ancient'),
      WordPair(word: 'new', synonym: 'fresh'),
      WordPair(word: 'good', synonym: 'excellent'),
      WordPair(word: 'bad', synonym: 'terrible'),
      WordPair(word: 'strong', synonym: 'powerful'),
      WordPair(word: 'weak', synonym: 'feeble'),
      WordPair(word: 'loud', synonym: 'noisy'),
      WordPair(word: 'quiet', synonym: 'silent'),
      WordPair(word: 'rich', synonym: 'wealthy'),
    ];
  }

  static Future<List<WordPair>> loadWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wordsJson = prefs.getString(_wordsKey);
      if (wordsJson != null) {
        final List<dynamic> wordsList = json.decode(wordsJson);
        return wordsList.map((j) => WordPair.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error loading words: $e');
    }
    final defaultWords = getDefaultWords();
    await saveWords(defaultWords);
    return defaultWords;
  }

  static Future<void> saveWords(List<WordPair> words) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(words.map((w) => w.toJson()).toList());
      await prefs.setString(_wordsKey, jsonStr);
    } catch (e) {
      print('Error saving words: $e');
    }
  }

  static Future<Map<String, int>> loadWrongCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countsJson = prefs.getString(_wrongCountsKey);
      if (countsJson != null) {
        final Map<String, dynamic> counts = json.decode(countsJson);
        return counts.map((k, v) => MapEntry(k, v as int));
      }
    } catch (e) {
      print('Error loading wrong counts: $e');
    }
    return {};
  }

  static Future<void> saveWrongCounts(Map<String, int> counts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(counts);
      await prefs.setString(_wrongCountsKey, jsonStr);
    } catch (e) {
      print('Error saving wrong counts: $e');
    }
  }

  static Future<void> addWords(List<WordPair> newWords) async {
    final existing = await loadWords();
    final existingSet = existing.map((w) => w.word.toLowerCase()).toSet();
    final toAdd = newWords.where((w) => !existingSet.contains(w.word.toLowerCase()));
    if (toAdd.isNotEmpty) {
      existing.addAll(toAdd);
      await saveWords(existing);
    }
  }

  static List<WordPair> parseCSV(String csvText) {
    final lines = csvText.trim().split('\n');
    final result = <WordPair>[];
    for (var line in lines) {
      final parts = line.split(',');
      if (parts.length >= 2) {
        final w = parts[0].trim();
        final s = parts[1].trim();
        if (w.isNotEmpty && s.isNotEmpty) {
          result.add(WordPair(word: w, synonym: s));
        }
      }
    }
    return result;
  }
}
