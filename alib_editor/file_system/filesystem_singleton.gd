@tool
class_name FileSystemSingleton
extends Singleton.RefCount

const CacheHelper = preload("res://addons/addon_lib/brohd/alib_runtime/cache_helper/cache_helper.gd")
const UTree = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_tree.gd")


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

var cache:Cache

var file_system_dock_favorites_dict:Dictionary = {}
var file_system_dock_item_dict:Dictionary = {}

var file_paths:= PackedStringArray()
var file_and_dir_paths:= PackedStringArray()

var _file_paths_dict:= {}
var _file_and_dir_paths_dict:={}

var editor_base_control:Control

var _init_complete:=false

signal filesystem_changed

func _init(node):
	cache = Cache.new()

func _ready() -> void:
	editor_node_ref = EditorNodeRef.get_instance()
	EditorNodeRef.call_on_ready(_register_dialogs)
	editor_fs = EditorInterface.get_resource_filesystem()
	editor_fs.filesystem_changed.connect(_on_filesystem_changed)
	
	get_filesystem_favorites()
	#get_filesystem_folder_colors()
	#rebuild_files()
	_init_complete = true

func _get_ready_bool():
	return _init_complete

func _set_interface_refs():
	cache.set_folder_icon()
	editor_fs = EditorInterface.get_resource_filesystem()
	editor_base_control = EditorInterface.get_base_control()
	
	cache.folder_colors_raw = get_filesystem_folder_colors()



func rebuild_files():
	_on_filesystem_changed()

func clear_all_caches():
	file_paths.clear()
	_file_paths_dict.clear()
	file_and_dir_paths.clear()
	_file_and_dir_paths_dict.clear()
	file_system_dock_favorites_dict.clear()
	file_system_dock_item_dict.clear()
	
	cache.clear()

func _on_filesystem_changed():
	_set_interface_refs()
	
	_file_paths_dict.clear()
	_file_and_dir_paths_dict.clear()
	#file_data.clear()
	#_file_scan()
	ALibRuntime.Utils.UProfile.TimeFunction.time_func(_file_scan, "FS SCAN")
	
	file_paths = PackedStringArray(_file_paths_dict.keys())
	file_and_dir_paths = PackedStringArray(_file_and_dir_paths_dict.keys())
	
	var t = ALibRuntime.Utils.UProfile.TimeFunction.new("ON FS")
	filesystem_changed.emit() # own signal
	t.stop()



func _file_scan():
	if get_fs_dock_split_mode() != 0:
		_singleton_build_fs_item_dict()
		_singleton_scan_for_files()
	else:
		_singleton_scan_tree_for_paths()



func _singleton_scan_for_files():
	_singleton_recursive_scan_for_files("res://")

func _singleton_recursive_scan_for_files(dir:String) -> void:
	_file_and_dir_paths_dict[dir] = true
	
	var fs_dir:EditorFileSystemDirectory = editor_fs.get_filesystem_path(dir)
	for i in fs_dir.get_subdir_count():
		var sub_dir = fs_dir.get_subdir(i)
		var path = sub_dir.get_path()
		_singleton_recursive_scan_for_files(path)
	
	for i in fs_dir.get_file_count():
		var path = fs_dir.get_file_path(i)
		#get_file_data(path)
		_file_paths_dict[path] = true
		_file_and_dir_paths_dict[path] = true


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
		if child.get_text(0) == get_favorites_text():
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
		_file_and_dir_paths_dict[file_path] = true
	_file_paths_dict[file_path] = true
	
	var child: TreeItem = item.get_first_child()
	while child != null:
		_singleton_recursive_scan_tree_for_paths(child)
		child = child.get_next() # Move to the next sibling

func _singleton_build_fs_item_dict():
	var fs_tree: Tree = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_TREE)
	if not fs_tree:
		printerr("FileSystemDock Tree not found.")
		return
	var root: TreeItem = fs_tree.get_root()
	if not root:
		printerr("FileSystemDock Tree has no root item.")
		return
	
	for child:TreeItem in root.get_children():
		if child.get_text(0) == get_favorites_text():
			for item in child.get_children():
				var path = item.get_metadata(0)
				file_system_dock_favorites_dict[path] = item
		elif child.get_text(0) == "res://":
			_singleton_recursive_build_fs_item_dict(child)

