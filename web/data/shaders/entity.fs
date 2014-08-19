uniform mediump mat4 lightMatrix;

uniform sampler2D diffuseTex;
uniform sampler2D shadowTex;

varying mediump vec2 uv;

void main() {
	gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
