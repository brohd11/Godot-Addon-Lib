class_name PopupWrapper
extends RefCounted

const PopupHelper = preload("res://addons/addon_lib/brohd/alib_runtime/popup_menu/popup_menu_path_helper.gd")
const USort = ALibRuntime.Utils.USort

class ItemParams extends PopupHelper.ParamKeys:
	const POSITION = "POSITION"
	enum Position{
		TOP,
		BOTTOM
	}
	const PRIORITY = "PRIORITY"

class WrapperParams:
	var fs_popup_callable = null
	var connect_callable:= true
	var items_to_skip:= []
	var show_shortcuts:= false
	var custom_context_item_data:= {}
	var sorted_custom_item_data:= {}
	var existing_item_dict:= {}
	
	var non_plugin_base_id = 5000
	var non_plugin_pre_scripts_data = {}
	var non_plugin_post_scripts_data = {}

static func popup_wrapper(new_popup:PopupMenu, popup_to_copy:PopupMenu, wrapper_params=null):
	if wrapper_params == null:
		wrapper_params = WrapperParams.new()
	if wrapper_params.fs_popup_callable == null:# and wrapper_params.connect_callable:
		wrapper_params.fs_popup_callable = _on_wrapper_pressed
	if wrapper_params.custom_context_item_data.is_empty():
		wrapper_params.custom_context_item_data = get_custom_context_items(popup_to_copy)
		
	
	wrapper_params.existing_item_dict = PopupHelper.create_popup_items_dict(new_popup)
	
	wrapper_params.sorted_custom_item_data = sort_custom_context_items(wrapper_params.custom_context_item_data)#, top_custom_item_data, bottom_custom_item_data)
	
	_copy_popup(new_popup, popup_to_copy, wrapper_params)
	
	if wrapper_params.connect_callable:
		new_popup.id_pressed.connect(wrapper_params.fs_popup_callable.bind(new_popup, popup_to_copy))


static func _copy_popup(new_popup:PopupMenu, popup_to_copy:PopupMenu, wrapper_params:WrapperParams):
	var callable = wrapper_params.fs_popup_callable
	var shortcuts = wrapper_params.show_shortcuts
	var unsorted_popup_data = wrapper_params.custom_context_item_data.get(popup_to_copy)
	var items_to_skip = unsorted_popup_data.keys()
	items_to_skip.append_array(wrapper_params.items_to_skip)
	
	var sorted_popup_data = wrapper_params.sorted_custom_item_data.get(popup_to_copy, {})
	
	## add custom pre
	var pre_items_dict = sorted_popup_data.get("pre", {})
	var post_items_dict = sorted_popup_data.get("post", {})
	for item_path in pre_items_dict.keys():
		var item_data = pre_items_dict.get(item_path)
		_add_custom_item(new_popup, item_path, item_data, wrapper_params.existing_item_dict)
	
	if not pre_items_dict.is_empty():
		new_popup.add_separator()
	##
	
	var base_index = new_popup.item_count
	var new_popup_count = 0
	for i in range(popup_to_copy.item_count):
		var new_popup_index = base_index + new_popup_count
		var is_sep = popup_to_copy.is_item_separator(i)
		if is_sep:
			if new_popup_index == 0:
				continue
			if new_popup.is_item_separator(new_popup_index - 1):
				continue
			if new_popup_index == popup_to_copy.item_count:
				continue
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
	
	## add custom post
	if not post_items_dict.is_empty():
		new_popup.add_separator()
	
	for item_path in post_items_dict:
		var item_data = post_items_dict.get(item_path)
		_add_custom_item(new_popup, item_path, item_data, {})
	##


static func get_custom_context_items(popup_to_copy:PopupMenu):
	var custom_item_data = {}
	_scan_popup_for_custom_items(popup_to_copy, popup_to_copy, custom_item_data)
	return custom_item_data


