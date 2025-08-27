import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/enhanced_quiz_state.dart';   // Use enhanced state
import 'screens/enhanced_home_screen.dart'; // Use enhanced home screen
import 'screens/enhanced_quiz_screen.dart';
import 'screens/enhanced_stats_screen.dart';
import 'screens/add_words_screen.dart';
import 'screens/wrong_words_screen.dart';

void main() {
  runApp(const SynoSRSApp());
}

class SynoSRSApp extends StatelessWidget {
  const SynoSRSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EnhancedQuizState(),   // Provide the enhanced quiz state
      child: MaterialApp(
        title: 'Syno SRS - Spaced Repetition Vocabulary',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
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
        home: const EnhancedHomeScreen(),  // Start with the new home screen
        routes: {
          // You can add additional routes to other enhanced screens here:
          '/quiz': (context) => const EnhancedQuizScreen(),
          '/stats': (context) => const EnhancedStatsScreen(),
          // Enhanced route names used by the new UI
          '/enhanced_quiz': (context) => const EnhancedQuizScreen(),
          '/enhanced_stats': (context) => const EnhancedStatsScreen(),
          '/add': (context) => const AddWordsScreen(),        // Keep old screens if desired
          '/wrong': (context) => const WrongWordsScreen(),
          // Or replace with enhanced versions if implemented
        },
      ),
    );
  }
}
