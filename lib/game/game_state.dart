import 'package:flutter/foundation.dart';

class GameState extends ChangeNotifier {
  int _score = 0;
  int _currentStage = 1;
  double _weaponMassMultiplier = 1.0;
  double _chainLengthMultiplier = 1.0;
  bool _hasSpikes = false;

  int get score => _score;
  int get currentStage => _currentStage;
  double get weaponMassMultiplier => _weaponMassMultiplier;
  double get chainLengthMultiplier => _chainLengthMultiplier;
  bool get hasSpikes => _hasSpikes;

  void addScore(int points) {
    _score += points;
    notifyListeners();
  }

  void nextStage() {
    _currentStage++;
    notifyListeners();
  }

  void applyHeavyHitterUpgrade() {
    _weaponMassMultiplier *= 1.2;
    notifyListeners();
  }

  void applyLongReachUpgrade() {
    _chainLengthMultiplier *= 1.15;
    notifyListeners();
  }

  void applySpikesUpgrade() {
    _hasSpikes = true;
    notifyListeners();
  }

  void reset() {
    _score = 0;
    _currentStage = 1;
    _weaponMassMultiplier = 1.0;
    _chainLengthMultiplier = 1.0;
    _hasSpikes = false;
    notifyListeners();
  }
}

