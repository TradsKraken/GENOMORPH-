extends Node

## TutorialManager — Autoload Singleton
## The tutorial is now triggered directly by prologue_manager.gd in the level scene,
## which calls hud.start_tutorial() after the story dialogue finishes.
## This autoload exists as a registry for any future tutorial-related global state.
