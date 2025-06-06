module scene;

import std.string;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;

import helix.allegro.bitmap;
import helix.allegro.shader;
import helix.allegro.font;
import helix.component;
import helix.color;
import helix.mainloop;
import helix.util.vec;

class TextComponent : Component {

	Font font;
	ALLEGRO_COLOR color;
	string text;

	this(MainLoop window) {
		super(window, "text");
	}

	override void draw(GraphicsContext gc) {
		al_draw_text(font.ptr, color, x, y, 0, toStringz(text));
	}
}

class RectComponent : Component {

	ALLEGRO_COLOR fill = Color.BLUE;

	this(MainLoop window) {
		super(window, "rect");
	}

	override void draw(GraphicsContext gc) {
		al_draw_filled_rectangle(x, y, x + w, y + h, fill);
	}

}

class ShaderComponent : Component {
	
	Shader shader;
	int t = 0;

	private Bitmap[string] samplers;
	private float[string] floats;
	private int[string] ints;
	private bool[string] bools;
	private float[][string] vecfs;

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

	void setInt(string name, int value) {
		ints[name] = value;
	}

	void setVecf(string name, float[] value) {
		vecfs[name] = value;
	}

	void setBool(string name, bool value) {
		bools[name] = value;
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
		foreach(k, v; ints) {
			setter.withInt(k, v);
		}
		foreach(k, v; vecfs) {
			setter.withFloatVector(k, v);
		}
		foreach(k, v; bools) {
			setter.withBool(k, v);
		}

		setter.withFloat("time", t++ / 60.0);
		
		foreach (child; children) {
			child.draw(gc);
		}
		
		shader.use(false);
	}
}
