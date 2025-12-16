import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';

class Player extends BodyComponent {
  static const double radius = 15.0;
  static const double visualRadius = 18.0;
  static const double density = 20.0; // Heavy anchor - much heavier than weapon to pull it around without being yanked
  static const double linearDamping = 10.0; // High damping for instant stops - player moves instantly, stops instantly
  static const double speed = 1000.0; // Fast movement speed for responsive touch-following
  
  forge2d.Vector2? targetPosition; // Target position to move towards
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
    
    // Set initial velocity to zero
    body.linearVelocity = forge2d.Vector2.zero();
    body.angularVelocity = 0.0;
    
    // Physics shape
    final physicsRadius = radius - 4.0;
    final shape = CircleShape();
    shape.radius = physicsRadius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = density
      ..friction = 0.3
      ..restitution = 0.0 // No bounce
      ..userData = "player";
    
    body.createFixture(fixtureDef);
    body.userData = "player";
    
    return body;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add visual representation
    final circle = CircleComponent(
      radius: visualRadius,
      paint: Paint()..color = Colors.blue,
    );
    circle.anchor = Anchor.center;
    add(circle);
    
    // Add inner circle for better visibility
    final innerCircle = CircleComponent(
      radius: visualRadius * 0.6,
      paint: Paint()..color = Colors.lightBlue,
    );
    innerCircle.anchor = Anchor.center;
    add(innerCircle);
  }

  void setTargetPosition(forge2d.Vector2? position) {
    // Set target position to move towards (null to stop)
    targetPosition = position;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move towards target position at constant speed
    if (targetPosition != null) {
      final currentPos = body.worldCenter;
      final direction = targetPosition! - currentPos;
      final distance = direction.length;
      
      // If close enough to target, stop
      if (distance < 5.0) {
        body.linearVelocity = forge2d.Vector2.zero();
      } else {
        // Move towards target using massive force for instant response
        // With high density (20.0) and high damping (10.0), we need huge force
        final normalized = direction.normalized();
        
        // Apply massive force for instant movement
        // With high density (20.0) and high damping (10.0), we need huge force
        final forceMagnitude = 60000.0; // Massive force multiplier to overcome high density and damping
        
        final force = forge2d.Vector2(
          normalized.x * forceMagnitude * body.mass,
          normalized.y * forceMagnitude * body.mass,
        );
        
        body.applyForce(force);
      }
    } else {
      // Stop immediately when no target
      body.linearVelocity = forge2d.Vector2.zero();
    }
  }
}
