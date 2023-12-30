#version 130

precision mediump float;

uniform sampler2D al_tex;       // default texture, set by al_draw_bitmap
uniform sampler2D gradientMap;  // reflection map
uniform float time;             // waves move over time...
uniform int ofstx;            // viewport offset in pixels
uniform int ofsty;            // viewport offset in pixels

varying vec2 varying_texcoord;

void main()
{
    vec2 offset = vec2(ofstx, -ofsty);
    float waveLen = 20;
    float speed = 6.282 * 10;
    vec4 color = texture(al_tex, varying_texcoord);
    float alpha = color.a;

    if (color.r == color.b && color.r > 0 && color.g == 0.0) {
        vec2 uv = gl_FragCoord.xy + offset; // gl_FragCoord coordinate relative to viewport, not texture.
        float h = 0.5 + 0.5
            * sin((0.35 * uv.x + 0.8 * uv.y + 0.25 * time * speed) / waveLen)
            * sin((0.5 * uv.x + 1.0 * uv.y - 0.15 * time * speed) / waveLen * 2)
            * sin((0.75 * uv.x - 1.0 * uv.y + 0.05 * time * speed) / waveLen);

        vec4 newColor = texture(gradientMap, vec2(h, 0.5));
        newColor.a = alpha;
        gl_FragColor = newColor;
    }
    else {
        gl_FragColor = color;
    }
}