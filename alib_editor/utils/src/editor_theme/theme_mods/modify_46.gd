extends EditorScript

func _run() -> void:
	modify_theme_46()

static func modify_theme_46():
	var thm = EditorInterface.get_editor_theme()
	var editor_scale = EditorInterface.get_editor_scale()
	
	var panel = &"panel"
	
	var margin_theme_type_variations = {
		&"NoBorderBottomPanel": 0,
		&"NoBorderHorizontalBottom": -2,
		&"NoBorderAnimation": 0
	}
	for marg_theme in margin_theme_type_variations.keys():
		var val = margin_theme_type_variations[marg_theme]
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
	
	var dock_tab_bar = EditorInterface.get_base_control().find_child("DockSlot*", true, false).find_child("*TabBar*", false, false)
	for _name in tab_sb:
		var sb = dock_tab_bar.get_theme_stylebox(_name)
		sb.set_content_margin_all(8 * editor_scale)
