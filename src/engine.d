module engine;

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

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import allegro5.allegro_ttf;

import irisEffect;

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
					if ("shader" in eltData) {
						IrisImageComponent img = new IrisImageComponent(window);
						img.img = window.resources.bitmaps[eltData["src"].str];
						div = img;
					}
					else {
						ImageComponent img = new ImageComponent(window);
						img.img = window.resources.bitmaps[eltData["src"].str];
						div = img;
					}
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

class TitleState : State {

	this(MainLoop window) {
		super(window);

		IrisEffect.init(window.resources);

		/* MENU */
		buildDialog(window.resources.getJSON("title-layout"));
		
		getElementById("btn_start_game").onAction.add((e) { 
			writeln("Pressed START");
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
