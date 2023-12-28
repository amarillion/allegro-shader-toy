#version 130

uniform float time;
uniform sampler2D al_tex;
uniform bool al_use_tex;

varying vec4 varying_color;
varying vec2 varying_texcoord;
void main(void)
{
	vec2 st = gl_FragCoord.xy;
	vec3 color = vec3(0.0);
	float checkSize = 3.0;
	st /= checkSize;
	float step = 20.0;
	float cellNo = mod(floor(st.x), 8.0) + 8.0 * mod(floor(st.y), 8.0);
	float fmodResult = mod (floor(cellNo / step) + mod(cellNo, step) * step, 64.0);
	if (fmodResult / 64.0 < time) {
		discard;
	}
	if ( al_use_tex )
		gl_FragColor = varying_color * texture2D( al_tex , varying_texcoord);
	else
		gl_FragColor = varying_color;
}