import 'package:flame_forge2d/flame_forge2d.dart';
import 'enemy.dart';
import 'weapon.dart';
import '../momentum_breaker_game.dart';

class GameContactListener extends ContactListener {
  final MomentumBreakerGame game;

  GameContactListener(this.game);

  @override
  void beginContact(Contact contact) {
    final fixtureA = contact.fixtureA;
    final fixtureB = contact.fixtureB;
    
    // Check if weapon hit enemy
    Weapon? weapon;
    Enemy? enemy;
    
    if (fixtureA.body.userData is Weapon) {
      weapon = fixtureA.body.userData as Weapon;
    } else if (fixtureB.body.userData is Weapon) {
      weapon = fixtureB.body.userData as Weapon;
    }
    
    if (fixtureA.body.userData is Enemy) {
      enemy = fixtureA.body.userData as Enemy;
    } else if (fixtureB.body.userData is Enemy) {
      enemy = fixtureB.body.userData as Enemy;
    }
    
    if (weapon != null && enemy != null && !enemy.isDestroyed) {
      _handleWeaponEnemyCollision(weapon, enemy, contact);
    }
  }

  void _handleWeaponEnemyCollision(Weapon weapon, Enemy enemy, Contact contact) {
    // Calculate relative velocity at impact
    final weaponVelocity = weapon.body.linearVelocity;
    final enemyVelocity = enemy.body.linearVelocity;
    final relativeVelocity = weaponVelocity - enemyVelocity;
    final impactSpeed = relativeVelocity.length;
    
    // Damage calculation based on impact speed
    // Minimum speed threshold to deal damage
    const minDamageSpeed = 50.0;
    if (impactSpeed < minDamageSpeed) {
      return; // Too slow to deal damage
    }
    
    // Damage scales with impact speed
    // Base damage formula: (speed - minSpeed) * damageMultiplier
    const damageMultiplier = 2.0;
    final damage = (impactSpeed - minDamageSpeed) * damageMultiplier;
    
    enemy.takeDamage(damage);
    
    // TODO: Add screen shake and particle effects here
    // For now, we'll just apply the damage
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

