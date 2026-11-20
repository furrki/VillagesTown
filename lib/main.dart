import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'data/models/nationality.dart';
import 'engines/game_manager.dart';
import 'engines/save_engine.dart';
import 'providers/game_provider.dart';
import 'purchases/full_game.dart';
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

void handleCampaignSaveLifecycle(GameManager game, AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      SaveEngine.retryPendingSave(game);
    case AppLifecycleState.paused:
    case AppLifecycleState.inactive:
    case AppLifecycleState.hidden:
    case AppLifecycleState.detached:
      SaveEngine.saveGame(game);
  }
}

class _ContentViewState extends State<ContentView> with WidgetsBindingObserver {
  bool _checkingForSave = true;
  bool _hasSave = false;
  Nationality? _selectedNationality;
  String? _characterName;
  String _nameDraft = '';
  bool _wasInGame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FullGame.instance.start();
    _checkSave();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Leaving the foreground can end the app: save what was done since the last autosave.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) FullGame.instance.onResume();
    handleCampaignSaveLifecycle(context.read<GameProvider>().gameManager, state);
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
          _nameDraft = '';
          // The game may have autosaved, so the menu must not trust the startup check.
          _checkingForSave = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkSave());
        }

        if (_checkingForSave) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Step 3: Origin selection
        if (_selectedNationality != null && _characterName != null) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) setState(() => _characterName = null);
            },
            child: OriginSelectionScreen(
            nationality: _selectedNationality!,
            characterName: _characterName!,
            onBack: () => setState(() => _characterName = null),
            onSelect: (origin) {
              game.setupGame(_selectedNationality!);
              game.initializeGame(
                characterName: _characterName!,
                origin: origin,
              );
            },
            ),
          );
        }

        // Step 2: Character naming
        if (_selectedNationality != null) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) setState(() => _selectedNationality = null);
            },
            child: CharacterCreationScreen(
            nationality: _selectedNationality!,
            initialName: _nameDraft,
            onBack: () => setState(() => _selectedNationality = null),
            onNext: (name) {
              setState(() { _nameDraft = name; _characterName = name; });
            },
            ),
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
