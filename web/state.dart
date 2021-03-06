library State;

import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'event_manager.dart';
import 'renderer.dart';
import 'scene.dart';
import 'render_resources.dart';
import 'menu.dart';

const int UP = 1;
const int RIGHT = 2;
const int DOWN = 3;
const int LEFT = 4;

abstract class State {
    void update(double time, EventManager eventManager);
    void render(RenderingContext gl, Renderer renderer,
                RenderResources resources);
    void input(int inputType, double time,
               Vector2 mousePos, EventManager eventManager);
    void clearInput();
}

class MenuState extends State {
    Menu menu;
    double time = 0.0;

    MenuState(int w, int h) {
        menu = new Menu(w, h);
    }
    void update(double delta, EventManager eventManager) {
        menu.update(delta);
        time += delta;
    }
    void render(RenderingContext gl, Renderer renderer,
                RenderResources resources) {
        renderer.startRender(gl);
        renderer.renderEntities(gl, menu.camera,
                                menu.backgroundEntities, resources, time);
        renderer.renderEntities(gl, menu.camera2D,
                                menu.entities, resources, time);
        renderer.endRender(gl, resources);
    }

    void input(int inputType, double time,
               Vector2 mousePos, EventManager eventManager) {
        menu.input(inputType, time, eventManager);
        menu.setMousePosition(mousePos);
    }

    void clearInput() {

    }
}

class GameState extends State {
    Scene scene;
    double time = 0.0;

    Map<int, bool> inputs = new Map();

    GameState(int w, int h, int canvasW, int canvasH, EventManager eventManager) {
        scene = new Scene(w, h);
    }

    void update(double delta, EventManager eventManager) {
        scene.input(inputs, delta);
        scene.update(delta);
        time += delta;
    }

    void render(RenderingContext gl, Renderer renderer,
                RenderResources resources) {
        renderer.startRender(gl);
        renderer.renderEntities(gl, scene.camera, scene.entities,
                                resources, time);
        renderer.endRender(gl, resources);
    }

    void input(int inputType, double time, Vector2 mousePos,
               EventManager eventManager) {
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