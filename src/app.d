module app;

import std.stdio;
import std.conv;

import allegro5.allegro;
import allegro5.allegro_audio;

import helix.mainloop;
import helix.richtext;

import dialog;
import mainState;

void main(string[] args)
{
	string sceneFile;

	// string sceneFile = "data/scene1/scene-oilslick.json";
	// string sceneFile = "data/scene2/scene-twirl.json";
	// string sceneFile = "data/scene3/scene-waterlevel.json";
	// string sceneFile = "data/scene4/scene-peppy.json";
	// string sceneFile = "data/scene5/scene-wish.json";
	
	if (args.length == 2) {
		sceneFile = args[1];
	}
	else if (args.length > 2) {
		writeln("Unexpected arguments. Must specify exactly one argument");
	}
	else {
		writeln("Must specify the scene file as argument");
		return;
	}

	al_run_allegro(
	{

		al_init();
		auto mainloop = new MainLoop(MainConfig.of
			.appName("krampus23")
			.targetFps(60)
		);
		mainloop.init();

		void showErrorDialog(Exception e) {
			writeln(e.info);
			RichTextBuilder builder = new RichTextBuilder()
				.h1("Error")
				.text(to!string(e.message)).p();
			openDialog(mainloop, builder.build());
		}

		mainloop.onException.add((e) {
			showErrorDialog(e);
		});

		mainloop.resources.addFile("data/DejaVuSans.ttf");
		mainloop.resources.addFile("data/style.json");
		mainloop.resources.addFile("data/title-layout.json");
		mainloop.resources.addFile("data/dialog-layout.json");
		mainloop.styles.applyResource("style");

		mainloop.onDisplaySwitch.add((switchIn) { if (switchIn) { writeln("Window switched in event called"); mainloop.resources.refreshAll(); }});

		mainloop.addState("MainState", new MainState(mainloop, sceneFile));
		mainloop.switchState("MainState");
		
		mainloop.run();

		return 0;
	});

}