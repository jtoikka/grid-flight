library Scene;

import 'package:vector_math/vector_math.dart';

import 'camera.dart';
import 'entity.dart';
import 'component.dart';
import 'factory.dart';
import 'physics.dart';

const SHADOWRESOLUTION = 1024.0;

class Scene {
    Camera camera;
    Camera light;
    Entity ship;
    double time = 0.0;
    List<Entity> entities = new List();

    Scene(Vector2 dimensions) {
        camera = new Camera(new Vector3(0.0, 0.0, 0.0), dimensions);
        light = new Camera(new Vector3(0.0, 4.9, -17.0),
                           new Vector2(SHADOWRESOLUTION, SHADOWRESOLUTION),
                           forward: new Vector3(0.0, -1.0, -0.0),
                           up: new Vector3(0.0, 0.0, -1.0),
                           orthographic: true);
        ship = Factory.createShip(new Vector3(0.0, 0.0, 3.0));
        entities.add(ship);
    }

    void update(double delta) {
        time += delta;
        for (var entity in entities) {
            var physComponent = entity.getComponent(PhysicsComponent);
            if (physComponent != null) {
                Physics.update(delta, entity);
            }
        }
    }

    void input(Map inputs, double time) {

    }
}