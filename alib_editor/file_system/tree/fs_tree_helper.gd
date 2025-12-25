extends "res://addons/addon_lib/brohd/alib_runtime/tree_helper/tree_helper_base.gd"

var filesystem_singleton:FileSystemSingleton

func _set_folder_icon_img():
	folder_icon = EditorInterface.get_base_control().get_theme_icon("Folder", &"EditorIcons")
	folder_color = EditorInterface.get_base_control().get_theme_color("folder_icon_color", "FileDialog")

func _set_folder_icon(file_path, slice_item):
	var icon = filesystem_singleton.get_icon(file_path)
	slice_item.set_icon(0, icon)
	var color = filesystem_singleton.get_folder_color(file_path)
	if color:
		slice_item.set_icon_modulate(0, color)
	var bg_color = filesystem_singleton.get_background_color(file_path)
	if bg_color:
		slice_item.set_custom_bg_color(0, bg_color)

func _set_item_icon(last_item, file_data):
	item_set_file_type_icon(last_item, file_data, null, show_item_preview)

func _mouse_left_clicked():
	mouse_left_clicked.emit()

func _mouse_right_clicked(data):
	mouse_right_clicked.emit()
	if popup_on_right_click:
		print("RIGHT CLICK IN TREE HELPER - IS THIS USED")
		#ab_lib.ABRightClick.move_and_show(tree_node, data)

func _mouse_double_clicked():
	mouse_double_clicked.emit()
	#if edit_on_double_click:
		#ab_lib.ABTree.Static.activate_in_fs()





func item_set_file_type_icon(item:TreeItem, file_data:Dictionary, file_path=null, show_preview=true):
	if not file_path:
		file_path = file_data.get(Keys.METADATA_PATH)
	var file_icon:Texture2D
	if file_data.get("custom_icon") == true and show_preview:
		pass
		#file_icon = ab_lib.ABTree.resource_preview_dict.get(file_path)
		#if not file_icon:
			#file_icon = ab_lib.ABTree.resource_preview_large_dict.get(file_path)
			#item.set_icon_max_width(0,16)
	else:
		var fs_tree_item = filesystem_singleton.file_system_dock_item_dict.get(file_path)
		if fs_tree_item:
			#var file_type:String = file_data.get(keys.tree.file_type)
			file_icon = fs_tree_item.get_icon(0)
		else:
			file_icon = filesystem_singleton.get_icon(file_path)
	
	var file_color:Color = file_data.get("color", Color.WHITE)
	item.set_icon(0, file_icon)
	if file_path.get_extension() != "":
		item.set_icon_modulate(0, file_color)


func update_tree_items(filtering, filter_callable, root_dir="res://"):
	if not filtering:
		for path in item_dict.keys():
			var runtime_data = data_dict.get(path)
			if not runtime_data:
				continue
			var item = item_dict.get(path) as TreeItem
			if not is_instance_valid(item):
				continue
			item.visible = true
			item.collapsed = runtime_data.get(Keys.METADATA_COLLAPSED)
		
		var root_item = tree_node.get_root()
		if tree_node.hide_root:
			var root_children = root_item.get_children()
			for c in root_children:
				c.visible = true
		
		var favorites_item = get_favorites_item()
		if is_instance_valid(favorites_item):
			var favorites = favorites_item.get_children()
			for f in favorites:
				f.visible = true
		
		return false
	updating = true
	
	var vis_files = []
	for path:String in item_dict.keys():
		var item = item_dict.get(path) as TreeItem
		if not item:
			continue
		if path.get_extension() == "":
			if DirAccess.dir_exists_absolute(path):
				item.visible = false
				continue
		if not filter_callable.call(path):
			item.visible = false
			
			continue
		vis_files.append(path)
	
	for path:String in vis_files:
		var is_dir = path.ends_with("/")
		var path_tail = path.get_slice(root_dir,1)
		var work_path = root_dir
		var slice_count = path_tail.get_slice_count("/")
		for i in range(slice_count):
			var slice = path_tail.get_slice("/", i)
			work_path = work_path.path_join(slice)
			var check_path = work_path
			if i != slice_count - 1:
				if not check_path.ends_with("/"):
					check_path = check_path + "/"
			var item = item_dict.get(check_path)
			if not item:
				continue
			
			item.visible = true
	
	var favorites_item = get_favorites_item()
	if is_instance_valid(favorites_item):
		var favorites = favorites_item.get_children()
		for f in favorites:
			var text = f.get_text(0)
			if not filter_callable.call(text):
				f.visible = false
			else:
				f.visible = true
	
	
	var root_item = tree_node.get_root()
	if not tree_node.hide_root:
		root_item.visible = true
		root_item.set_collapsed_recursive(false)
	else:
		var root_children = root_item.get_children()
		for c in root_children:
			c.visible = true
			c.set_collapsed_recursive(false)
	
	updating = false
	return true


func get_favorites_item():
	var root_children = tree_node.get_root().get_children()
	for c in root_children:
		if c.get_text(0) == filesystem_singleton.get_favorites_text():
			return c

func is_favorited_item_selected():
	for item in selected_items:
		var par = item.get_parent()
		if par and par.get_text(0) == filesystem_singleton.get_favorites_text():
			return true
	return false

func is_item_in_favorites(item:TreeItem):
	var par = item.get_parent()
	if par:
		if par.get_text(0) == filesystem_singleton.get_favorites_text():
			return true
	return false

func set_tree_item_params(path:String, item:TreeItem):
	var meta = {
		Keys.METADATA_PATH: path
	}
	item.set_metadata(0, meta)
	item.set_icon(0, filesystem_singleton.get_icon(path))
	var color = filesystem_singleton.get_icon_color(path)
	if color:
		item.set_icon_modulate(0, color)
	#var bg_color = filesystem_singleton.get_background_color(path)
	#if bg_color:
		#item.set_custom_bg_color(0, bg_color)
