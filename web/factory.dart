library Factory;

import 'package:vector_math/vector_math.dart';
import 'dart:math';

import 'entity.dart';
import 'component.dart';

class Factory {
    static Entity createShip(Vector3 position) {
        var entity = new Entity();
        entity.entityType = EntityType.SHIP;

        var renderComponent = new RenderComponent();
        renderComponent.meshID = "spaceShip";
        renderComponent.type = RenderType.BASIC;
        renderComponent.textureID = "tileDark";
        entity.addComponent(renderComponent);

        entity.position = position;

        var collisionComponent = new CollisionComponent();
        collisionComponent.shape = CollisionShape.CUBE;
        collisionComponent.halfDimensionsA = new Vector3(0.3, 0.15, 0.2);
        entity.addComponent(collisionComponent);

        var physicsComponent = new PhysicsComponent();
        physicsComponent.velocity = new Vector3(0.0, 0.0, 4.0);
        entity.addComponent(physicsComponent);

        return entity;
    }

    static Entity createTunnel() {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        var renderComponent = new RenderComponent();
        renderComponent.meshID = "tunnel";
        renderComponent.type = RenderType.GROUND;
        renderComponent.textureID = "tile";
        entity.addComponent(renderComponent);
        entity.followShip = true;

        // Add collision component (custom shape)

        return entity;
    }

    static Entity createGround() {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        var renderComponent = new RenderComponent();
        renderComponent.meshID = "ground";
        renderComponent.type = RenderType.GROUND;
        renderComponent.textureID = "tile";
        entity.addComponent(renderComponent);
        renderComponent.offsetMultiplier = 1.0;
        entity.followShip = true;

        // Add collision component (plane)

        return entity;
    }

    static Entity createRiverWalls() {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        var renderComponent = new RenderComponent();
        renderComponent.meshID = "riverwalls";
        renderComponent.type = RenderType.GROUND;
        renderComponent.textureID = "tile";
        renderComponent.offsetMultiplier = -1.0;
        entity.addComponent(renderComponent);
        entity.followShip = true;

        // Add collision component

        return entity;
    }

    static List randomBag(int max, int numValues) {
        final rng = new Random();
        var bag = new List<int>();
        for (int i = 0; i < max; i++) {
            bag.add(i);
        }
        var pulledValues = new List<int>();
        for (int i = 0; i < numValues; i++) {
            var bagPos = rng.nextInt(bag.length);
            pulledValues.add(bag.removeAt(bagPos));
        }
        return pulledValues;
    }

    static Entity createWall(double dist, int numX, int numY) {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        entity.position.z = dist;

        var renderComponent = new RenderComponent();
        renderComponent.meshID = "collumn";
        renderComponent.type = RenderType.BASIC;
        renderComponent.textureID = "tileDark";

        var collumns = new List();
        var rows = new List();

        var randCollumns = randomBag(7, numX);
        for (var rand in randCollumns) {
            collumns.add(new Vector3(rand - 3.0, 0.0, 0.0));
        }

        var randRows = randomBag(5, numY);
        for (var rand in randRows) {
            rows.add(new Vector3(0.0, rand - 2.0, 0.0));
        }

        entity.removeOffscreen = true;


        renderComponent.multiDraw = new Map();
        renderComponent.multiDraw["collumn"] = collumns;
        renderComponent.multiDraw["row"] = rows;

        entity.addComponent(renderComponent);

        // Add collision Array

        var collisionComponent = new CollisionComponent();
        var collisionArray = new List.filled(35, false);

        collisionComponent.shape = CollisionShape.ARRAY;
        collisionComponent.halfDimensionsA = new Vector3(0.5, 10.0, 0.5);
        collisionComponent.halfDimensionsB = new Vector3(3.5, 0.5, 0.5);
        collisionComponent.offsetsA = collumns;
        collisionComponent.offsetsB = rows;
        entity.addComponent(collisionComponent);

        return entity;
    }

    static Entity createCollisionWallLeft() {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        entity.position = new Vector3(-4.0, 0.0, 0.0);

        var collisionComponent = new CollisionComponent();
        collisionComponent.shape = CollisionShape.CUBE;
        collisionComponent.halfDimensionsA = new Vector3(0.5, 10.0, 100.0);
        entity.addComponent(collisionComponent);

        entity.followShip = true;

        return entity;
    }

