#version 130

// derived from OpenGL Dev Cookbook Ch 3. 
// https://github.com/bagobor/opengl33_dev_cookbook_2013/blob/master/Chapter3/TwirlFilter/TwirlFilter/shaders/shader.vert

in vec2 al_pos; //object space vertex

//vertex shader output
smooth out vec2 vUV;	//texture coordinates for texture lookup in the fragment shader

void main()
{    
	//output the clipspace position
	gl_Position = vec4(al_pos*2.0-1.0,0.0,1.0);	 

	//set the input object space vertex position as texture coordinate
	vUV = al_pos;
}