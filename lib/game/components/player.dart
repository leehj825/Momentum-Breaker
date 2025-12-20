import 'package:flame/components.dart' hide Vector2;
import 'package:flame/components.dart' as flame show Vector2;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Player extends BodyComponent {
  static const double radius = 15.0;
  static const double density = 1.0;
  static const double linearDamping = 5.0; // Reduced from 10.0 for better feel with continuous force
  
  flame.Vector2 _currentInput = flame.Vector2.zero();
  double _currentStrength = 0.0;
  final flame.Vector2 initialPosition;

  Player({required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: Vector2(initialPosition.x, initialPosition.y),
      linearDamping: linearDamping,
    );
    
    final body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = radius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = density
      ..friction = 0.3
      ..restitution = 0.1;
    
    body.createFixture(fixtureDef);
    
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

  void applyInput(flame.Vector2 direction, double strength) {
    _currentInput = direction;
    _currentStrength = strength;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (_currentStrength > 0 && _currentInput.length > 0) {
      final normalized = _currentInput.normalized();
      // Apply force (mass * acceleration). 
      // Adjusted multiplier for continuous force application
      final force = Vector2(normalized.x, normalized.y) * _currentStrength * 300000.0;
      body.applyForce(force);
    }
  }
}