    static Entity createCollisionWallRight() {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        entity.position = new Vector3(4.0, 0.0, 0.0);

        var collisionComponent = new CollisionComponent();
        collisionComponent.shape = CollisionShape.CUBE;
        collisionComponent.halfDimensionsA = new Vector3(0.5, 10.0, 100.0);
        entity.addComponent(collisionComponent);

        entity.followShip = true;

        return entity;
    }

    static Entity createCollisionCeiling() {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        entity.position = new Vector3(0.0, 3.0, 0.0);

        var collisionComponent = new CollisionComponent();
        collisionComponent = new CollisionComponent();
        collisionComponent.shape = CollisionShape.CUBE;
        collisionComponent.halfDimensionsA = new Vector3(10.0, 0.5, 100.0);
        entity.addComponent(collisionComponent);

        entity.followShip = true;

        return entity;
    }

    static Entity createCollisionFloorLeft(double shipPosition) {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        entity.position = new Vector3(-3.5, -6.0, shipPosition);

        entity.riverOffset = -3.5;
        entity.shipOffset = shipPosition;

        var collisionComponent = new CollisionComponent();
        collisionComponent = new CollisionComponent();
        collisionComponent.shape = CollisionShape.CUBE;
        collisionComponent.halfDimensionsA = new Vector3(2.0, 3.5, 1000.1);
        entity.addComponent(collisionComponent);

        entity.followShip = true;
        entity.moveWithRiver = true;

        return entity;

    }

    static Entity createCollisionFloorRight(double shipPosition) {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        entity.position = new Vector3(3.5, -6.0, shipPosition);

        entity.riverOffset = 3.5;
        entity.shipOffset = shipPosition;

        var collisionComponent = new CollisionComponent();
        collisionComponent.shape = CollisionShape.CUBE;
        collisionComponent.halfDimensionsA = new Vector3(2.0, 3.5, 1000.0);
        entity.addComponent(collisionComponent);

        entity.followShip = true;
        entity.moveWithRiver = true;

        return entity;

    }

    static Entity createWater() {
        var entity = new Entity();
        entity.entityType = EntityType.TUNNEL;

        entity.position = new Vector3(0.0, -5.0, 0.0);

        entity.shipOffset = 0.0;

        var collisionComponent = new CollisionComponent();
        collisionComponent.shape = CollisionShape.CUBE;
        collisionComponent.halfDimensionsA = new Vector3(10.0, 0.5, 100.0);
        entity.addComponent(collisionComponent);

        entity.followShip = true;

        var renderComponent = new RenderComponent();
        renderComponent.meshID = "water";
        renderComponent.textureID = "heightmap1";
        renderComponent.type = RenderType.WATER;
        renderComponent.offsetMultiplier = 1.0;
        entity.addComponent(renderComponent);

        return entity;
    }

    static Entity createStartButton(Vector2 dimensions) {
        var entity = new Entity();
        entity.entityType = EntityType.BUTTON;

        var renderComponent = new RenderComponent();
        renderComponent.meshID = "start";
        renderComponent.textureID = "atlas";
        renderComponent.type = RenderType.FLAT;
        entity.addComponent(renderComponent);

        var collisionComponent = new CollisionComponent();
        collisionComponent.halfDimensionsA = new Vector3(dimensions.x, dimensions.y, 0.0);
        entity.addComponent(collisionComponent);

//        entity.followMouse = true;

//        entity.position = new Vector3(0.0, 0.0, 0.0);
//        entity.scale = new Vector3(2.0, 2.0, 2.0);
        return entity;
    }

    static Entity createCursor() {
        var entity = new Entity();
        entity.entityType = EntityType.BUTTON;

        var renderComponent = new RenderComponent();
        renderComponent.meshID = "mouse";
        renderComponent.textureID = "atlas";
        renderComponent.type = RenderType.FLAT;
        entity.addComponent(renderComponent);

        entity.followMouse = true;

        return entity;
    }
}