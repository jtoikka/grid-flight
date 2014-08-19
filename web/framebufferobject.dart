library FramebufferObject;

import 'dart:web_gl';

class FramebufferObject {
    Framebuffer handle;

    FramebufferObject(RenderingContext gl,
                      List<Texture> textures,
                      List<int> attachments) {
        handle = gl.createFramebuffer();

        gl.bindFramebuffer(FRAMEBUFFER, handle);
        for (int i = 0; i < attachments.length; i++) {
            gl.framebufferTexture2D(FRAMEBUFFER, attachments[i],
                                    TEXTURE_2D, textures[i], 0);
        }

        var FBOstatus = gl.checkFramebufferStatus(FRAMEBUFFER);
        if (FBOstatus != FRAMEBUFFER_COMPLETE) {
            print("ERROR: Framebuffer incomplete");
        }
        gl.bindFramebuffer(FRAMEBUFFER, null);
    }
}