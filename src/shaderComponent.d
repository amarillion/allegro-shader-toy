module shaderComponent;

import helix.allegro.bitmap;
import helix.allegro.shader;
import helix.resources;
import allegro5.allegro;
import allegro5.shader;
import std.string : toStringz;
import std.conv : to;
import helix.component;
import helix.mainloop;

class ShaderComponent : Component {
	
	Shader shader;
	int t = 0;

	private Bitmap[string] samplers;

	void setSampler(string name, Bitmap bitmap) {
		samplers[name] = bitmap;
	}

	void setFragSource(string fragSource) {
		shader = Shader.ofFragment(fragSource);
	}

	public this(MainLoop window) {
		super(window, "shader");
	}

	override void draw(GraphicsContext gc) {
		auto setter = shader.use(true);

		foreach(k, v; samplers) {
			setter.withSampler(k, v);
		}

		//TODO: config
		setter.withIntVector("offset", [ 0, 0 ], 2, 1);
		
		setter.withFloat("time", t++ / 60.0);
		
		foreach (child; children) {
			child.draw(gc);
		}
		
		shader.use(false);
	}
}
