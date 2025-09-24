extends RefCounted
#! namespace ALib.Editor.UEditorNodes

const Docks = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/docks.gd")
const BottomPanel = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/bottom_panel.gd")
const MainScreen = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/main_screen.gd")
const FileSystem = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/filesystem.gd")

static func get_current_dock(control):
	return Docks.get_current_dock(control)

static func get_current_dock_control(control):
	return Docks.get_current_dock_control(control)
