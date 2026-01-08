@tool
extends Tree

#! import-p FileData,

const FileSystemTree = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_tree.gd")

const UFile = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_file.gd")
const UTree = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_tree.gd")
const FSTreeHelper = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/fs_tree_helper.gd")

const FSPopupHelper = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/fs_popup_helper.gd")

const FileData = FileSystemSingleton.FileData

const FAVORITES_META = "FAVORITES"

const _FS_ID_NEED_RESCAN = [4, 5]
const _FS_ID_NEED_HANDLE = [0, 21, 22, 10]


@export var filters:Array[LineEdit] = []

var root_item:TreeItem

var global_buses = []

var root_dir = "res://"
var file_array = []

var tree_first_build:bool = false
var multi_selected_flag:bool = false
var only_send_to_filter:bool

var show_files:bool = false
var show_item_preview:bool = false


var _filter_debounce:=false
var filter_text_array:=[]
var sel_item_path:= ""

var filesystem_singleton:FileSystemSingleton

var tree_helper:FSTreeHelper

signal right_clicked(self_node, selected_path:String, path_array:Array)
signal double_clicked(selected_path:String)


signal tree_item_selected(selected_paths)

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	allow_rmb_select = true
	allow_reselect = true
	select_mode = Tree.SELECT_MULTI
	hide_root = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	filesystem_singleton = FileSystemSingleton.get_instance()
	
	_new_tree_helper()
	
	for lineedit:LineEdit in filters:
		lineedit.right_icon = EditorInterface.get_base_control().get_theme_icon("Search", "EditorIcons")
		lineedit.placeholder_text = "Filter Files"
		lineedit.text_changed.connect(filter_text_changed)
	
	#await get_tree().process_frame
	
	item_edited.connect(_on_item_edited)

func set_dir(target_dir:String):
	root_dir = target_dir
	#_get_file_array(target_dir)

func _new_tree_helper():
	tree_helper = FSTreeHelper.new(self)
	tree_helper.filesystem_singleton = filesystem_singleton
	tree_helper.popup_on_right_click = false
	tree_helper.mouse_double_clicked.connect(_on_tree_helper_mouse_double_clicked)
	tree_helper.multi_item_selected.connect(_on_tree_helper_multi_item_selected)
	tree_helper.mouse_left_clicked.connect(_on_tree_helper_mouse_left_clicked)
	tree_helper.mouse_right_clicked.connect(_on_tree_helper_mouse_right_clicked)



func clear_items():
	clear()
	tree_helper.clear_items_keep_paths()

func set_active():
	if file_array.is_empty():
		await full_build()
	elif tree_helper.item_dict.is_empty():
		#await full_build()
		_build_tree()
	#full_build() # would like to use above, but issues on start up
	
	_emit_item_selected()

func set_inactive():
	tree_helper.tree_node.clear()
	tree_helper.selected_items.clear()
	tree_helper.item_dict.clear()
	clear()

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
		file_array = filesystem_singleton.get_files_in_dir(dir, true)

func _build_tree():
	if not is_instance_valid(tree_helper):
		_new_tree_helper()
	if not is_instance_valid(tree_helper.filesystem_singleton):
		tree_helper.filesystem_singleton = filesystem_singleton
	
	tree_helper.show_files = show_files
	
	var selected_paths = tree_helper.selected_item_paths.duplicate()
	
	var folder_icon = filesystem_singleton.get_folder_icon()
	var folder_color = filesystem_singleton.get_folder_color()
	
	var target_dir = root_dir
	
	tree_helper.clear_items()
	tree_helper.set_thumbnail_size()
	tree_helper.show_item_preview = show_item_preview# HelperInst.ABConfig.toggle_tree_previews
	tree_helper.updating = true
	
	var tree_root = create_item()
	if target_dir == "res://": # handle favorites
		var favorites_item = create_item(tree_root)
		favorites_item.set_text(0, filesystem_singleton.get_favorites_text())
		favorites_item.set_icon(0, filesystem_singleton.get_favorites_icon())
		favorites_item.set_metadata(0, {FileData.PATH: FAVORITES_META})
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
		var bg_color = filesystem_singleton.get_background_color(target_dir)
		if bg_color:
			root_item.set_custom_bg_color(0, bg_color)
	
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
		var file_type = file_data.get(FileData.TYPE)
		if file_type != FileData.FOLDER:
			if not show_files:
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

