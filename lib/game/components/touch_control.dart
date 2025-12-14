import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class TouchControl extends PositionComponent 
    with HasGameRef<MomentumBreakerGame>, DragCallbacks, TapCallbacks {
  Vector2? _touchPosition;
  bool _isActive = false;
  
  // Visual indicator for touch point (optional)
  bool _showIndicator = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Cover entire screen to receive touch events
    position = Vector2.zero();
    anchor = Anchor.topLeft;
    priority = 50; // Lower than UI buttons but higher than game objects
  }
  
  @override
  void onMount() {
    super.onMount();
    // Set size to cover entire game area
    if (gameRef.size.x > 0 && gameRef.size.y > 0) {
      size = gameRef.size;
    }
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Update size when game resizes
    this.size = size;
  }
  
  @override
  bool containsLocalPoint(Vector2 point) {
    // Accept all points within the game area
    return point.x >= 0 && point.x <= size.x && point.y >= 0 && point.y <= size.y;
  }

  @override
  void render(Canvas canvas) {
    // Draw touch indicator if active
    if (_isActive && _touchPosition != null && _showIndicator) {
      // Draw a circle at touch position
      final indicatorPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      const indicatorRadius = 20.0;
      canvas.drawCircle(
        _touchPosition!.toOffset(),
        indicatorRadius,
        indicatorPaint,
      );
      canvas.drawCircle(
        _touchPosition!.toOffset(),
        indicatorRadius,
        borderPaint,
      );
      
      // Draw line from player to touch point
      if (gameRef.player.isMounted) {
        final playerPos = gameRef.player.body.worldCenter;
        final linePaint = Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        canvas.drawLine(
          Offset(playerPos.x, playerPos.y),
          _touchPosition!.toOffset(),
          linePaint,
        );
      }
    }
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!gameRef.isPlaying) return false;
    
    // Get touch position in world coordinates
    final touchPos = event.canvasPosition;
    _touchPosition = touchPos;
    _isActive = true;
    _updatePlayerMovement();
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isActive || !gameRef.isPlaying) return false;
    
    // Update touch position
    _touchPosition = event.canvasEndPosition;
    _updatePlayerMovement();
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isActive) return false;
    
    _isActive = false;
    _touchPosition = null;
    _stopPlayerMovement();
    return true;
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!gameRef.isPlaying) return false;
    
    // Handle tap/click - treat as drag start
    final touchPos = event.canvasPosition;
    _touchPosition = touchPos;
    _isActive = true;
    _updatePlayerMovement();
    return true;
  }
  
  @override
  bool onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (!_isActive) return false;
    
    _isActive = false;
    _touchPosition = null;
    _stopPlayerMovement();
    return true;
  }

  void _updatePlayerMovement() {
    if (!gameRef.isPlaying || !gameRef.player.isMounted || _touchPosition == null) {
      return;
    }
    
    // Calculate direction from player to touch point
    final playerPos = gameRef.player.body.worldCenter;
    final playerWorldPos = Vector2(playerPos.x, playerPos.y);
    final direction = _touchPosition! - playerWorldPos;
    final distance = direction.length;
    
    // If very close, don't move
    if (distance < 5.0) {
      _stopPlayerMovement();
      return;
    }
    
    // Normalize direction and apply movement
    final normalized = direction.normalized();
    final forge2dDirection = forge2d.Vector2(normalized.x, normalized.y);
    
    // Strength based on distance (clamped for smooth movement)
    // Further away = stronger movement, but cap it
    final maxDistance = 200.0;
    final strength = (distance / maxDistance).clamp(0.0, 1.0);
    
    // Apply input to player
    gameRef.player.applyInput(forge2dDirection, strength);
  }
  
  void _stopPlayerMovement() {
    // Stop player movement by applying zero input
    if (gameRef.player.isMounted) {
      gameRef.player.applyInput(forge2d.Vector2.zero(), 0.0);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Continuously update movement while touch is active
    if (_isActive && _touchPosition != null && gameRef.isPlaying) {
      _updatePlayerMovement();
    }
  }
}

