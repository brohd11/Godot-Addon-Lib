@tool
extends Tree

const FileSystemTree = preload("res://addons/addon_lib/brohd/alib_editor/file_system/tree/filesystem_tree.gd")

const UFile = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_file.gd")
const UTree = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_tree.gd")
const FSTreeHelper = preload("res://addons/addon_lib/brohd/alib_editor/file_system/tree/fs_tree_helper.gd")

const FSPopupHelper = preload("res://addons/addon_lib/brohd/alib_editor/file_system/tree/fs_popup_helper.gd")


const _FS_ID_NEED_RESCAN = []
const _FS_ID_NEED_HANDLE = [0, 21, 22, 10]


@export var filters:Array[LineEdit] = []

var root_item:TreeItem

var global_buses = []

var root_dir = "res://"
var file_array = []

var tree_first_build:bool = false
var multi_selected_flag:bool = false
var only_send_to_filter:bool


var _filter_debounce:=false
var filter_text_array:=[]
var sel_item_path:= ""

var filesystem_singleton:FileSystemSingleton

var tree_helper:FSTreeHelper

signal new_tab(dir_path)

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	allow_rmb_select = true
	allow_reselect = true
	select_mode = Tree.SELECT_MULTI
	hide_root = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	filesystem_singleton = FileSystemSingleton.get_instance()
	filesystem_singleton.filesystem_changed.connect(_on_scan_files_complete, 1)
	_new_tree_helper()
	
	for lineedit:LineEdit in filters:
		lineedit.right_icon = EditorInterface.get_base_control().get_theme_icon("Search", "EditorIcons")
		lineedit.placeholder_text = "Filter Files"
		lineedit.text_changed.connect(filter_text_changed)
	
	#await get_tree().process_frame
	
	item_edited.connect(_on_item_edited)
	visibility_changed.connect(_on_visibilty_changed)

func set_dir(target_dir:String):
	root_dir = target_dir
	_get_file_array(target_dir)

func _new_tree_helper():
	tree_helper = FSTreeHelper.new(self)
	tree_helper.filesystem_singleton = filesystem_singleton
	tree_helper.popup_on_right_click = false
	tree_helper.mouse_double_clicked.connect(_on_tree_helper_mouse_double_clicked)
	tree_helper.multi_item_selected.connect(_on_tree_helper_multi_item_selected)
	tree_helper.mouse_left_clicked.connect(_on_tree_helper_mouse_left_clicked)
	tree_helper.mouse_right_clicked.connect(_on_tree_helper_mouse_right_clicked)


func _on_scan_files_complete():
	print("BUIL")
	full_build()

func clear_items():
	clear()
	tree_helper.clear_items_keep_paths()

func full_build():
	_get_file_array(root_dir)
	await get_tree().process_frame
	_build_tree()

func quick_build():
	_build_tree()
	_scroll_to_selected_and_emit()


func _get_file_array(dir):
	if dir == "res://":
		file_array = filesystem_singleton.file_paths
	else:
		file_array = filesystem_singleton.get_files_in_dir(dir)

