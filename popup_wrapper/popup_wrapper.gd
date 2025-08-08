extends RefCounted

class WrapperParams:
	var fs_popup_callable = null
	var items_to_skip = []
	var show_shortcuts = false

static func popup_wrapper(new_popup:PopupMenu, popup_to_copy:PopupMenu, wrapper_params=null):
	if wrapper_params == null:
		wrapper_params = WrapperParams.new()
	if wrapper_params.fs_popup_callable == null:
		wrapper_params.fs_popup_callable = _on_wrapper_pressed
	_copy_popup(new_popup, popup_to_copy, wrapper_params)
	new_popup.id_pressed.connect(wrapper_params.fs_popup_callable.bind(new_popup, popup_to_copy))

static func _copy_popup(new_popup:PopupMenu, popup_to_copy:PopupMenu, wrapper_params:WrapperParams):
	var callable = wrapper_params.fs_popup_callable
	var items_to_skip = wrapper_params.items_to_skip
	var shortcuts = wrapper_params.show_shortcuts
	var base_index = new_popup.item_count
	var new_popup_count = 0
	for i in range(popup_to_copy.item_count):
		var new_popup_index = base_index + new_popup_count
		var is_sep = popup_to_copy.is_item_separator(i)
		if is_sep:
			if new_popup_index > 0 and not new_popup.is_item_separator(new_popup_index - 1):
				new_popup.add_separator()
				new_popup_count += 1
			continue
		
		var id = popup_to_copy.get_item_id(i)
		var text = popup_to_copy.get_item_text(i)
		if text in items_to_skip:
			continue
		new_popup_count += 1
		
		var submenu = popup_to_copy.get_item_submenu_node(i)
		if is_instance_valid(submenu):
			var new_submenu = PopupMenu.new()
			_copy_popup(new_submenu, submenu, wrapper_params)
			new_submenu.id_pressed.connect(callable.bind(new_submenu, submenu))
			new_popup.add_submenu_node_item(text, new_submenu)
		else:
			
			new_popup.add_item(text, id)
			if shortcuts:
				var shortcut = popup_to_copy.get_item_shortcut(i)
				new_popup.set_item_shortcut(new_popup_index, shortcut)
		
		var icon = popup_to_copy.get_item_icon(i)
		if icon:
			new_popup.set_item_icon(new_popup_index, icon)
			var mod = popup_to_copy.get_item_icon_modulate(i)
			new_popup.set_item_icon_modulate(new_popup_index, mod)

static func squash_icons(popup:PopupMenu):
	var popup_has_texture = false
	for i in range(popup.item_count):
		if popup.get_item_icon(i) != null:
			popup_has_texture = true
			break
	if popup_has_texture:
		for i in range(popup.item_count):
			if popup.get_item_icon(i) != null:
				continue
			popup.set_item_indent(i, -2)

static func _on_wrapper_pressed(id:int, wrapper_popup:PopupMenu, fs_popup:PopupMenu):
	if id >= 5000:
		return
	fs_popup.id_pressed.emit(id)
