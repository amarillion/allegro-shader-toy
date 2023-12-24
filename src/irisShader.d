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
	private static Shader shader;
	
	static init(ResourceManager resources) {
		fragShaderSource = resources.shaders["iris_frag"];
		gradient = resources.bitmaps["gradient"];
		shader = Shader.ofFragment(fragShaderSource);
		inited = true;
	}

	this() {
		assert(inited, "Must call IrisEffect.init(resources) first");
	}

	void enable(float time, int ofstx, int ofsty) {
		shader.use(true)
			.withSampler("gradientMap", gradient)
			.withIntVector("offset", [ ofstx, ofsty ], 2, 1)
			.withFloat("time", time);
	}

	void disable() {
		shader.use(false);
	}

}

class ShaderComponent : Component {
	Bitmap img = null;
	IrisEffect fx;
	int t = 0;

	this(MainLoop window) {
		super(window, "img");
		fx = new IrisEffect(); // TODO replace hardcoded shader...
	}

	override void draw(GraphicsContext gc) {
		fx.enable(t++ / 60.0, 0, 0); // TODO: get access to FPS rate here...
		
		foreach (child; children) {
			child.draw(gc);
		}
		
		fx.disable();
	}
}
