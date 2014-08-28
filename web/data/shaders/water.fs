uniform sampler2D diffuseTex; //heightMap1
uniform sampler2D heightMap2;
uniform sampler2D lookup;

varying mediump vec3 viewPos;
varying mediump vec2 uvA;
varying mediump vec2 uvB;

void main() {
    mediump float heightA = texture2D(diffuseTex, uvA).r;
    mediump float heightB = texture2D(heightMap2, uvB).r;
    mediump float h = (heightA + heightB);
    h *= h * 1.8;
    gl_FragColor = vec4(h, h, h, 1.0);
    // gl_FragColor = texture2D(lookup, vec2(0.0, h));
    // gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    // if (h > 0.5 && h < 0.51) {
        // gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    // }
}