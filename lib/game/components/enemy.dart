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
  
  final Player player;
  final forge2d.Vector2 initialPosition;
  double currentHealth = health;
  bool isDestroyed = false;

  Enemy({required this.player, required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic, // Dynamic so it can move and interact with physics properly
      position: forge2d.Vector2(initialPosition.x, initialPosition.y),
      fixedRotation: true, // Lock rotation so enemies don't roll around
    );
    
    final body = world.createBody(bodyDef);
    
    // Shrink hitbox: make physics shape smaller than visual size (3px buffer on each side)
    final halfSize = (size - 6) / 2;
    final shape = PolygonShape()
      ..setAsBox(halfSize, halfSize, forge2d.Vector2.zero(), 0.0);
    
    final fixtureDef = FixtureDef(shape)
      ..density = 1.0 // Add density for dynamic body
      ..friction = 0.3
      ..restitution = 0.1
      ..isSensor = false // Not a sensor so it can collide
      ..userData = "enemy"; // String identifier for collision detection
    
    body.createFixture(fixtureDef);
    body.userData = "enemy"; // Also store on body for easier access
    
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
      // Stop velocity when not playing
      body.linearVelocity = forge2d.Vector2.zero();
      return;
    }
    
    // Move towards player using velocity (proper physics instead of teleportation)
    final playerPos = player.body.worldCenter;
    final enemyPos = body.worldCenter;
    final direction = (playerPos - enemyPos).normalized();
    
    // Set velocity instead of using setTransform
    body.linearVelocity = direction * speed;
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

