@tool
class_name FileSystemSingleton
extends Singleton.RefCount

const CacheHelper = preload("res://addons/addon_lib/brohd/alib_runtime/cache_helper/cache_helper.gd")

const PE_STRIP_CAST_SCRIPT = preload("res://addons/addon_lib/brohd/alib_editor/file_system/filesystem_singleton.gd")


static func get_singleton_name() -> String:
	return "FileSystemSingleton"

static func get_instance() -> FileSystemSingleton:
	return _get_instance(PE_STRIP_CAST_SCRIPT)

static func instance_valid() -> bool:
	return _instance_valid(PE_STRIP_CAST_SCRIPT)

static func register_node(node:Node):
	return _register_node(PE_STRIP_CAST_SCRIPT, node)

static func call_on_ready(callable, print_err:bool=true):
	_call_on_ready(PE_STRIP_CAST_SCRIPT, callable, print_err)

static var editor_fs:EditorFileSystem

var editor_node_ref:EditorNodeRef

var _data_cache:= {}

var file_system_dock_favorites_dict:Dictionary = {}
var file_system_dock_item_dict:Dictionary = {}

var file_paths:= PackedStringArray()
var file_and_dir_paths:= PackedStringArray()

var file_paths_dict:= {}
var file_and_dir_paths_dict:={}

var _file_types:= {}
var file_data:= {}

var editor_base_control:Control

signal filesystem_changed

func _init(node):
	pass

func _ready() -> void:
	editor_node_ref = EditorNodeRef.get_instance()
	editor_fs = EditorInterface.get_resource_filesystem()
	editor_fs.filesystem_changed.connect(_on_filesystem_changed)

func _set_interface_refs():
	
	editor_fs = EditorInterface.get_resource_filesystem()
	editor_base_control = EditorInterface.get_base_control()

func _fs_dock_in_bottom_panel() -> bool:
	var fs_dock = EditorInterface.get_file_system_dock()
	var dock_par = fs_dock.get_parent()
	return dock_par.get_class() == "EditorBottomPanel"
	
func rebuild_files():
	_on_filesystem_changed()

func _on_filesystem_changed():
	_set_interface_refs()
	
	file_paths.clear()
	file_and_dir_paths.clear()
	#file_data.clear()
	#_fs_scan_for_files("res://")
	ALibRuntime.Utils.UProfile.TimeFunction.time_func(_file_scan, "FS SCAN")
	
	file_paths = PackedStringArray(file_paths_dict.keys())
	file_and_dir_paths = PackedStringArray(file_and_dir_paths_dict.keys())
	
	var t = ALibRuntime.Utils.UProfile.TimeFunction.new("ON FS")
	filesystem_changed.emit() # own signal
	t.stop()



func _file_scan():
	if _fs_dock_in_bottom_panel():
		_singleton_scan_for_files()
	else:
		_singleton_scan_tree_for_paths()



func _singleton_scan_for_files():
	_singleton_recursive_scan_for_files("res://")

func _singleton_recursive_scan_for_files(dir:String) -> void:
	file_and_dir_paths_dict[dir] = true
	
	var fs_dir:EditorFileSystemDirectory = editor_fs.get_filesystem_path(dir)
	for i in fs_dir.get_subdir_count():
		var sub_dir = fs_dir.get_subdir(i)
		var path = sub_dir.get_path()
		_singleton_recursive_scan_for_files(path)
	
	for i in fs_dir.get_file_count():
		var path = fs_dir.get_file_path(i)
		#get_file_data(path)
		file_paths_dict[path] = true
		file_and_dir_paths_dict[path] = true


func _singleton_scan_tree_for_paths():
	var fs_tree: Tree = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_TREE)
	if not fs_tree:
		printerr("FileSystemDock Tree not found.")
		return
	var root: TreeItem = fs_tree.get_root()
	if not root:
		printerr("FileSystemDock Tree has no root item.")
		return
	
	for child:TreeItem in root.get_children():
		if child.get_text(0) == "Favorites:":
			for item in child.get_children():
				var path = item.get_metadata(0)
				file_system_dock_favorites_dict[path] = item
		elif child.get_text(0) == "res://":
			_singleton_recursive_scan_tree_for_paths(child)