func select_paths(paths:Array):
	deselect_all()
	tree_helper.clear_selection()
	_select_selected_paths(paths)
	tree_helper.uncollapse_items()
	_emit_item_selected()
	

func _select_selected_paths(selected_paths):
	for path in selected_paths:
		var item = tree_helper.item_dict.get(path) as TreeItem
		if item:
			item.select(0)
			tree_helper.selected_items.append(item)
			tree_helper.selected_item_paths.append(path)

func get_selected_paths():
	return tree_helper.selected_item_paths

func _scroll_to_selected_and_emit():
	var selected_paths = get_selected_paths()
	if not selected_paths.is_empty():
		var sel_item = tree_helper.item_dict.get(selected_paths[0])
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
	


func _emit_item_selected():
	var selected_paths = get_selected_paths()
	if selected_paths.is_empty():
		return
	var selected = get_selected()
	var path = tree_helper.get_path_from_item(selected)
	
	if tree_helper.is_item_in_favorites(selected) and not path.ends_with("/"):
		tree_item_selected.emit([FAVORITES_META])
	else:
		tree_item_selected.emit(selected_paths)


func _on_tree_helper_multi_item_selected():
	_emit_item_selected()

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
		double_clicked.emit(path)
		#var selected_in_fs = select_selected_in_fs()
		#if not selected_in_fs:
			#return
		#filesystem_singleton.activate_in_fs()


func _on_tree_helper_mouse_right_clicked():
	var selected_item = get_selected()
	var data = selected_item.get_metadata(0)
	if not data:
		return
	
	var path = tree_helper.get_path_from_item(selected_item)
	if path == FAVORITES_META:
		return
	
	right_clicked.emit(self, path, tree_helper.selected_item_paths)



func rc_expand_folder():
	var items = tree_helper.get_selected_tree_items()
	for item in items:
		item.collapsed = false

func rc_hierarchy(expand:bool):
	var selected = get_selected()
	selected.set_collapsed_recursive(not expand)



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
	
	if not filesystem_singleton.is_new_name_valid(original_file_name, new_name):
		item.set_text(0, original_file_name)
		original_file_name = ""
		return
	var old_path = tree_helper.get_path_from_item(item)
	var new_path = old_path
	filesystem_singleton.rename_path(old_path, new_name)


#endregion


func get_click_data(): # need to rethink this? instead of recursive, that could be done at target
	var data = UTree.get_click_data_standard(tree_helper.selected_items)
	return data


func _get_drag_data(at_position):
	return FileSystemSingleton.GetDropData.files(tree_helper.selected_item_paths, self)

func _can_drop_data(at_position, data):
	return FileSystemSingleton.CanDropData.files(at_position, data)

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
	
	get_window().gui_cancel_drag() #^r twice calling?
	filesystem_singleton.move_dialogs(self)
	
	#if from is FileSystemTree:
		#var selected = from.select_selected_in_fs(from.tree_helper.selected_item_paths)
		#if not selected:
			#return
	#else:
		#var selected = filesystem_singleton.select_items_in_fs(tree_helper.selected_item_paths)
		#if not selected:
			#print("Could not select the items in FileSystem")
			#return
	
	if from is FileSystemTree:
		var selected = filesystem_singleton.ensure_items_selected(from.tree_helper.selected_item_paths)
		if not selected:
			return
	else:
		var selected = filesystem_singleton.ensure_items_selected(tree_helper.selected_item_paths)
		if not selected:
			print("Could not select the items in FileSystem")
			return
	
	
	get_window().gui_cancel_drag()
	filesystem_singleton.move_dialogs(self)
	filesystem_singleton.show_file_move_dialog(target_dir)


#func select_selected_in_fs(path_array:Array=tree_helper.selected_item_paths):
	#var selected_in_fs = filesystem_singleton.select_items_in_fs(path_array)
	#if not selected_in_fs:
		#filesystem_singleton.rebuild_files()
		#selected_in_fs = filesystem_singleton.select_items_in_fs(path_array)
		#if not selected_in_fs:
			#print("Could not select the items in FileSystem")
		#return selected_in_fs
	#else:
		#return true
