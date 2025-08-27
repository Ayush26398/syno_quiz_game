class WordPair {
  final String word;
  final String synonym;

  WordPair({required this.word, required this.synonym});

  factory WordPair.fromJson(Map<String, dynamic> json) {
    return WordPair(
      word: json['word'] ?? '',
      synonym: json['synonym'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'synonym': synonym,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WordPair &&
              runtimeType == other.runtimeType &&
              word == other.word &&
              synonym == other.synonym;

  @override
  int get hashCode => word.hashCode ^ synonym.hashCode;
}

class WrongWordStat {
  final String word;
  final int count;

  WrongWordStat({required this.word, required this.count});

  factory WrongWordStat.fromJson(Map<String, dynamic> json) {
    return WrongWordStat(
      word: json['word'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'count': count,
    };
  }
}