func _singleton_recursive_build_fs_item_dict(item: TreeItem):
	if item == null:
		return
	var file_path = item.get_metadata(0)
	if file_path == null:
		print("NO TREE META", item.get_text(0))
		return
	file_system_dock_item_dict[file_path] = item
	var child: TreeItem = item.get_first_child()
	while child != null:
		_singleton_recursive_build_fs_item_dict(child)
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
	if not fs_dir:
		return files
	for i in fs_dir.get_subdir_count():
		var sub_dir = fs_dir.get_subdir(i)
		files.append_array(recursive_scan_for_file_paths(sub_dir.get_path()))
	
	for i in fs_dir.get_file_count():
		files.append(fs_dir.get_file_path(i))
	return files

func get_file_data(path:String):
	var cached = CacheHelper.get_cached_data(path, cache.file_data)
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
	CacheHelper.store_data(path, _file_data, cache.file_data, [path])
	return _file_data

func _get_file_type(path:String):
	var cached = CacheHelper.get_cached_data(path, cache.file_types)
	if cached != null:
		return cached
	#if _file_types.has(path):
		#return _file_types[path]
	var file_type = editor_fs.get_file_type(path)
	#_file_types[path] = file_type
	CacheHelper.store_data(path, file_type, cache.file_types, [path])
	return file_type

func get_icon(file_path:String):
	if file_system_dock_item_dict.has(file_path):
		var item = file_system_dock_item_dict.get(file_path)
		if item:
			return item.get_icon(0)
	if file_path.ends_with("/"):
		return get_folder_icon()
	var file_type = _get_file_type(file_path)
	return editor_base_control.get_theme_icon(file_type, &"EditorIcons")

func get_folder_icon():
	return cache.folder_icon

static func get_favorites_icon():
	return EditorInterface.get_base_control().get_theme_icon("Favorites", "EditorIcons")

static func get_favorites_text():
	return "Favorites:"

func get_icon_color(file_path:String):
	if file_system_dock_item_dict.has(file_path):
		var item = file_system_dock_item_dict.get(file_path)
		if is_instance_valid(item):
			return item.get_icon_modulate(0)
	if file_path.ends_with("/"):
		return get_folder_color(file_path)
	#var file_type = _get_file_type(file_path)
	#return editor_base_control.get_theme_icon(file_type, &"EditorIcons")
	return Color.WHITE


func get_background_color(file_path:String):
	if cache.folder_color_path_cache.has(file_path):
		return cache.folder_color_path_cache[file_path]
	if file_system_dock_item_dict.has(file_path):
		var item = file_system_dock_item_dict.get(file_path)
		if is_instance_valid(item):
			var color = item.get_custom_bg_color(0)
			cache.folder_color_path_cache[file_path] = color
			return color
	
	if cache.folder_colors_raw.has(file_path):
		var color = Keys.FOLDER_COLORS_DICT.get(cache.folder_colors_raw.get(file_path))
		color.a = 0.1
		cache.folder_color_path_cache[file_path] = color
		return color
	var color = get_folder_color(file_path)
	if color != cache.folder_color:
		color *= 0.7
		color.a = 0.1
		cache.folder_color_path_cache[file_path] = color
		return color


func get_folder_color(file_path:String=""):
	if file_path == "":
		return cache.folder_color
	var color = ""
	var working_path = file_path
	while true:
		var check_path = working_path
		if not check_path.ends_with("/"):
			check_path = check_path + "/"
		
		if cache.folder_colors_raw.has(check_path):
			color = cache.folder_colors_raw.get(check_path)
			break
		
		if working_path == "res://":
			break
		var old_path = working_path
		working_path = working_path.get_base_dir()
		if working_path == old_path:
			break # fail-safe: if get_base_dir() returns the same path, break
	  
	return Keys.FOLDER_COLORS_DICT.get(color, cache.folder_color)


func get_files_in_dir(dir:String, include_dirs:bool=false):
	var first_item = file_system_dock_item_dict.get(dir)
	if fs_dock_in_bottom_panel() or first_item == null:
		return recursive_scan_for_file_paths(dir, include_dirs)
	else:
		return recursive_scan_tree_for_paths(first_item)

