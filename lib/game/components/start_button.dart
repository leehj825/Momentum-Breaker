import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class StartButton extends RectangleComponent 
    with TapCallbacks, HasGameRef<MomentumBreakerGame> {
  final VoidCallback onStart;
  bool _hasRendered = false;

  StartButton({
    required this.onStart,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Set size and position - model after UpgradeButton
    size = Vector2(250, 100);
    anchor = Anchor.center;
    
    // Use paint property like UpgradeButton does
    paint = Paint()..color = Colors.green.withOpacity(0.9);
    
    priority = 1001; // Very high priority to render on top and receive events
    
    // Debug: print to verify button is created
    print('StartButton created with size: $size');
  }
  
  @override
  void onMount() {
    super.onMount();
    // Position button in center when mounted (size should be available)
    _updatePosition();
  }
  
  void _updatePosition() {
    // Use screen size for UI positioning (viewport space)
    final screenSize = gameRef.size;
    print('StartButton _updatePosition: screenSize=$screenSize, current position=$position');
    if (screenSize.x > 0 && screenSize.y > 0) {
      position = Vector2(screenSize.x / 2, screenSize.y / 2);
      print('StartButton positioned at center: $position');
    } else {
      // Try a fixed position that should be visible
      position = Vector2(400, 300); // Center of typical screen
      print('StartButton using fallback position: $position');
    }
    // Force a very large size to ensure visibility
    if (size.x < 200) {
      size = Vector2(300, 120);
      print('StartButton size forced to: $size');
    }
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Update position when game resizes
    _updatePosition();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    // Ensure position is set even if onGameResize didn't fire
    if (position.x == 0 && position.y == 0) {
      _updatePosition();
    }
  }

  @override
  void render(Canvas canvas) {
    // Debug: print when rendering
    if (!_hasRendered) {
      print('StartButton render called! position=$position, size=$size');
      _hasRendered = true;
    }
    
    // Draw button background using super.render (like UpgradeButton)
    super.render(canvas);
    
    // Draw border with thicker line
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawRect(size.toRect(), borderPaint);
    
    // Draw text with larger font - make it very visible
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
  bool containsLocalPoint(Vector2 point) {
    // Make sure hit detection works
    return point.x >= 0 && point.x <= size.x && point.y >= 0 && point.y <= size.y;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    onStart();
    return true;
  }
}

