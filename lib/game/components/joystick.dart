import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../momentum_breaker_game.dart';

class VirtualJoystick extends Component with HasGameRef<MomentumBreakerGame>, DragCallbacks {
  static const double joystickRadius = 60.0;
  static const double knobRadius = 25.0;
  static const double maxDistance = joystickRadius - knobRadius;
  
  Vector2? _touchPosition;
  Vector2 _joystickPosition = Vector2.zero();
  Vector2 _knobPosition = Vector2.zero();
  bool _isActive = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Position joystick in bottom-left corner
    _joystickPosition = Vector2(
      joystickRadius + 20,
      gameRef.size.y - joystickRadius - 20,
    );
    _knobPosition = _joystickPosition;
  }

  @override
  void render(Canvas canvas) {
    // Draw joystick base
    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      _joystickPosition.toOffset(),
      joystickRadius,
      basePaint,
    );
    
    // Draw joystick border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(
      _joystickPosition.toOffset(),
      joystickRadius,
      borderPaint,
    );
    
    // Draw knob
    final knobPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      _knobPosition.toOffset(),
      knobRadius,
      knobPaint,
    );
    
    // Draw knob border
    final knobBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(
      _knobPosition.toOffset(),
      knobRadius,
      knobBorderPaint,
    );
  }

  @override
  void onDragStart(DragStartEvent event) {
    final localPos = event.localPosition;
    final distance = (localPos - _joystickPosition).length;
    
    if (distance <= joystickRadius * 2) {
      _touchPosition = localPos;
      _isActive = true;
      _updateKnobPosition(localPos);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isActive) return;
    
    final localPos = event.canvasEndPosition;
    _touchPosition = localPos;
    _updateKnobPosition(localPos);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!_isActive) return;
    
    _isActive = false;
    _touchPosition = null;
    _knobPosition = _joystickPosition;
    _updatePlayerInput(Vector2.zero());
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

  void _updatePlayerInput(Vector2 direction, [double strength = 0.0]) {
    gameRef.player.applyInput(direction, strength);
  }
}
