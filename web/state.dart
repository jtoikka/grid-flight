library State;

import 'dart:web_gl';
import 'package:vector_math/vector_math.dart';

import 'event_manager.dart';
import 'renderer.dart';
import 'scene.dart';

const int UP = 1;
const int RIGHT = 2;
const int DOWN = 3;
const int LEFT = 4;

abstract class State {
    void update(double time, EventManager eventManager);
    void render(RenderingContext gl, Renderer renderer);
    void input(int inputType, double time);
    void clearInput();
}

class GameState extends State {
    Scene scene;

    Map<int, bool> inputs = new Map();

    GameState(int w, int h, int canvasW, int canvasH, EventManager eventManager) {
        scene = new Scene(new Vector2(w.toDouble(), h.toDouble()));
    }

    void update(double time, EventManager eventManager) {
        scene.input(inputs, time);
        scene.update(time);
    }

    void render(RenderingContext gl, Renderer renderer) {
        renderer.renderScene(gl, scene);
    }

    void input(int inputType, double time) {
        if (inputType == UP) {
            inputs[UP] = true;
        } else if (inputType == LEFT) {
            inputs[LEFT] = true;
        } else if (inputType == DOWN) {
            inputs[DOWN] = true;
        } else if (inputType == RIGHT) {
            inputs[RIGHT] = true;
        }
    }

    void clearInput() {
        inputs.clear();
    }
}