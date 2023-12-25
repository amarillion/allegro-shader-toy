module engine;

import helix.allegro.shader;
import helix.allegro.bitmap;
import helix.color;
import helix.component;
import helix.style;
import helix.resources;
import helix.mainloop;
import helix.util.vec;
import helix.util.rect;
import helix.tilemap;
import helix.widgets;
import helix.richtext;

import std.stdio;
import std.conv;
import std.math;
import std.exception;
import std.format;
import std.path;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import allegro5.allegro_ttf;

import shaderComponent;

import std.json;

import dialog;

class State : Component {

	this(MainLoop window) {
		super(window, "default");
	}

	//TODO: I want to move this registry to window...
	private Component[string] componentRegistry;

	void buildDialog(JSONValue data) {
		buildDialogRecursive(this, data);
	}

	void buildDialogRecursive(Component parent, JSONValue data) {

		assert(data.type == JSONType.ARRAY);

		foreach (eltData; data.array) {
			// create child components
		
			Component div = null;
			string type = eltData["type"].str;
			switch(type) {
				case "button": {
					div = new Button(window);
					break;
				}
				case "richtext": {
					div = new RichText(window);
					break;
				}
				case "image": {
					string src = eltData["src"].str;
					ImageComponent img = new ImageComponent(window);
					img.img = window.resources.bitmaps[src];
					// Create extra lambda context so we don't share references to src. https://forum.dlang.org/post/vbekijbseskytuaojhxi@forum.dlang.org
					() {
						string boundSrc = src.dup;
						ImageComponent boundImg = img;
						window.resources.bitmaps.onReload[src].add({ boundImg.img = window.resources.bitmaps[boundSrc]; });
					} ();
					div = img;
					break;
				}
				case "pre": {
					auto pre = new PreformattedText(window);
					div = pre;
					break;
				}
				default: div = new Component(window, "div"); break;
			}

			assert("layout" in eltData);
			div.layoutFromJSON(eltData["layout"].object);

			if ("text" in eltData) {
				div.text = eltData["text"].str;
			}
			
			// override local style. TODO: make more generic
			if ("style" in eltData) {
				div.setLocalStyle(eltData["style"]);
			}

			if ("id" in eltData) {
				div.id = eltData["id"].str;
				componentRegistry[div.id] = div;
			}

			parent.addChild(div);
			if ("children" in eltData) {
				buildDialogRecursive(div, eltData["children"]);
			}
		}
	}

	Component getElementById(string id) {
		enforce(id in componentRegistry, format("Component '%s' not found", id));
		return componentRegistry[id];
	}

	override void draw(GraphicsContext gc) {
		foreach (child; children) {
			child.draw(gc);
		}
	}
}

class SceneBuilder {

	private ImageComponent buildBitmap(JSONValue eltData) {
		string src = eltData["src"].str;
		string key = baseName(stripExtension(src));
		ImageComponent img = new ImageComponent(window);
		Bitmap bmp = userResources.bitmaps[key];
		img.img = bmp;
		// Create extra lambda context so we don't share references to src. https://forum.dlang.org/post/vbekijbseskytuaojhxi@forum.dlang.org
		() {
			string boundSrc = key.dup;
			ImageComponent boundImg = img;
			userResources.bitmaps.onReload[key].add({ boundImg.img = userResources.bitmaps[boundSrc]; });
		} ();
		img.setShape(0, 0, bmp.w, bmp.h); // TODO: automatic sizing should make it equal to image size by default
		return img;
	}

	private ShaderComponent buildShader(JSONValue eltData) {
		string fragFile = eltData["fragSrc"].str;
		string key = baseName(stripExtension(fragFile));
		string fragSource = userResources.shaders[key];
		auto shader = new ShaderComponent(window);
		
		shader.setFragSource(fragSource);

		userResources.shaders.onReload[key].add({ shader.setFragSource(userResources.shaders[key]); });
		
		// now load bitmaps...
		assert("shaderConfig" in eltData);
		assert(eltData["shaderConfig"].type == JSONType.OBJECT);
		JSONValue shaderConfig = eltData["shaderConfig"].object;
		
		foreach(string shaderVariable, value; shaderConfig) {
			assert(value.type == JSONType.object);
			if ("bitmap" in value.object) {
				string sampler = value.object["bitmap"].str;
				string samplerKey = baseName(stripExtension(sampler));
				writefln("Detected sampler variable %s %s", shaderVariable, samplerKey);
				shader.setSampler(shaderVariable, userResources.bitmaps[samplerKey]);
				userResources.bitmaps.onReload[samplerKey].add({ shader.setSampler(shaderVariable, userResources.bitmaps[samplerKey]); });
			}  
		}

		return shader;
	}

	private void buildSceneRecursive(Component parent, JSONValue data) {
		assert(data.type == JSONType.ARRAY, "Expected JSON array");
		foreach (eltData; data.array) {
			// create child components
			
			Component div = null;
			string type = eltData["type"].str;
			switch(type) {
				case "bitmap": {
					div = buildBitmap(eltData);
					break;
				}
				case "shader": {
					div = buildShader(eltData);
					break;
				}
				default: assert(false, format("Unknown scene object type '%s'", type));
			}

			parent.addChild(div);
			if ("children" in eltData) {
				buildSceneRecursive(div, eltData["children"]);
			}
		}

	}
	
	private ResourceManager userResources;
	private MainLoop window;

	private this(MainLoop window, ResourceManager resources) {
		userResources = resources;
	}

	public static fromJSON(MainLoop window, ResourceManager resources, Component parent, JSONValue data) {
		SceneBuilder builder = new SceneBuilder(window, resources);
		builder.buildSceneRecursive(parent, data);
	}
}

class TitleState : State {

	ResourceManager userResources;

	this(MainLoop window) {
		super(window);

		try {

			userResources = new ResourceManager();
			// files below are part of scene-oilslick and should not be hardcoded.
			// TODO: extract references from scene json.
			userResources.addFile("data/scene-oilslick.json");
			userResources.addFile("data/iris_frag.glsl");
			userResources.addFile("data/gradient.png");
			userResources.addFile("data/map3.png");
			userResources.addFile("data/map3_2.png");
			userResources.addFile("data/mysha256x256.png");
			// end of scene.

			window.onDisplaySwitch.add((switchIn) { if (switchIn) { userResources.refreshAll(); }});

			/* MENU */
			buildDialog(window.resources.jsons["title-layout"]);
			
			auto canvas = getElementById("canvas");
			
			SceneBuilder.fromJSON(window, userResources, canvas, userResources.jsons["scene-oilslick"]["scene"]);
			//TODO: auto-reload scene...

			getElementById("btn_credits").onAction.add((e) { 
				RichTextBuilder builder = new RichTextBuilder()
					.h1("Allegro Shader Toy")
					.text("Play around with Shader programs in Allegro.").br()
					.text("It was made by ").b("Amarillion").text(" for ").b("BugSquasher").text(" during KrampusHack 2023, a secret santa game jam.").p()
					.h1("Happy holidays BugSquasher, and best wishes for 2024!")
					.text("Coded by").p()
					.link("Martijn 'Amarillion' van Iersel", "https://twitter.com/mpvaniersel").p();
				openDialog(window, builder.build());
			});
		}
		catch (ShaderException e) {
			writeln(e.message);
			/*
			TODO: register a global exception handler that shows this dialog,
			So that any exception can be handled this way.
			*/
			RichTextBuilder builder = new RichTextBuilder()
				.h1("Error")
				.text(to!string(e.message)).p();
			openDialog(window, builder.build());
		}

	}

}
