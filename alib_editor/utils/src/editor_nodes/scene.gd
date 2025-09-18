const Docks = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/docks.gd")

static var _scene_tree_dock

static func get_scene_tabs():
	var main_screen = EditorInterface.get_editor_main_screen()
	var main_screen_parent = main_screen.get_parent().get_parent()
	for c in main_screen_parent.get_children():
		if c.get_class() == "EditorSceneTabs":
			return c

static func get_scene_tabs_popup():
	var scene_tabs = get_scene_tabs()
	var popup = scene_tabs.get_child(0).get_child(0).get_child(1)

static func get_scene_tree_dock():
	if is_instance_valid(_scene_tree_dock):
		return _scene_tree_dock
	var docks = Docks.get_all_docks()
	for d in docks:
		var children = d.get_children()
		for c:Node in children:
			if c.get_class() == "SceneTreeDock":
				_scene_tree_dock = c
				return _scene_tree_dock
	printerr("Could not get scene tree dock.")

static func get_scene_tree_popup():
	if not is_instance_valid(_scene_tree_dock):
		get_scene_tree_dock()
	
	var popup = _scene_tree_dock.get_child(15)
	return popup

static func get_canvas_item_editor():
	var main_screen = EditorInterface.get_editor_main_screen()
	for child in main_screen.get_children():
		var _class = child.get_class()
		if _class == "CanvasItemEditor":
			return child

static func get_canvas_item_editor_popup():
	var canvas_editor = get_canvas_item_editor()
	var popup = canvas_editor.get_child(4)
	return popup

static func get_current_scene_path():
	var open_scenes = EditorInterface.get_open_scenes()
	var scene_tabs = get_scene_tabs()
	var tab_bar = scene_tabs.get_child(0).get_child(0).get_child(0) as TabBar
	var current_tab_name = tab_bar.get_tab_title(tab_bar.current_tab)
	for scene_path in open_scenes:
		var base_name = scene_path.get_basename()
		if base_name.ends_with(current_tab_name):
			return scene_path
