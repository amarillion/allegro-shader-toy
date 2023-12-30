module mainState;

import std.json;
import std.conv;

import allegro5.shader;

import helix.resources;
import helix.mainloop;
import helix.richtext;

import scene;
import dialog;
import dialogBuilder;
import sceneManager;

class MainState : DialogBuilder {

	SceneManager sceneManager;
	ResourceManager userResources;

	this(MainLoop window, string sceneFile) {
		super(window);

		userResources = new ResourceManager();

		window.onClose.add(() { destroy(userResources); });
		
		window.onDisplaySwitch.add((switchIn) { 
			if (switchIn) { userResources.refreshAll(); }
		});

		/* MENU */
		buildDialog(window.resources.jsons["title-layout"]);
		
		auto canvas = getElementById("canvas");
		
		window.onInit.add({
			sceneManager = SceneManager.buildFromFile(window, userResources, canvas, sceneFile);
			//TODO: auto-reload scene...
		});

		getElementById("btn_credits").onAction.add((e) { 
			RichTextBuilder builder = new RichTextBuilder()
				.h1("Allegro Shader Toy")
				.text("Play around with Shader programs in Allegro.").br()
				.text("It was made by ").b("Amarillion").text(" for ").b("BugSquasher")
				.text(" during KrampusHack 2023, a secret santa game jam.").p()
				.h1("Happy holidays BugSquasher, and best wishes for 2024!")
				.text("Coded by").p()
				.link("Martijn 'Amarillion' van Iersel", "https://twitter.com/mpvaniersel").p();
			openDialog(window, builder.build());
		});

		string fragSrc = to!string(al_get_default_shader_source(
			ALLEGRO_SHADER_PLATFORM.ALLEGRO_SHADER_AUTO, 
			ALLEGRO_SHADER_TYPE.ALLEGRO_VERTEX_SHADER
		));
		
		string vertSrc = to!string(al_get_default_shader_source(
			ALLEGRO_SHADER_PLATFORM.ALLEGRO_SHADER_AUTO, 
			ALLEGRO_SHADER_TYPE.ALLEGRO_PIXEL_SHADER
		));
		
		getElementById("btn_default_shaders").onAction.add((e) { 
			RichTextBuilder builder = new RichTextBuilder()
				.h1("Default Vertex Shader")
				.lines(fragSrc).p()
				.h1("Default Pixel Shader")
				.lines(vertSrc).p();
			openDialog(window, builder.build());
		});

	}

}
