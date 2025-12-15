import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class Arena extends Component with HasGameReference<MomentumBreakerGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Use screen size (world size = screen size, dynamically adjusted to device)
    final worldSize = game.size;
    
    // Add floor/background (render first, behind everything)
    final floor = RectangleComponent(
      size: worldSize,
      position: Vector2.zero(),
      paint: Paint()..color = const Color(0xFF16213e), // Dark blue floor
    );
    floor.anchor = Anchor.topLeft;
    floor.priority = -100; // Low priority so it renders behind everything
    add(floor);
    
    // Create walls around the arena
    final wallThickness = 20.0;
    final wallColor = Colors.grey[800]!;
    
    // Top wall
    _createWall(
      forge2d.Vector2(worldSize.x / 2, wallThickness / 2),
      forge2d.Vector2(worldSize.x, wallThickness),
      wallColor,
    );
    
    // Bottom wall
    _createWall(
      forge2d.Vector2(worldSize.x / 2, worldSize.y - wallThickness / 2),
      forge2d.Vector2(worldSize.x, wallThickness),
      wallColor,
    );
    
    // Left wall
    _createWall(
      forge2d.Vector2(wallThickness / 2, worldSize.y / 2),
      forge2d.Vector2(wallThickness, worldSize.y),
      wallColor,
    );
    
    // Right wall
    _createWall(
      forge2d.Vector2(worldSize.x - wallThickness / 2, worldSize.y / 2),
      forge2d.Vector2(wallThickness, worldSize.y),
      wallColor,
    );
  }

  void _createWall(forge2d.Vector2 position, forge2d.Vector2 size, Color color) {
    final wallDef = BodyDef(
      type: BodyType.static,
      position: position,
    );
    
    final wallBody = game.world.createBody(wallDef);
    
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;
    final shape = PolygonShape()
      ..setAsBox(halfWidth, halfHeight, forge2d.Vector2.zero(), 0.0);
    
    final fixtureDef = FixtureDef(shape)
      ..friction = 0.3
      ..restitution = 0.1;
    
    wallBody.createFixture(fixtureDef);
    
    // Add visual component
    final wallSprite = RectangleComponent(
      size: size,
      paint: Paint()..color = color,
    );
    wallSprite.anchor = Anchor.center;
    add(wallSprite);
  }
}

