attribute vec3 position;
attribute vec2 texCoord;

uniform mat4 modelToCameraMatrix;
uniform mat4 cameraToClipMatrix;

varying vec2 uv;

void main() {
	vec4 posCam = modelToCameraMatrix * vec4(position, 1.0);
	gl_Position = cameraToClipMatrix * posCam;

	uv = texCoord;
}