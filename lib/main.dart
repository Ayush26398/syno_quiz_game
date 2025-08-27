import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/quiz_state.dart';
import 'screens/home_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/add_words_screen.dart';
import 'screens/wrong_words_screen.dart';
import 'screens/stats_screen.dart';

void main() {
  runApp(const SynoQuizApp());
}

class SynoQuizApp extends StatelessWidget {
  const SynoQuizApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => QuizState(),
      child: MaterialApp(
        title: 'Syno Quiz Game',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          cardTheme: CardThemeData(    // use CardThemeData, not CardTheme
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/quiz': (context) => const QuizScreen(),
          '/add': (context) => const AddWordsScreen(),
          '/wrong': (context) => const WrongWordsScreen(),
          '/stats': (context) => const StatsScreen(),
        },
      ),
    );
  }
}
