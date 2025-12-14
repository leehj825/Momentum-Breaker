import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import 'components/player.dart';
import 'components/weapon.dart';
import 'components/enemy.dart';
import 'components/joystick.dart';
import 'components/upgrade_overlay.dart';
import 'components/arena.dart';
import 'components/collision_listener.dart';
import 'components/restart_button.dart';
import 'components/start_button.dart';
import 'game_state.dart';

class MomentumBreakerGame extends Forge2DGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  @override
  Color backgroundColor() => const Color(0xFF1a1a2e); // Dark blue-gray background
  late Player player;
  late Weapon weapon;
  late VirtualJoystick joystick;
  List<Enemy> get enemies => _enemies;
  final List<Enemy> _enemies = [];
  bool isPaused = false;
  bool showUpgradeOverlay = false;
  bool isGameOver = false;
  bool hasStarted = false; // Track if game has started
  int enemiesToSpawn = 5;
  late GameContactListener contactListener;
  GameState? gameState;
  RestartButton? restartButton;
  StartButton? startButton;
  Component? startOverlay;

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
    
    // Add UI components to camera viewfinder so they're always visible
    // (UI overlays should be in screen space, not world space)
    
    // Create arena
    final arena = Arena();
    await add(arena);
    
    // Create player and weapon
    await _initializePlayerAndWeapon();
    
    // Create joystick
    joystick = VirtualJoystick();
    await add(joystick);
    
    // Create restart button (will be added when game over)
    restartButton = RestartButton(
      onRestart: _restartGame,
    );
    // Don't add it yet - will add on game over
    
    // Create start button overlay (shown initially)
    // Add to camera viewfinder so it's in screen space
    final background = _StartOverlayBackground();
    background.priority = 150;
    await camera.viewfinder.add(background);
    
    startButton = StartButton(
      onStart: _startGame,
    );
    startButton!.priority = 200; // Even higher priority
    await camera.viewfinder.add(startButton!);
    
    // Store reference for removal
    startOverlay = background;
    
    // Spawn initial enemies
    _spawnEnemies();
    
    // Pause the game initially until start button is clicked
    pauseEngine();
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

  void _startGame() {
    hasStarted = true;
    // Remove start overlay background from camera viewfinder
    if (startOverlay != null && startOverlay!.isMounted) {
      startOverlay!.removeFromParent();
    }
    // Remove start button from camera viewfinder
    if (startButton != null && startButton!.isMounted) {
      startButton!.removeFromParent();
    }
    if (restartButton != null && restartButton!.isMounted) {
      restartButton!.removeFromParent(); // Hide restart button
    }
    resumeEngine();
  }

  Future<void> _restartGame() async {
    // Reset game state
    isGameOver = false;
    isPaused = false;
    showUpgradeOverlay = false;
    hasStarted = false; // Reset start state
    
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
    
    // Show start button overlay and pause game
    final background = _StartOverlayBackground();
    background.priority = 150;
    await camera.viewfinder.add(background);
    startOverlay = background;
    
    if (startButton != null && !startButton!.isMounted) {
      startButton!.priority = 200;
      await camera.viewfinder.add(startButton!);
    }
    if (restartButton != null && restartButton!.isMounted) {
      restartButton!.removeFromParent();
    }
    pauseEngine();
  }

  void onGameOver() {
    isGameOver = true;
    pauseEngine();
    // Show restart button on game over
    if (restartButton != null && !restartButton!.isMounted) {
      add(restartButton!);
    }
    print("Game Over! Press Restart to play again.");
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isPaused && !showUpgradeOverlay && !isGameOver && hasStarted) {
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

// Background overlay component that handles resizing
class _StartOverlayBackground extends RectangleComponent 
    with HasGameRef<MomentumBreakerGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()..color = Colors.black.withOpacity(0.7);
    anchor = Anchor.topLeft;
    position = Vector2.zero();
  }
  
  @override
  void onMount() {
    super.onMount();
    if (gameRef.size.x > 0 && gameRef.size.y > 0) {
      size = gameRef.size;
    }
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) {
      this.size = size;
    }
  }
}

