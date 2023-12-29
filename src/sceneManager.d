module sceneManager;

import std.string : toStringz, format;
import std.conv : to;
import std.json;
import std.path;
import std.exception;
import std.stdio;

import allegro5.allegro;
import allegro5.allegro_color : al_color_html;
import allegro5.shader;

import helix.resources;
import helix.component;
import helix.mainloop;
import helix.color;
import helix.widgets;
import helix.allegro.bitmap;

import scene;

class SceneManager {

	private void loadUserFiles(string baseDir, JSONValue data) {
		enforce(data.type == JSONType.ARRAY, "Expected JSON array");
		foreach (eltData; data.array) {

			// create child components
			Component div = null;
			string type = eltData["type"].str;
			switch(type) {
				case "bitmap": {
					string bmpFile = eltData["src"].str;
					// TODO: set root dir on ResourceManager, let it do the rebasing
					string bmpRebased = buildNormalizedPath(baseDir, bmpFile);
					resources.addFile(bmpRebased);
					break;
				}
				case "text": {
					if ("font" in eltData) {
						string fontFile = eltData["font"].str;
						// TODO: set root dir on ResourceManager, let it do the rebasing
						string fontRebased = buildNormalizedPath(baseDir, fontFile);
						resources.addFile(fontRebased);
					}
					break;
				}
				case "shader": {
					// TODO: set root dir on ResourceManager, let it do the rebasing
					if ("fragSrc" in eltData) {
						string fragFile = eltData["fragSrc"].str;
						string fragRebased = buildNormalizedPath(baseDir, fragFile);
						resources.addFile(fragRebased);
					}

					if ("vertSrc" in eltData) {
						string vertFile = eltData["vertSrc"].str;
						string vertRebased = buildNormalizedPath(baseDir, vertFile);
						resources.addFile(vertRebased);
					}

					enforce("shaderConfig" in eltData, "ShadeConfig is required for shader object");
					enforce(eltData["shaderConfig"].type == JSONType.OBJECT);
					JSONValue shaderConfig = eltData["shaderConfig"].object;

					foreach(string shaderVariable, value; shaderConfig) {
						enforce(value.type == JSONType.object);
						if ("bitmap" in value.object) {
							string sampler = value.object["bitmap"].str;
							string samplerRebased = buildNormalizedPath(baseDir, sampler);
							resources.addFile(samplerRebased);
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

	private Component buildText(JSONValue eltData) {

		int fontSize = 12;
		if ("fontSize" in eltData) {
			enforce(eltData["fontSize"].type == JSONType.INTEGER);
			fontSize = to!int(eltData["fontSize"].integer);
		}
		TextComponent result = new TextComponent(window);
		if ("font" in eltData) {
			string src = eltData["font"].str;
			string fontKey = baseName(stripExtension(src));
			result.font = resources.fonts[fontKey].get(fontSize);
			resources.fonts.onReload[fontKey].add({
				result.font = resources.fonts[fontKey].get(fontSize);
			});
		}
		else {
			result.font = resources.fonts["builtin_font"].get();
		}

		int x = to!int(eltData["x"].integer);
		int y = to!int(eltData["y"].integer);

		if ("color" in eltData) {
			string color = eltData["color"].str;
			result.color = al_color_html(toStringz(color));
		}
		else {
			result.color = Color.BLACK;
		}
		result.text = eltData["text"].str;
		result.setShape(x, y, 1, 1);
		return result;
	}

	private Component buildRect(JSONValue eltData) {
		RectComponent result = new RectComponent(window);
		if ("fill" in eltData) {
			string colorStr = eltData["fill"].str;
			result.fill = al_color_html(toStringz(colorStr));
		}
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
		Bitmap bmp = resources.bitmaps[key];
		img.img = bmp;
		resources.bitmaps.onReload[key].add({ 
			refreshSceneIfIncomplete();
			img.img = resources.bitmaps[key]; 
		});
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
			fragSource = resources.shaders[fragKey];
			shader.setFragSource(fragSource);
			resources.shaders.onReload[fragKey].add({ 
				refreshSceneIfIncomplete();
				shader.setFragSource(resources.shaders[fragKey]);
			});
		}
		if ("vertSrc" in eltData) {
			string vertFile = eltData["vertSrc"].str;
			string vertKey = baseName(stripExtension(vertFile));
			vertSource = resources.shaders[vertKey];
			shader.setVertSource(vertSource);
			resources.shaders.onReload[vertKey].add({ 
				refreshSceneIfIncomplete();
				shader.setFragSource(resources.shaders[vertKey]); 
			});
		}
		
		enforce("shaderConfig" in eltData);
		enforce(eltData["shaderConfig"].type == JSONType.OBJECT);
		JSONValue shaderConfig = eltData["shaderConfig"].object;
		
		foreach(string shaderVariable, value; shaderConfig) {
			enforce(value.type == JSONType.object);
			if ("bitmap" in value.object) {
				string sampler = value.object["bitmap"].str;
				string samplerKey = baseName(stripExtension(sampler));
				shader.setSampler(shaderVariable, resources.bitmaps[samplerKey]);
				resources.bitmaps.onReload[samplerKey].add({
					refreshSceneIfIncomplete();
					shader.setSampler(shaderVariable, resources.bitmaps[samplerKey]); 
				});
			}
			else if ("float" in value.object) {
				shader.setFloat(shaderVariable, value.object["float"].floating);
			}
		}

		return shader;
	}
	
	private void buildSceneRecursive(Component parent, JSONValue data) {
		enforce(data.type == JSONType.ARRAY, "Expected JSON array");
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
				case "text": {
					div = buildText(eltData);
					break;
				}
				default: enforce(false, format("Unknown scene object type '%s'", type));
			}

			parent.addChild(div);
			if ("children" in eltData) {
				buildSceneRecursive(div, eltData["children"]);
			}
		}

	}
	
	private ResourceManager resources;
	private MainLoop window;
	private Component rootComponent;
	private string jsonKey;
	private string filename;

	private this(MainLoop window, ResourceManager resources, Component rootComponent, string jsonKey, string filename) {
		this.window = window;
		this.resources = resources;
		this.rootComponent = rootComponent;
		this.jsonKey = jsonKey;
		this.filename = filename;
	}

	bool sceneComplete = false;

	private void refreshSceneIfIncomplete() {
		if (!sceneComplete) {
			writeln("Rebuilding incompete scene");
			rootComponent.clearChildren();
			JSONValue rootData = resources.jsons[jsonKey]["scene"];
			buildSceneRecursive(rootComponent, rootData);
			window.calculateLayout(); // TODO: this call should not be necessary, window should know layout is dirty...
			sceneComplete = true;
		}
	}

	void buildScene() {
		sceneComplete = false;
		JSONValue rootData = resources.jsons[jsonKey]["scene"];
		loadUserFiles(dirName(filename), rootData);
		buildSceneRecursive(rootComponent, rootData);
		window.calculateLayout(); // TODO: this call should not be necessary, window should know layout is dirty...
		sceneComplete = true; // reached here without intervening exceptions.
	}

	public static SceneManager buildFromFile(MainLoop window, ResourceManager resources, Component parent, string filename) {
		enforce(extension(filename) == ".json", format("Scene file [%s] must have .json extension", filename));
		
		string key = baseName(stripExtension(filename));
		resources.addFile(filename);
		
		SceneManager builder = new SceneManager(window, resources, parent, key, filename);
		
		resources.jsons.onReload[key].add({
			writeln("Scene file has changed, reloading...");
			builder.buildScene();
		});

		builder.buildScene();

		return builder;
	}
}
