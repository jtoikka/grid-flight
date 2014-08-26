import 'dart:html';
import 'dart:web_gl';

import 'package:game_loop/game_loop_html.dart';

import 'state_machine.dart';

const FRAMELENGTH = 0.015;

CanvasElement canvas;
RenderingContext gl;
StateMachine stateMachine;

double leftOverTime = 0.0;

void update(GameLoopHtml gameLoop) {
    double time = gameLoop.accumulatedTime + leftOverTime;
    const double delta = FRAMELENGTH;
    checkInput(gameLoop, time);
    while (time >= delta) {
        stateMachine.update(delta);
        time -= delta;
    }
    leftOverTime = time;
    stateMachine.clearInput();
}

void render(GameLoopHtml gameLoop) {
    stateMachine.render(gl);
}

const int UP = 1;
const int RIGHT = 2;
const int DOWN = 3;
const int LEFT = 4;
const int MOUSELEFT = 5;

void checkInput(GameLoopHtml gameLoop, double time) {
    if (gameLoop.keyboard.isDown(KeyCode.W)) {
        stateMachine.input(UP, time);
    }
    if (gameLoop.keyboard.isDown(KeyCode.A)) {
        stateMachine.input(LEFT, time);
    }
    if (gameLoop.keyboard.isDown(KeyCode.S)) {
        stateMachine.input(DOWN, time);
    }
    if (gameLoop.keyboard.isDown(KeyCode.D)) {
        stateMachine.input(RIGHT, time);
    }
    if (gameLoop.mouse.released(0)) {
        stateMachine.input(MOUSELEFT, time);
    }

    gameLoop.mouse.clampX;
    gameLoop.mouse.clampY;
    stateMachine.mousePosition.x = gameLoop.mouse.clampX.toDouble();
    stateMachine.mousePosition.y = gameLoop.mouse.clampY.toDouble();
}

void main() {
    canvas = querySelector("#gameCanvas");
    gl = canvas.getContext("webgl");
    if (gl == null) {
        gl = canvas.getContext("experimental-webgl");
        if (gl == null) {
            print("WebGL context could not be created");
            return;
        }
    }

    stateMachine = new StateMachine(gl, canvas.width, canvas.height,
                                    canvas.width, canvas.height);

    GameLoopHtml gameLoop = new GameLoopHtml(canvas);
    gameLoop.onUpdate = update;
    gameLoop.onRender = render;
    gameLoop.pointerLock.lockOnClick = false;
    gameLoop.start();
}
