module mainState;

import helix.resources;
import helix.mainloop;
import helix.richtext;

import scene;
import dialog;
import dialogBuilder;
import sceneManager;

import std.json;

class MainState : DialogBuilder {

	SceneManager sceneManager;
	ResourceManager userResources;

	this(MainLoop window) {
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
			// string sceneFile = "data/scene1/scene-oilslick.json";
			// string sceneFile = "data/scene2/scene-twirl.json";
			// string sceneFile = "data/scene3/scene-waterlevel.json";
			// string sceneFile = "data/scene4/scene-peppy.json";
			string sceneFile = "data/scene5/scene-wish.json";
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

	}

}
