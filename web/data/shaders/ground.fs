#extension GL_OES_standard_derivatives: enable

uniform sampler2D diffuseTex;

varying mediump vec3 viewPos;
varying mediump vec2 uv;

void main() {
    mediump vec4 colour = texture2D(diffuseTex, uv);
    mediump vec3 normal = normalize(cross(dFdx(viewPos), dFdy(viewPos)));
    gl_FragColor = vec4(colour.xyz, 1.0);
}