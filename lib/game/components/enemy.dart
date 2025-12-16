import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import 'player.dart';
import '../momentum_breaker_game.dart';

class Enemy extends BodyComponent {
  static const double size = 20.0;
  static const double speed = 50.0;
  static const double health = 100.0;
  static const double density = 1.0; // Lighter than weapon
  static const double linearDamping = 5.0; // They shouldn't fly forever when hit
  
  final Player player;
  final forge2d.Vector2 initialPosition;
  double currentHealth = health;
  bool isDestroyed = false;

  Enemy({required this.player, required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: forge2d.Vector2(initialPosition.x, initialPosition.y),
      linearDamping: linearDamping,
      fixedRotation: true, // Lock rotation so enemies don't roll around
    );
    
    final body = world.createBody(bodyDef);
    
    // Shrink hitbox: make physics shape smaller than visual size
    final halfSize = (size - 6) / 2;
    final shape = PolygonShape()
      ..setAsBox(halfSize, halfSize, forge2d.Vector2.zero(), 0.0);
    
    final fixtureDef = FixtureDef(shape)
      ..density = density
      ..friction = 0.3
      ..restitution = 0.1
      ..isSensor = false
      ..userData = "enemy";
    
    body.createFixture(fixtureDef);
    body.userData = "enemy";
    
    return body;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add visual representation
    final square = RectangleComponent(
      size: Vector2(size, size),
      paint: Paint()..color = Colors.green,
    );
    square.anchor = Anchor.center;
    add(square);
    
    // Add inner square for visibility
    final innerSquare = RectangleComponent(
      size: Vector2(size * 0.7, size * 0.7),
      paint: Paint()..color = Colors.lightGreen,
    );
    innerSquare.anchor = Anchor.center;
    add(innerSquare);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Stop movement if game isn't playing or enemy is destroyed
    final game = parent as MomentumBreakerGame;
    if (!game.isPlaying || isDestroyed) {
      return;
    }
    
    // Move towards player using ApplyForce (allows knockback to work)
    final playerPos = player.body.worldCenter;
    final enemyPos = body.worldCenter;
    final direction = (playerPos - enemyPos);
    
    // Only apply movement force if moving slower than max speed
    // This allows knockback (high speed) to decay naturally
    if (direction.length > 0.1 && body.linearVelocity.length < speed / 2) {
      final normalized = direction.normalized();
      // Use ApplyForce so enemies get knocked back properly when hit by the heavy weapon
      body.applyForce(normalized * speed * body.mass * 10);
    }
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
