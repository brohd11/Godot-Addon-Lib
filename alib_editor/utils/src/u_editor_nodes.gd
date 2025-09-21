extends RefCounted

const Docks = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/docks.gd") #>import docks.gd
const BottomPanel = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/bottom_panel.gd") #>import bottom_panel.gd
const MainScreen = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/main_screen.gd") #>import main_screen.gd
const FileSystem = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/filesystem.gd") #>import filesystem.gd

static func get_current_dock(control):
	return Docks.get_current_dock(control)

static func get_current_dock_control(control):
	return Docks.get_current_dock_control(control)
