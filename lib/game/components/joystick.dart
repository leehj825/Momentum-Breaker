import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:forge2d/forge2d.dart' as forge2d;
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class VirtualJoystick extends PositionComponent 
    with HasGameRef<MomentumBreakerGame>, DragCallbacks, TapCallbacks {
  static const double joystickRadius = 60.0;
  static const double knobRadius = 25.0;
  static const double maxDistance = joystickRadius - knobRadius;
  
  Vector2? _touchPosition;
  Vector2 _joystickPosition = Vector2.zero();
  Vector2 _knobPosition = Vector2.zero();
  bool _isActive = false;
  Vector2? _dragStartPosition;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Position joystick in bottom-left corner
    _joystickPosition = Vector2(
      joystickRadius + 20,
      gameRef.size.y - joystickRadius - 20,
    );
    _knobPosition = _joystickPosition;
    
    // Set component position and size so it can receive events
    position = _joystickPosition;
    size = Vector2(joystickRadius * 2 + 40, joystickRadius * 2 + 40);
    anchor = Anchor.center;
    
    // Ensure the component can receive pointer events
    priority = 100; // High priority to receive events first
  }

  @override
  void render(Canvas canvas) {
    // Draw relative to component center (which is at _joystickPosition)
    final center = Vector2(size.x / 2, size.y / 2);
    
    // Draw joystick base
    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      center.toOffset(),
      joystickRadius,
      basePaint,
    );
    
    // Draw joystick border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(
      center.toOffset(),
      joystickRadius,
      borderPaint,
    );
    
    // Draw knob (relative to component center)
    final knobOffset = _knobPosition - _joystickPosition;
    final knobPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (center + knobOffset).toOffset(),
      knobRadius,
      knobPaint,
    );
    
    // Draw knob border
    final knobBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(
      (center + knobOffset).toOffset(),
      knobRadius,
      knobBorderPaint,
    );
  }
  
  @override
  bool containsLocalPoint(Vector2 point) {
    // Check if point is within the joystick area
    final center = Vector2(size.x / 2, size.y / 2);
    final distance = (point - center).length;
    return distance <= joystickRadius * 2;
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // Get position in canvas coordinates (world space)
    final canvasPos = event.canvasPosition;
    final distance = (canvasPos - _joystickPosition).length;
    
    if (distance <= joystickRadius * 2) {
      _touchPosition = canvasPos;
      _dragStartPosition = canvasPos;
      _isActive = true;
      _updateKnobPosition(canvasPos);
      return true;
    }
    
    return false;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isActive || _dragStartPosition == null) return false;
    
    // Use canvasEndPosition which gives current position in canvas coordinates
    final canvasPos = event.canvasEndPosition;
    _touchPosition = canvasPos;
    _updateKnobPosition(canvasPos);
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isActive) return false;
    
    _isActive = false;
    _touchPosition = null;
    _dragStartPosition = null;
    _knobPosition = _joystickPosition;
    _updatePlayerInput(forge2d.Vector2.zero());
    return true;
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // Handle mouse click/tap on joystick area (for single clicks without drag)
    // Use canvasPosition which is in world/canvas coordinates
    final canvasPos = event.canvasPosition;
    final distance = (canvasPos - _joystickPosition).length;
    
    if (distance <= joystickRadius * 2) {
      _touchPosition = canvasPos;
      _dragStartPosition = canvasPos;
      _isActive = true;
      _updateKnobPosition(canvasPos);
      return true;
    }
    
    return false;
  }
  
  @override
  bool onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (!_isActive) return false;
    
    _isActive = false;
    _touchPosition = null;
    _dragStartPosition = null;
    _knobPosition = _joystickPosition;
    _updatePlayerInput(forge2d.Vector2.zero());
    return true;
  }

  void _updateKnobPosition(Vector2 touchPos) {
    final direction = touchPos - _joystickPosition;
    final distance = direction.length;
    
    if (distance > maxDistance) {
      _knobPosition = _joystickPosition + direction.normalized() * maxDistance;
    } else {
      _knobPosition = touchPos;
    }
    
    // Calculate input direction and strength
    final inputDirection = (_knobPosition - _joystickPosition) / maxDistance;
    final strength = (inputDirection.length).clamp(0.0, 1.0);
    
    _updatePlayerInput(inputDirection, strength);
  }

  void _updatePlayerInput(forge2d.Vector2 direction, [double strength = 0.0]) {
    gameRef.player.applyInput(direction, strength);
  }

}

