library Physics;

import 'entity.dart';
import 'component.dart';

class Physics {
    static void update(double delta, Entity entity) {
        var physComponent = entity.getComponent(PhysicsComponent);
        entity.position += physComponent.velocity * delta
                        + physComponent.acceleration * delta * delta * 0.5;
        physComponent.velocity += physComponent.acceleration * delta;
    }
}