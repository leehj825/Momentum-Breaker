import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class TouchControl extends PositionComponent 
    with HasGameReference<MomentumBreakerGame>, DragCallbacks, TapCallbacks {
  // Touch following state
  Vector2? _currentDragPosition; // Current touch/drag position (target for player)
  bool _isActive = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Cover entire screen to receive touch events
    position = Vector2.zero();
    anchor = Anchor.topLeft;
    
    // UI components should stick to screen (viewport space), not world space
    // This tells Flame to ignore the camera and draw directly on the glass
    // Note: PositionType.viewport may not be available in all Flame versions
    // Components added to game root (not camera.viewfinder) should work correctly
    // positionType = PositionType.viewport; // Uncomment if available
    
    priority = 50; // Lower than UI buttons but higher than game objects
  }
  
  @override
  void onMount() {
    super.onMount();
    // Set size to cover entire screen area (viewport space)
    _updateSize();
  }
  
  void _updateSize() {
    // Use screen size for UI hit detection (viewport space)
    final screenSize = game.size;
    if (screenSize.x > 0 && screenSize.y > 0) {
      size = screenSize;
    }
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Update size when game resizes
    _updateSize();
  }
  
  @override
  bool containsLocalPoint(Vector2 point) {
    // Accept all points within the game area
    return point.x >= 0 && point.x <= size.x && point.y >= 0 && point.y <= size.y;
  }

  @override
  void render(Canvas canvas) {
    // Touch control is invisible - player follows touch location
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!game.isPlaying) return false;
    
    // Set target position to touch location
    final touchPos = event.canvasPosition;
    _currentDragPosition = touchPos;
    _isActive = true;
    _updatePlayerMovement();
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isActive || !game.isPlaying) return false;
    
    // Update target position to current drag position
    final newDragPos = event.canvasEndPosition;
    _currentDragPosition = newDragPos;
    
    _updatePlayerMovement();
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isActive) return false;
    
    // Clear target and stop movement
    _isActive = false;
    _currentDragPosition = null;
    _stopPlayerMovement();
    return true;
  }
  
  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (!_isActive) return;
    
    // Clear target and stop movement
    _isActive = false;
    _currentDragPosition = null;
    _stopPlayerMovement();
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!game.isPlaying) return false;
    
    // Set target position on tap
    final touchPos = event.canvasPosition;
    _currentDragPosition = touchPos;
    _isActive = true;
    _updatePlayerMovement();
    return true;
  }
  
  @override
  bool onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (!_isActive) return false;
    
    // Keep target position on tap up (player continues to move there)
    // Only stop on drag end
    return true;
  }

  void _updatePlayerMovement() {
    if (!game.isPlaying || !game.player.isMounted || 
        _currentDragPosition == null) {
      return;
    }
    
    // Convert screen coordinates to world coordinates
    // Since camera is centered and 1:1 zoom, screen position = world position
    final worldTarget = forge2d.Vector2(
      _currentDragPosition!.x,
      _currentDragPosition!.y,
    );
    
    // Set target position for player to follow
    game.player.setTargetPosition(worldTarget);
  }
  
  void _stopPlayerMovement() {
    // Stop player movement by clearing target
    if (game.player.isMounted) {
      game.player.setTargetPosition(null);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Continuously update movement while touch is active
    if (_isActive && _currentDragPosition != null && game.isPlaying) {
      _updatePlayerMovement();
    }
  }
}

