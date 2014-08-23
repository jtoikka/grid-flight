library stateMachine;

import 'dart:web_gl';
import 'dart:html';
import 'dart:convert';

import 'state.dart';
import 'renderer.dart';
import 'event_manager.dart';

class StateMachine {
    State _activeState;
    Renderer _renderer;
    EventManager _eventManager;
    Listener _listener;

    int loadStatus = 0;

    final int loadCount = 6;

    GameState _gameState;

    StateMachine(RenderingContext gl, int w, int h, int canvasW, int canvasH) {
        _eventManager = new EventManager();
        _listener = new Listener();
        _eventManager.addListener("stateMachine", _listener);
        _gameState = new GameState(w, h, canvasW, canvasH, _eventManager);
        _activeState = _gameState;
        _renderer = new Renderer(gl, w, h);
       loadResources(gl);
    }

    // This should be delegated to a JSON file
    void loadResources(RenderingContext gl) {
        HttpRequest.getString("data/shaders/shaders.json").then((jsonString) {
            Map data = JSON.decode(jsonString);
            Map shaders = data["shaders"];

            shaders.forEach((name, data) {
                _renderer.shaderManager.createProgram(gl, name,
                                                      data["vertex"],
                                                      data["fragment"],
                                                      data["attributes"],
                                                      unifs : data["unifs"])
                                                      .then((e) => loadStatus++);
            });
        });
        HttpRequest.getString("data/meshes/meshes.json").then((jsonString) {
            Map meshes = JSON.decode(jsonString);
            meshes.forEach((name, path) {
                _renderer.loadMesh(gl, path, name).then((e) => loadStatus++);
            });
        });
        HttpRequest.getString("data/textures/textures.json").then((jsonString) {
           Map textures = JSON.decode(jsonString);
           textures.forEach((name, path) {
               _renderer.loadTexture(gl, path, name).then((e) => loadStatus++);
           });
        });
    }

    void render(RenderingContext gl) {
        if (loadStatus >= loadCount) {
            _activeState.render(gl, _renderer);
        }
    }

    bool texLoaded = false;

    void update(double time) {
        if (loadStatus >= loadCount) {
            _eventManager.delegateEvents();
            _activeState.update(time, _eventManager);
        }
    }

    void input(int inputType, double time) {
        if (loadStatus >= loadCount) {
            _activeState.input(inputType, time);
        }
    }

    void clearInput() {
        if (loadStatus >= loadCount) {
            _activeState.clearInput();
        }
    }
}