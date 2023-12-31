# Allegro Shader Toy

A little toy program to play with shaders in Allegro.

I created this for [KrampusHack 2023](https://tins.amarillion.org/krampu23/) for _Bugsquasher_. Happy holidays Bugsquasher!

## Tutorial video

This concept is perhaps unusual for a speedhack. So to make it more clear, I decided to create a tutorial video.
You can watch it on youtube: [Allegro Shader Toy Tutorial](https://www.youtube.com/watch?v=uOgsUEA0tM0)

## KrampusHack 2023

Here was Bugsquashers wishlist:

	Tax my new gfx card's abilities. Bet you can't make it drop under 60FPS lol right.

	I want a graphics program. Whether it draws, allows you to draw, or just looks groovy I don't care.

	Use shaders to draw cool stuff, allegro should help with this if you're interested in using Allegro again, I don't care.

	Final optional wish is an options list that can change attributes of the shader in use.

	Most importantly, learn something, have fun, don't stress it...

The allegro shader toy is my interpretation of this wishlist. It is definitely a program that uses shaders to draw cool stuff. 
I don't think any of the examples I included will make it drop under 60FPS, although you could easily write a really inefficient shader that will do so.
Finally, the program allows you to change the float and int attributes of shaders using the shaderConfig of your scene files.

## How to use this program

To use this program, you must have a scene file, and ideally also one or more shader programs.
See below on how to write scene files. This program comes with a number of example scenes for experimentation.

Run the program with `allegro-shader-toy scene-file.json`

This program is designed for fast iteration: you can edit scene file, shaders and bitmaps,
and your changes will be hot-swapped into the running program. That way you can see the effect of small
tweaks really quickly. If you make mistakes, like a syntax error in a json file or shader program,
you should see an error message pop up indicating the line and position of the mistake.

## How to write a scene file

You start by creating or editing a _scene file_. The app comes with example scene files that you can edit.
It helps a lot to use an IDE that understands JSON-ML schema (for example, Visual Studio Code). Such an IDE will
help you write correct JSON that is understood by the program.

In your scene file, you can define four different objects:
  * Filled rectangles, with x, y, w, h and fill properties.
  * Bitmaps, with a src property.
  * Shaders, with fragSrc, vertSrc, and shaderConfig. 
    Through the shaderConfig you can pass float, int and texture uniform variables to your shader program.

These scene objects can be nested, so they form a _scene graph_.

## How to write a shader

You write shaders in the OpenGL shader language (GLSL). 

Shader programs consist of two parts: a vertex shader, and a fragment shader (a.k.a. pixel shader).
Allegro has defaults for both, so you only need to provide one of the two (depending on what you are trying to do).

When using allegro drawing functions such as al_draw_bitmap or al_draw_filled_rectangle,
data is passed to your shader functions in a certain way. For example, in the fragment shader receives 
the bitmap that you're drawing in `al_tex`. The coordinate within the texture (normalized to 0-1 range), 
will be in `varying_texcoord`. 

To make it easy on yourself, stick with the Allegro conventions as much as possible.