func _singleton_recursive_scan_tree_for_paths(item: TreeItem):
	if item == null:
		return
	var file_path = item.get_metadata(0)
	if file_path == null:
		print("NO TREE META", item.get_text(0))
		return
	file_system_dock_item_dict[file_path] = item
	if file_path.ends_with("/"):
		file_and_dir_paths_dict[file_path] = true
	file_paths_dict[file_path] = true
	
	var child: TreeItem = item.get_first_child()
	while child != null:
		_singleton_recursive_scan_tree_for_paths(child)
		child = child.get_next() # Move to the next sibling

static func recursive_scan_tree_for_paths(item: TreeItem, include_dirs:bool=false) -> PackedStringArray:
	var path_array:= PackedStringArray()
	if item == null:
		return path_array
	var file_path = item.get_metadata(0)
	if file_path.ends_with("/"):
		if include_dirs:
			path_array.append(file_path)
	else:
		path_array.append(file_path)
	
	var child: TreeItem = item.get_first_child()
	while child != null:
		path_array.append_array(recursive_scan_tree_for_paths(child))
		child = child.get_next() # Move to the next sibling
	
	return path_array

static func recursive_scan_for_file_paths(dir:String, include_dirs:bool=false) -> PackedStringArray:
	var files = PackedStringArray()
	if include_dirs:
		files.append(dir)
	
	var fs_dir:EditorFileSystemDirectory = editor_fs.get_filesystem_path(dir)
	for i in fs_dir.get_subdir_count():
		var sub_dir = fs_dir.get_subdir(i)
		files.append_array(recursive_scan_for_file_paths(sub_dir.get_path()))
	
	for i in fs_dir.get_file_count():
		files.append(fs_dir.get_file_path(i))
	return files

func get_file_data(path:String):
	var cached = CacheHelper.get_cached_data(path, file_data)
	if cached:
		return cached
	#if file_data.has(path):
		#return file_data[path]
	var file_type = _get_file_type(path)
	var icon = editor_base_control.get_theme_icon(file_type, &"EditorIcons")
	if file_type == "":
		file_type = "Folder"
	
	var _file_data = {
		"item_path": path,
		"file_icon": icon,
		"file_type": file_type,
		"file_custom_icon": false,
	}
	#file_data[path] = _file_data
	CacheHelper.store_data(path, _file_data, file_data, [path])
	return _file_data

func _get_file_type(path:String):
	var cached = CacheHelper.get_cached_data(path, _file_types)
	if cached != null:
		return cached
	#if _file_types.has(path):
		#return _file_types[path]
	var file_type = editor_fs.get_file_type(path)
	#_file_types[path] = file_type
	CacheHelper.store_data(path, file_type, _file_types, [path])
	return file_type

func get_icon(file_path:String):
	if file_system_dock_item_dict.has(file_path):
		var item = file_system_dock_item_dict.get(file_path) as TreeItem
		return item.get_icon(0)
	var file_type = _get_file_type(file_path)
	return editor_base_control.get_theme_icon(file_type, &"EditorIcons")

func get_icon_color(file_path:String):
	if file_system_dock_item_dict.has(file_path):
		var item = file_system_dock_item_dict.get(file_path) as TreeItem
		return item.get_icon_modulate(0)
	if file_path.ends_with("/"):
		return get_folder_color(file_path)
	#var file_type = _get_file_type(file_path)
	#return editor_base_control.get_theme_icon(file_type, &"EditorIcons")
	return Color.WHITE

func get_folder_color(file_path:String):
	var color = ""
	var folder_colors = get_filesystem_folder_colors()
	var working_path = file_path
	while working_path != "res://" or working_path.count("/") > 0:
		var check_path = working_path
		if not check_path.ends_with("/"):
			check_path = check_path + "/"
		if folder_colors.has(check_path):
			color = folder_colors.get(check_path)
			break
		working_path = working_path.get_base_dir()
	match color:
		"red":return Color(1.0, 0.271, 0.271)
		"orange":return Color(1.0, 0.561, 0.271)
		"yellow":return Color(1.0, 0.890, 0.271)
		"green":return Color(0.502, 1.0, 0.271)
		"teal":return Color(0.271, 1.0, 0.635)
		"blue":return Color(0.271, 0.843, 1.0)
		"purple":return Color(0.502, 0.271, 1.0)
		"pink":return Color(1.0, 0.271, 0.588)
		"gray":return Color(0.616, 0.616, 0.616)
	
	return Color.WHITE



