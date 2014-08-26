library Scene;

import 'package:vector_math/vector_math.dart';

import 'camera.dart';
import 'entity.dart';
import 'component.dart';
import 'factory.dart';
import 'physics.dart';
import 'river.dart';

const SHADOWRESOLUTION = 1024;
const FOLLOWOFFSET = 3.5;
const WALLPERIOD = 16.0;
const MAXDEPTH = 400.0;

class Scene {
    Camera camera;
    Camera light;
    Entity ship;
    River river;
    double time = 0.0;
    List<Entity> entities = new List();

    double lastAddedWall = 0.0; // Previous distance at which wall added

    Scene(int w, int h) {
        river = new River();
        camera = new Camera(w: w, h: h);
        light = new Camera(position: new Vector3(0.0, 4.9, -17.0),
                           w: SHADOWRESOLUTION, h: SHADOWRESOLUTION,
                           forward: new Vector3(0.0, -1.0, -0.0),
                           up: new Vector3(0.0, 0.0, -1.0),
                           orthographic: true);
        ship = Factory.createShip(new Vector3(0.0, 0.0, 3.0));
        entities.add(ship);

        var tunnelRender = Factory.createTunnel();
        entities.add(tunnelRender);

        var tunnelWallLeft = Factory.createCollisionWallLeft();
        entities.add(tunnelWallLeft);

        var tunnelWallRight = Factory.createCollisionWallRight();
        entities.add(tunnelWallRight);

        var tunnelCeiling = Factory.createCollisionCeiling();
        entities.add(tunnelCeiling);

        var tunnelFloorLeft = Factory.createCollisionFloorLeft(FOLLOWOFFSET);
        entities.add(tunnelFloorLeft);

        var tunnelFloorRight = Factory.createCollisionFloorRight(FOLLOWOFFSET);
        entities.add(tunnelFloorRight);

        var ground = Factory.createGround();
        entities.add(ground);

        var riverWalls = Factory.createRiverWalls();
        entities.add(riverWalls);

        for (double i = WALLPERIOD; i < MAXDEPTH; i+=WALLPERIOD) {
            var wall = Factory.createWall(i + 0.5, 1, 1);
            entities.add(wall);
            lastAddedWall = i;
        }
    }

    void update(double delta) {
        time += delta;
        for (var entity in entities) {
            var physComponent = entity.getComponent(PhysicsComponent);
            if (physComponent != null) {
                Physics.update(delta, entity);
            }
            if (entity.followShip) {
                entity.position.z = ship.position.z - FOLLOWOFFSET
                                  + entity.shipOffset;
            }
            if (entity.moveWithRiver) {
                entity.position.x = river.getOffset(entity.position.z)
                                  + entity.riverOffset;
            }
            if (entity.removeOffscreen) {
                if (entity.position.z - ship.position.z + FOLLOWOFFSET < 0.0) {
                    entity.toBeRemoved = true;
                }
            }
        }
        entities.removeWhere((entity) => entity.toBeRemoved);
        if (ship.position.z - lastAddedWall + MAXDEPTH > WALLPERIOD) {
            var dist = lastAddedWall + WALLPERIOD;
            var wall = Factory.createWall(dist + 0.5, 2, 1);
            entities.add(wall);
            lastAddedWall = dist;
        }
        checkCollisions();
        updateCamera(delta, ship.position);
    }

    void updateCamera(double delta, Vector3 shipPos) {
        camera.position.z = ship.position.z - FOLLOWOFFSET;
        camera.position.x = ship.position.x * 0.84;
        camera.position.y = ship.position.y * 0.84;
        camera.forward = ship.position - camera.position
                       + new Vector3(0.0, 0.0, 18.0);
        camera.forward = camera.forward.normalize();
    }

    void checkCollisions() {
        var shipCollision = ship.getComponent(CollisionComponent);
        if (shipCollision == null) {
            print("Ship missing collision box");
            return;
        }
        var resolveVector = ((v) {
            var min = v.x.abs() < v.y.abs() ? v.x : v.y;
            min = min.abs() < v.z.abs() ? min : v.z;
            if (v.x == min) {
                return new Vector3(v.x, 0.0, 0.0);
            } else if (v.y == min) {
                return new Vector3(0.0, v.y, 0.0);
            }
            return new Vector3(0.0, 0.0, v.z);
        });
        for (var entity in entities) {
            var collisionComponent = entity.getComponent(CollisionComponent);
            if (collisionComponent != null) {
                if (entity.entityType == EntityType.SHIP) continue;
                switch (collisionComponent.shape) {
                case CollisionShape.ARRAY:
                    var depthDiff = (ship.position.z - entity.position.z).abs();
                    var sumDepthDimensions = shipCollision.halfDimensionsA.z
                                           + collisionComponent.halfDimensionsA.z;
                    if (depthDiff - sumDepthDimensions > 0.0) continue;
                    var checkEach = ((offset, halfDimensions) {
                        var collision = aabbCollision(
                                            ship.position,
                                            entity.position + offset,
                                            shipCollision.halfDimensionsA,
                                            halfDimensions);
                        if (collision.z != 0.0) {
                            var resolution = resolveVector(collision);
                            if (resolution.z < 0.0) {
                                print("Took damage!");
                            } else {
                                ship.position += resolution;
                            }
                        }
                    });
                    for (var offset in collisionComponent.offsetsA) {
                        checkEach(offset, collisionComponent.halfDimensionsA);
                    }
                    for (var offset in collisionComponent.offsetsB) {
                        checkEach(offset, collisionComponent.halfDimensionsB);
                    }
                    break;
                case CollisionShape.CUBE:
                    var collision = aabbCollision(
                                        ship.position, entity.position,
                                        shipCollision.halfDimensionsA,
                                        collisionComponent.halfDimensionsA);
                    var resolution = resolveVector(collision);
//                    if (collision.z != 0.0)
//                        print(collision);
                    ship.position += resolution;
                    break;
                default:
                    break;
                };
            }
        }
    }

    Vector3 aabbCollision(Vector3 positionA, Vector3 positionB,
                       Vector3 halfDimensionsA, Vector3 halfDimensionsB) {
        var diffPosition = positionA - positionB;
        var sumDimensions = halfDimensionsA + halfDimensionsB;

        var collisionX = sumDimensions.x - diffPosition.x.abs();
        var collisionY = sumDimensions.y - diffPosition.y.abs();
        var collisionZ = sumDimensions.z - diffPosition.z.abs();

        if (collisionX < 0.0 || collisionY < 0.0 || collisionZ < 0.0) {
            return new Vector3(0.0, 0.0, 0.0);
        }

        var collision = new Vector3(collisionX, collisionY, collisionZ);
        if (diffPosition.x < 0.0) collision.x = -collision.x;
        if (diffPosition.y < 0.0) collision.y = -collision.y;
        if (diffPosition.z < 0.0) collision.z = -collision.z;
        return collision;
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