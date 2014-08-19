library Factory;

import 'package:vector_math/vector_math.dart';

import 'entity.dart';
import 'component.dart';

class Factory {
    static Entity createShip(Vector3 position) {
        var entity = new Entity();
        entity.entityType = EntityType.SHIP;

        var renderComponent = new RenderComponent();
        renderComponent.meshID = "spaceShip";
        entity.addComponent(renderComponent);

        entity.position = position;
        entity.scale *= 0.3;
        entity.forward = new Vector3(0.0, 0.0, -1.0);

        var collisionComponent = new CollisionComponent();
        collisionComponent.shape = CollisionShape.CUBE;
        collisionComponent.height = 1.5;
        collisionComponent.width = 1.5;
        entity.addComponent(collisionComponent);

        var physicsComponent = new PhysicsComponent();
        physicsComponent.velocity = new Vector3(0.0, 0.0, 2.0);
        entity.addComponent(physicsComponent);

        return entity;
    }
}