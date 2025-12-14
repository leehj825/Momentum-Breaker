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
    // Use gameRef.size which should be available after onLoad
    final gameSize = gameRef.size;
    position = Vector2(gameSize.x / 2, gameSize.y / 2);
    size = Vector2(200, 80); // Larger button for better visibility
    anchor = Anchor.center;
    
    paint = Paint()..color = Colors.green.withOpacity(0.95); // More opaque
    
    priority = 200; // High priority to receive events
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Update position when game resizes
    position = Vector2(size.x / 2, size.y / 2);
  }

  @override
  void render(Canvas canvas) {
    // Draw button background (super.render draws the rectangle)
    super.render(canvas);
    
    // Draw border with thicker line
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawRect(size.toRect(), borderPaint);
    
    // Draw text with larger font
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'START GAME',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Colors.black87,
            ),
          ],
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

