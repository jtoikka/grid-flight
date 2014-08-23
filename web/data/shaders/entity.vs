attribute vec3 position;
attribute vec2 texCoords;

uniform mat4 modelToCameraMatrix;
uniform mat4 cameraToClipMatrix;

varying vec3 viewPosition;

varying vec2 uv;

void main() {
	vec4 posCam = modelToCameraMatrix * vec4(position, 1.0);
	gl_Position = cameraToClipMatrix * posCam;

    viewPosition = posCam.xyz;
	uv = texCoords;
}