static func _scan_popup_for_custom_items(popup_to_copy:PopupMenu, top_popup:PopupMenu, custom_item_data:Dictionary, 
						custom_ancestor:bool=false, parent_data:Dictionary={}):
	#var popup_data = {}
	custom_item_data[popup_to_copy] = {}
	var custom_item_start_id = 2000
	var custom_item_end_id = 3000  ## can these be different?
	for i in range(popup_to_copy.item_count):
		var is_sep = popup_to_copy.is_item_separator(i)
		if is_sep:
			continue
		var id = popup_to_copy.get_item_id(i)
		var text = popup_to_copy.get_item_text(i)
		
		var custom_id = (id >= custom_item_start_id and id < custom_item_end_id)# or id >= 5000
		var is_custom = custom_id or custom_ancestor
		
		var path = text
		var submenu = popup_to_copy.get_item_submenu_node(i)
		if is_instance_valid(submenu):
			
			if custom_id: # don't want to ignore standard submenus
				var target_popup = popup_to_copy
				if custom_ancestor: # ALERT
					target_popup = top_popup
				custom_item_data[target_popup][path] = {}
				custom_item_data[target_popup][path]["submenu"] = true
			var icon = popup_to_copy.get_item_icon(i)
			var submenu_data = {
				"popup_path": path,
				ItemParams.ICON: [icon]
			}
			
			if custom_ancestor:
				var popup_path = parent_data.get("popup_path")
				if popup_path:
					path = popup_path.path_join(text)
					submenu_data["popup_path"] = path
				if ItemParams.ICON in parent_data:
					submenu_data[ItemParams.ICON] = parent_data[ItemParams.ICON].duplicate()
			
			#submenu_data[ItemParams.ICON].append(icon)
			
			_scan_popup_for_custom_items(submenu, top_popup, custom_item_data, is_custom, submenu_data)
		else:
			if is_custom:
				var target_popup = popup_to_copy
				if custom_ancestor:
					target_popup = top_popup
					var popup_path = parent_data.get("popup_path")
					if popup_path:
						path = popup_path.path_join(text)
				#else: # TESTING
					#var popup_path = parent_data.get("popup_path")
					#if popup_path:
						#path = popup_path.path_join(text)
					#print(path)
					#print(parent_data)
					##TESTING
				var signal_connections = popup_to_copy.get_signal_connection_list("id_pressed")
				if signal_connections.is_empty():
					print("--- POPUP HAS NO CONNECTIONS ---")
					print(text)
					print("---")
					continue
				var callable = signal_connections.get(0).get("callable") as Callable
				#var args = callable.get_bound_arguments()
				var icon = popup_to_copy.get_item_icon(i)
				var icons = []
				if ItemParams.ICON in parent_data:
					icons = parent_data.get(ItemParams.ICON).duplicate()
				icons.append(icon)
				
				var metadata = popup_to_copy.get_item_metadata(i)
				var user_metadata = {}
				if metadata != null:
					user_metadata = metadata
				
				custom_item_data[target_popup][path] = {
					"id": id,
					PopupHelper.ParamKeys.CALLABLE: callable,
					#"args": callable.get_bound_arguments(),
					PopupHelper.ParamKeys.ICON: icons,
					PopupHelper.ParamKeys.METADATA: user_metadata,
				}
	#custom_item_data[popup_to_copy] = popup_data


static func _add_custom_item(popup, item_path, item_data, popup_item_dict):
	var submenu = item_data.get("submenu", false)
	if submenu:
		return
	var id = item_data.get("id")
	var callable = item_data.get(ItemParams.CALLABLE) as Callable
	item_data[ItemParams.CALLABLE] = null
	if callable == null:
		return
	var parent = PopupHelper.add_single_item(popup, item_path, item_data, popup_item_dict)
	if id < 2000: # does this need to be changed to account for scene tags 3000
		if not parent.id_pressed.is_connected(callable):
			parent.id_pressed.connect(callable)

static func squash_icons(popup:PopupMenu, recursive=true):
	var popup_has_texture = false
	for i in range(popup.item_count):
		if popup.get_item_icon(i) != null:
			popup_has_texture = true
		
		var submenu = popup.get_item_submenu_node(i)
		if submenu and recursive:
			squash_icons(submenu)
	
	if popup_has_texture:
		for i in range(popup.item_count):
			if popup.get_item_icon(i) != null:
				continue
			popup.set_item_indent(i, -2)
			

static func popup_cleanup(popup:PopupMenu):
	if popup.is_item_separator(popup.item_count - 1):
		popup.remove_item(popup.item_count - 1)


