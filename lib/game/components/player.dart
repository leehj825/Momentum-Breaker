import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';

class Player extends BodyComponent {
  static const double radius = 15.0;
  static const double density = 4.0; // Heavy enough to dictate movement (The Boss)
  static const double linearDamping = 4.0; // Good control
  
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
    
    // Set initial velocity to zero to prevent drift
    body.linearVelocity = forge2d.Vector2.zero();
    body.angularVelocity = 0.0;
    
    // Shrink hitbox: make physics shape smaller than visual size (4px buffer)
    final physicsRadius = radius - 4.0;
    final shape = CircleShape();
    shape.radius = physicsRadius; // Use smaller radius for physics
    
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
      // Apply WAY more force to move the heavy player fast
      // High number necessary to overcome high density and linear damping
      final impulseMagnitude = strength * 1000.0;
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

