import 'dart:math' as math;
import 'package:flame/components.dart' hide Vector2;
import 'package:flame/components.dart' as flame show Vector2;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'player.dart';

class Weapon extends BodyComponent {
  static const double baseRadius = 25.0;
  static const double baseDensity = 5.0; // High density for heavy feel
  static const double friction = 0.5;
  
  final Player player;
  final flame.Vector2 initialPosition;
  RopeJoint? joint; // Changed to RopeJoint
  double currentMassMultiplier = 1.0;
  double currentChainLengthMultiplier = 1.0;
  bool hasSpikes = false;
  
  Weapon({required this.player, required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: Vector2(initialPosition.x, initialPosition.y),
      linearDamping: 1.0, // Reduced damping for more swing
      angularDamping: 1.0,
    );
    
    final body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = baseRadius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = baseDensity * currentMassMultiplier
      ..friction = friction
      ..restitution = 0.2
      ..userData = this; // Store reference for collision detection
    
    body.createFixture(fixtureDef);
    body.userData = this; // Also store on body for easier access
    
    return body;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add visual representation
    final circle = CircleComponent(
      radius: baseRadius,
      paint: Paint()..color = Colors.red[900]!,
    );
    circle.anchor = Anchor.center;
    add(circle);
    
    // Add inner circle
    final innerCircle = CircleComponent(
      radius: baseRadius * 0.7,
      paint: Paint()..color = Colors.red[700]!,
    );
    innerCircle.anchor = Anchor.center;
    add(innerCircle);
  }

  Future<void> createJoint() async {
    final playerPos = player.body.worldCenter;
    final weaponPos = body.worldCenter;
    final distance = (weaponPos - playerPos).length;
    final baseChainLength = distance * currentChainLengthMultiplier;
    
    final jointDef = RopeJointDef()
      ..bodyA = player.body
      ..bodyB = body
      ..localAnchorA.setFrom(Vector2.zero())
      ..localAnchorB.setFrom(Vector2.zero())
      ..maxLength = baseChainLength;
    
    joint = RopeJoint(jointDef);
    world.createJoint(joint!);
  }

  void updateMass(double multiplier) {
    currentMassMultiplier = multiplier;
    // Recreate body with new mass
    final oldPos = body.worldCenter;
    final oldVelocity = body.linearVelocity;
    
    world.destroyBody(body);
    
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: oldPos,
      linearDamping: 1.0,
      angularDamping: 1.0,
    );
    
    body = world.createBody(bodyDef);
    body.linearVelocity = oldVelocity; // Preserve velocity
    
    final shape = CircleShape();
    shape.radius = baseRadius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = baseDensity * currentMassMultiplier
      ..friction = friction
      ..restitution = 0.2
      ..userData = this;
    
    body.createFixture(fixtureDef);
    body.userData = this;
    
    // Recreate joint
    createJoint();
  }

  void updateChainLength(double multiplier) {
    currentChainLengthMultiplier = multiplier;
    if (joint != null) {
      final playerPos = player.body.worldCenter;
      final weaponPos = body.worldCenter;
      final distance = (weaponPos - playerPos).length;
      
      // Calculate new length based on multiplier and original distance concept
      // Or just scale current length?
      // Let's use a standard base length logic.
      // Assuming initial distance was ~50.
      final newLength = 50.0 * currentChainLengthMultiplier; 
      
      // Destroy old joint
      world.destroyJoint(joint!);
      
      // Create new joint with updated length
      final jointDef = RopeJointDef()
        ..bodyA = player.body
        ..bodyB = body
        ..localAnchorA.setFrom(Vector2.zero())
        ..localAnchorB.setFrom(Vector2.zero())
        ..maxLength = newLength;
      
      joint = RopeJoint(jointDef);
      world.createJoint(joint!);
    }
  }

  void addSpikes() {
    if (hasSpikes) return;
    hasSpikes = true;
    
    // Add visual spikes
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final spikeLength = baseRadius * 0.4;
      final spikeX = spikeLength * math.cos(angle);
      final spikeY = spikeLength * math.sin(angle);
      
      // Use Flame's Vector2 for component position/size
      final spike = RectangleComponent(
        size: flame.Vector2(5, spikeLength),
        paint: Paint()..color = Colors.grey[900]!,
        angle: angle,
        position: flame.Vector2(spikeX, spikeY),
      );
      spike.anchor = Anchor.bottomCenter;
      add(spike);
    }
  }

  Vector2 getVelocity() {
    return body.linearVelocity;
  }
}
