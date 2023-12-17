module irisEffect;

import helix.allegro.bitmap;
import helix.resources;
import allegro5.allegro;
import allegro5.shader;
import std.stdio : writeln, writefln;
import std.string : toStringz;
import helix.component;
import helix.mainloop;

class IrisEffect {

	static Bitmap gradient;
	static string fragShaderSource;
	static bool inited = false;
	
	ALLEGRO_SHADER *shader;
	
	static init(ResourceManager resources) {
		fragShaderSource = resources.shaders["iris_frag"];
		writeln(fragShaderSource);
		gradient = resources.bitmaps["gradient"];
		inited = true;
	}

	this() {
		assert(inited, "Must call IrisEffect.init(resources) first");

		shader = al_create_shader(ALLEGRO_SHADER_PLATFORM.ALLEGRO_SHADER_AUTO);
		assert(shader);

		bool ok;

		ok = al_attach_shader_source(shader, ALLEGRO_SHADER_TYPE.ALLEGRO_PIXEL_SHADER, toStringz(fragShaderSource));
		//TODO: assert with message format...
		if (!ok) writefln("al_attach_shader_source failed: %s\n", al_get_shader_log(shader));
		assert(ok);

		ok = al_attach_shader_source(shader, ALLEGRO_SHADER_TYPE.ALLEGRO_VERTEX_SHADER,
			al_get_default_shader_source(ALLEGRO_SHADER_PLATFORM.ALLEGRO_SHADER_AUTO, ALLEGRO_SHADER_TYPE.ALLEGRO_VERTEX_SHADER)
		);
	//	ok = al_attach_shader_source(shader, ALLEGRO_VERTEX_SHADER, vertShaderSource.c_str());

		//TODO: assert with message format...
		if (!ok) writefln("al_attach_shader_source failed: %s\n", al_get_shader_log(shader));
		assert(ok);

		ok = al_build_shader(shader);
		//TODO: assert with message...
		if (!ok) writefln("al_build_shader failed: %s\n", al_get_shader_log(shader));
		assert(ok);
	}

	void enable(float time, int ofstx, int ofsty) {
		al_use_shader(shader);

		al_set_shader_sampler(toStringz("gradientMap"), gradient.ptr, 1);
		int[2] offset = [ ofstx, ofsty ];

		al_set_shader_int_vector(toStringz("offset"), 2, &offset[0], 1);
		al_set_shader_float(toStringz("time"), time);
	}

	void disable() {
		al_use_shader(null);
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
		
		fx.enable(t++, 0, 0);
		al_draw_scaled_bitmap(img.ptr, 0, 0, iw, ih, x, y, w, h, 0);
		fx.disable();
	}
}
