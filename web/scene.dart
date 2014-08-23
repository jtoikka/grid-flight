library Scene;

import 'package:vector_math/vector_math.dart';

import 'camera.dart';
import 'entity.dart';
import 'component.dart';
import 'factory.dart';
import 'physics.dart';
import 'river.dart';

const SHADOWRESOLUTION = 1024.0;
const FOLLOWOFFSET = 5.0;

class Scene {
    Camera camera;
    Camera light;
    Entity ship;
    River river;
    double time = 0.0;
    List<Entity> entities = new List();

    Scene(Vector2 dimensions) {
        river = new River();
        camera = new Camera(new Vector3(0.0, 0.0, 0.0), dimensions);
        light = new Camera(new Vector3(0.0, 4.9, -17.0),
                           new Vector2(SHADOWRESOLUTION, SHADOWRESOLUTION),
                           forward: new Vector3(0.0, -1.0, -0.0),
                           up: new Vector3(0.0, 0.0, -1.0),
                           orthographic: true);
        ship = Factory.createShip(new Vector3(0.0, 0.0, 3.0));
        entities.add(ship);

        var tunnel = Factory.createTunnel();
        entities.add(tunnel);

        var ground = Factory.createGround();
        entities.add(ground);

        var riverWalls = Factory.createRiverWalls();
        entities.add(riverWalls);

        var collumn = Factory.createWall(99.5, 1, 1);
        entities.add(collumn);
    }

    void update(double delta) {
        time += delta;
        for (var entity in entities) {
            var physComponent = entity.getComponent(PhysicsComponent);
            if (physComponent != null) {
                Physics.update(delta, entity);
            }
            if (entity.followShip) {
                entity.position.z = ship.position.z - FOLLOWOFFSET;
            }
        }
        updateCamera(delta, ship.position);
    }

    void updateCamera(double delta, Vector3 shipPos) {
        camera.position.z = ship.position.z - FOLLOWOFFSET;
        camera.position.x = ship.position.x * 0.54;
        camera.position.y = ship.position.y * 0.5;
        camera.forward = ship.position - camera.position
                       + new Vector3(0.0, 0.0, 18.0);
        camera.forward = camera.forward.normalize();
    }

    static const UP = 1;
    static const RIGHT = 2;
    static const DOWN = 3;
    static const LEFT = 4;

    bool up = false;
    bool down = false;
    bool left = false;
    bool right = false;

    void input(Map inputs, double time) {
        var physComponent = ship.getComponent(PhysicsComponent);
        physComponent.velocity.y = 0.0;
        physComponent.velocity.x = 0.0;
        if (inputs[UP] != null) {
            physComponent.velocity.y = 2.5;
        }
        if (inputs[DOWN] != null) {
            physComponent.velocity.y = -2.5;
        }
        if (inputs[LEFT] != null) {
            physComponent.velocity.x = 3.5;
        }
        if (inputs[RIGHT] != null) {
            physComponent.velocity.x = -3.5;
        }
    }
}