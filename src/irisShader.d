module irisEffect;

import helix.allegro.bitmap;
import helix.allegro.shader;
import helix.resources;
import allegro5.allegro;
import allegro5.shader;
import std.string : toStringz;
import std.conv : to;
import helix.component;
import helix.mainloop;

class IrisEffect {

	static Bitmap gradient;
	static string fragShaderSource;
	static bool inited = false;
	private Shader shader;
	
	static init(ResourceManager resources) {
		fragShaderSource = resources.shaders["iris_frag"];
		gradient = resources.bitmaps["gradient"];
		inited = true;
	}

	this() {
		assert(inited, "Must call IrisEffect.init(resources) first");
		shader = Shader.ofFragment(fragShaderSource);
	}

	void enable(float time, int ofstx, int ofsty) {
		shader.use(true);

		al_set_shader_sampler(toStringz("gradientMap"), gradient.ptr, 1);
		int[2] offset = [ ofstx, ofsty ];

		al_set_shader_int_vector(toStringz("offset"), 2, &offset[0], 1);
		al_set_shader_float(toStringz("time"), time);
	}

	void disable() {
		shader.use(false);
	}

}

class IrisImageComponent : Component {

	Bitmap img = null;
	IrisEffect fx;
	int t = 0;

	this(MainLoop window) {
		super(window, "img");
		fx = new IrisEffect();
	}

	override void draw(GraphicsContext gc) {
		assert(img);
		
		// stretch mode...
		// TODO: allow other drawing modes...
		int iw = img.w;
		int ih = img.h;
		
		fx.enable(t++ / 60.0, 0, 0); // TODO: get access to FPS rate here...
		al_draw_scaled_bitmap(img.ptr, 0, 0, iw, ih, x, y, w, h, 0);
		fx.disable();
	}
}
