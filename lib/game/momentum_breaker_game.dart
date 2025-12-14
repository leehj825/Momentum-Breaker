import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'components/player.dart';
import 'components/weapon.dart';
import 'components/enemy.dart';
import 'components/joystick.dart';
import 'components/upgrade_overlay.dart';
import 'components/arena.dart';
import 'components/collision_listener.dart';
import 'components/restart_button.dart';
import 'game_state.dart';

class MomentumBreakerGame extends Forge2DGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late Weapon weapon;
  late VirtualJoystick joystick;
  List<Enemy> get enemies => _enemies;
  final List<Enemy> _enemies = [];
  bool isPaused = false;
  bool showUpgradeOverlay = false;
  bool isGameOver = false;
  int enemiesToSpawn = 5;
  late GameContactListener contactListener;
  GameState? gameState;
  RestartButton? restartButton;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Set up Forge2D world with zero gravity (top-down)
    world.gravity = forge2d.Vector2.zero();
    
    // Set up contact listener for collision detection
    contactListener = GameContactListener(this);
    // Set the contact listener on the physics world
    world.physicsWorld.setContactListener(contactListener);
    
    // Set up camera
    camera.viewfinder.anchor = Anchor.center;
    
    // Create arena
    final arena = Arena();
    await add(arena);
    
    // Create player and weapon
    await _initializePlayerAndWeapon();
    
    // Create joystick
    joystick = VirtualJoystick();
    await add(joystick);
    
    // Create restart button
    restartButton = RestartButton(
      onRestart: _restartGame,
    );
    await add(restartButton!);
    
    // Spawn initial enemies
    _spawnEnemies();
  }

  Future<void> _initializePlayerAndWeapon() async {
    // Player starts at center
    final playerPos = forge2d.Vector2(size.x / 2, size.y / 2);
    player = Player(initialPosition: playerPos);
    await add(player);
    
    // Weapon starts at a reasonable distance from player
    final weaponPos = forge2d.Vector2(size.x / 2 + 60, size.y / 2);
    weapon = Weapon(player: player, initialPosition: weaponPos);
    await add(weapon);
    
    // Connect player and weapon with joint
    await weapon.createJoint();
  }

  void _spawnEnemies() {
    _enemies.clear();
    final spawnRadius = size.x * 0.3;
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    
    for (int i = 0; i < enemiesToSpawn; i++) {
      final angle = (i / enemiesToSpawn) * 2 * math.pi;
      final x = centerX + spawnRadius * math.cos(angle);
      final y = centerY + spawnRadius * math.sin(angle);
      
      final enemy = Enemy(player: player, initialPosition: forge2d.Vector2(x, y));
      _enemies.add(enemy);
      add(enemy);
    }
  }

  void onEnemyDestroyed(Enemy enemy) {
    _enemies.remove(enemy);
    enemy.removeFromParent();
    
    // Check victory condition
    if (_enemies.isEmpty && !showUpgradeOverlay) {
      _showUpgradeOverlay();
    }
  }

  void _showUpgradeOverlay() {
    showUpgradeOverlay = true;
    pauseEngine();
    
    // Remove any existing overlay first
    children.whereType<UpgradeOverlay>().forEach((existingOverlay) {
      existingOverlay.removeFromParent();
    });
    
    late final UpgradeOverlay overlay;
    overlay = UpgradeOverlay(
      onUpgradeSelected: (upgradeType) {
        overlay.removeFromParent();
        _applyUpgrade(upgradeType);
        showUpgradeOverlay = false;
        resumeEngine();
        _nextStage();
      },
    );
    
    add(overlay);
  }

  void _applyUpgrade(UpgradeType upgradeType) {
    if (gameState == null) return;
    
    switch (upgradeType) {
      case UpgradeType.heavyHitter:
        gameState!.applyHeavyHitterUpgrade();
        weapon.updateMass(gameState!.weaponMassMultiplier);
        break;
      case UpgradeType.longReach:
        gameState!.applyLongReachUpgrade();
        weapon.updateChainLength(gameState!.chainLengthMultiplier);
        break;
      case UpgradeType.spikes:
        gameState!.applySpikesUpgrade();
        weapon.addSpikes();
        break;
    }
  }

  void _nextStage() {
    if (gameState == null) return;
    gameState!.nextStage();
    enemiesToSpawn = 5 + (gameState!.currentStage - 1) * 2;
    _spawnEnemies();
  }

  Future<void> _restartGame() async {
    // Reset game state
    isGameOver = false;
    isPaused = false;
    showUpgradeOverlay = false;
    
    // Remove all enemies
    for (final enemy in List<Enemy>.from(_enemies)) {
      enemy.removeFromParent();
    }
    _enemies.clear();
    
    // Remove upgrade overlay if present
    children.whereType<UpgradeOverlay>().forEach((overlay) {
      overlay.removeFromParent();
    });
    
    // Reset game state
    if (gameState != null) {
      gameState!.reset();
    }
    
    // Reset player and weapon positions
    final playerPos = forge2d.Vector2(size.x / 2, size.y / 2);
    player.body.setTransform(playerPos, 0.0);
    player.body.linearVelocity = forge2d.Vector2.zero();
    player.body.angularVelocity = 0.0;
    
    final weaponPos = forge2d.Vector2(size.x / 2 + 60, size.y / 2);
    weapon.body.setTransform(weaponPos, 0.0);
    weapon.body.linearVelocity = forge2d.Vector2.zero();
    weapon.body.angularVelocity = 0.0;
    
    // Reset weapon upgrades
    weapon.currentMassMultiplier = 1.0;
    weapon.currentChainLengthMultiplier = 1.5; // Base chain length
    weapon.hasSpikes = false;
    
    // Remove spikes visually if they exist (spikes are RectangleComponents added after initial load)
    final spikesToRemove = <Component>[];
    for (final child in weapon.children) {
      if (child is RectangleComponent && child != weapon.children.first) {
        spikesToRemove.add(child);
      }
    }
    for (final spike in spikesToRemove) {
      spike.removeFromParent();
    }
    
    // Recreate joint with reset chain length
    if (weapon.joint != null) {
      world.destroyJoint(weapon.joint!);
    }
    await weapon.createJoint();
    
    // Reset camera
    camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
    
    // Reset enemy spawn count
    enemiesToSpawn = 5;
    
    // Spawn new enemies
    _spawnEnemies();
    
    // Resume engine if paused
    if (paused) {
      resumeEngine();
    }
  }

  void onGameOver() {
    isGameOver = true;
    pauseEngine();
    print("Game Over! Press Restart to play again.");
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isPaused && !showUpgradeOverlay && !isGameOver) {
      // Process enemy removals queued from collision detection
      contactListener.processEnemyRemovals();
      
      // Update camera to follow player smoothly
      final playerWorldPos = player.body.worldCenter;
      final currentCameraPos = camera.viewfinder.position;
      final cameraSpeed = 5.0;
      
      final targetPos = forge2d.Vector2(playerWorldPos.x, playerWorldPos.y);
      final diff = targetPos - currentCameraPos;
      camera.viewfinder.position = currentCameraPos + diff * cameraSpeed * dt;
    }
  }
}

enum UpgradeType {
  heavyHitter,
  longReach,
  spikes,
}

