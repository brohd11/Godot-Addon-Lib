const Docks = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/docks.gd")



static func get_scene_tabs():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCENE_TABS)

static func get_scene_tabs_popup():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCENE_TABS_POPUP)

static func get_scene_tree_dock():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCENE_TREE_DOCK)

static func get_scene_tree_popup():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCENE_TREE_POPUP)

static func get_current_scene_path():
	var open_scenes = EditorInterface.get_open_scenes()
	var scene_tabs = get_scene_tabs()
	var tab_bar = scene_tabs.get_child(0).get_child(0).get_child(0) as TabBar
	var current_tab_name = tab_bar.get_tab_title(tab_bar.current_tab)
	for scene_path in open_scenes:
		var base_name = scene_path.get_basename()
		if base_name.ends_with(current_tab_name):
			return scene_path


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
