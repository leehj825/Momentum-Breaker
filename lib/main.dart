import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import 'game/momentum_breaker_game.dart';
import 'game/game_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        title: 'Momentum Breaker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const GameScreen(),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final game = MomentumBreakerGame();
    game.gameState = gameState;
    
    return Scaffold(
      body: GameWidget<MomentumBreakerGame>.controlled(
        gameFactory: () => game,
      ),
    );
  }
}