static func get_filesystem_folder_colors():
	var data_cache:Dictionary
	if FileSystemSingleton.instance_valid():
		data_cache = FileSystemSingleton.get_instance().cache.data_cache
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
		FileSystemSingleton.get_instance().cache.folder_color_path_cache.clear()
		CacheHelper.store_data(Keys.FOLDER_COLORS, folder_colors, data_cache, [FilePaths.PROJECT])
	return folder_colors

static func get_filesystem_favorites():
	var data_cache:Dictionary
	if FileSystemSingleton.instance_valid():
		data_cache = FileSystemSingleton.get_instance().cache.data_cache
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


func activate_in_fs():
	var fs_tree = get_filesystem_tree() as Tree
	fs_tree.item_activated.emit()

func select_items_in_fs(selected_item_paths:Array, navigate=false) -> bool:
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
		else:
			return false
	
	if fs_tree.visible:
		fs_tree.queue_redraw()
	return true


func _register_dialogs():
	var fs_dock = EditorInterface.get_file_system_dock()
	var dialog_nodes = []
	for n in fs_dock.get_children():
		if n.get_class() in Keys.DIALOGS_TO_MOVE:
			dialog_nodes.append(n)
	
	EditorNodeRef.register(Keys.FS_DIALOGS, dialog_nodes)

static func get_dialogs():
	return EditorNodeRef.get_registered(Keys.FS_DIALOGS)

static func move_dialogs(new_parent):
	var window_checked = false
	var dialog_nodes = EditorNodeRef.get_registered(Keys.FS_DIALOGS)
	for dialog in dialog_nodes:
		if not window_checked:
			window_checked = true
			if dialog.get_parent().get_window() == new_parent.get_window():
				return
		new_parent = new_parent.get_window().get_child(0) # TEST
		if dialog.get_parent() != new_parent:
			dialog.reparent(new_parent)

static func reset_dialogs(pos=null, mouse=null):
	var dialog_nodes = EditorNodeRef.get_registered(Keys.FS_DIALOGS)
	for dialog in dialog_nodes:
		dialog.reparent(EditorInterface.get_file_system_dock())


static func show_file_move_dialog(target_dir:=""):
	var file_system_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_POPUP)
	file_system_popup.id_pressed.emit(9)
	var dialogs = FileSystemSingleton.get_dialogs()
	var move_dialog:Window
	for dialog in dialogs:
		if dialog.get_class() == "EditorDirDialog":
			move_dialog = dialog
			break
	
	var nodes = move_dialog.find_children("*", "Tree", true, false)
	var dialog_tree = nodes[0] as Tree
	var root = dialog_tree.get_root()
	if root == null:
		return
	var paths = EditorInterface.get_selected_paths()
	if paths.is_empty():
		return
	var first_sel = paths[0]
	if first_sel.get_extension() != "":
		first_sel = first_sel.get_base_dir()
	if target_dir != "":
		first_sel = target_dir
	if not first_sel.ends_with("/"):
		first_sel = first_sel + "/"
	
	var item = UTree.find_item_by_meta(root, first_sel)
	if item:
		root.set_collapsed_recursive(true)
		if first_sel == "res://":
			root.collapsed = false
		var par = item.get_parent()
		while par != null:
			par.collapsed = false
			par = par.get_parent()
	else:
		return
	
	dialog_tree.deselect_all()
	item.select(0)
	dialog_tree.scroll_to_item(item, true)
	dialog_tree.queue_redraw()
	
	move_dialog.visibility_changed.connect(_dialog_closed.bind(move_dialog))

static func _dialog_closed(dialog:Window):
	if dialog.visibility_changed.is_connected(_dialog_closed):
		dialog.visibility_changed.disconnect(_dialog_closed)
	reset_dialogs()

static func populate_filesystem_popup(calling_node:Node):
	ALibEditor.Nodes.FileSystem.populate_popup(calling_node)

static func popuplate_filesystem_bottom_popup(calling_node:Node):
	ALibEditor.Nodes.FileSystem.populate_bottom_popup(calling_node)

