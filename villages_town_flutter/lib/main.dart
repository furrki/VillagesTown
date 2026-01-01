import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'ui/screens/nationality_selection_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: const VillagesTownApp(),
    ),
  );
}

class VillagesTownApp extends StatelessWidget {
  const VillagesTownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Villages Town',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const ContentView(),
    );
  }
}

class ContentView extends StatelessWidget {
  const ContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;

        if (!game.gameStarted) {
          return NationalitySelectionScreen(
            onSelect: (nationality) {
              game.setupGame(nationality);
              game.initializeGame();
            },
          );
        }

        return const GameScreen();
      },
    );
  }
}
