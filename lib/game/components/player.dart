import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Player extends BodyComponent {
  static const double radius = 15.0;
  static const double density = 1.0;
  static const double linearDamping = 10.0; // High damping for quick stops
  
  Vector2? inputDirection;

  Player({required Vector2 position}) : super(position: position);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: position,
      linearDamping: linearDamping,
    );
    
    final body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = radius / worldScale;
    
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

  void applyInput(Vector2 direction, double strength) {
    if (direction.length > 0) {
      final force = direction.normalized() * strength * 1000.0;
      body.applyLinearImpulse(force);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Input is handled externally via applyInput
  }
}

