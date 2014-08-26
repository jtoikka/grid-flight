library Camera;

import 'dart:math';

import 'package:vector_math/vector_math.dart';

class Camera {
    Vector3 position = new Vector3(0.0, 0.0, 0.0);
    Vector3 forward = new Vector3(0.0, 0.0, 1.0);
    Vector3 up = new Vector3(0.0, 1.0, 0.0);

    int w = 1; // width of viewport in pixels
    int h = 1; // height in pixels
    double fieldOfView; /// Field of view specified in degrees.

    Matrix4 cameraToClipMatrix;

    Camera({Vector3 position, int w, int h,
            double fieldOfView: 34.0, Vector3 forward, Vector3 up,
           orthographic: false}) {
        if (position != null) this.position = position;
        if (forward != null) this.forward = forward.normalize();
        if (up != null) this.up = up.normalize();
        if (w != null) this.w = w;
        if (h != null) this.h = h;
        this.fieldOfView = fieldOfView;

        if (orthographic)
            cameraToClipMatrix = orthographicProjection();
        else
            cameraToClipMatrix = perspectiveProjection(this.w,
                                                       this.h,
                                                       fieldOfView);
    }

    static Matrix4 perspectiveProjection(int w, int h, double fieldOfView,
                                        {zNear: 0.3, zFar: 400.0}) {
        var cameraToClipMatrix = new Matrix4.zero();
        var frustumScale = calcFrustumScale(fieldOfView);

        cameraToClipMatrix[0] = frustumScale / (w.toDouble() / h.toDouble());
        cameraToClipMatrix[5] = frustumScale;
        cameraToClipMatrix[10] = (zFar + zNear) / (zNear - zFar);
        cameraToClipMatrix[11] = -1.0;
        cameraToClipMatrix[14] = (2 * zFar * zNear) / (zNear - zFar);

        return cameraToClipMatrix;
    }

    static Matrix4 orthographicProjection({zNear: -10.0, zFar: 18,
                                          width: 3.0, height: 3.0}) {
        Matrix4 orthoMatrix = new Matrix4.identity();
        orthoMatrix = new Matrix4.identity();
        orthoMatrix[0] = 2 / width;
        orthoMatrix[5] = 2 / height;
        orthoMatrix[10] = -2 / (zFar - zNear);
        orthoMatrix[14] = -(zFar + zNear) / (zFar - zNear);
        return orthoMatrix;
    }

/**
 * Calculates frustum scale from field of view specified in degrees [fovDeg].
 */
    static double calcFrustumScale(double fovDeg) {
        const double degToRad = PI * 2.0 / 360.0;
        var fovRad = fovDeg * degToRad;
        return 1.0 / tan(fovRad / 2.0);
    }

    Matrix4 getLookMatrix() {
        return makeViewMatrix(position, position + forward, up);
    }
}