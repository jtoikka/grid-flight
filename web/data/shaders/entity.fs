#extension GL_OES_standard_derivatives: enable

uniform mediump mat4 lightMatrix;

uniform sampler2D diffuseTex;
uniform sampler2D shadowTex;

varying mediump vec3 viewPosition;
varying mediump vec2 uv;

void main() {
    mediump vec4 colour = texture2D(diffuseTex, uv);
    mediump vec3 normal = normalize(cross(dFdx(viewPosition), dFdy(viewPosition)));
	gl_FragColor = colour;
    // gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
