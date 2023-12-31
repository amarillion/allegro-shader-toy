#version 130

precision mediump float;

out vec4 vFragColor;	//fragment shader output

//shader uniforms
uniform float time;         // time in seconds
uniform float waterHeight;  // water level in pixels from the top

uniform sampler2D al_tex;
varying vec2 varying_texcoord;

void main()
{
    vec2 uv = varying_texcoord; // just a shorter alias
    vec2 size = textureSize(al_tex, 0);
    float frequency = 50.0;
    float amplitude = 4.0;
    float speed = 6.0;
    float waterHeightFrac = 1.0 - 1.0 / size.y * waterHeight;

    // calculate a ripple distortion vector
    // inspired by: https://shaderfrog.com/app/view/145
    vec2 ripple = vec2(
        sin(  (length( uv ) * frequency ) + ( time * speed ) ),
        cos( ( length( uv ) * frequency ) + ( time * speed ) )
    // Scale amplitude to make input more convenient for users
    ) * ( amplitude / 1000.0 );

    vec2 uvAdj = uv + ripple;

    // if we're above the water height, ignore ripple effect.
    if (uvAdj.y > waterHeightFrac) {
        vFragColor = texture(al_tex, uv);
        return;
    }

    vFragColor = texture(al_tex, uvAdj);

    // give it a blue tint
    vFragColor *= vec4(0.7, 0.75, 1.1, 1.0);
}