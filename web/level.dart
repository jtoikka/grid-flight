library Level;

import 'dart:math';

import 'entity.dart';
import 'factory.dart';

class Level {

    final rng = new Random();

    List<Entity> entities;

    Level(int wallSpacing, int levelLength, int numFuelCells,
          int numUpgrades, int numCoins,
          Map collumnPrevalence, Map rowPrevalence) {
        for (int i = 0; i < levelLength; i+= wallSpacing) {
            var c = rng.nextDouble();
            var r = rng.nextDouble();
            var collumns = 0;
            var rows = 0;
            collumnPrevalence.forEach((n, p) {
                if (c < p) collumns = n;
            });
            rowPrevalence.forEach((n, p) {
                if (r < p) rows = n;
            });
            var wall = Factory.createWall(i + 0.5, collumns, rows);
            entities.add(wall);
        }
    }
}