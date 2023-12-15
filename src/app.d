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
		auto mainloop = new MainLoop("krampus23");
		mainloop.init();
		
		mainloop.resources.addFile("data/DejaVuSans.ttf");
		mainloop.resources.addFile("data/style.json");
		mainloop.resources.addFile("data/title-layout.json");
		mainloop.resources.addFile("data/dialog-layout.json");

		mainloop.styles.applyResource("style");

		mainloop.addState("TitleState", new TitleState(mainloop));
		mainloop.switchState("TitleState");

		mainloop.run();

		return 0;
	});

}