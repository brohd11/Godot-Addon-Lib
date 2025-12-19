@tool
extends VBoxContainer

@onready var tree: Tree = %Tree

const FileSystemTree = preload("res://addons/addon_lib/brohd/alib_editor/file_system/tree/filesystem_tree.gd")

static func get_scene() -> PackedScene:
	return load("res://addons/addon_lib/brohd/alib_editor/file_system/tree/filesystem_tree.tscn")

func set_dir(target_dir:String):
	tree.set_dir(target_dir)
