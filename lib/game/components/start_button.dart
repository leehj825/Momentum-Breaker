import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class StartButton extends RectangleComponent 
    with TapCallbacks, HasGameRef<MomentumBreakerGame> {
  final VoidCallback onStart;

  StartButton({
    required this.onStart,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Position button in center of screen
    position = Vector2(gameRef.size.x / 2, gameRef.size.y / 2);
    size = Vector2(150, 60);
    anchor = Anchor.center;
    
    paint = Paint()..color = Colors.green.withOpacity(0.9);
    
    priority = 200; // High priority to receive events
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawRect(size.toRect(), borderPaint);
    
    // Draw text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Start Game',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: size.x);
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool onTapDown(TapDownEvent event) {
    onStart();
    return true;
  }
}

