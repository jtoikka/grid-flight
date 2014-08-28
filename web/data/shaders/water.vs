attribute vec3 position;
attribute vec2 texCoords;

uniform mat4 modelToCameraMatrix;
uniform mat4 cameraToClipMatrix;

uniform sampler2D noiseTex;

uniform float dist;
uniform float time;

varying vec3 viewPos;
varying vec2 uvA;
varying vec2 uvB;

#define PI 3.1415927
#define NOISERES 512.0
#define AMPLITUDE 4.0
#define FREQUENCY 0.03125

float cosineInterpolate(float f, float c, float mu) {
    float mu2 = (1.0 - cos(mu * PI)) * 0.5;
    return (f * (1.0 - mu2) + c * mu2);
}

float noise(float dist) {
    float delta = dist * FREQUENCY;
    float low = floor(delta);
    float high = ceil(delta);
    float r1 = texture2D(noiseTex, vec2(low/NOISERES, 0.5)).r;
    float r2 = texture2D(noiseTex, vec2(high/NOISERES, 0.5)).r;
    float noise = (cosineInterpolate(r1, r2, (delta - low)) - 0.5) * AMPLITUDE;
    return noise;
}

void main() {
    vec4 pos = vec4(position, 1.0);
    float offset = noise(-pos.z + dist);

    pos.x += offset;

    float depthOffset = pos.z / 100.0;
    uvA = texCoords;
    uvA.y -= offset + time * 0.02 + depthOffset * 0.3;
    uvA.x = (pos.z - dist) * 0.100 + time * 0.05;

    uvB = texCoords;
    uvB.y -= offset - time * 0.01 - depthOffset * 0.7;
    uvB.x = (pos.z - dist) * 0.1 + time * 0.04;

    vec4 cameraPos = modelToCameraMatrix * pos;
    gl_Position = cameraToClipMatrix * cameraPos;

    viewPos = cameraPos.xyz;
}