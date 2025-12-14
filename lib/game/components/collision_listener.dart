import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'enemy.dart';
import '../momentum_breaker_game.dart';

class GameContactListener extends ContactListener {
  final MomentumBreakerGame game;
  
  // Queue for safe enemy removal (don't remove during physics step)
  final List<Enemy> _enemiesToRemove = [];

  GameContactListener(this.game);

  @override
  void beginContact(Contact contact) {
    final fixtureA = contact.fixtureA;
    final fixtureB = contact.fixtureB;
    
    final userDataA = fixtureA.body.userData;
    final userDataB = fixtureB.body.userData;
    
    // Case A: Weapon hits Enemy
    if ((userDataA == "weapon" && userDataB == "enemy") ||
        (userDataA == "enemy" && userDataB == "weapon")) {
      _handleWeaponEnemyCollision(contact);
    }
    
    // Case B: Enemy hits Player
    if ((userDataA == "enemy" && userDataB == "player") ||
        (userDataA == "player" && userDataB == "enemy")) {
      _handleEnemyPlayerCollision();
    }
  }

  void _handleWeaponEnemyCollision(Contact contact) {
    // Find which body is the weapon and which is the enemy
    final bodyA = contact.fixtureA.body;
    final bodyB = contact.fixtureB.body;
    
    forge2d.Body weaponBody;
    Enemy? enemy;
    
    if (bodyA.userData == "weapon") {
      weaponBody = bodyA;
      // Find the enemy component from the game's enemy list
      enemy = _findEnemyByBody(bodyB);
    } else {
      weaponBody = bodyB;
      enemy = _findEnemyByBody(bodyA);
    }
    
    if (enemy == null || enemy.isDestroyed) {
      return; // Enemy not found or already destroyed
    }
    
    // Get the linear velocity of the weapon
    final weaponVelocity = weaponBody.linearVelocity;
    final weaponSpeed = weaponVelocity.length;
    
    // Rule: If weapon speed is greater than threshold (8.0), destroy enemy
    // Lower threshold since weapon now has damping and moves slower
    const speedThreshold = 8.0;
    if (weaponSpeed > speedThreshold) {
      // Queue enemy for safe removal
      if (!_enemiesToRemove.contains(enemy)) {
        _enemiesToRemove.add(enemy);
      }
    }
    // If speed is low, let physics handle the bounce (do nothing)
  }
  
  void _handleEnemyPlayerCollision() {
    // Game Over: Call game over handler
    if (!game.isGameOver) {
      game.onGameOver();
    }
  }
  
  Enemy? _findEnemyByBody(forge2d.Body body) {
    // Search through game's enemy list to find the enemy with this body
    for (final enemy in game.enemies) {
      if (enemy.body == body && !enemy.isDestroyed) {
        return enemy;
      }
    }
    return null;
  }
  
  // Call this method from the game's update loop to safely remove enemies
  void processEnemyRemovals() {
    for (final enemy in _enemiesToRemove) {
      if (!enemy.isDestroyed) {
        enemy.isDestroyed = true;
        game.onEnemyDestroyed(enemy);
      }
    }
    _enemiesToRemove.clear();
  }

  @override
  void endContact(Contact contact) {
    // Not needed for this implementation
  }

  @override
  void preSolve(Contact contact, Manifold oldManifold) {
    // Not needed for this implementation
  }

  @override
  void postSolve(Contact contact, ContactImpulse impulse) {
    // Not needed for this implementation
  }
}

