# Momentum Breaker

A 2D top-down action-roguelite game built with Flutter and Flame engine, featuring physics-based movement and inertia mechanics.

## Game Concept

The player controls a small character connected via a chain to a massive weapon. Movement generates momentum and centrifugal force, which is used to swing the weapon into enemies for damage. The game is entirely focused on physics-based movement where **movement is attack**.

## Key Features

- **Physics-Based Combat**: Damage is calculated based on impact velocity
- **Heavy Weapon Feel**: The weapon has realistic mass and inertia
- **Progressive Upgrades**: Choose upgrades between stages that modify physics properties
- **Smooth Camera**: Camera follows the player with smooth interpolation

## Technical Stack

- **Framework**: Flutter (latest stable)
- **Game Engine**: Flame
- **Physics**: flame_forge2d (Forge2D physics engine)
- **State Management**: Provider

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode (for platform-specific builds)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the game:
   ```bash
   flutter run
   ```

### Platform Support

- Android (minSdkVersion: 21)
- iOS
- macOS (min version: 10.14)

## Game Mechanics

### Player Control
- Virtual joystick in the bottom-left corner
- High linear damping for responsive, quick stops

### Weapon Physics
- Heavy weapon connected via DistanceJoint
- Swings freely around the player
- Damage scales with impact velocity

### Upgrades
- **Heavy Hitter**: +20% weapon mass (harder to swing, hits harder)
- **Long Reach**: +15% chain length (wider swing radius)
- **Spikes**: Visual upgrade (placeholder for future mechanics)

## Development Status

This is a prototype implementation. Future enhancements may include:
- Screen shake and particle effects on impact
- More upgrade types
- Additional enemy types
- Sound effects and music
- More complex stage layouts

## License

This project is a prototype/game development project.
