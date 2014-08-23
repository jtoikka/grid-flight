library Mesh;

import 'dart:html';
import 'dart:async';
import 'dart:web_gl';
import 'dart:typed_data';
import 'dart:collection';

class Mesh {
    List<double> vertices = new List();
    List<int> indices = new List();
    List<double> texCoords = new List();

    Buffer vertexBuffer;
    Buffer indexBuffer;
    Buffer uvBuffer;

    bool isRenderable = false;

    Future objLoaded;

    Mesh.fromList(List verticesList, List indicesList, RenderingContext gl) {
        vertexBuffer = gl.createBuffer();
        indexBuffer = gl.createBuffer();
        uvBuffer = gl.createBuffer();

        vertices = verticesList;
        indices = indicesList;

        gl.bindBuffer(ARRAY_BUFFER, vertexBuffer);
        gl.bufferData(ARRAY_BUFFER, new Float32List.fromList(verticesList),
                      STATIC_DRAW);

        gl.bindBuffer(ELEMENT_ARRAY_BUFFER, indexBuffer);
        gl.bufferData(ELEMENT_ARRAY_BUFFER,
                      new Uint16List.fromList(indicesList), STATIC_DRAW);
        gl.bindBuffer(ELEMENT_ARRAY_BUFFER, null);

        gl.bindBuffer(ARRAY_BUFFER, uvBuffer);
        gl.bufferData(ARRAY_BUFFER, new Float32List.fromList(texCoords),
                      STATIC_DRAW);
        gl.bindBuffer(ARRAY_BUFFER, null);

        isRenderable = true;
    }

    Mesh(String path, RenderingContext gl) {
        objLoaded = importObj(path).then((value) {
            vertexBuffer = gl.createBuffer();
            indexBuffer = gl.createBuffer();
            uvBuffer = gl.createBuffer();
            gl.bindBuffer(ARRAY_BUFFER, vertexBuffer);
            gl.bufferData(ARRAY_BUFFER, new Float32List.fromList(vertices), STATIC_DRAW);
            gl.bindBuffer(ARRAY_BUFFER, null);

            gl.bindBuffer(ELEMENT_ARRAY_BUFFER, indexBuffer);
            gl.bufferData(ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(indices), STATIC_DRAW);
            gl.bindBuffer(ELEMENT_ARRAY_BUFFER, null);

            gl.bindBuffer(ARRAY_BUFFER, uvBuffer);
            gl.bufferData(ARRAY_BUFFER, new Float32List.fromList(texCoords),
                          STATIC_DRAW);
            gl.bindBuffer(ARRAY_BUFFER, null);

            isRenderable = true;
        });
    }

    Future importObj(String path) {
        var objectFuture = HttpRequest.getString(path);

        return objectFuture.then((src) {
            var uvs = new List();

            var temp = new SplayTreeMap<int, List>();

            var lines = src.split("\n");
            for (var line in lines) {
                if (line.length > 0) {
                    var values = line.split(' ');
                    switch (values[0]) {
                    case 'v':
                        var x = double.parse(values[1]);
                        var y = double.parse(values[2]);
                        var z = double.parse(values[3]);
                        vertices.addAll([x, y, z]);
                        break;
                    case 'vt':
                        var x = double.parse(values[1]);
                        var y = double.parse(values[2]);
                        uvs.addAll([x, y]);
                        break;
                    case 'f':
                        var v1 = values[1].split('/');
                        var v2 = values[2].split('/');
                        var v3 = values[3].split('/');
                        var a = int.parse(v1[0]) - 1;
                        var b = int.parse(v2[0]) - 1;
                        var c = int.parse(v3[0]) - 1;
                        indices.addAll([a, b, c]);

                        if (v1.length > 1) {
                            var texIndex1 = int.parse(v1[1]) - 1;
                            var texIndex2 = int.parse(v2[1]) - 1;
                            var texIndex3 = int.parse(v3[1]) - 1;

//                            print(uvs[texIndex1 * 2]);

                            temp[a] = [uvs[texIndex1 * 2], uvs[texIndex1 * 2 + 1]];
                            temp[b] = [uvs[texIndex2 * 2], uvs[texIndex2 * 2 + 1]];
                            temp[c] = [uvs[texIndex3 * 2], uvs[texIndex3 * 2 + 1]];
                        }

                        break;
                    default:
                        break;
                    }
                }
            }
            for (var coords in temp.values) {
                texCoords.addAll(coords);
            }
        });
    }
}