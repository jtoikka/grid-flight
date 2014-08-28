library Renderer;

import 'dart:web_gl';
import 'package:vector_math/vector_math.dart';

import 'mesh.dart';
import 'shader_manager.dart';
import 'framebufferobject.dart';
import 'camera.dart';
import 'entity.dart';
import 'component.dart';
import 'scene.dart';
import 'render_resources.dart';

const NOISETEXUNIT = 0;
const DIFFUSETEXUNIT = 1;
const PALETTETEXUNIT = 2;
const SHADOWTEXUNIT = 3;
const DITHERNOISETEXUNIT = 5;
const DEPTHTEXUNIT = 6;
const HEIGHTMAPTEXUNIT = 7;

const INTERNALRESX = 480;
const INTERNALRESY = 320;

class Renderer {
    ShaderManager shaderManager;

    int width, height;

    FramebufferObject shadowFBO;
    FramebufferObject renderFBO;

/*
 * Initializes rendering state and shaders, with a viewport of width [w], and
 * height [h]. Requires rendering context [gl].
 */
    Renderer(RenderingContext gl, int w, int h, RenderResources resources) {
        width = w;
        height = h;

        shaderManager = new ShaderManager();

        setupRender(gl);

        var depthTexExt = gl.getExtension("WEBGL_depth_texture");
        if (depthTexExt == null) {
            print("Depth textures not supported");
        }
        var floatExt = gl.getExtension("OES_texture_float");
        if (floatExt == null) {
            print("Floating point textures not supported");
        }
        var standardDerivatives = gl.getExtension("OES_standard_derivatives");
        if (standardDerivatives == null) {
            print("Standard derivatives not supported");
        }

        resources.genEmptyTexture(gl, INTERNALRESX, INTERNALRESY,
                                  RGB, "renderTex");
        resources.genEmptyTexture(gl, INTERNALRESX, INTERNALRESY,
                                  DEPTH_COMPONENT, "renderDepth");
        var attachments = [DEPTH_ATTACHMENT, COLOR_ATTACHMENT0];
        var fboTextures = [resources.textures["renderDepth"].texture,
                           resources.textures["renderTex"].texture];
        renderFBO = new FramebufferObject(gl, fboTextures, attachments);


        resources.genEmptyTexture(gl, 1024, 1024, DEPTH_COMPONENT,
                                  "shadowTexture");
        resources.genEmptyTexture(gl, 1024, 1024, RGB, "footex");

        var shadowTextures = [resources.textures["shadowTexture"].texture,
                              resources.textures["footex"].texture];
        var shadowAttachments = [DEPTH_ATTACHMENT, COLOR_ATTACHMENT0];
        shadowFBO = new FramebufferObject(gl, shadowTextures,
                                          shadowAttachments);

        resources.genBayerMatrixTex(gl, "noise");
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
        if (program.unifs["worldToCameraMatrix"] != null) {
//            print(modelToCamera);
            gl.uniformMatrix4fv(program.unifs["worldToCameraMatrix"], false,
                                modelToCamera.storage);
//            print(transformationMatrix);
        }
        if (transformationMatrix != null) {
            modelToCamera *= transformationMatrix;
        }
        gl.uniformMatrix4fv(program.unifs["modelToCameraMatrix"], false,
                      modelToCamera.storage);
    }

    void setupRender(RenderingContext gl) {
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
    }

