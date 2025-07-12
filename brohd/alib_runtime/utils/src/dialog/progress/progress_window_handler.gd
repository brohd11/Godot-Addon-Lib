@tool
extends "res://addons/addon_lib/brohd/alib_runtime/utils/src/dialog/handler_base.gd"

const PROGRESS_WINDOW_SCENE = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/dialog/progress/class/progress_window.tscn")

func _init(message:String,_root_node=null):
	_set_root_node(_root_node)
	
	_create_dialog(message)

func _create_dialog(message):
	dialog = PROGRESS_WINDOW_SCENE.instantiate()
	
	dialog.set_text(message)
	
	root_node.add_child(dialog)

func increment_bar(new_val):
	dialog.increment_bar(new_val)
	
	pass
