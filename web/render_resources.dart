library RenderResources;

import 'dart:web_gl';
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:math';

import 'mesh.dart';

class TextureObject {
    Texture texture;
    int width, height;
}

class RenderResources {

    Map<String, Mesh> meshes;
    Map<String, TextureObject> textures;

    int maxAnisotropy = 0;

    RenderResources(RenderingContext gl) {
        meshes = new Map();
        textures = new Map();
        var anisotropicExt = gl.getExtension("EXT_texture_filter_anisotropic"); // TODO: implement alternative names
        if (anisotropicExt != null) {
            maxAnisotropy = gl.getParameter(
                ExtTextureFilterAnisotropic.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        }
    }

    Future loadMesh(RenderingContext gl, String path, String name) {
        Mesh mesh = new Mesh(path, gl);
        meshes[name] = mesh;
        return mesh.objLoaded;
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
                if (maxAnisotropy > 0) {
                    int smaller = maxAnisotropy < 4 ? maxAnisotropy : 4;
                    gl.texParameterf(TEXTURE_2D,
                        ExtTextureFilterAnisotropic.TEXTURE_MAX_ANISOTROPY_EXT,
                        smaller);
                    gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, LINEAR);
                }
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

    void loadTextureFromList(RenderingContext gl, int resolutionX,
                             int resolutionY, Uint8List data, String name) {
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
        textures[name]= texObj;
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

    void genNoiseTex(RenderingContext gl, int resolution, String name) {
        var values = new List(resolution * resolution * 3);
        final rng = new Random();
        for (int i = 0; i < values.length; i++) {
            values[i] = rng.nextDouble();
        }
        var texture = gl.createTexture();
        gl.bindTexture(TEXTURE_2D, texture);
        gl.texImage2DTyped(TEXTURE_2D, 0, RGB, resolution, resolution,
                           0, RGB, FLOAT, new Float32List.fromList(values));
        gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
        gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);
        gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_S, REPEAT);
        gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_T, REPEAT);

        var texObj = new TextureObject();
        texObj.texture = texture;
        texObj.width = resolution;
        texObj.height = resolution;
        textures[name] = texObj;
    }

    void genBayerMatrixTex(RenderingContext gl, String name) {
        var matrix =
            [ 0, 32,  8, 40,  2, 34, 10, 42,
             48, 16, 56, 24, 50, 18, 58, 26,
             12, 44,  4, 36, 14, 46,  6, 38,
             60, 28, 52, 20, 62, 30, 54, 22,
              3, 35, 11, 43,  1, 33,  9, 41,
             51, 19, 59, 27, 49, 17, 57, 25,
             15, 47,  7, 39, 13, 45,  5, 37,
             63, 31, 55, 23, 61, 29, 53, 21];

        var values = new List();
        for (var value in matrix) {
            var val = value.toDouble() / 255.0;
            values.add(val);
            values.add(val);
            values.add(val);
        }
        var texture = gl.createTexture();
        gl.bindTexture(TEXTURE_2D, texture);
        gl.texImage2DTyped(TEXTURE_2D, 0, RGB, 8, 8,
                           0, RGB, FLOAT, new Float32List.fromList(values));
        gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
        gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);
        gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_S, REPEAT);
        gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_T, REPEAT);

        var texObj = new TextureObject();
        texObj.texture = texture;
        texObj.width = 8;
        texObj.height = 8;
        textures[name] = texObj;
    }

    void loadSprites(RenderingContext gl, String spriteSheet,
                     int width, int height, int screenW, int screenH,
                     Map sprites) {
        sprites.forEach((name, sprite) {
            double ax = sprite["left"] / width;
            double ay = sprite["top"] / height;
            double bx = sprite["right"] / width;
            double by = sprite["bottom"] / height;
            double depth = sprite["depth"].toDouble();
            double w = bx - ax; w = w / 2 * width / screenW;
            double h = ay - by; h = h / 2 * height / screenW;

            var vertices = [-w, -h, depth,
                             w, -h, depth,
                             w,  h, depth,
                            -w,  h, depth];

            var texCoords = [ax, ay,
                             bx, ay,
                             bx, by,
                             ax, by];

            var indices = [1, 0, 3,
                           1, 3, 2];

            var mesh = new Mesh.fromData(gl, vertices, texCoords, indices);
            meshes[name] = mesh;
        });
    }
}