import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class UpgradeOverlay extends Component with HasGameReference<MomentumBreakerGame> {
  final Function(UpgradeType) onUpgradeSelected;

  UpgradeOverlay({required this.onUpgradeSelected});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // High priority to ensure overlay receives events and renders on top
    priority = 1000;
    
    // UI components should stick to screen (viewport space), not world space
    // This tells Flame to ignore the camera and draw directly on the glass
    // Note: PositionType.viewport may not be available in all Flame versions
    // Components added to game root (not camera.viewfinder) should work correctly
    // positionType = PositionType.viewport; // Uncomment if available
    
    // Get screen size for UI layout (viewport space)
    final overlaySize = game.size;
    
    // Add overlay background
    final background = RectangleComponent(
      size: overlaySize,
      paint: Paint()..color = Colors.black.withOpacity(0.7),
    );
    add(background);
    
    // Add upgrade buttons
    final buttonWidth = overlaySize.x * 0.25;
    final buttonHeight = 100.0;
    final spacing = overlaySize.x * 0.05;
    final startX = (overlaySize.x - (buttonWidth * 3 + spacing * 2)) / 2;
    final y = overlaySize.y / 2;
    
    // Heavy Hitter button
    final heavyHitterButton = UpgradeButton(
      position: Vector2(startX, y),
      size: Vector2(buttonWidth, buttonHeight),
      title: 'Heavy Hitter',
      description: '+20% Mass',
      color: Colors.orange,
      onTap: () => onUpgradeSelected(UpgradeType.heavyHitter),
    );
    add(heavyHitterButton);
    
    // Long Reach button
    final longReachButton = UpgradeButton(
      position: Vector2(startX + buttonWidth + spacing, y),
      size: Vector2(buttonWidth, buttonHeight),
      title: 'Long Reach',
      description: '+15% Chain Length',
      color: Colors.blue,
      onTap: () => onUpgradeSelected(UpgradeType.longReach),
    );
    add(longReachButton);
    
    // Spikes button
    final spikesButton = UpgradeButton(
      position: Vector2(startX + (buttonWidth + spacing) * 2, y),
      size: Vector2(buttonWidth, buttonHeight),
      title: 'Spikes',
      description: 'Add Spikes',
      color: Colors.purple,
      onTap: () => onUpgradeSelected(UpgradeType.spikes),
    );
    add(spikesButton);
    
    // Add title
    final title = TextComponent(
      text: 'Choose an Upgrade',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(overlaySize.x / 2, y - 150),
      anchor: Anchor.center,
    );
    add(title);
  }
}

class UpgradeButton extends RectangleComponent with TapCallbacks, HasGameReference<MomentumBreakerGame> {
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  UpgradeButton({
    required Vector2 position,
    required Vector2 size,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    paint = Paint()..color = color.withOpacity(0.8);
    
    // High priority to ensure buttons receive tap events
    priority = 1001;
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
      text: TextSpan(
        text: '$title\n$description',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
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
    onTap();
    return true;
  }
}

