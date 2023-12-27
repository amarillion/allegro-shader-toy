#version 130

// derived from OpenGL Dev Cookbook Ch 3. 
// https://github.com/bagobor/opengl33_dev_cookbook_2013/blob/master/Chapter3/TwirlFilter/TwirlFilter/shaders/shader.vert

precision mediump float;

out vec4 vFragColor;	//fragment shader output

//input from the vertex shader
smooth in vec2 vUV;						//2D texture coordinates

//shader uniforms
uniform sampler2D textureMap;			//the image to ripple
uniform float time;				        //time

//TODO: take into account water height...

void main()
{
    float frequency = 50.0;
    float amplitude = 4.0;
    float speed = 10.0;

	vec2 uv = vUV;

    // inspired by: https://shaderfrog.com/app/view/145
    vec2 ripple = vec2(
        sin(  (length( uv ) * frequency ) + ( time * speed ) ),
        cos( ( length( uv ) * frequency ) + ( time * speed ) )
    // Scale amplitude to make input more convenient for users
    ) * ( amplitude / 1000.0 );

    vec3 color = texture(textureMap, uv + ripple).rgb;

    vFragColor = vec4( color, 1.0 );

   //shift by 0.5 to bring it back to original unshifted position
   //vFragColor = texture(textureMap, (shifted+0.5));
}