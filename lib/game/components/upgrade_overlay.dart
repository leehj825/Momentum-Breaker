import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class UpgradeOverlay extends Component with HasGameRef<MomentumBreakerGame> {
  final Function(UpgradeType) onUpgradeSelected;

  UpgradeOverlay({required this.onUpgradeSelected});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add overlay background
    final background = RectangleComponent(
      size: gameRef.size,
      paint: Paint()..color = Colors.black.withOpacity(0.7),
    );
    add(background);
    
    // Add upgrade buttons
    final buttonWidth = gameRef.size.x * 0.25;
    final buttonHeight = 100.0;
    final spacing = gameRef.size.x * 0.05;
    final startX = (gameRef.size.x - (buttonWidth * 3 + spacing * 2)) / 2;
    final y = gameRef.size.y / 2;
    
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
      position: Vector2(gameRef.size.x / 2, y - 150),
      anchor: Anchor.center,
    );
    add(title);
  }
}

class UpgradeButton extends RectangleComponent with TapCallbacks, HasGameRef<MomentumBreakerGame> {
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

