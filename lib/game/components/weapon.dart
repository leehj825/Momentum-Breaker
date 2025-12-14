import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import 'player.dart';

class Weapon extends BodyComponent {
  static const double baseRadius = 12.0; // Smaller physics radius for better balance
  static const double visualRadius = 25.0; // Visual size stays larger
  static const double baseDensity = 3.0; // Heavy enough to hit, light enough to pull
  static const double friction = 0.0; // No friction for free swinging
  
  final Player player;
  final forge2d.Vector2 initialPosition;
  forge2d.RopeJoint? joint;
  double currentMassMultiplier = 1.0;
  double currentChainLengthMultiplier = 1.0; // Base multiplier (1.2 rope length is applied in createJoint)
  bool hasSpikes = false;
  
  Weapon({required this.player, required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: forge2d.Vector2(initialPosition.x, initialPosition.y),
      linearDamping: 0.3, // Some air resistance to prevent chaotic swinging
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
    
    // Add visual representation (use visualRadius for visuals, baseRadius for physics)
    final circle = CircleComponent(
      radius: visualRadius,
      paint: Paint()..color = Colors.red[900]!,
    );
    circle.anchor = Anchor.center;
    add(circle);
    
    // Add inner circle
    final innerCircle = CircleComponent(
      radius: visualRadius * 0.7,
      paint: Paint()..color = Colors.red[700]!,
    );
    innerCircle.anchor = Anchor.center;
    add(innerCircle);
  }

  Future<void> createJoint() async {
    final playerPos = player.body.worldCenter;
    final weaponPos = body.worldCenter;
    final distance = (weaponPos - playerPos).length;
    // Calculate maximum chain length (slightly tighter rope for better control)
    // Base is 1.2, then apply multiplier for upgrades
    final maxLength = distance * 1.2 * currentChainLengthMultiplier;
    
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
      linearDamping: 0.3, // Match new damping value
      angularDamping: 0.0,
    );
    
    body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = baseRadius; // Use smaller physics radius
    
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
      // Use 1.2 base multiplier for tighter rope control, then apply upgrade multiplier
      final newMaxLength = distance * 1.2 * currentChainLengthMultiplier;
      
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
      final spikeLength = visualRadius * 0.4; // Use visual radius for spike positioning
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

