library Component;

import 'package:vector_math/vector_math.dart';

class Component {}

class CollisionShape {
    static const CUBE = const CollisionShape._(0);
    static const PLANE = const CollisionShape._(1);
    static const ARRAY = const CollisionShape._(2);

    static get values => [CUBE, PLANE, ARRAY];

    final int value;

    const CollisionShape._(this.value);
}

class CollisionComponent extends Component {
    CollisionShape shape;
    Vector3 halfDimensionsA = new Vector3(0.0, 0.0, 0.0);
    Vector3 halfDimensionsB;
    bool damaging = false;

    List<Vector3> offsetsA;
    List<Vector3> offsetsB;
}

class RenderType {
    static const BASIC = const RenderType._(0);
    static const GROUND = const RenderType._(1);

    static get values => [BASIC, GROUND];

    final int value;

    const RenderType._(this.value);
}

class RenderComponent extends Component {
    String meshID;
    RenderType type;
    String textureID;
    double offsetMultiplier = 0.0;
    Map<String, List<Vector3>> multiDraw;
}

class PhysicsComponent extends Component {
    Vector3 velocity = new Vector3(0.0, 0.0, 0.0);
    Vector3 acceleration = new Vector3(0.0, 0.0, 0.0);
}