func _build_tree():
	if not is_visible_in_tree():
		print("NOT VISIBLE IN TREE, NOT BUILDING ", root_dir)
		return
	
	if not is_instance_valid(tree_helper):
		_new_tree_helper()
	if not is_instance_valid(tree_helper.filesystem_singleton):
		tree_helper.filesystem_singleton = filesystem_singleton
	
	var selected_paths = tree_helper.selected_item_paths.duplicate()
	var hide_files = false# HelperInst.ABConfig.hide_tree_files
	
	var folder_icon = filesystem_singleton.get_folder_icon()
	var folder_color = filesystem_singleton.get_folder_color()
	
	var target_dir = root_dir
	
	
	tree_helper.clear_items()
	tree_helper.show_item_preview = false# HelperInst.ABConfig.toggle_tree_previews
	tree_helper.updating = true
	
	var tree_root = create_item()
	if target_dir == "res://": # handle favorites
		var favorites_item = create_item(tree_root)
		favorites_item.set_text(0, filesystem_singleton.get_favorites_text())
		favorites_item.set_icon(0, filesystem_singleton.get_favorites_icon())
		var favorites = filesystem_singleton.get_filesystem_favorites()
		for path in favorites:
			var item = create_item(favorites_item)
			var text = path.get_file()
			if path.ends_with("/"):
				text = path.trim_suffix("/").get_file()
			item.set_text(0, text)
			tree_helper.set_tree_item_params(path, item)
			tree_helper.item_dict[text] = item
	
	
	root_item = create_item(tree_root) as TreeItem
	tree_helper.parent_item = root_item
	tree_helper.item_dict[target_dir] = root_item
	
	if not DirAccess.dir_exists_absolute(target_dir):
		root_item.set_text(0, "Doesn't Exist: " + target_dir)
		return
	
	if target_dir == "res://": # handle favorites
		root_item.set_text(0, "res://")
	else:
		var target_dir_folder_name = target_dir.trim_suffix("/").get_file()
		root_item.set_text(0, target_dir_folder_name)
	
	tree_helper.set_tree_item_params(target_dir, root_item)
	
	
	#var file_dict = ab_lib.ABTree.res_file_dict
	#var icon_dict = ab_lib.ABTree.editor_icon_dict
	#var res_prev_dict = ab_lib.ABTree.resource_preview_dict
	#var large_res_prev_dict = ab_lib.ABTree.resource_preview_large_dict
	
	for file_path:String in file_array:
		var file_data = filesystem_singleton.get_file_data(file_path)
		if not file_data:
			continue
		
		var last_item:TreeItem = tree_helper.new_file_path(file_path, target_dir, file_data)
		last_item.set_metadata(0, file_data)
		var file_type = file_data.get("file_type")
		if file_type != "Folder":
			if hide_files:
				last_item.visible = false
				continue
			var fs_item = filesystem_singleton.file_system_dock_item_dict.get(file_path)
			if fs_item:
				var tool_tip = fs_item.get_tooltip_text(0)
				last_item.set_tooltip_text(0, tool_tip)
			else:
				last_item.set_tooltip_text(0, file_path.get_file())
	
	if not tree_first_build:
		tree_first_build = true
	
	tree_helper.updating = false
	_select_selected_paths(selected_paths)
	
	if _is_filtering():
		_update_tree_items()
	


func _select_selected_paths(selected_paths):
	for path in selected_paths:
		var item = tree_helper.item_dict.get(path) as TreeItem
		if item:
			item.select(0)
			tree_helper.selected_items.append(item)
			tree_helper.selected_item_paths.append(path)
	

func _scroll_to_selected_and_emit():
	if tree_helper.selected_item_paths.is_empty():
		_emit_item_selected([])
	else:
		var sel_item = tree_helper.item_dict.get(tree_helper.selected_item_paths[0])
		if sel_item:
			set_selected(sel_item,0)
			scroll_to_item(sel_item)


func _update_tree_items():
	var filter_callable = _check_filter
	#if HelperInst.ABConfig.file_tree_search_split: # can set this, maybe figure out fuzzy search?
		#filter_callable = _check_filter_split
	var is_filtering = _is_filtering()
	tree_helper.update_tree_items(is_filtering, filter_callable, root_dir)
	tree_helper.uncollapse_items()
	_scroll_to_selected_and_emit()


func _is_filtering():
	for string in filter_text_array:
		if string != "":
			return true
	return false

func _check_filter(text:String):
	for string in filter_text_array:
		if not UTree.check_filter(text, string):
			return false
	return true

func _check_filter_split(text:String):
	for string in filter_text_array:
		if not UTree.check_filter_split(text, string):
			return false
	return true

func filter_text_changed(new_text):
	filter_text_array.clear()
	for lineedit in filters:
		filter_text_array.append(lineedit.text)
	
	#if _filter_debounce: #^ not sure I really need this
		#return
	#_filter_debounce = true
	#await get_tree().create_timer(0.3).timeout
	#_filter_debounce = false
	
	_update_tree_items()
	
	if tree_helper.selected_item_paths.size() > 0:
		sel_item_path = tree_helper.selected_item_paths[0]


func _emit_item_selected(item_data_array):
	return


func _on_tree_helper_multi_item_selected():
	await get_tree().process_frame
	#select_selected_in_fs() # not necessary for right click emulation
	var item_data_array = get_click_data()
	_emit_item_selected(item_data_array)


func _on_tree_helper_mouse_left_clicked():
	pass


