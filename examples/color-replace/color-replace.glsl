#ifdef GL_ES
precision lowp float;
#endif
uniform sampler2D al_tex;
uniform bool al_use_tex;
uniform bool al_alpha_test;
uniform int al_alpha_func;
uniform float al_alpha_test_val;
varying vec4 varying_color;
varying vec2 varying_texcoord;

uniform bool enable_replace_color;
uniform vec3 original_color;
uniform vec3 replacement_color;

bool alpha_test_func(float x, int op, float compare);
vec4 replace_color(vec4 color, vec3 original_color, vec3 replacement_color);

void main() {
  vec4 c;
  if (al_use_tex) {
    c = varying_color * texture2D(al_tex, varying_texcoord);
  }
  else {
    c = varying_color;
  }
  if (!al_alpha_test || alpha_test_func(c.a, al_alpha_func, al_alpha_test_val)) {
    if(enable_replace_color) {
      gl_FragColor = replace_color(c, original_color, replacement_color);
    }
    else {
      gl_FragColor = c;
    }
  }
  else {
    discard;
  }
}

// replace color if it matches, but keep original alpha
vec4 replace_color(vec4 color, vec3 original_color, vec3 replacement_color) {
    if (color.rgb == original_color) {
        return vec4(replacement_color.rgb, color.a);
    }
    return color;
}

bool alpha_test_func(float x, int op, float compare)
{
  if (op == 0) return false;
  else if (op == 1) return true;
  else if (op == 2) return x < compare;
  else if (op == 3) return x == compare;
  else if (op == 4) return x <= compare;
  else if (op == 5) return x > compare;
  else if (op == 6) return x != compare;
  else if (op == 7) return x >= compare;
  return false;
}
