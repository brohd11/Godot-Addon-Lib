extends RefCounted

const PopupHelper = preload("res://addons/addon_lib/brohd/alib_runtime/popup_menu/popup_menu_path_helper.gd")
const Params = PopupHelper.ParamKeys

static func add_context_popups(plugin:EditorContextMenuPlugin, script_editor, menu_items, context_menu_callable):
	var multi_popup_groups = {}
	
	for menu_path:String in menu_items:
		var slice_count = menu_path.get_slice_count("/")
		if slice_count > 1:
			var first_slice = menu_path.get_slice("/", 0)
			if not first_slice in multi_popup_groups:
				multi_popup_groups[first_slice] = {}
			multi_popup_groups[first_slice][menu_path] = menu_items.get(menu_path)
			continue
		
		var popup_data = menu_items.get(menu_path)
		var icon = popup_data.get(Params.ICON_KEY)
		if icon is Array:
			icon = icon[icon.size() - 1]
		var menu_name = menu_path.get_file()
		plugin.add_context_menu_item(menu_path, context_menu_callable.bind(menu_name), icon)
	
	
	for group in multi_popup_groups:
		var group_data = multi_popup_groups.get(group)
		var popup = PopupMenu.new()
		popup.id_pressed.connect(_submenu_pressed.bind(popup, script_editor, context_menu_callable))
		for menu_path in group_data:
			var popup_data = menu_items.get(menu_path)
			var icon = popup_data.get(Params.ICON_KEY)
			if icon is Array:
				icon = icon[icon.size() - 1]
			var menu_name = menu_path.get_file()
			if icon:
				popup.add_icon_item(icon, menu_name)
			else:
				popup.add_item(menu_name)
		
		plugin.add_context_submenu_item(group, popup)

static func _submenu_pressed(id, popup, script_editor, callable):
	var name = PopupHelper.parse_id_text(id, popup)
	callable.call(script_editor, name)
