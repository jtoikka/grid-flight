library Ship;

import 'entity.dart';
import 'component.dart';

class Ship {
    static void update(double delta, Entity entity) {
        var physicsComponent = entity.getComponent(PhysicsComponent);
        entity.position += physicsComponent.velocity;
    }
}