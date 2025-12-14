import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';

class Player extends BodyComponent {
  static const double radius = 15.0;
  static const double density = 1.0;
  static const double linearDamping = 10.0; // High damping for quick stops
  
  forge2d.Vector2? inputDirection;
  final forge2d.Vector2 initialPosition;

  Player({required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: forge2d.Vector2(initialPosition.x, initialPosition.y),
      linearDamping: linearDamping,
    );
    
    final body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = radius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = density
      ..friction = 0.3
      ..restitution = 0.1
      ..userData = "player"; // String identifier for collision detection
    
    body.createFixture(fixtureDef);
    body.userData = "player"; // Also store on body for easier access
    
    return body;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add visual representation
    final circle = CircleComponent(
      radius: radius,
      paint: Paint()..color = Colors.blue,
    );
    circle.anchor = Anchor.center;
    add(circle);
    
    // Add inner circle for better visibility
    final innerCircle = CircleComponent(
      radius: radius * 0.6,
      paint: Paint()..color = Colors.lightBlue,
    );
    innerCircle.anchor = Anchor.center;
    add(innerCircle);
  }

  void applyInput(forge2d.Vector2 direction, double strength) {
    if (direction.length > 0 && strength > 0) {
      final normalized = direction.normalized();
      // Apply impulse every frame for continuous movement
      // Using impulse scaled by mass for consistent feel
      final impulseMagnitude = strength * 50.0; // Impulse multiplier
      final impulse = forge2d.Vector2(
        normalized.x * impulseMagnitude * body.mass,
        normalized.y * impulseMagnitude * body.mass,
      );
      body.applyLinearImpulse(impulse);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Input is handled externally via applyInput
  }
}