func _on_tree_helper_mouse_double_clicked():
	var selected = get_selected()
	var meta = selected.get_metadata(0)
	var path = meta.get(FSTreeHelper.Keys.METADATA_PATH)
	if path.ends_with("/"):
		tree_helper.uncollapse_items()
		var item = tree_helper.get_tree_item(path)
		if item:
			item.collapsed = false
			tree_helper.show_tree_item(item)
	else:
		var selected_in_fs = select_selected_in_fs()
		if not selected_in_fs:
			return
		filesystem_singleton.activate_in_fs()


func _on_tree_helper_mouse_right_clicked():
	await get_tree().process_frame
	
	var items_selected = select_selected_in_fs()
	if not items_selected:
		return
	
	filesystem_singleton.populate_filesystem_popup(self)
	
	var selected_item = get_selected()
	var data = selected_item.get_metadata(0)
	if not data:
		return
	
	var items = {
		"pre":{},
		"post":{}
		}
	
	var path = tree_helper.get_path_from_item(selected_item)
	if path.ends_with("/") and not tree_helper.is_item_in_favorites(selected_item):
		items["pre"]["Create New Tab"] = {
				PopupWrapper.ItemParams.ICON_KEY:["New"]
			}
	
	var window = get_window()
	var popup = PopupMenu.new()
	window.add_child(popup)
	popup.popup_hide.connect(_on_popup_hide.bind(popup))
	FSPopupHelper.recreate_popup(popup, _on_wrapper_clicked, [], items)
	popup.position = DisplayServer.mouse_get_position()
	popup.popup()


func _on_wrapper_clicked(id:int, popup:PopupMenu, fs_popup:PopupMenu):
	print(id)
	var is_folder_popup = fs_popup.get_item_text(0) == "Default (Reset)"
	var is_create_popup = fs_popup == EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_CREATE_POPUP)
	if is_folder_popup:
		fs_popup.id_pressed.emit(id)
		filesystem_singleton.rebuild_files()
		return
	elif is_create_popup:
		pass
	else:
		if id in _FS_ID_NEED_HANDLE:
			if id == 0: # Expand Folder
				_rc_expand_folder()
			if id == 21: # Expand Hierarchy
				_rc_hierarchy(true)
			elif id == 22: # Collapse Hierarchy
				_rc_hierarchy(false)
			elif id == 10:
				start_edit()
			return
	
	if id < 5000:
		if fs_popup == EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.FILESYSTEM_BOTTOM_POPUP):
			fs_popup = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.FILESYSTEM_POPUP)
		fs_popup.id_pressed.emit(id)
	else:
		if id == 5000:
			_rc_new_tab()
	
	if id in _FS_ID_NEED_RESCAN:
		filesystem_singleton.rebuild_files()


func _on_popup_hide(popup:PopupMenu):
	popup.queue_free()

func _rc_expand_folder():
	var items = tree_helper.get_selected_tree_items()
	for item in items:
		item.collapsed = false

func _rc_hierarchy(expand:bool):
	var selected = get_selected()
	selected.set_collapsed_recursive(not expand)

func _rc_new_tab():
	var selected = get_selected()
	var path = tree_helper.get_path_from_item(selected)
	if path and path.ends_with("/"):
		new_tab.emit(path)


func _on_visibilty_changed():
	if not is_instance_valid(owner):
		return
	if not owner.visible:
		prints("CLEARING TREE ", root_dir)
		tree_helper.tree_node.clear()
		tree_helper.selected_items.clear()
		tree_helper.item_dict.clear()
		clear()
		return
	
	prints("ACTIVE ", root_dir)
	if tree_helper.item_dict.is_empty():
		_build_tree()
	var item_data_array = get_click_data()
	_emit_item_selected(item_data_array)




#region works but too jank

var original_file_name = ""
func start_edit():
	var item = get_selected()
	original_file_name = item.get_text(0)
	edit_selected(true)
	
	var line_edit = get_child(1, true).get_child(0, true).get_child(0, true) as LineEdit
	var ext_idx = line_edit.text.find(".")
	if ext_idx > -1:
		line_edit.select(0, ext_idx)


