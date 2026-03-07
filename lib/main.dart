import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'data/models/nationality.dart';
import 'engines/save_engine.dart';
import 'providers/game_provider.dart';
import 'ui/screens/character_creation_screen.dart';
import 'ui/screens/nationality_selection_screen.dart';
import 'ui/screens/origin_selection_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    riverpod.ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => GameProvider(),
        child: const VillagesTownApp(),
      ),
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

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  bool _checkingForSave = true;
  bool _hasSave = false;
  Nationality? _selectedNationality;
  String? _characterName;
  bool _wasInGame = false;

  @override
  void initState() {
    super.initState();
    _checkSave();
  }

  Future<void> _checkSave() async {
    final has = await SaveEngine.hasSave();
    if (mounted) setState(() { _checkingForSave = false; _hasSave = has; });
  }

  Future<void> _loadSave() async {
    final game = context.read<GameProvider>().gameManager;
    final success = await SaveEngine.loadGame(game);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load save')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;

        if (game.gameStarted) {
          // Remember that we were in-game so we can reset creation
          // state if the player returns to menu.
          _wasInGame = true;
          return const GameScreen();
        }

        // Returning from a running game → reset creation flow
        if (_wasInGame) {
          _wasInGame = false;
          _selectedNationality = null;
          _characterName = null;
        }

        if (_checkingForSave) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Step 3: Origin selection
        if (_selectedNationality != null && _characterName != null) {
          return OriginSelectionScreen(
            nationality: _selectedNationality!,
            characterName: _characterName!,
            onSelect: (origin) {
              game.setupGame(_selectedNationality!);
              game.initializeGame(
                characterName: _characterName!,
                origin: origin,
              );
            },
          );
        }

        // Step 2: Character naming
        if (_selectedNationality != null) {
          return CharacterCreationScreen(
            nationality: _selectedNationality!,
            onNext: (name) {
              setState(() => _characterName = name);
            },
          );
        }

        // Step 1: Nationality selection
        return NationalitySelectionScreen(
          hasSavedGame: _hasSave,
          onSelect: (nationality) {
            setState(() => _selectedNationality = nationality);
          },
          onContinue: _hasSave ? () => _loadSave() : null,
        );
      },
    );
  }
}
