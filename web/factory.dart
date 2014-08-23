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
//        entity.addComponent(renderComponent);

        entity.position = position;
        entity.scale *= 0.15;

        var collisionComponent = new CollisionComponent();
        collisionComponent.shape = CollisionShape.CUBE;
        collisionComponent.height = 1.5;
        collisionComponent.width = 1.5;
        entity.addComponent(collisionComponent);

        var physicsComponent = new PhysicsComponent();
        physicsComponent.velocity = new Vector3(0.0, 0.0, 8.0);
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


        renderComponent.multiDraw = new Map();
        renderComponent.multiDraw["collumn"] = collumns;
        renderComponent.multiDraw["row"] = rows;

        entity.addComponent(renderComponent);

        return entity;
    }
}