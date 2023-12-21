module dialog;

import std.stdio;
import helix.mainloop;
import helix.widgets;
import engine;
import helix.component;
import helix.richtext;

class Dialog : State {

	this(MainLoop window, Component slotted = null) {
		super(window);
		
		buildDialog(window.resources.jsons["dialog-layout"]);

		if (slotted) {
			getElementById("div_slot").addChild(slotted);
		}

		getElementById("btn_ok").onAction.add(
			(e) { window.popScene(); }
		);
	}

}

void openDialog(MainLoop window, string msg) {
	PreformattedText slotted = new PreformattedText(window);
	slotted.text = msg;
	Dialog dlg = new Dialog(window, slotted);
	window.pushScene(dlg);
}

void openDialog(MainLoop window, Fragment[] Fragments) {
	RichText slotted = new RichText(window);
	slotted.setFragments(Fragments);
	Dialog dlg = new Dialog(window, slotted);
	window.pushScene(dlg);
}