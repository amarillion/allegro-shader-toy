#version 130

// derived from OpenGL Dev Cookbook Ch 3. 
// https://github.com/bagobor/opengl33_dev_cookbook_2013/blob/master/Chapter3/TwirlFilter/TwirlFilter/shaders/shader.vert

precision mediump float;

out vec4 vFragColor;	//fragment shader output

varying vec2 varying_texcoord;

//shader uniforms
uniform sampler2D al_tex;

// uniform float twirl_amount;	//the amount of twirl
// derived from time for demo
uniform float time;


void main()
{
   // derive twirl_amount from time for demo.
   float twirl_amount = abs(20.0 - mod(time * 2, 40.0));
   
   vec2 pivot = vec2(0.5);

	//get the shifted UV coordinates so that the origin of twirl is at the center of image
	vec2 uv = varying_texcoord-pivot;
	
	//get the angle from the shifter UV coordinates
   float angle = atan(uv.y, uv.x);

   //get the radius using the Euclidean distance of the shifted texture coordinate
   float radius = length(uv);

   //increment angle by product of twirl amount and radius
   angle += radius * twirl_amount; 

   //convert to Cartesian coordinates
   vec2 shifted = radius* vec2(cos(angle), sin(angle)) + pivot;

   if (shifted.x < 0 || shifted.y < 0 || shifted.x > 1 || shifted.y > 1) {
      discard;
   }

   //shift by 0.5 to bring it back to original unshifted position
   vFragColor = texture(al_tex, (shifted));    
}