    void startRender(RenderingContext gl) {
        gl.bindFramebuffer(FRAMEBUFFER, renderFBO.handle);
        gl.viewport(0, 0, INTERNALRESX, INTERNALRESY);
        gl.clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT);
    }

    void endRender(RenderingContext gl, RenderResources resources) {
        gl.bindFramebuffer(FRAMEBUFFER, null);
        gl.viewport(0, 0, width, height);
        var screenProgram = shaderManager.programs["screen"];
        gl.useProgram(screenProgram.handle);

        gl.activeTexture(TEXTURE0 + DIFFUSETEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["renderTex"].texture);
        gl.uniform1i(screenProgram.unifs["screenTex"], DIFFUSETEXUNIT);

        gl.activeTexture(TEXTURE0 + PALETTETEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["palette"].texture);
        gl.uniform1i(screenProgram.unifs["paletteTex"], PALETTETEXUNIT);

        gl.activeTexture(TEXTURE0 + DITHERNOISETEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["noise"].texture);
        gl.uniform1i(screenProgram.unifs["noiseTex"], DITHERNOISETEXUNIT);

        gl.activeTexture(TEXTURE0 + DEPTHTEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["renderDepth"].texture);
        gl.uniform1i(screenProgram.unifs["depthTex"], DEPTHTEXUNIT);

        gl.disable(DEPTH_TEST);
        renderMesh(gl, resources.meshes["quad"], screenProgram);
        gl.enable(DEPTH_TEST);
    }


    void renderEntities(RenderingContext gl, Camera camera,
                     List entities, RenderResources resources, double time) {
        setupRender(gl);
        var sortedEntities = new Map<RenderType, List>();
        for (var value in RenderType.values) {
            sortedEntities[value] = new List();
        }
        for (var entity in entities) {
            var renderComponent = entity.getComponent(RenderComponent);
            if (renderComponent != null) {
                sortedEntities[renderComponent.type].add(entity);
            }
        }

        var entityProgram = shaderManager.programs["entity"];
        gl.useProgram(entityProgram.handle);
        setCameraToClipMatrix(gl, camera, entityProgram);
        gl.uniform1f(entityProgram.unifs["dist"], camera.position.z);

        gl.activeTexture(TEXTURE0 + SHADOWTEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["shadowTexture"].texture);
        gl.uniform1i(entityProgram.unifs["shadowTex"], SHADOWTEXUNIT);

        gl.activeTexture(TEXTURE0 + NOISETEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["noiseTex"].texture);
        gl.uniform1i(entityProgram.unifs["noiseTex"], NOISETEXUNIT);

        for (var entity in sortedEntities[RenderType.BASIC]) {
            renderEntity(gl, entity, camera, entityProgram, resources);
        }

        for (var entity in sortedEntities[RenderType.FLAT]) {
            renderEntity(gl, entity, camera, entityProgram, resources);
        }

        var groundProgram = shaderManager.programs["ground"];
        gl.useProgram(groundProgram.handle);
        setCameraToClipMatrix(gl, camera, groundProgram);
        gl.uniform1f(groundProgram.unifs["dist"], camera.position.z);

        gl.activeTexture(TEXTURE0 + SHADOWTEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["shadowTexture"].texture);
        gl.uniform1i(groundProgram.unifs["shadowTex"], SHADOWTEXUNIT);

        gl.activeTexture(TEXTURE0 + NOISETEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["noiseTex"].texture);
        gl.uniform1i(groundProgram.unifs["noiseTex"], NOISETEXUNIT);

        for (var entity in sortedEntities[RenderType.GROUND]) {
            var renderComponent = entity.getComponent(RenderComponent);
            gl.uniform1f(groundProgram.unifs["offsetMultiplier"],
                         renderComponent.offsetMultiplier);
            renderEntity(gl, entity, camera, groundProgram, resources);
        }

        var waterProgram = shaderManager.programs["water"];
        gl.useProgram(waterProgram.handle);
        setCameraToClipMatrix(gl, camera, waterProgram);
        gl.uniform1f(waterProgram.unifs["dist"], camera.position.z);
        gl.uniform1f(waterProgram.unifs["time"], time);

        gl.activeTexture(TEXTURE0 + HEIGHTMAPTEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["heightmap2"].texture);
        gl.uniform1i(waterProgram.unifs["heightMap2"], HEIGHTMAPTEXUNIT);

        gl.activeTexture(TEXTURE0 + PALETTETEXUNIT);
        gl.bindTexture(TEXTURE_2D, resources.textures["waterlookup"].texture);
        gl.uniform1i(waterProgram.unifs["lookup"], PALETTETEXUNIT);

        for (var entity in sortedEntities[RenderType.WATER]){
            renderEntity(gl, entity, camera, waterProgram, resources);
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
                      CompiledProgram program, RenderResources resources) {
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
        gl.bindTexture(TEXTURE_2D,
                       resources.textures[renderComponent.textureID].texture);
        gl.uniform1i(program.unifs["diffuseTex"], DIFFUSETEXUNIT);

        var lookMatrix = entity.getLookMatrix();

        gl.useProgram(program.handle);
        if (renderComponent.multiDraw != null) {
            var previousOffset = new Vector3(0.0, 0.0, 0.0);
            renderComponent.multiDraw.forEach((meshName, offsets) {
                var mesh = resources.meshes[meshName];
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
                    gl.drawElements(TRIANGLES, mesh.indices.length,
                                    UNSIGNED_SHORT, 0);
                }
            });
        } else {
            transform = transform * lookMatrix;
            setModelToCameraMatrix(gl, camera, program,
                                   transformationMatrix: transform);
            renderMesh(gl, resources.meshes[renderComponent.meshID], program);
        }
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
}