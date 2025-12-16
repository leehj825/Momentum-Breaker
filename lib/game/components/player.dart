import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';

class Player extends BodyComponent {
  static const double radius = 15.0;
  static const double visualRadius = 18.0;
  static const double density = 20.0; // Heavy enough to pull the weapon without getting yanked
  static const double linearDamping = 10.0; // Lower damping makes player feel less sluggish, while still stopping quickly enough to "whip" the chain
  static const double speed = 400.0; // Increased movement speed for snappier, more responsive control
  
  forge2d.Vector2? inputDirection;
  double inputStrength = 0.0;
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

  void applyInput(forge2d.Vector2 direction, double strength) {
    // Store input for velocity-based movement
    inputDirection = direction;
    inputStrength = strength;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Velocity-based movement: 1:1 control
    // If joystick moves, player moves. If joystick stops, player stops.
    if (inputDirection != null && inputStrength > 0) {
      final velocity = forge2d.Vector2(
        inputDirection!.x * speed * inputStrength,
        inputDirection!.y * speed * inputStrength,
      );
      body.linearVelocity = velocity;
    } else {
      // Stop immediately when no input
      body.linearVelocity = forge2d.Vector2.zero();
    }
  }
}