func _on_item_edited():
	var item = get_edited()
	var new_name = item.get_text(0)
	var exit = false
	if new_name == "":
		exit = true
	if new_name == original_file_name:
		exit = true
	
	
	if exit:
		item.set_text(0, original_file_name)
		original_file_name = ""
		return
	
	var root = Engine.get_main_loop().root
	var line = ALibEditor.Nodes.FileSystem.get_tree_line_edit() as LineEdit
	var line_editor_submit = ALibRuntime.Utils.UNode.get_signal_callable(line, "text_submitted", "Tree::_line_editor_submit")
	
	var edfs_dock = EditorInterface.get_file_system_dock()
	
	edfs_dock.show()
	await get_tree().process_frame
	#await get_tree().process_frame
	
	var popup = ALibEditor.Nodes.FileSystem.get_popup() as PopupMenu
	popup.id_pressed.emit(10)
	line_editor_submit.call(new_name)
	
	edfs_dock.hide()
	return
	
	
	#var edfs_dock = EditorInterface.get_file_system_dock()
	var edfs_container = edfs_dock.get_parent()
	var current_tab_index = 0
	var set_edfs_vis = false
	if not edfs_dock.visible:
		set_edfs_vis = true
		if edfs_container is TabContainer:
			current_tab_index = edfs_container.current_tab
		else:
			edfs_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
			edfs_dock.clip_contents = true
		edfs_dock.show()
		#await get_tree().process_frame
	
	await get_tree().process_frame
	#var popup = ALibEditor.Nodes.FileSystem.get_popup() as PopupMenu
	popup.id_pressed.emit(10)
	line.text = item.get_text(0)
	line.text_submitted.emit(line.text)
	
	get_window().grab_focus()
	original_file_name = ""
	
	while EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().process_frame
	
	
	if set_edfs_vis:
		if edfs_container is TabContainer:
			edfs_container.current_tab = current_tab_index
		else:
			edfs_dock.hide()
			edfs_dock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			edfs_dock.clip_contents = false


#endregion


func get_click_data():
	var data = UTree.get_click_data_standard(tree_helper.selected_items)
	return data


func _get_drag_data(at_position):
	if tree_helper.is_favorited_item_selected():
		get_window().gui_cancel_drag()
		return
	return UTree.get_drop_data.files(tree_helper.selected_item_paths, self)

func _can_drop_data(at_position, data):
	return UTree.can_drop_data.files(at_position, data)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var files = []
	if data.has("files"):
		files = data.get("files")
	elif data.has("file_and_dirs"):
		files = data.get("file_and_dirs")
	
	var from = data.get("from")
	var target_item = get_item_at_position(at_position)
	var meta = target_item.get_metadata(0)
	var target_dir = ""
	if meta is String:
		target_dir = meta
	if meta is Dictionary:
		target_dir = tree_helper.get_path_from_item(target_item)
	if not target_dir.ends_with("/"):
		target_dir = target_dir.get_base_dir()
		if not target_dir.ends_with("/"):
			target_dir += "/"
	
	for file:String in files:
		if file == target_dir:
			return
		if UFile.is_file_in_directory(target_dir, file):
			return
		var file_dir = file
		file_dir = file_dir.trim_suffix("/")
		file_dir = file_dir.get_base_dir()
		if not file_dir.ends_with("/"):
			file_dir += "/"
		if file_dir == target_dir:
			return
	
	get_window().gui_cancel_drag()
	filesystem_singleton.move_dialogs(self)
	
	if from is FileSystemTree:
		var selected = from.select_selected_in_fs(from.tree_helper.selected_item_paths)
		if not selected:
			return
	else:
		var selected = filesystem_singleton.select_items_in_fs(tree_helper.selected_item_paths)
		if not selected:
			print("Could not select the items in FileSystem")
			return
	
	get_window().gui_cancel_drag()
	filesystem_singleton.move_dialogs(self)
	filesystem_singleton.show_file_move_dialog(target_dir)


func select_selected_in_fs(path_array:Array=tree_helper.selected_item_paths):
	var selected_in_fs = filesystem_singleton.select_items_in_fs(path_array)
	if not selected_in_fs:
		filesystem_singleton.rebuild_files()
		selected_in_fs = filesystem_singleton.select_items_in_fs(path_array)
		if not selected_in_fs:
			print("Could not select the items in FileSystem")
		return selected_in_fs
	else:
		return true
