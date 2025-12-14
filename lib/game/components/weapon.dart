import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import 'player.dart';

class Weapon extends BodyComponent {
  static const double baseRadius = 25.0;
  static const double baseDensity = 5.0; // High density for heavy feel
  static const double friction = 0.5;
  
  final Player player;
  final forge2d.Vector2 initialPosition;
  DistanceJoint? joint;
  double currentMassMultiplier = 1.0;
  double currentChainLengthMultiplier = 1.0;
  bool hasSpikes = false;
  
  Weapon({required this.player, required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: forge2d.Vector2(initialPosition.x, initialPosition.y),
      linearDamping: 2.0, // Moderate damping
    );
    
    final body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = baseRadius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = baseDensity * currentMassMultiplier
      ..friction = friction
      ..restitution = 0.2
      ..userData = "weapon"; // String identifier for collision detection
    
    body.createFixture(fixtureDef);
    body.userData = "weapon"; // Also store on body for easier access
    
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
    
    final jointDef = DistanceJointDef()
      ..initialize(
        player.body,
        body,
        playerPos,
        weaponPos,
      )
      ..length = baseChainLength
      ..frequencyHz = 0.0 // No spring effect
      ..dampingRatio = 0.0;
    
    joint = DistanceJoint(jointDef);
    world.createJoint(joint!);
  }

  void updateMass(double multiplier) {
    currentMassMultiplier = multiplier;
    // Recreate body with new mass
    final oldPos = body.worldCenter;
    world.destroyBody(body);
    
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: oldPos,
      linearDamping: 2.0,
    );
    
    body = world.createBody(bodyDef);
    
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
      final newLength = distance * currentChainLengthMultiplier;
      
      // Destroy old joint
      world.destroyJoint(joint!);
      
      // Create new joint with updated length
      final jointDef = DistanceJointDef()
        ..initialize(
          player.body,
          body,
          playerPos,
          weaponPos,
        )
        ..length = newLength
        ..frequencyHz = 0.0
        ..dampingRatio = 0.0;
      
      joint = DistanceJoint(jointDef);
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
      
      final spike = RectangleComponent(
        size: Vector2(5, spikeLength),
        paint: Paint()..color = Colors.grey[900]!,
        angle: angle,
        position: Vector2(spikeX, spikeY),
      );
      spike.anchor = Anchor.bottomCenter;
      add(spike);
    }
  }

  Vector2 getVelocity() {
    return body.linearVelocity;
  }
}

