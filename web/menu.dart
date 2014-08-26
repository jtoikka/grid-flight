library Menu;

import 'package:vector_math/vector_math.dart';

import 'camera.dart';
import 'entity.dart';
import 'component.dart';
import 'factory.dart';
import 'event_manager.dart';

class Menu {
    Camera camera;
    Camera camera2D;

    int width, height;

    Vector2 mousePosition = new Vector2(0.0, 0.0);

    List<Entity> entities = new List();
    List<Entity> backgroundEntities = new List();

    Menu(int w, int h) {
        width = w;
        height = h;
        camera = new Camera(w: w, h: h);
        camera2D = new Camera();
        camera2D.cameraToClipMatrix =
            Camera.orthographicProjection(width: 1, height: h / w);

        var tunnelRender = Factory.createTunnel();
        backgroundEntities.add(tunnelRender);

        var ground = Factory.createGround();
        backgroundEntities.add(ground);

        var riverWalls = Factory.createRiverWalls();
        backgroundEntities.add(riverWalls);

        var startButton = Factory.createStartButton(new Vector2(192.0, 64.0));
        entities.add(startButton);
    }

    void update(double delta) {
        camera.position.z += delta * 2.0;
        for (var entity in backgroundEntities) {
            if (entity.followShip) {
                entity.position.z += delta * 2.0;
            }
        }
        for (var entity in entities) {
            if (entity.followMouse) {
                entity.position.x = 0.5 - mousePosition.x / width;
                entity.position.y = (0.5 - mousePosition.y / height)
                                  * height/width;
                print((mousePosition));
            }
        }
    }

    void input(int inputType, double delta, EventManager eventManager) {
        if (inputType == 5) {
            for (var entity in entities) {
                checkMouseCollision(entity, eventManager);
            }
        }
    }

    void checkMouseCollision(Entity entity, EventManager eventManager) {
        var collisionComponent = entity.getComponent(CollisionComponent);
        if (collisionComponent == null) return;

        var mouseX = mousePosition.x - width / 2.0;
        var mouseY = -(mousePosition.y - height / 2.0);

        if (mouseX > entity.position.x - collisionComponent.halfDimensionsA.x
         && mouseX < entity.position.x + collisionComponent.halfDimensionsA.x
         && mouseY > entity.position.y - collisionComponent.halfDimensionsA.y
         && mouseY < entity.position.y + collisionComponent.halfDimensionsA.y) {
            var event = new GameEvent();
            event.recipients.add("stateMachine");
            event.args["switchState"] = "game";
            eventManager.addEvent(event);
        }
    }

    void setMousePosition(Vector2 pos) {
        mousePosition = pos;
    }
}