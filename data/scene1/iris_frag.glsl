#version 130

// derived from OpenGL Dev Cookbook Ch 3. 
// https://github.com/bagobor/opengl33_dev_cookbook_2013/blob/master/Chapter3/TwirlFilter/TwirlFilter/shaders/shader.vert

precision mediump float;

uniform sampler2D al_tex;               // default texture, set by al_draw_bitmap
uniform sampler2D gradientMap;			// reflection map
uniform float time;				        // waves move over time...
uniform vec2 offset;                    // viewport offset

varying vec2 varying_texcoord;
varying vec2 pixel_position;

void main()
{

    float waveLen = 20;
    float speed = 6.282 * 25;
    vec4 color = texture(al_tex, varying_texcoord);
    float alpha = color.a;

    if (color.r == color.b && color.r > 0 && color.g == 0.0) {
    	vec2 uv = gl_FragCoord.xy + offset.xy;                  // gl_FragCoord coordinate relative to viewport, not texture.
    	float h = 0.5 + 0.5
    	    * sin((0.3 * uv.x + 0.5 * uv.y + 0.1 * time * speed) / waveLen)
    	    * sin((0.5 * uv.x + 1.0 * uv.y - 0.2 * time * speed) / waveLen * 2)
    	    * sin((0.8 * uv.x - 1.0 * uv.y + 0.3 * time * speed) / waveLen);

        vec4 newColor = texture(gradientMap, vec2(h, 0.5));
        newColor.a = alpha;
        gl_FragColor = newColor;
   }
   else {
        gl_FragColor = color;
   }
}