import 'package:flame/components.dart' hide Vector2;
import 'package:flame/components.dart' as flame show Vector2;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class Arena extends Component with HasGameRef<MomentumBreakerGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    final worldSize = gameRef.size;
    
    // Create walls around the arena
    final wallThickness = 20.0;
    final wallColor = Colors.grey[800]!;
    
    // Top wall
    _createWall(
      Vector2(worldSize.x / 2, wallThickness / 2),
      flame.Vector2(worldSize.x, wallThickness),
      wallColor,
    );
    
    // Bottom wall
    _createWall(
      Vector2(worldSize.x / 2, worldSize.y - wallThickness / 2),
      flame.Vector2(worldSize.x, wallThickness),
      wallColor,
    );
    
    // Left wall
    _createWall(
      Vector2(wallThickness / 2, worldSize.y / 2),
      flame.Vector2(wallThickness, worldSize.y),
      wallColor,
    );
    
    // Right wall
    _createWall(
      Vector2(worldSize.x - wallThickness / 2, worldSize.y / 2),
      flame.Vector2(wallThickness, worldSize.y),
      wallColor,
    );
  }

  void _createWall(Vector2 position, flame.Vector2 size, Color color) {
    final wallDef = BodyDef(
      type: BodyType.static,
      position: position,
    );
    
    final wallBody = gameRef.world.createBody(wallDef);
    
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;
    final shape = PolygonShape()
      ..setAsBox(halfWidth, halfHeight, Vector2.zero(), 0.0);
    
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

