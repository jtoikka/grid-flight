library Renderer;

import 'dart:web_gl';
import 'dart:html';
import 'dart:async';
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import 'mesh.dart';
import 'shader_manager.dart';
import 'framebufferobject.dart';
import 'camera.dart';
import 'entity.dart';
import 'component.dart';
import 'scene.dart';

const NOISETEXUNIT = 0;
const DIFFUSETEXUNIT = 1;
const SHADOWTEXUNIT = 3;

class TextureObject {
    Texture texture;
    int width, height;
}

class Renderer {
    ShaderManager shaderManager;

    int width, height;

    FramebufferObject shadowFBO;

    Map<String, Mesh> meshes = new Map();
    Map<String, TextureObject> textures = new Map();

    int maxAnisotropy = 0;


/*
 * Initializes rendering state and shaders, with a viewport of width [w], and
 * height [h]. Requires rendering context [gl].
 */
    Renderer(RenderingContext gl, int w, int h) {
        width = w;
        height = h;

        shaderManager = new ShaderManager();

        createQuad(gl, 1.0);

        gl.enable(CULL_FACE);
        gl.enable(DEPTH_TEST);
        gl.enable(BLEND);
        gl.blendFunc(ONE, ONE_MINUS_SRC_ALPHA);
        gl.cullFace(BACK);
        gl.frontFace(CCW);
        gl.depthMask(true);
        gl.depthFunc(LEQUAL);
        gl.depthRange(0.0, 1.0);
        gl.clearDepth(1.0);
        gl.enableVertexAttribArray(0);
        gl.enableVertexAttribArray(1);
        gl.clearColor(1.0, 1.0, 1.0, 1.0);

        var depthTexExt = gl.getExtension("WEBGL_depth_texture");
        if (depthTexExt == null) {
            print("Depth textures not supported");
        }
        var floatExt = gl.getExtension("OES_texture_float");
        if (floatExt == null) {
            print("Texture float not supported");
        }
        var standardDerivatives = gl.getExtension("OES_standard_derivatives");
        if (standardDerivatives == null) {
            print("Standard derivatives not supported");
        }
        var anisotropicExt = gl.getExtension("EXT_texture_filter_anisotropic"); // TODO: implement alternative names
        if (anisotropicExt != null) {
            maxAnisotropy = gl.getParameter(ExtTextureFilterAnisotropic.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        }

        genEmptyTexture(gl, 1024, 1024, DEPTH_COMPONENT, "shadowTexture");
        genEmptyTexture(gl, 1024, 1024, RGB, "footex");

        var shadowTextures = [textures["shadowTexture"].texture,
                              textures["footex"].texture];
        var attachments = [DEPTH_ATTACHMENT, COLOR_ATTACHMENT0];
        shadowFBO = new FramebufferObject(gl, shadowTextures, attachments);
    }

    Vector3 hexToRGB(int value) {
        double r = ((value & 0xff0000) >> 16) / 255.0;
        double g = ((value & 0x00ff00) >> 8) / 255.0;
        double b = (value & 0x0000ff) / 255.0;
        return new Vector3(r, g, b);
    }

    double clamp(double value, double min, double max) {
        if (value > max) return max;
        if (value < min) return min;
        return value;
    }

    void setCameraToClipMatrix(RenderingContext gl, Camera camera,
                               CompiledProgram program) {
        var cameraToClipMatrix = camera.cameraToClipMatrix;
        gl.uniformMatrix4fv(program.unifs["cameraToClipMatrix"], false,
                      cameraToClipMatrix.storage);
    }

    void setModelToCameraMatrix(RenderingContext gl, Camera camera,
                                CompiledProgram program,
                                {Matrix4 transformationMatrix}) {
        Matrix4 modelToCamera = camera.getLookMatrix();
        if (transformationMatrix != null) {
            modelToCamera *= transformationMatrix;
        }
        gl.uniformMatrix4fv(program.unifs["modelToCameraMatrix"], false,
                      modelToCamera.storage);
    }

    var firstRender = true;

    void renderScene(RenderingContext gl, Scene scene) {
        if (firstRender) {
            firstRender = false;
            var data = scene.river.noiseSequence;
            textures["noiseTex"] = loadTextureFromList(gl, data.length ~/ 3,
                                                       1, data);
        }
        var sortedEntities = new Map<RenderType, List>();
        for (var value in RenderType.values) {
            sortedEntities[value] = new List();
        }
        for (var entity in scene.entities) {
            var renderComponent = entity.getComponent(RenderComponent);
            if (renderComponent != null) {
                sortedEntities[renderComponent.type].add(entity);
            }
        }

        var entityProgram = shaderManager.programs["entity"];
        gl.useProgram(entityProgram.handle);
        setCameraToClipMatrix(gl, scene.camera, entityProgram);

        gl.activeTexture(TEXTURE0 + SHADOWTEXUNIT);
        gl.bindTexture(TEXTURE_2D,  textures["shadowTexture"].texture);
        gl.uniform1i(entityProgram.unifs["shadowTex"], SHADOWTEXUNIT);

        for (var entity in sortedEntities[RenderType.BASIC]) {
            renderEntity(gl, entity, scene.camera, entityProgram);
        }

        var groundProgram = shaderManager.programs["ground"];
        gl.useProgram(groundProgram.handle);
        setCameraToClipMatrix(gl, scene.camera, groundProgram);
        gl.uniform1f(groundProgram.unifs["dist"], scene.camera.position.z);

        gl.activeTexture(TEXTURE0 + SHADOWTEXUNIT);
        gl.bindTexture(TEXTURE_2D,  textures["shadowTexture"].texture);
        gl.uniform1i(groundProgram.unifs["shadowTex"], SHADOWTEXUNIT);

        gl.activeTexture(TEXTURE0 + NOISETEXUNIT);
        gl.bindTexture(TEXTURE_2D, textures["noiseTex"].texture);
        gl.uniform1i(groundProgram.unifs["noiseTex"], NOISETEXUNIT);

        for (var entity in sortedEntities[RenderType.GROUND]) {
            var renderComponent = entity.getComponent(RenderComponent);
            gl.uniform1f(groundProgram.unifs["offsetMultiplier"],
                         renderComponent.offsetMultiplier);
            renderEntity(gl, entity, scene.camera, groundProgram);
        }
    }

    void renderMesh(RenderingContext gl, Mesh mesh, CompiledProgram program) {
        if (mesh.isRenderable) {
            gl.bindBuffer(ARRAY_BUFFER, mesh.vertexBuffer);
            gl.vertexAttribPointer(program.attribs["position"],
                                   3, FLOAT, false, 0, 0);

            gl.bindBuffer(ARRAY_BUFFER, mesh.uvBuffer);
            gl.vertexAttribPointer(program.attribs["texCoords"],
                                   2, FLOAT, false, 0, 0);

            gl.bindBuffer(ELEMENT_ARRAY_BUFFER, mesh.indexBuffer);

            gl.drawElements(TRIANGLES, mesh.indices.length, UNSIGNED_SHORT, 0);
        }
    }

    void renderEntity(RenderingContext gl, Entity entity, Camera camera,
                      CompiledProgram program) {
        var renderComponent = entity.getComponent(RenderComponent);

        Matrix4 transform = new Matrix4.zero();
        transform[0] = entity.scale.x;
        transform[5] = entity.scale.y;
        transform[10] = entity.scale.z;
        transform[15] = 1.0;
        transform[12] = entity.position.x;
        transform[13] = entity.position.y;
        transform[14] = entity.position.z;

        gl.activeTexture(TEXTURE0 + DIFFUSETEXUNIT);
        gl.bindTexture(TEXTURE_2D, textures[renderComponent.textureID].texture);
//        gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, LINEAR_MIPMAP_LINEAR);
        gl.uniform1i(program.unifs["diffuseTex"], DIFFUSETEXUNIT);

        var lookMatrix = entity.getLookMatrix();

        gl.useProgram(program.handle);
        if (renderComponent.multiDraw != null) {
            var previousOffset = new Vector3(0.0, 0.0, 0.0);
            renderComponent.multiDraw.forEach((meshName, offsets) {
                var mesh = meshes[meshName];
                gl.bindBuffer(ARRAY_BUFFER, mesh.vertexBuffer);
                gl.vertexAttribPointer(program.attribs["position"],
                                       3, FLOAT, false, 0, 0);

                gl.bindBuffer(ARRAY_BUFFER, mesh.uvBuffer);
                gl.vertexAttribPointer(program.attribs["texCoords"],
                                       2, FLOAT, false, 0, 0);

                gl.bindBuffer(ELEMENT_ARRAY_BUFFER, mesh.indexBuffer);
                for (var offset in offsets) {
                    transform[12] += offset.x - previousOffset.x;
                    transform[13] += offset.y - previousOffset.y;
                    transform[14] += offset.z - previousOffset.z;
                    var transMat = transform * lookMatrix;
                    previousOffset = offset;
                    setModelToCameraMatrix(gl, camera, program,
                                           transformationMatrix: transMat);
                    gl.drawElements(TRIANGLES, mesh.indices.length, UNSIGNED_SHORT, 0);
                }
            });
        } else {
            transform = transform * lookMatrix;
            setModelToCameraMatrix(gl, camera, program,
                                   transformationMatrix: transform);
            renderMesh(gl, meshes[renderComponent.meshID], program);
        }
    }

    Future loadTexture(RenderingContext gl, String path,
                     String id, {bool nearest: false}) {
        var image = new ImageElement(src: path);

        var tempObj = new TextureObject();
        textures[id] = tempObj;

        var load = image.onLoad.listen((e) {
            var texture = gl.createTexture();
            gl.bindTexture(TEXTURE_2D, texture);
            gl.texImage2DImage(TEXTURE_2D, 0, RGBA, RGBA, UNSIGNED_BYTE, image);
            if (nearest) {
                gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
                gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);
            } else {
                if (maxAnisotropy > 0)
                    gl.texParameterf(TEXTURE_2D, ExtTextureFilterAnisotropic.TEXTURE_MAX_ANISOTROPY_EXT, 8);
                gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, LINEAR);
                gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER,
                        LINEAR_MIPMAP_LINEAR);
                gl.generateMipmap(TEXTURE_2D);
            }
            gl.bindTexture(TEXTURE_2D, null);

            var texObj = new TextureObject();
            texObj.texture = texture;
            texObj.width = image.width;
            texObj.height = image.height;

            textures[id] = texObj;
        });
        return load.asFuture();
    }

    TextureObject loadTextureFromList(RenderingContext gl, int resolutionX,
                             int resolutionY, Uint8List data) {
        var texture = gl.createTexture();
        gl.activeTexture(TEXTURE0);
        gl.bindTexture(TEXTURE_2D, texture);
        gl.texImage2DTyped(TEXTURE_2D, 0, RGB, resolutionX, resolutionY, 0,
                            RGB, UNSIGNED_BYTE, data);
        gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
        gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);

        var texObj = new TextureObject();
        texObj.texture = texture;
        texObj.width = resolutionX;
        texObj.height = resolutionY;
        return texObj;
    }

    void genEmptyTexture(RenderingContext gl, int width,
                            int height, int format, String id) {
        var type = UNSIGNED_INT;
        if (format == RGB || format == RGBA) type = FLOAT;
        var texture = gl.createTexture();
        gl.bindTexture(TEXTURE_2D, texture);
        gl.texImage2DTyped(TEXTURE_2D, 0, format, width, height,
                           0, format, type, null);
        gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
        gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);
        gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_S, CLAMP_TO_EDGE);
        gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_T, CLAMP_TO_EDGE);

        var texObj = new TextureObject();
        texObj.texture = texture;
        texObj.width = width;
        texObj.height = height;
        textures[id] = texObj;
    }

    Future loadMesh(RenderingContext gl, String path, String name) {
        Mesh mesh = new Mesh(path, gl);
        meshes[name] = mesh;
        return mesh.objLoaded;
    }

    void generatePlane(RenderingContext gl, int resolutionX, int resolutionZ,
                       double maxDepth, double width, double height,
                       Matrix3 rotationMatrix, String meshName,
                       {Vector3 translation, mirrored: false}) {
        var vertices = new List();
        var indices = new List<int>();

        var largestIndex = 0;

        var createPlane = (Matrix3 rotMat, offset) {
            for (var i = 0.0; i < resolutionZ; i++) {
                var depth = (i) / resolutionZ;
                depth *= -maxDepth;
                for (var j = 0.0; j < resolutionX; j++) {
                    var posX = width * j / (resolutionX - 1.0) - width * 0.5;
                    Vector3 rotated = rotMat * new Vector3(posX, height, depth);
                    if (offset != null) rotated += offset;
                    vertices.addAll(rotated.storage);
                }
            }

            for (var i = 0; i < resolutionZ - 1; i++) {
                for (var j = 0; j < resolutionX - 1; j++) {
                    var index0 = j + 0 + i * resolutionX + largestIndex;
                    var index1 = j + 1 + i * resolutionX + largestIndex;
                    var index2 = j + (i + 1) * resolutionX + largestIndex;
                    var index3 = j + (i + 1) * resolutionX + largestIndex + 1;

                    indices.addAll([index0, index1, index2,
                                    index2, index1, index3]);
                }
            }
            largestIndex = indices.last + 1;
        };

        createPlane(rotationMatrix, translation);
        if (mirrored) {
            Matrix3 mirrored = rotationMatrix.clone();
            mirrored[1] = -rotationMatrix[1];
            mirrored[3] = -rotationMatrix[3];
            Vector3 trans = new Vector3(-translation.x, translation.y, -translation.z);
            createPlane(mirrored, trans);
        }

        Mesh mesh = new Mesh.fromList(vertices, indices, gl);
        meshes[meshName] = mesh;
    }

    void renderShadow(RenderingContext gl, Scene scene, Camera light) {
        gl.bindFramebuffer(FRAMEBUFFER, shadowFBO.handle);
        gl.colorMask(false, false, false, false);

        gl.clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT);

        // ...render stuff

        gl.colorMask(true, true, true, true);
        gl.bindFramebuffer(FRAMEBUFFER, null);
    }

    Matrix4 calcLightMatrix(RenderingContext gl, Camera camera, Camera light) {
        Matrix4 inv = camera.getLookMatrix();
        inv.invert();
        Matrix4 mat = light.cameraToClipMatrix * light.getLookMatrix() * inv;
        return mat;
    }

    void createQuad(RenderingContext gl, double scale) {
        var vertices = [-scale, -scale, 0.0,
                         scale, -scale, 0.0,
                         scale,  scale, 0.0,
                        -scale,  scale, 0.0];

        var indices = [0, 1, 2,
                       0, 2, 3];

        Mesh mesh = new Mesh.fromList(vertices, indices, gl);
        meshes["quad"] = mesh;

    }
}