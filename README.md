# Allegro Shader Toy

A little toy program to play with shaders in Allegro.

I created this for [KrampusHack 2023](https://tins.amarillion.org/krampu23/).

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
  * Shaders, with fragSrc, vertSrc, and shader 

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
