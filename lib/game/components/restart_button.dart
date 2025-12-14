import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class RestartButton extends RectangleComponent 
    with TapCallbacks, HasGameRef<MomentumBreakerGame> {
  final VoidCallback onRestart;

  RestartButton({
    required this.onRestart,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Position button in top-right corner
    position = Vector2(gameRef.size.x - 120, 40);
    size = Vector2(100, 50);
    anchor = Anchor.center;
    
    paint = Paint()..color = Colors.green.withOpacity(0.8);
    
    priority = 200; // High priority to receive events
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRect(size.toRect(), borderPaint);
    
    // Draw text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Restart',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
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
    onRestart();
    return true;
  }
}

