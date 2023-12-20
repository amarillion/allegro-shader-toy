module app;

import std.stdio;
import helix.mainloop;
import engine;
import allegro5.allegro;
import allegro5.allegro_audio;

void main()
{
	al_run_allegro(
	{

		al_init();
		auto mainloop = new MainLoop(MainConfig.of
			.appName("krampus23")
			.targetFps(60)
		);
		mainloop.init();
		
		mainloop.resources.addFile("data/DejaVuSans.ttf");
		mainloop.resources.addFile("data/style.json");
		mainloop.resources.addFile("data/title-layout.json");
		mainloop.resources.addFile("data/dialog-layout.json");
		mainloop.resources.addFile("data/iris_frag.glsl");
		mainloop.resources.addFile("data/gradient.png");
		mainloop.resources.addFile("data/map3.png");
		mainloop.resources.addFile("data/map3_2.png");

		mainloop.styles.applyResource("style");

		mainloop.onDisplaySwitch.add((switchIn) { if (switchIn) { writeln("Window switched in event called"); mainloop.resources.refreshAll(); }});
		mainloop.addState("TitleState", new TitleState(mainloop));
		mainloop.switchState("TitleState");

		mainloop.run();

		return 0;
	});

}