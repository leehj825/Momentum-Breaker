import 'package:flame/components.dart' hide Vector2;
import 'package:flame/components.dart' as flame show Vector2;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import '../momentum_breaker_game.dart';

class Enemy extends BodyComponent {
  static const double size = 20.0;
  static const double speed = 40.0; // Slightly reduced speed for dynamic body control
  static const double health = 100.0;
  static const double linearDamping = 5.0;
  
  final Player player;
  final flame.Vector2 initialPosition;
  double currentHealth = health;
  bool isDestroyed = false;

  Enemy({required this.player, required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic, // Changed to dynamic for physics interactions
      position: Vector2(initialPosition.x, initialPosition.y),
      linearDamping: linearDamping,
      fixedRotation: true, // Keep orientation fixed for now
    );
    
    final body = world.createBody(bodyDef);
    
    final halfSize = size / 2;
    final shape = PolygonShape()
      ..setAsBox(halfSize, halfSize, Vector2.zero(), 0.0);
    
    final fixtureDef = FixtureDef(shape)
      ..density = 2.0 // Heavier than player
      ..friction = 0.3
      ..restitution = 0.2
      ..userData = this;
    
    body.createFixture(fixtureDef);
    body.userData = this;
    
    return body;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add visual representation
    final square = RectangleComponent(
      size: flame.Vector2(size, size),
      paint: Paint()..color = Colors.green,
    );
    square.anchor = Anchor.center;
    add(square);
    
    // Add inner square for visibility
    final innerSquare = RectangleComponent(
      size: flame.Vector2(size * 0.7, size * 0.7),
      paint: Paint()..color = Colors.lightGreen,
    );
    innerSquare.anchor = Anchor.center;
    add(innerSquare);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isDestroyed) return;
    
    // Move towards player
    final playerPos = player.body.worldCenter;
    final enemyPos = body.worldCenter;
    final direction = (playerPos - enemyPos).normalized();
    
    // Apply force to move
    final force = direction * speed * 4000.0; // Adjusted multiplier
    body.applyForce(force);
  }

  void takeDamage(double damage) {
    currentHealth -= damage;
    if (currentHealth <= 0 && !isDestroyed) {
      isDestroyed = true;
      final game = parent as MomentumBreakerGame;
      game.onEnemyDestroyed(this);
    }
  }
}
