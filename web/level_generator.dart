library LevelGenerator;

import 'dart:collection';
import 'dart:async';

import 'level.dart';

class LevelGenerator {
    Queue<Level> levels;
    int loadedLevels;
    int maxLevels;

    LevelGenerator(int maxLevels) {
        this.maxLevels = maxLevels;
    }

    Future loadLevel() {

    }
}