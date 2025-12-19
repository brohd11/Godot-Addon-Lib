extends "res://addons/addon_lib/brohd/alib_runtime/tree_helper/tree_helper_base.gd"

var filesystem_singleton:FileSystemSingleton

func _set_folder_icon_img():
	folder_icon = EditorInterface.get_base_control().get_theme_icon("Folder", &"EditorIcons")
	folder_color = EditorInterface.get_base_control().get_theme_color("folder_icon_color", "FileDialog")

func _set_folder_icon(file_path, slice_item):
	var fs_folder_item = filesystem_singleton.file_system_dock_item_dict.get(file_path) as TreeItem
	if fs_folder_item:
		slice_item.set_icon(0, fs_folder_item.get_icon(0))
		var mod = fs_folder_item.get_icon_modulate(0)
		slice_item.set_icon_modulate(0, mod)
		var bg = fs_folder_item.get_custom_bg_color(0)
		if bg != Color.BLACK:
			slice_item.set_custom_bg_color(0, bg)
	else:
		slice_item.set_icon(0, folder_icon)
		slice_item.set_icon_modulate(0, folder_color)

func _set_item_icon(last_item, file_data):
	item_set_file_type_icon(last_item, file_data, null, show_item_preview)
	pass

func _mouse_left_clicked():
	mouse_left_clicked.emit()

func _mouse_right_clicked(data):
	print("YE")
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
			print("NO ICON ", file_path)
	
	var file_color:Color = file_data.get("color", Color.WHITE)
	item.set_icon(0, file_icon)
	if file_path.get_extension() != "":
		item.set_icon_modulate(0, file_color)
