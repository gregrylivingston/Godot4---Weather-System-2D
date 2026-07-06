@tool
extends EditorPlugin
## Weather System 2D — editor plugin entry point.
##
## The kit's nodes (WaterBody2D, and — as they migrate into the addon — SkySetting and
## MapCamera2D) declare `class_name`, so they register as global classes automatically and
## appear in the "Create New Node" dialog without needing add_custom_type() here.
##
## This plugin exists so the kit can be enabled/disabled as a unit and so future editor
## tooling (gizmos, inspector plugins, scene-builder docks) has a home.

func _enter_tree() -> void:
	# Reserved for future editor integrations (custom gizmos / inspector plugins).
	pass


func _exit_tree() -> void:
	pass
