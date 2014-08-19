library shader_manager;

import 'dart:web_gl';
import 'dart:html';
import 'dart:async';


/**
 *  Container for compiled programs.
 */
class CompiledProgram {
    Program handle;
    Map<String, int> attribs = new Map();
    Map<String, UniformLocation> unifs = new Map();
}

class ShaderManager {
    Map programs; // Map of programs, accessed via name

    ShaderManager() {
        programs = new Map();
    }

/**
 * Creates a shader program from a given vertex source [vertexSrc] and fragment
 * source [fragSrc]. The program is stored as a *CompiledProgram* in the
 * *programs* map, accessed via the unique provided identifier [name]. A list of
 * vertex attributes [attribs] should be included (eg. position, normal, uv), as
 * these are enabled upon compilation of the program. A list of uniforms [unif]
 * can be optionally provided The method returns a
 * 'Future', which can be used to check if the program has finished compiling. A
 * WebGL context [gl] must be provided.
 */
    Future createProgram(RenderingContext gl, String name,
                       String vertexSrc, String fragSrc,
                       List<String> attribs,
                       {List<String> unifs}) {
        var vertSourceFuture = HttpRequest.getString(vertexSrc);
        var fragSourceFuture = HttpRequest.getString(fragSrc);

        var vertexShader = gl.createShader(VERTEX_SHADER);
        var fragmentShader = gl.createShader(FRAGMENT_SHADER);

        var program = gl.createProgram();

        var vsCompiledFuture = vertSourceFuture.then((src) {
            gl.shaderSource(vertexShader, src);
            gl.compileShader(vertexShader);
            if (!gl.getShaderParameter(vertexShader, COMPILE_STATUS)) {
                throw new Exception(gl.getShaderInfoLog(vertexShader));
            }
        });

        var fsCompiledFuture = fragSourceFuture.then((src) {
           gl.shaderSource(fragmentShader, src);
           gl.compileShader(fragmentShader);
           if (!gl.getShaderParameter(fragmentShader, COMPILE_STATUS)) {
               throw new Exception(gl.getShaderInfoLog(fragmentShader));
           }
        });

        return Future.wait([vsCompiledFuture, fsCompiledFuture]).then((_) {
            gl.attachShader(program, vertexShader);
            gl.attachShader(program, fragmentShader);
            gl.linkProgram(program);
            if (!gl.getProgramParameter(program, LINK_STATUS)) {
                throw new Exception(gl.getProgramInfoLog(program));
            }
            gl.deleteShader(vertexShader);
            gl.deleteShader(fragmentShader);

            gl.useProgram(program);
            CompiledProgram cp = new CompiledProgram();
            cp.handle = program;

            for (var attrib in attribs) {
                var attribLocation = gl.getAttribLocation(program, attrib);
                if (attribLocation == -1) {
                    print("Attribute: " + attrib + " not found");
                }
                cp.attribs[attrib] = attribLocation;
            }
            if (unifs != null) {
                for (var unif in unifs) {
                    var unifLocation = gl.getUniformLocation(program, unif);
                    cp.unifs[unif] = unifLocation;
                }
            }
            programs[name] = cp;
            gl.useProgram(null);
        });
    }

}