static func get_filesystem_tree() -> Tree:
	return ALibEditor.Nodes.FileSystem.get_tree()

static func show_filesystem():
	_toggle_fs_bottom_panel_button_vis(true)

static func hide_filesystem():
	if not fs_dock_in_bottom_panel():
		print("Can only hide dock in bottom panel.")
		return
	
	var fs = EditorInterface.get_file_system_dock()
	var split_button = fs.get_child(0).get_child(0).get_child(3)
	var split_callable = ALibRuntime.Utils.UNode.get_signal_callable(split_button, 
		"pressed", "FileSystemDock::_change_split_mode")
	if not split_callable:
		print("Could not get split mode button.")
		return
	
	for i in range(3):
		if get_fs_dock_split_mode() != 0:
			split_callable.call()
		else:
			break
	
	_toggle_fs_bottom_panel_button_vis(false)
	

static func _toggle_fs_bottom_panel_button_vis(toggled:bool):
	var bottom_panel_buttons = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.BOTTOM_PANEL_BUTTONS)
	for b in bottom_panel_buttons.get_children():
		if b.text == "FileSystem":
			b.toggled.emit(false)
			b.visible = toggled
			break

## 0=None, 1=Vertical, 2=Horizontal, -1=Err
static func get_fs_dock_split_mode():
	var tree = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.FILESYSTEM_TREE)
	if not tree:
		return -1
	var filter_panel = tree.get_parent().get_child(1)
	if not filter_panel.visible:
		return 0
	var split = tree.get_parent() as SplitContainer
	if split.vertical:
		return 1
	return 2

static func fs_dock_in_bottom_panel() -> bool:
	var fs_dock = EditorInterface.get_file_system_dock()
	var minor_version = ALibRuntime.Utils.UVersion.get_minor_version()
	if minor_version <= 5: # versions will need testing
		var dock_par = fs_dock.get_parent()
		if dock_par is TabContainer:
			return false
		dock_par = dock_par.get_parent()
		return dock_par.get_class() == "EditorBottomPanel"
	elif minor_version == 6:
		var dock_par = fs_dock.get_parent()
		print(dock_par)
		return dock_par.get_class() == "EditorBottomPanel"
	return false


func _all_unregistered_callback():
	pass

class Cache:
	var data_cache:= {}
	var folder_colors_raw:= {}
	var folder_color_path_cache:= {}
	var file_types:= {}
	var file_data:={}
	
	var folder_icon:Texture2D
	var folder_color:Color
	
	func clear():
		data_cache.clear()
		folder_colors_raw.clear()
		folder_color_path_cache.clear()
		file_types.clear()
		file_data.clear()
		
		set_folder_icon()
	
	func set_folder_icon():
		folder_icon = EditorInterface.get_base_control().get_theme_icon("Folder", &"EditorIcons")
		folder_color = EditorInterface.get_base_control().get_theme_color("folder_icon_color", "FileDialog")

class FilePaths:
	const PROJECT = "res://project.godot"
	const FAVORITES = "res://.godot/editor/favorites"

class Keys:
	const FOLDER_COLORS = &"FolderColors"
	const FAVORITES = &"FileSystemFavorites"
	
	const FOLDER_COLORS_DICT = {
		"red":Color(1.0, 0.271, 0.271),
		"orange":Color(1.0, 0.561, 0.271),
		"yellow":Color(1.0, 0.890, 0.271),
		"green":Color(0.502, 1.0, 0.271),
		"teal":Color(0.271, 1.0, 0.635),
		"blue":Color(0.271, 0.843, 1.0),
		"purple":Color(0.502, 0.271, 1.0),
		"pink":Color(1.0, 0.271, 0.588),
		"gray":Color(0.616, 0.616, 0.616),
	}
	
	const FS_DIALOGS = "FS_DIALOGS"
	const DIALOGS_TO_MOVE = [ "ScriptCreateDialog", "DependencyEditor", "DependencyRemoveDialog", "ConfirmationDialog", "EditorDirDialog",
	"SceneCreateDialog","ShaderCreateDialog","DependencyEditorOwners","DirectoryCreateDialog","CreateDialog"]
