import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import 'player.dart';

class Weapon extends BodyComponent {
  static const double baseRadius = 12.0;
  static const double visualRadius = 20.0;
  static const double baseDensity = 1.0; // Lightweight = Fast Acceleration
  static const double linearDamping = 0.05; // Low drag removes "underwater" feel - weapon preserves speed
  static const double friction = 0.0; // No friction against walls
  static const double baseMaxLength = 150.0; // Fixed reach (base) - shortened for closer combat
  
  final Player player;
  final forge2d.Vector2 initialPosition;
  forge2d.RopeJoint? joint;
  double currentMassMultiplier = 1.0;
  double currentChainLengthMultiplier = 1.0; // Multiplier for chain length upgrades
  bool hasSpikes = false;
  
  Weapon({required this.player, required this.initialPosition});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: forge2d.Vector2(initialPosition.x, initialPosition.y),
      linearDamping: linearDamping,
      angularDamping: 0.0,
      bullet: true, // Enable bullet mode - prevents fast-moving weapon from tunneling through walls
    );
    
    final body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = baseRadius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = baseDensity * currentMassMultiplier
      ..friction = friction
      ..restitution = 0.5 // Bouncy. If it hits a wall, it should bounce off, not stick
      ..userData = "weapon";
    
    body.createFixture(fixtureDef);
    body.userData = "weapon";
    
    // Set initial velocity to zero
    body.linearVelocity = forge2d.Vector2.zero();
    body.angularVelocity = 0.0;
    
    return body;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add visual representation
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

  @override
  void update(double dt) {
    super.update(dt);
    
    // ARTIFICIAL TENSION SYSTEM - High Speed Whip Physics
    // Constantly push weapon away from player (simulating centrifugal force)
    final playerPos = player.body.worldCenter;
    final myPos = body.worldCenter;
    final diff = myPos - playerPos;
    
    if (diff.length > 0.1) {
      final direction = diff.normalized();
      // Apply continuous outward force to keep chain taut
      // 2000.0 multiplier gives it a strong "flinging" tendency
      final forceMagnitude = body.mass * 2000.0;
      final force = forge2d.Vector2(
        direction.x * forceMagnitude,
        direction.y * forceMagnitude,
      );
      
      body.applyForce(force);
    }
  }

  Future<void> createJoint() async {
    // Use fixed maxLength with multiplier for upgrades
    // No slack multiplier needed because Artificial Tension will keep it at max length naturally
    final maxLength = baseMaxLength * currentChainLengthMultiplier;
    
    final jointDef = forge2d.RopeJointDef()
      ..bodyA = player.body
      ..bodyB = body
      ..maxLength = maxLength;
    // localAnchorA and localAnchorB default to Vector2.zero() (body centers)
    
    joint = forge2d.RopeJoint(jointDef);
    world.createJoint(joint!);
  }

  void updateMass(double multiplier) {
    currentMassMultiplier = multiplier;
    // Recreate body with new mass
    final oldPos = body.worldCenter;
    final oldVel = body.linearVelocity;
    world.destroyBody(body);
    
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: oldPos,
      linearDamping: linearDamping,
      angularDamping: 0.0,
      bullet: true, // Enable bullet mode - prevents fast-moving weapon from tunneling through walls
    );
    
    body = world.createBody(bodyDef);
    
    final shape = CircleShape();
    shape.radius = baseRadius;
    
    final fixtureDef = FixtureDef(shape)
      ..density = baseDensity * currentMassMultiplier
      ..friction = friction
      ..restitution = 0.5
      ..userData = "weapon";
    
    body.createFixture(fixtureDef);
    body.userData = "weapon";
    
    // Restore velocity
    body.linearVelocity = oldVel;
    
    // Recreate joint
    createJoint();
  }

  void updateChainLength(double multiplier) {
    currentChainLengthMultiplier = multiplier;
    if (joint != null) {
      // Destroy old joint
      world.destroyJoint(joint!);
      
      // Create new RopeJoint with updated max length
      final maxLength = baseMaxLength * currentChainLengthMultiplier;
      final jointDef = forge2d.RopeJointDef()
        ..bodyA = player.body
        ..bodyB = body
        ..maxLength = maxLength;
      
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
      final spikeLength = visualRadius * 0.4;
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
