#extension GL_OES_standard_derivatives: enable

uniform mediump mat4 lightMatrix;
uniform mediump mat4 invModelToCam;

uniform sampler2D diffuseTex;
uniform sampler2D shadowTex;

varying mediump vec3 viewPosition;
varying mediump vec2 uv;
varying mediump vec3 lightCam;

#define ATTENUATION 10.0
#define LIGHTRADIUS 1.5
#define AMBIENT 0.4

void main() {
    mediump vec3 lightDir = lightCam - viewPosition;
    mediump float lightDistSqrd = dot(lightDir, lightDir);
    mediump float attenuation = ATTENUATION 
                / (1.0 + 1.0 / LIGHTRADIUS * sqrt(lightDistSqrd)
                + 1.0 / (LIGHTRADIUS * LIGHTRADIUS) * lightDistSqrd);

    mediump vec4 colour = texture2D(diffuseTex, uv);
    mediump vec3 normal = normalize(cross(dFdx(viewPosition), 
                                          dFdy(viewPosition)));

    mediump float diffuse = (1.0 - normal.y) * 0.5;
    mediump vec3 ambient = colour.xyz * attenuation * 0.1 
                         + colour.xyz * AMBIENT;
    mediump vec3 totalLight = colour.xyz * attenuation * diffuse
                            + ambient;

    gl_FragColor = vec4(totalLight, 1.0);
}
