uniform sampler2D screenTex;
uniform sampler2D paletteTex;
uniform sampler2D noiseTex;
uniform sampler2D depthTex;

varying mediump vec2 uv;

#define LOOKUPRES 0.125
#define NOISERES 0.125
#define ZNEAR 0.3
#define ZFAR 400.0

const mediump vec2 screenSize = vec2(240.0, 160.0);

mediump float linearizeDepth(mediump float value) {
    return (2.0 * ZNEAR / (ZFAR + ZNEAR - value * (ZFAR - ZNEAR)));
}

void main() {
    mediump vec4 baseColour = texture2D(screenTex, uv);
    mediump float depth = linearizeDepth(texture2D(depthTex, uv).r);
    depth *= 1.2;
    baseColour.r -= depth;
    baseColour.r = clamp(baseColour.r, 0.01, 0.99);
    mediump float randomValue = texture2D(noiseTex, uv * screenSize * NOISERES).r * 0.9;
    gl_FragColor = texture2D(paletteTex, vec2(0.0, baseColour.r + randomValue));
    // gl_FragColor = texture2D(noiseTex, uv * screenSize * NOISERES);
    // mediump float depth = linearizeDepth(texture2D(depthTex, uv).r);
    // gl_FragColor = vec4(depth, depth, depth, 1.0);
    // gl_FragColor = vec4(baseColour.r, 0.0, 0.0, 1.0);
}