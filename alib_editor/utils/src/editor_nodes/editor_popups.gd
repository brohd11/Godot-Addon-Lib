class_name EditorPopups
#extends "some_calss"

const ScriptEd = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/script_editor.gd")
const FileSystem = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/filesystem.gd")
const Scene = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/scene.gd")

static func get_script_editor_code_popup():
	return ScriptEd.get_popup()

static func get_script_editor_popup():
	return ScriptEd.get_script_list_popup()

static func get_file_system_popup():
	return FileSystem.get_popup()

static func get_file_system_create_popup():
	return FileSystem.get_create_popup()

static func get_scene_tabs_popup():
	return Scene.get_scene_tabs_popup()

static func get_scene_tree_popup():
	return Scene.get_scene_tree_popup()

static func get_2d_editor_popup():
	return Scene.get_canvas_item_editor_popup()
