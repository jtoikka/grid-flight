library Entity;

import 'package:vector_math/vector_math.dart';

import 'component.dart';

class EntityType {
    static const TUNNEL = const EntityType._(0);
    static const FUEL = const EntityType._(1);
    static const SHIP = const EntityType._(2);
    static const HORIZONTAL = const EntityType._(3);
    static const VERTICAL = const EntityType._(4);

    static get values => [TUNNEL, FUEL, SHIP, HORIZONTAL, VERTICAL];

    final int value;

    const EntityType._(this.value);
}

class Entity {
    EntityType entityType;

    Vector3 scale = new Vector3(1.0, 1.0, 1.0);
    Vector3 position = new Vector3.zero();
    Vector3 forward = new Vector3(0.0, 0.0, 1.0);
    Vector3 up = new Vector3(0.0, 1.0, 0.0);

    bool followShip = false;
    bool removeOffscreen = false;
    bool toBeRemoved = false;
    bool moveWithRiver = false;

    double riverOffset = 0.0;
    double shipOffset = 0.0;

    Map<Type, Component> components = new Map();

    Matrix4 getLookMatrix() {
        return makeViewMatrix(new Vector3(0.0, 0.0, 0.0), forward, up);
    }

    void addComponent(var component) {
        components[component.runtimeType] = component;
    }

    Component getComponent(Type type) {
        if (components.containsKey(type)) {
            return components[type];
        }
        return null;
    }
}