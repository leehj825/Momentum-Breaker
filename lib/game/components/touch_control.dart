import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class TouchControl extends PositionComponent 
    with HasGameReference<MomentumBreakerGame>, DragCallbacks, TapCallbacks {
  // Joystick state variables
  Vector2? _startDragPosition; // The center/anchor of the joystick (FIXED during drag)
  Vector2? _currentDragPosition; // The knob/thumb position (updates during drag)
  bool _isActive = false;
  
  // Joystick parameters
  static const double _maxRange = 60.0; // Maximum distance from anchor

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
    // Joystick visual is hidden - touch control still works invisibly
    // Movement is controlled by touch/drag but no visual feedback is shown
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!game.isPlaying) return false;
    
    // Record the anchor point at initial touch - this MUST NOT CHANGE until drag ends
    final touchPos = event.canvasPosition;
    _startDragPosition = touchPos;
    _currentDragPosition = touchPos; // Start knob at same position
    _isActive = true;
    _updatePlayerMovement();
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isActive || !game.isPlaying || _startDragPosition == null) return false;
    
    // Update only _currentDragPosition (anchor stays fixed)
    final newDragPos = event.canvasEndPosition;
    
    // Calculate vector from anchor to new position
    final direction = newDragPos - _startDragPosition!;
    final distance = direction.length;
    
    // Clamp knob position to max range from anchor
    if (distance > _maxRange) {
      final normalized = direction.normalized();
      _currentDragPosition = _startDragPosition! + normalized * _maxRange;
    } else {
      _currentDragPosition = newDragPos;
    }
    
    _updatePlayerMovement();
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isActive) return false;
    
    // Clear both positions and stop movement
    _isActive = false;
    _startDragPosition = null;
    _currentDragPosition = null;
    _stopPlayerMovement();
    return true;
  }
  
  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (!_isActive) return;
    
    // Clear both positions and stop movement
    _isActive = false;
    _startDragPosition = null;
    _currentDragPosition = null;
    _stopPlayerMovement();
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!game.isPlaying) return false;
    
    // Treat tap as drag start (for mouse clicks)
    final touchPos = event.canvasPosition;
    _startDragPosition = touchPos;
    _currentDragPosition = touchPos;
    _isActive = true;
    _updatePlayerMovement();
    return true;
  }
  
  @override
  bool onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (!_isActive) return false;
    
    // Clear both positions and stop movement
    _isActive = false;
    _startDragPosition = null;
    _currentDragPosition = null;
    _stopPlayerMovement();
    return true;
  }

  void _updatePlayerMovement() {
    if (!game.isPlaying || !game.player.isMounted || 
        _startDragPosition == null || _currentDragPosition == null) {
      return;
    }
    
    // Calculate direction vector from anchor to current knob position
    final direction = _currentDragPosition! - _startDragPosition!;
    final distance = direction.length;
    
    // If very close to center, don't move
    if (distance < 2.0) {
      _stopPlayerMovement();
      return;
    }
    
    // Normalize direction
    final normalized = direction.normalized();
    final forge2dDirection = forge2d.Vector2(normalized.x, normalized.y);
    
    // Calculate strength: distance / maxRange (clamped between 0.0 and 1.0)
    final strength = (distance / _maxRange).clamp(0.0, 1.0);
    
    // Apply input to player based on direction * strength (like standard joystick)
    game.player.applyInput(forge2dDirection, strength);
  }
  
  void _stopPlayerMovement() {
    // Stop player movement by applying zero input
    if (game.player.isMounted) {
      game.player.applyInput(forge2d.Vector2.zero(), 0.0);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Continuously update movement while drag is active
    if (_isActive && _startDragPosition != null && _currentDragPosition != null && game.isPlaying) {
      _updatePlayerMovement();
    }
  }
}

