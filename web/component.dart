library Component;

import 'package:vector_math/vector_math.dart';

class Component {}

class CollisionShape {
    static const CUBE = const CollisionShape._(0);

    static get values => [CUBE];

    final int value;

    const CollisionShape._(this.value);
}

class CollisionComponent extends Component {
    CollisionShape shape;
    double width;
    double height;
}

class RenderComponent extends Component {
    String meshID;
}

class PhysicsComponent extends Component {
    Vector3 velocity = new Vector3(0.0, 0.0, 0.0);
    Vector3 acceleration = new Vector3(0.0, 0.0, 0.0);
}