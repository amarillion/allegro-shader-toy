module shaderComponent;

import helix.allegro.bitmap;
import helix.allegro.shader;
import helix.resources;
import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.shader;
import std.string : toStringz;
import std.conv : to;
import helix.component;
import helix.mainloop;
import helix.color;

class RectComponent : Component {

	this(MainLoop window) {
		super(window, "rect");
	}

	override void draw(GraphicsContext gc) {
		al_draw_filled_rectangle(x, y, w, h, Color.BLUE);
	}

}

class ShaderComponent : Component {
	
	Shader shader;
	int t = 0;

	private Bitmap[string] samplers;
	private float[string] floats;

	void setSampler(string name, Bitmap bitmap) {
		samplers[name] = bitmap;
	}

	private string fragSource = "";
	private string vertSource = "";

	private void update() {
		if (fragSource != "" && vertSource != "") {
			shader = shader.ofShaders(vertSource, fragSource);
		}
		else if (fragSource != "") {
			shader = shader.ofFragment(fragSource);
		}
		else if (vertSource != "") {
			shader = shader.ofVertex(vertSource);
		}
	}

	void setFragSource(string fragSource) {
		this.fragSource = fragSource;
		update();
	}

	void setVertSource(string vertSource) {
		this.vertSource = vertSource;
		update();
	}

	void setFloat(string name, float value) {
		floats[name] = value;
	}

	public this(MainLoop window) {
		super(window, "shader");
	}

	override void draw(GraphicsContext gc) {
		auto setter = shader.use(true);

		foreach(k, v; samplers) {
			setter.withSampler(k, v);
		}
		foreach(k, v; floats) {
			setter.withFloat(k, v);
		}

		//TODO: remnant from iris_frag. Move to config
		setter.withIntVector("offset", [ 0, 0 ], 2, 1);
		
		setter.withFloat("time", t++ / 60.0);
		
		foreach (child; children) {
			child.draw(gc);
		}
		
		shader.use(false);
	}
}