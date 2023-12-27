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

class DialogBuilder : Component {

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

	private void loadUserFiles(string baseDir, JSONValue data) {
		assert(data.type == JSONType.ARRAY, "Expected JSON array");
		foreach (eltData; data.array) {

			// create child components
			Component div = null;
			string type = eltData["type"].str;
			switch(type) {
				case "bitmap": {
					string bmpFile = eltData["src"].str;
					// TODO: set root dir on ResourceManager, let it do the rebasing
					string bmpRebased = buildNormalizedPath(baseDir, bmpFile);
					userResources.addFile(bmpRebased);
					break;
				}
				case "shader": {
					// TODO: set root dir on ResourceManager, let it do the rebasing
					if ("fragSrc" in eltData) {
						string fragFile = eltData["fragSrc"].str;
						string fragRebased = buildNormalizedPath(baseDir, fragFile);
						userResources.addFile(fragRebased);
					}

					if ("vertSrc" in eltData) {
						string vertFile = eltData["vertSrc"].str;
						string vertRebased = buildNormalizedPath(baseDir, vertFile);
						userResources.addFile(vertRebased);
					}

					assert("shaderConfig" in eltData);
					assert(eltData["shaderConfig"].type == JSONType.OBJECT);
					JSONValue shaderConfig = eltData["shaderConfig"].object;

					foreach(string shaderVariable, value; shaderConfig) {
						assert(value.type == JSONType.object);
						if ("bitmap" in value.object) {
							string sampler = value.object["bitmap"].str;
							string samplerRebased = buildNormalizedPath(baseDir, sampler);
							userResources.addFile(samplerRebased);
						}
					}

					break;

				}
				default: break; // pass through. some objects don't refer files
			}

			if ("children" in eltData) {
				loadUserFiles(baseDir, eltData["children"]);
			}
		}
	}

	private Component buildRect(JSONValue eltData) {
		Component result = new RectComponent(window);
		// result.style.background = 0; // TODO
		result.setShape(
			cast(int)eltData["x"].integer, 
			cast(int)eltData["y"].integer,
			cast(int)eltData["w"].integer,
			cast(int)eltData["h"].integer
		);
		return result;
	}

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
		string fragSource = "";
		string vertSource = "";

		auto shader = new ShaderComponent(window);
		if ("fragSrc" in eltData) {
			string fragFile = eltData["fragSrc"].str;
			string fragKey = baseName(stripExtension(fragFile));
			fragSource = userResources.shaders[fragKey];
			shader.setFragSource(fragSource);
			userResources.shaders.onReload[fragKey].add({ 
				shader.setFragSource(userResources.shaders[fragKey]);
			});
		}
		if ("vertSrc" in eltData) {
			string vertFile = eltData["vertSrc"].str;
			string vertKey = baseName(stripExtension(vertFile));
			vertSource = userResources.shaders[vertKey];
			shader.setVertSource(vertSource);
			userResources.shaders.onReload[vertKey].add({ 
				shader.setFragSource(userResources.shaders[vertKey]); 
			});
		}
		
		//TODO: currently only reloading fragSource...
		
		// now load bitmaps...
		assert("shaderConfig" in eltData);
		assert(eltData["shaderConfig"].type == JSONType.OBJECT);
		JSONValue shaderConfig = eltData["shaderConfig"].object;
		
		foreach(string shaderVariable, value; shaderConfig) {
			assert(value.type == JSONType.object);
			if ("bitmap" in value.object) {
				string sampler = value.object["bitmap"].str;
				string samplerKey = baseName(stripExtension(sampler));
				shader.setSampler(shaderVariable, userResources.bitmaps[samplerKey]);
				userResources.bitmaps.onReload[samplerKey].add({ shader.setSampler(shaderVariable, userResources.bitmaps[samplerKey]); });
			}
			else if ("float" in value.object) {
				shader.setFloat(shaderVariable, value.object["float"].floating);
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
				case "rect": {
					div = buildRect(eltData);
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

	public static fromFile(MainLoop window, ResourceManager resources, Component parent, string filename) {
		resources.addFile(filename);
		string jsonKey = baseName(stripExtension(filename));
		SceneBuilder builder = new SceneBuilder(window, resources);
		auto data = resources.jsons[jsonKey]["scene"];
		// TODO: add scene file hotloading...
		builder.loadUserFiles(dirName(filename), data);
		builder.buildSceneRecursive(parent, data);

		window.calculateLayout(); // TODO: this call should not be necessary, window should know layout is dirty...
	}
}

class TitleState : DialogBuilder {

	ResourceManager userResources;

	this(MainLoop window) {
		super(window);

		
		userResources = new ResourceManager();
		window.onClose.add(() { destroy(userResources); });
		
		window.onDisplaySwitch.add((switchIn) { if (switchIn) { userResources.refreshAll(); }});

		/* MENU */
		buildDialog(window.resources.jsons["title-layout"]);
		
		auto canvas = getElementById("canvas");
		
		window.onInit.add({
			// string sceneFile = "data/scene1/scene-oilslick.json";
			string sceneFile = "data/scene2/scene-twirl.json";
			// string sceneFile = "data/scene3/scene-waterlevel.json";
			
			SceneBuilder.fromFile(window, userResources, canvas, sceneFile);
			//TODO: auto-reload scene...
		});

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

}
