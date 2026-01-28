extends RefCounted
#! namespace ALibEditor.Utils class UEditorTheme

const BACKPORTED = 100
const ThemeColor = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_theme/theme_color.gd")
const ThemeSetter = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_theme/theme_setter.gd")

static func get_icon(icon_name:String, theme_type:String=&"EditorIcons"):
	var icon = EditorInterface.get_editor_theme().get_icon(icon_name, theme_type)
	return icon

static func get_icon_name(icon, theme_type:String=&"EditorIcons"):
	if BACKPORTED < 2:
		var path = new().get_script().resource_path
		printerr("Cannot get icon list in backported plugin version 4.%s. Calling file: %s" % [BACKPORTED, path])
		return ""
	var icon_list = EditorInterface.get_editor_theme().get_icon_list(theme_type)
	for icon_name in icon_list:
		if icon == get_icon(icon_name, theme_type):
			return icon_name

static func set_menu_button_to_editor_theme(menu_button:MenuButton):
	menu_button.flat = false
	var b = Button.new()
	menu_button.add_child(b)
	var overides = ["normal", "pressed"]
	for o in overides:
		menu_button.add_theme_stylebox_override(o, b.get_theme_stylebox(o))
	b.queue_free()

static func button_set_main_screen_theme_var(button:Button):
	button.theme_type_variation = &"MainScreenButton"

static func get_size_of_control_type(type):
	var ins = type.new()
	EditorInterface.get_base_control().add_child(ins)
	var new_size = ins.size
	ins.hide()
	ins.queue_free()
	return new_size


static func modify_theme_46():
	var thm = EditorInterface.get_editor_theme()
	var editor_scale = EditorInterface.get_editor_scale()
	
	var panel = &"panel"
	
	var margins = {
		&"NoBorderBottomPanel": 0,
		&"NoBorderHorizontalBottom":-2,
		&"NoBorderAnimation":0
	}
	for marg_theme in margins.keys():
		var val = margins[marg_theme]
		thm.set_constant(&"margin_left", marg_theme, val)
		thm.set_constant(&"margin_right", marg_theme, val)
		thm.set_constant(&"margin_bottom", marg_theme, val)
	
	var item_sb = thm.get_stylebox(panel, &"ItemList").duplicate() as StyleBoxFlat
	var base_color = thm.get_color(&"base_color", &"Editor")
	var darkened_base = base_color.darkened(0.2)
	item_sb.bg_color = darkened_base
	thm.set_stylebox(panel, &"Tree", item_sb)
	thm.set_stylebox(panel, &"ItemList", item_sb)
	thm.set_stylebox(panel, &"EditorInspector", item_sb)
	
	
	var tab_sb = [&"tab_selected", &"tab_unselected", &"tab_hovered", &"tab_focus", &"tab_disabled"]
	for _name in tab_sb:
		var sb = thm.get_stylebox(_name, &"TabBar").duplicate()
		sb.set_content_margin_all(8 * editor_scale)
		thm.set_stylebox(_name, &"TabBar", sb)
	
	var dock_set = false
	var docks = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.DOCKS)
	for dock in docks:
		if dock_set:
			break
		for c in dock.get_children(true):
			if c is TabBar:
				for _name in tab_sb:
					var sb = c.get_theme_stylebox(_name)
					sb.set_content_margin_all(8 * editor_scale)
				dock_set = true
				break
		
