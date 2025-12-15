import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import 'player.dart';

class Weapon extends BodyComponent {
  static const double baseRadius = 12.0; // Physics radius (unchanged)
  static const double visualRadius = 20.0; // Visual radius (smaller for better gameplay)
  static const double baseDensity = 10.0; // Heavy object has more inertia - resists changing direction, enhances "pulling" feeling
  static const double friction = 0.0; // No friction for free swinging
  
  final Player player;
  final forge2d.Vector2 initialPosition;
  forge2d.DistanceJoint? joint;
  double currentMassMultiplier = 1.0;
  double currentChainLengthMultiplier = 1.0; // Base multiplier for chain length upgrades
  double baseChainLength = 200.0; // Base orbital radius (200px)
  bool hasSpikes = false;
  
  Weapon({required this.player, required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: forge2d.Vector2(initialPosition.x, initialPosition.y),
      linearDamping: 0.01, // Almost zero drag - weapon slides almost forever, maintains momentum
      angularDamping: 0.0, // No angular damping for free rotation
    );
    
    final body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = baseRadius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = baseDensity * currentMassMultiplier
      ..friction = friction // No friction for free swinging
      ..restitution = 0.5 // Higher bounce preserves momentum when hitting walls/enemies
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

    // Calculate the rigid orbital radius
    // We accept whatever distance they spawned at as the "rod length"
    // This ensures no snapping/teleporting on start

    final jointDef = forge2d.DistanceJointDef()
      ..initialize(player.body, body, playerPos, weaponPos)
      ..frequencyHz = 0.0 // 0.0 = Rigid Rod (No elasticity, perfect for swinging)
      ..dampingRatio = 0.0; // 0.0 = No damping (Spin forever)
    // Note: initialize() automatically sets the 'length' property to the distance

    joint = forge2d.DistanceJoint(jointDef);
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
      linearDamping: 0.01, // Almost zero drag - weapon slides almost forever, maintains momentum
      angularDamping: 0.0,
    );
    
    body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = baseRadius; // Use smaller physics radius
    
    final fixtureDef = FixtureDef(shape)
      ..density = baseDensity * currentMassMultiplier
      ..friction = friction // Use constant value
      ..restitution = 0.5 // Higher bounce preserves momentum when hitting walls/enemies
      ..userData = "weapon";
    
    body.createFixture(fixtureDef);
    body.userData = "weapon";
    
    // Recreate joint
    createJoint();
  }

  void updateChainLength(double multiplier) {
    currentChainLengthMultiplier = multiplier;
    if (joint != null) {
      // DistanceJoint.length is not mutable, so we must recreate the joint
      // Calculate new length based on base length and multiplier
      final newLength = baseChainLength * currentChainLengthMultiplier;
      
      // Get current positions
      final playerPos = player.body.worldCenter;
      final weaponPos = body.worldCenter;
      
      // Destroy old joint
      world.destroyJoint(joint!);
      
      // Create new DistanceJoint with updated length
      final jointDef = forge2d.DistanceJointDef()
        ..initialize(player.body, body, playerPos, weaponPos)
        ..frequencyHz = 0.0 // 0.0 = Rigid Rod (No elasticity, perfect for swinging)
        ..dampingRatio = 0.0; // 0.0 = No damping (Spin forever)
      
      // Override the length set by initialize() with our desired length
      jointDef.length = newLength;
      
      joint = forge2d.DistanceJoint(jointDef);
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