static func create_context_plugin_items(plugin:EditorContextMenuPlugin, popup_args, menu_items:Dictionary, context_menu_callable):
	var fs_popup:PopupMenu
	if "SLOT" in plugin:
		if plugin.SLOT == EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE:
			fs_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCRIPT_EDITOR_CODE_POPUP)
		elif plugin.SLOT == EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR:
			fs_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCRIPT_EDITOR_POPUP)
		elif plugin.SLOT == EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM:
			fs_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_POPUP)
		elif plugin.SLOT == EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM_CREATE:
			fs_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_CREATE_POPUP)
		elif plugin.SLOT == EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TABS:
			fs_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCENE_TABS_POPUP)
		elif plugin.SLOT == EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE:
			fs_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCENE_TREE_POPUP)
		elif plugin.SLOT == EditorContextMenuPlugin.CONTEXT_SLOT_2D_EDITOR:
			fs_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.EDITOR_2D_POPUP)
	
	
	var meta_dict = {}
	var count = 0
	
	var multi_popup_groups = {}
	menu_items = menu_items.duplicate(true)
	
	
	for menu_path:String in menu_items:
		
		var slice_count = menu_path.get_slice_count("/")
		if slice_count > 1:
			var first_slice = menu_path.get_slice("/", 0)
			if not first_slice in multi_popup_groups:
				multi_popup_groups[first_slice] = {}
				
			multi_popup_groups[first_slice][menu_path] = menu_items.get(menu_path)
			continue
		
		var popup_data = menu_items.get(menu_path)
		var icon = popup_data.get(ItemParams.ICON)
		if icon is Array:
			icon = icon[icon.size() - 1]
		elif icon is String:
			icon = PopupHelper._get_icon(icon)
		
		var menu_name = menu_path.get_file()
		plugin.add_context_menu_item(menu_path, context_menu_callable.bind(menu_name), icon)
		
		var metadata = popup_data.get(ItemParams.METADATA)
		if metadata and fs_popup:
			meta_dict[fs_popup.item_count + count] = metadata
		count += 1
	
	var popup_items = {}
	for group in multi_popup_groups:
		var group_data = multi_popup_groups.get(group)
		var popup = PopupMenu.new()
		var _submenu_pressed = func(id, popup, se, callable): callable.call(se, PopupHelper.parse_menu_path(id, popup))
		popup.id_pressed.connect(_submenu_pressed.bind(popup, popup_args, context_menu_callable))
		popup_items[group] = popup
		var icon = null
		var first_item = false
		for menu_path in group_data.keys():
			var popup_data = menu_items.get(menu_path)
			if not first_item:
				first_item = true
				var icons = popup_data.get(ItemParams.ICON,[])
				if icons.size() == menu_path.get_slice_count("/"):
					icon = icons[0]
				if icon is String:
					icon = PopupHelper._get_icon(icon)
			popup_data[ItemParams.CALLABLE] = _submenu_pressed.bind(popup_args, context_menu_callable)
			PopupHelper.add_single_item(popup, menu_path, popup_data, popup_items)
		
		plugin.add_context_submenu_item(group, popup, icon)
	
	if fs_popup:
		var set_metadata = func(fs, dict): for i in dict: fs.set_item_metadata(i, dict.get(i))
		set_metadata.call_deferred(fs_popup, meta_dict)

static func set_fs_popup_metadata(fs_popup:PopupMenu, meta_data_dict): #TODO test on weaker machine, converted to anon above
	for index in meta_data_dict:
		var meta = meta_data_dict.get(index)
		fs_popup.set_item_metadata(index, meta)



static func _context_plugin_submenu_pressed(id, popup, popup_args, callable):
	var path = PopupHelper.parse_menu_path(id, popup)
	callable.call(popup_args, path)

static func _on_wrapper_pressed(id:int, wrapper_popup:PopupMenu, fs_popup:PopupMenu):
	if id >= 5000:
		return
	#print("POPUP WRAPPER PRESSED")
	fs_popup.id_pressed.emit(id)

static func sort_custom_context_items(all_custom_items:Dictionary):#, pre_dict, post_dict):
	var all_sorted_data = {}
	for popup in all_custom_items.keys():
		var sorted_data = {}
		sorted_data["pre"] = {}
		sorted_data["post"] = {}
		var pre_priority_dict = {}
		var post_priority_dict = {}
		var popup_data = all_custom_items.get(popup)
		for item_path in popup_data:
			var item_data = popup_data.get(item_path)
			var meta = item_data.get(ItemParams.METADATA)
			if meta is Dictionary:
				var priority = meta.get(ItemParams.PRIORITY, 1000)
				var position = meta.get(ItemParams.POSITION, ItemParams.Position.TOP)
				if position == ItemParams.Position.TOP:
					pre_priority_dict[item_path] = priority
				elif position == ItemParams.Position.BOTTOM:
					post_priority_dict[item_path] = priority
		
		var sorted_pre = USort.sort_priority_dict(pre_priority_dict)
		for key in sorted_pre.keys():
			sorted_data["pre"][key] = popup_data[key]
		
		var sorted_post = USort.sort_priority_dict(post_priority_dict)
		for key in sorted_post.keys():
			sorted_data["post"][key] = popup_data[key]
		
		all_sorted_data[popup] = sorted_data
	
	return all_sorted_data
