attribute vec3 position;
attribute vec2 texCoords;

uniform mat4 modelToCameraMatrix;
uniform mat4 worldToCameraMatrix;
uniform mat4 cameraToClipMatrix;

uniform sampler2D noiseTex;

uniform float dist;

varying vec3 viewPosition;
varying vec2 uv;
varying vec3 lightCam;

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
    float offset = noise(-modelToCameraMatrix[3].z + dist);
	vec4 posCam = modelToCameraMatrix * vec4(position, 1.0);
	gl_Position = cameraToClipMatrix * posCam;

    vec3 light = vec3(-offset, -4.5, dist - modelToCameraMatrix[3].z);
    lightCam = (worldToCameraMatrix * vec4(light, 1.0)).xyz;

    viewPosition = posCam.xyz;
	uv = texCoords;
}