import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import 'player.dart';

class Weapon extends BodyComponent {
  static const double baseRadius = 25.0;
  static const double baseDensity = 20.0; // Much heavier for more momentum
  static const double friction = 0.0; // No friction for free swinging
  
  final Player player;
  final forge2d.Vector2 initialPosition;
  forge2d.RopeJoint? joint;
  double currentMassMultiplier = 1.0;
  double currentChainLengthMultiplier = 1.5; // Chain length multiplier for swings
  bool hasSpikes = false;
  
  Weapon({required this.player, required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: forge2d.Vector2(initialPosition.x, initialPosition.y),
      linearDamping: 0.02, // Drastically reduced damping for longer swings
      angularDamping: 0.0, // No angular damping for free rotation
    );
    
    final body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = baseRadius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = baseDensity * currentMassMultiplier
      ..friction = friction // No friction for free swinging
      ..restitution = 0.4 // Higher bounce for more dynamic collisions
      ..userData = "weapon"; // String identifier for collision detection
    
    body.createFixture(fixtureDef);
    body.userData = "weapon"; // Also store on body for easier access
    
    // Set initial velocity to zero to prevent drift
    body.linearVelocity = forge2d.Vector2.zero();
    body.angularVelocity = 0.0;
    
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
    // Calculate maximum chain length (allows slack for swinging)
    final maxLength = distance * currentChainLengthMultiplier;
    
    // Use RopeJoint instead of DistanceJoint for chain-like behavior
    // RopeJointDef uses default constructor, then set properties
    final jointDef = forge2d.RopeJointDef()
      ..bodyA = player.body
      ..bodyB = body
      ..maxLength = maxLength; // Maximum rope length (allows slack)
    // localAnchorA and localAnchorB default to Vector2.zero() (body centers)
    
    joint = forge2d.RopeJoint(jointDef);
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
      linearDamping: 0.02, // Match new damping value
      angularDamping: 0.0,
    );
    
    body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = baseRadius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = baseDensity * currentMassMultiplier
      ..friction = friction // Use constant value
      ..restitution = 0.4
      ..userData = "weapon";
    
    body.createFixture(fixtureDef);
    body.userData = "weapon";
    
    // Recreate joint
    createJoint();
  }

  void updateChainLength(double multiplier) {
    currentChainLengthMultiplier = multiplier;
    if (joint != null) {
      final playerPos = player.body.worldCenter;
      final weaponPos = body.worldCenter;
      final distance = (weaponPos - playerPos).length;
      final newMaxLength = distance * currentChainLengthMultiplier;
      
      // Destroy old joint
      world.destroyJoint(joint!);
      
      // Create new RopeJoint with updated max length
      final jointDef = forge2d.RopeJointDef()
        ..bodyA = player.body
        ..bodyB = body
        ..maxLength = newMaxLength; // Maximum rope length
      // localAnchorA and localAnchorB default to Vector2.zero() (body centers)
      
      joint = forge2d.RopeJoint(jointDef);
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

  forge2d.Vector2 getVelocity() {
    return body.linearVelocity;
  }
}

