library stateMachine;

import 'dart:web_gl';
import 'dart:html';
import 'dart:convert';

import 'package:vector_math/vector_math.dart';

import 'state.dart';
import 'renderer.dart';
import 'event_manager.dart';
import 'render_resources.dart';

class StateMachine {
    State _activeState;
    Renderer _renderer;
    EventManager _eventManager;
    Listener _listener;
    RenderResources _renderResources;

    int loadStatus = 0;

    final int loadCount = 6;

    GameState _gameState;
    MenuState _menuState;

    Vector2 mousePosition = new Vector2(0.0, 0.0);

    StateMachine(RenderingContext gl, int w, int h, int canvasW, int canvasH) {
        _eventManager = new EventManager();
        _listener = new Listener();
        _eventManager.addListener("stateMachine", _listener);
        _gameState = new GameState(w, h, canvasW, canvasH, _eventManager);
        _menuState = new MenuState(w, h);
        _activeState = _menuState;
        _renderResources = new RenderResources(gl);
        _renderer = new Renderer(gl, w, h, _renderResources);
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
                _renderResources.loadMesh(gl, path, name)
                    .then((e) => loadStatus++);
            });
        });
        HttpRequest.getString("data/textures/textures.json").then((jsonString) {
           Map textures = JSON.decode(jsonString);
           textures.forEach((name, data) {
                _renderResources.loadTexture(gl, data["path"], name, nearest: data["nearest"])
                    .then((e) => loadStatus++);
           });
        });
        HttpRequest.getString("data/textures/sprites.json").then((jsonString) {
            Map data = JSON.decode(jsonString);
            var sheet = data["spriteSheet"];
            var width = data["width"];
            var height = data["height"];
            var sprites = data["sprites"];
            _renderResources.loadSprites(gl, sheet, width, height,
                                        _renderer.width, _renderer.height,
                                        sprites);
            loadStatus++;
        });
        var data = _gameState.scene.river.noiseSequence;
        _renderResources.loadTextureFromList(gl, data.length ~/ 3, 1,
                                            data, "noiseTex");
    }

    void render(RenderingContext gl) {
        if (loadStatus >= loadCount) {
            _activeState.render(gl, _renderer, _renderResources);
        }
    }

    bool texLoaded = false;

    void update(double time) {
        if (loadStatus >= loadCount) {
            _eventManager.delegateEvents();
            handleEvents();
            _activeState.update(time, _eventManager);
        }
    }

    void handleEvents() {
        for (var event in _listener.events) {
            print(event.args.values);
            if (event.args["switchState"] != null) {
                switch(event.args["switchState"]) {
                    case "game":
                        _activeState = _gameState;
                        break;
                    default:
                        break;
                }
            }
        }
        _listener.events.clear();
    }

    void input(int inputType, double time) {
        if (loadStatus >= loadCount) {
            _activeState.input(inputType, time, mousePosition, _eventManager);
        }
    }

    void clearInput() {
        if (loadStatus >= loadCount) {
            _activeState.clearInput();
        }
    }
}