func get_files_in_dir(dir:String, include_dirs:bool=false):
	var first_item = file_system_dock_item_dict.get(dir)
	if _fs_dock_in_bottom_panel() or first_item == null:
		return recursive_scan_for_file_paths(dir, include_dirs)
	else:
		return recursive_scan_tree_for_paths(first_item)



static func get_filesystem_folder_colors():
	var data_cache:Dictionary
	if FileSystemSingleton.instance_valid():
		data_cache = FileSystemSingleton.get_instance()._data_cache
		var cached = CacheHelper.get_cached_data(Keys.FOLDER_COLORS, data_cache)
		if cached != null:
			return cached
	
	var config = ConfigFile.new()
	var err = config.load(FilePaths.PROJECT)
	if err != OK:
		printerr("Could not get project file: Error %s" % err)
		return
	var folder_colors = config.get_value("file_customization", "folder_colors", {})
	if FileSystemSingleton.instance_valid():
		CacheHelper.store_data(Keys.FOLDER_COLORS, folder_colors, data_cache, [FilePaths.PROJECT])
	return folder_colors

static func get_filesystem_favorites():
	var data_cache:Dictionary
	if FileSystemSingleton.instance_valid():
		data_cache = FileSystemSingleton.get_instance()._data_cache
		var cached = CacheHelper.get_cached_data(Keys.FAVORITES, data_cache)
		if cached != null:
			return cached
	
	if FileAccess.file_exists(FilePaths.FAVORITES):
		var file_as_string = FileAccess.get_file_as_string(FilePaths.FAVORITES)
		var favorites_array = file_as_string.split("\n", false)
		if FileSystemSingleton.instance_valid():
			CacheHelper.store_data(Keys.FAVORITES, favorites_array, data_cache, [FilePaths.FAVORITES])
		return favorites_array
	else:
		printerr("Could not get favorites file.")
		return []

func get_folder_icon():
	return EditorInterface.get_base_control().get_theme_icon("Folder", &"EditorIcons")

func get_folder_default_color():
	return EditorInterface.get_base_control().get_theme_color("folder_icon_color", "FileDialog")



func activate_in_fs():
	var fs_tree = get_filesystem_tree() as Tree
	fs_tree.item_activated.emit()

func select_items_in_fs(selected_item_paths:Array, navigate=false):
	var sel_paths_reversed = selected_item_paths.duplicate()
	var fs_tree = get_filesystem_tree()
	sel_paths_reversed.reverse()
	if sel_paths_reversed.size() > 0:
		#var fs_tree = ALibEditor.Nodes.FileSystem.get_tree() as Tree
		var fs_item = fs_tree.get_selected()
		fs_tree.multi_selected.emit(fs_item, 0, true)
	if navigate and sel_paths_reversed.size() > 0:
		EditorInterface.get_file_system_dock().navigate_to_path(sel_paths_reversed[0])
	
	#var tree = ALibEditor.Nodes.FileSystem.get_tree() as Tree
	fs_tree.deselect_all()
	var items = []
	
	for path:String in sel_paths_reversed:
		#if path.get_extension() == "" and not path.ends_with("/"):
			#path = path + "/"
		var fs_item = file_system_dock_item_dict.get(path)
		if is_instance_valid(fs_item):
			items.append(fs_item)
			fs_item.select(0)
	
	if fs_tree.visible:
		fs_tree.queue_redraw()

static func populate_filesystem_popup(calling_node:Node):
	ALibEditor.Nodes.FileSystem.populate_popup(calling_node)

static func get_filesystem_tree() -> Tree:
	return ALibEditor.Nodes.FileSystem.get_tree()

func _all_unregistered_callback():
	pass



class FilePaths:
	const PROJECT = "res://project.godot"
	const FAVORITES = "res://.godot/editor/favorites"

class Keys:
	const FOLDER_COLORS = &"FolderColors"
	const FAVORITES = &"FileSystemFavorites"
