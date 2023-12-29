#version 130

uniform float time;
varying vec4 varying_color;
varying vec2 varying_texcoord;

uniform sampler2D al_tex;
uniform bool al_use_tex;

void main(void)
{
	vec2 st = gl_FragCoord.xy;
	vec3 color = vec3(0.0);
	float pixelSize = 4.0;
	st /= pixelSize;
	float step = 20.0;
	vec2 cellco = mod(floor(st), 8.0);
	
	if (varying_color.a == 0) {
		discard;
	}

	vec4 xmas;
	if (cellco.x < cellco.y + mod(time * 12.0, 8.0)) {
		xmas = vec4(1, 0, 0, 1);
	}
	else {
		xmas = vec4(0, 1, 0, 1);
	}

	if ( al_use_tex ) {

		if (texture2D( al_tex , varying_texcoord).a == 0) discard;

		// sample surrounding pixels
		float dist = 0.001;
		if (texture2D( al_tex , varying_texcoord + vec2(dist, 0)).a == 0 ||
			texture2D( al_tex , varying_texcoord + vec2(0, dist)).a == 0 ||
			texture2D( al_tex , varying_texcoord + vec2(-dist, 0)).a == 0 ||
			texture2D( al_tex , varying_texcoord + vec2(0, -dist)).a == 0
		) {
			xmas = vec4(1, 1, 1, 1);
		}
		
	}
	
	gl_FragColor = xmas;
}