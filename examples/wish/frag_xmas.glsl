#version 130

uniform float time;
varying vec4 varying_color;
varying vec2 varying_texcoord;

uniform sampler2D al_tex;
uniform bool al_use_tex;

void main(void)
{
	// fallback for non-texture use
	if (!al_use_tex) {
		gl_FragColor = varying_color;
		return;	
	}

	// check if we're outside texture
	if (texture2D(al_tex, varying_texcoord).a == 0) discard;

	ivec2 ts = textureSize(al_tex, 0);
	vec2 pix = 1.0 / ts;

	vec2 st = gl_FragCoord.xy;
	st /= 80;
	
	float diag = st.x - st.y - (time * 1.3);
	float diag2 = st.x + st.y + (time * 0.5);

	vec4 xmas;
	if (mod(diag, 2) > 1) {
		float intensity = abs(1.0 - mod(diag2 / 1.0, 2.0));
		xmas = vec4(intensity, 0, 0, 1);
	}
	else {
		float intensity = abs(1.0 - mod((diag2 + 1.0) / 1.0, 2.0));
		xmas = vec4(0, intensity, 0, 1);
	}

	if ( al_use_tex ) {

		if (texture2D( al_tex , varying_texcoord).a == 0) discard;

		for (int j = 1; j < 4; ++j) {
			if (
				texture2D( al_tex , varying_texcoord + vec2(pix.x*j, 0)).a == 0 ||
				texture2D( al_tex , varying_texcoord + vec2(0, pix.y*j)).a == 0 ||
				texture2D( al_tex , varying_texcoord + vec2(-pix.x*j, 0)).a == 0 ||
				texture2D( al_tex , varying_texcoord + vec2(0, -pix.y*j)).a == 0
			) {
					xmas = vec4(1, 1, 1, 1);
					break;
			}		
		}

	}
	
	gl_FragColor = xmas;
}