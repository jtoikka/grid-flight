library Mesh;

import 'dart:html';
import 'dart:async';
import 'dart:web_gl';
import 'dart:typed_data';

class Mesh {
    List<double> vertices = new List();
    List<int> indices = new List();

    Buffer vertexBuffer;
    Buffer indexBuffer;

    bool isRenderable = false;

    Future objLoaded;

    Mesh.fromList(List verticesList, List indicesList, RenderingContext gl) {
        vertexBuffer = gl.createBuffer();
        indexBuffer = gl.createBuffer();

        vertices = verticesList;
        indices = indicesList;

        gl.bindBuffer(ARRAY_BUFFER, vertexBuffer);
        gl.bufferData(ARRAY_BUFFER, new Float32List.fromList(verticesList), STATIC_DRAW);
        gl.bindBuffer(ARRAY_BUFFER, null);

        gl.bindBuffer(ELEMENT_ARRAY_BUFFER, indexBuffer);
        gl.bufferData(ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(indicesList), STATIC_DRAW);
        gl.bindBuffer(ELEMENT_ARRAY_BUFFER, null);

        isRenderable = true;
    }

    Mesh(String path, RenderingContext gl) {
        objLoaded = importObj(path).then((value) {
            vertexBuffer = gl.createBuffer();
            indexBuffer = gl.createBuffer();
            gl.bindBuffer(ARRAY_BUFFER, vertexBuffer);
            gl.bufferData(ARRAY_BUFFER, new Float32List.fromList(vertices), STATIC_DRAW);
            gl.bindBuffer(ARRAY_BUFFER, null);

            gl.bindBuffer(ELEMENT_ARRAY_BUFFER, indexBuffer);
            gl.bufferData(ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(indices), STATIC_DRAW);
            gl.bindBuffer(ELEMENT_ARRAY_BUFFER, null);

            isRenderable = true;
        });
    }

    Future importObj(String path) {
        var objectFuture = HttpRequest.getString(path);

        return objectFuture.then((src) {
            var lines = src.split("\n");
            for (var line in lines) {
                if (line.length > 0) {
                    switch (line[0]) {
                    case 'v':
                        var values = line.split(' ');
                        var x = double.parse(values[1]);
                        var y = double.parse(values[2]);
                        var z = double.parse(values[3]);
                        vertices.addAll([x, y, z]);
                        break;
                    case 'f':
                        var values = line.split(' ');
                        var a = int.parse(values[1]) - 1;
                        var b = int.parse(values[2]) - 1;
                        var c = int.parse(values[3]) - 1;
                        indices.addAll([a, b, c]);
                        break;
                    default:
                        break;
                    }
                }
            }
        });
    }
}