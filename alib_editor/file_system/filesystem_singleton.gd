@tool
class_name FileSystemSingleton
extends Singleton.RefCount

const CacheHelper = preload("res://addons/addon_lib/brohd/alib_runtime/cache_helper/cache_helper.gd")
const UTree = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_tree.gd")

const FileTypes = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/file_types.gd")
const FSTooltop = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/fs_tooltip.gd")
const FSRename = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/fs_rename.gd")


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

static func clear_caches():
	get_instance().clear_all_caches()

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
var editor_resource_preview:EditorResourcePreview

var _previews_generated:=false #^ need a flag to retrigger when all are built after initial build
var _init_complete:=false

signal filesystem_changed

func _init(node):
	cache = Cache.new()

func _ready() -> void:
	editor_node_ref = EditorNodeRef.get_instance()
	EditorNodeRef.call_on_ready(_register_dialogs)
	editor_fs = EditorInterface.get_resource_filesystem()
	while editor_fs.is_scanning():
		await get_tree().process_frame
	editor_fs.filesystem_changed.connect(_on_filesystem_changed)
	EditorInterface.get_resource_previewer().preview_invalidated.connect(func(path):queue_preview(path))
	
	get_filesystem_favorites()
	#get_filesystem_folder_colors()
	#rebuild_files()
	_set_interface_refs()
	_init_complete = true



func _get_ready_bool():
	return _init_complete

func _generate_previews():
	for path:String in file_paths:
		queue_preview(path)
	_previews_generated = true

func _set_interface_refs():
	cache.set_folder_icon()
	editor_fs = EditorInterface.get_resource_filesystem()
	editor_base_control = EditorInterface.get_base_control()
	editor_resource_preview = EditorInterface.get_resource_previewer()
	
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
	cache.set_editor_icons()
	_previews_generated = false # trigger a build if needed

func _on_filesystem_changed():
	_set_interface_refs()
	
	_file_paths_dict.clear()
	_file_and_dir_paths_dict.clear()
	#cache.file_data.clear()
	#_file_scan()
	ALibRuntime.Utils.UProfile.TimeFunction.time_func(_file_scan, "FS SCAN")
	
	file_paths = PackedStringArray(_file_paths_dict.keys())
	file_and_dir_paths = PackedStringArray(_file_and_dir_paths_dict.keys())
	
	if not _previews_generated:
		_generate_previews()
	
	filesystem_changed.emit() # own signal



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
	if not file_path.ends_with("/"):
		_file_paths_dict[file_path] = true
	_file_and_dir_paths_dict[file_path] = true
	
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
		path_array.append_array(recursive_scan_tree_for_paths(child, include_dirs))
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
		files.append_array(recursive_scan_for_file_paths(sub_dir.get_path(), include_dirs))
	
	for i in fs_dir.get_file_count():
		files.append(fs_dir.get_file_path(i))
	return files

static func is_path_valid(path:String):
	if instance_valid():
		return get_instance()._file_and_dir_paths_dict.has(path)
	return false

func get_file_data(path:String):
	var cached = CacheHelper.get_cached_data(path, cache.file_data)
	if cached:
		return cached
	
	var file_type = get_file_type(path)
	var icon = _get_type_icon(path)
	var preview_icon = icon
	
	if file_type == "":
		file_type = FileData.FOLDER
	
	var _file_data = {
		FileData.PATH: path,
		FileData.PREVIEW_ICON: preview_icon,
		FileData.TYPE_ICON: icon,
		FileData.TYPE: file_type,
		FileData.CUSTOM_ICON: false,
	}
	
	CacheHelper.store_data(path, _file_data, cache.file_data, [path])
		
	return _file_data

static func get_file_type_static(path:String):
	if instance_valid():
		return get_instance().get_file_type(path)
	return {}


func get_file_type(path:String):
	var cached = CacheHelper.get_cached_data(path, cache.file_types)
	if cached != null:
		return cached
	#if _file_types.has(path):
		#return _file_types[path]
	var file_type = editor_fs.get_file_type(path)
	#_file_types[path] = file_type
	CacheHelper.store_data(path, file_type, cache.file_types, [path])
	return file_type



func get_type_icon(file_path:String):
	var data = get_file_data(file_path)
	if data == null:
		return _get_type_icon(file_path)
	return data.get(FileData.TYPE_ICON)

func _get_type_icon(file_path):
	#if file_system_dock_item_dict.has(file_path):
		#var item = file_system_dock_item_dict.get(file_path)
		#if item:
			#return item.get_icon(0)
	if file_path.ends_with("/"):
		return get_folder_icon()
	var file_type = get_file_type(file_path)
	if cache.editor_icons.has(file_type):
		return cache.editor_icons[file_type]
	if Keys.VALID_FILE_TYPES.has(file_type):
		return cache.editor_icons[Keys.VALID_FILE_TYPES.get(file_type)]
	var fs_dir = EditorInterface.get_resource_filesystem().get_filesystem_path(file_path.get_base_dir())
	if fs_dir.get_file_import_is_valid(fs_dir.find_file_index(file_path.get_file())):
		return cache.file_icon
	return EditorInterface.get_editor_theme().get_icon("FileBroken", "EditorIcons")

static func get_preview(path:String):
	if instance_valid():
		return get_instance()._get_preview(path)

func _get_preview(path:String):
	var cached_preview = CacheHelper.get_cached_data(path, cache.resource_previews)
	if cached_preview != null:
		return cached_preview
	queue_preview(path)

func queue_preview(path:String):
	editor_resource_preview.queue_resource_preview(path, self, &"_get_resource_preview", null)

func _get_resource_preview(path, preview, thumbnail, user_data):
	if preview == null:
		return
	
	var data = {
		FileData.Preview.PREVIEW: preview,
		FileData.Preview.THUMBNAIL: thumbnail
	}
	CacheHelper.store_data(path, data, cache.resource_previews, [path])

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

## Recursive get files in directory.
func get_files_in_dir(dir:String, include_dirs:bool=false):
	var first_item = file_system_dock_item_dict.get(dir)
	if get_fs_dock_split_mode() != 0 or first_item == null:
		return recursive_scan_for_file_paths(dir, include_dirs)
	else:
		return recursive_scan_tree_for_paths(first_item, include_dirs)

static func get_dir_contents(dir:String):
	var files = PackedStringArray()
	var fs_dir:EditorFileSystemDirectory = editor_fs.get_filesystem_path(dir)
	if not fs_dir:
		return files
	for i in fs_dir.get_subdir_count():
		var sub_dir = fs_dir.get_subdir(i)
		files.append(sub_dir.get_path())
	
	for i in fs_dir.get_file_count():
		files.append(fs_dir.get_file_path(i))
	return files
	

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


static func activate_in_fs():
	var fs_tree = get_filesystem_tree() as Tree
	fs_tree.item_activated.emit()

static func ensure_items_selected(path_array:Array):
	var instance = get_instance()
	var selected_in_fs = instance.select_items_in_fs(path_array)
	if not selected_in_fs:
		instance.rebuild_files()
		selected_in_fs = instance.select_items_in_fs(path_array)
		if not selected_in_fs:
			print("Could not select the items in FileSystem")
		return selected_in_fs
	else:
		return true

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

static func move_dialogs(new_parent, connect_vis_signal:=true):
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
		
		if connect_vis_signal:
			if not dialog.visibility_changed.is_connected(_on_dialog_visibility_changed):
				dialog.visibility_changed.connect(_on_dialog_visibility_changed.bind(dialog))

static func _on_dialog_visibility_changed(dialog_changed:Window):
	if dialog_changed.visible == false:
		var dialog_nodes = EditorNodeRef.get_registered(Keys.FS_DIALOGS)
		for dialog:Window in dialog_nodes:
			if dialog.visibility_changed.is_connected(_on_dialog_visibility_changed):
				dialog.visibility_changed.disconnect(_on_dialog_visibility_changed)
		reset_dialogs()

static func reset_dialogs(parent=null, mouse=null):
	var dialog_nodes = EditorNodeRef.get_registered(Keys.FS_DIALOGS)
	var first_dialog = dialog_nodes[0]
	if first_dialog.get_parent() == EditorInterface.get_file_system_dock():
		return
	if parent is Node:
		if first_dialog.get_window() != parent.get_window():
			return
	for dialog:Window in dialog_nodes:
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

## Takes a file path, and the new name of the file. New name is not entire path.
static func rename_path(old_path:String, new_path:String):
	await FSRename.rename_path(old_path, new_path)

static func is_new_name_valid(original_file_name:String, new_file_name:String) -> bool:
	return FSRename.is_new_name_valid(original_file_name, new_file_name)

static func fs_navigate_to_path(path:String, activate_rename:=false):
	FSRename.show_item_in_dock(path, activate_rename)

static func get_custom_tooltip(path:String):
	return FSTooltop.get_custom_tooltip(path)

static func get_thumbnail_size():
	return Vector2(64, 64) * EditorInterface.get_editor_scale()

static func get_drag_preview(paths:Array):
	var ins = get_instance()
	var file_icon = ins.cache.file_icon
	var folder_icon = ins.cache.folder_icon
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 0)
	var path_size = paths.size()
	for i in range(5):
		if i >= path_size:
			break
		var path = paths[i]
		var hbox = HBoxContainer.new()
		var icon = folder_icon if path.ends_with("/") else file_icon
		var _name = path.trim_suffix("/").get_file()
		var texture = TextureRect.new()
		texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		texture.texture = icon
		var lab = Label.new()
		lab.text = _name
		hbox.add_child(texture)
		hbox.add_child(lab)
		container.add_child(hbox)
	if path_size > 5:
		var leftover = path_size - 5
		var lab = Label.new()
		lab.text = "%s more files" % leftover
		container.add_child(lab)
	
	return container

func _all_unregistered_callback():
	pass

class Cache:
	var data_cache:= {}
	var folder_colors_raw:= {}
	var folder_color_path_cache:= {}
	var file_types:= {}
	var file_data:={}
	var resource_previews:={}
	
	var file_icon:Texture2D
	var folder_icon:Texture2D
	var folder_color:Color
	
	var editor_icons:= {}
	
	func clear():
		data_cache.clear()
		folder_colors_raw.clear()
		folder_color_path_cache.clear()
		file_types.clear()
		file_data.clear()
		
		set_folder_icon()
	
	func set_folder_icon():
		file_icon = EditorInterface.get_base_control().get_theme_icon("File", &"EditorIcons")
		folder_icon = EditorInterface.get_base_control().get_theme_icon("Folder", &"EditorIcons")
		folder_color = EditorInterface.get_base_control().get_theme_color("folder_icon_color", "FileDialog")
	
	func set_editor_icons():
		editor_icons = {}
		var editor_theme = EditorInterface.get_editor_theme()
		for _name in editor_theme.get_icon_list(&"EditorIcons"):
			editor_icons[_name] = editor_theme.get_icon(_name, &"EditorIcons")

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
	
	const VALID_FILE_TYPES = {
		"Resource":"Object", # this is actually file in the normal tree
		"Texture": "CompressedTexture2D"
		#"JSON":true,
	}


class FileData:
	const FOLDER = &"Folder"
	const PATH = &"item_path"
	const TYPE_ICON = &"file_type_icon"
	const PREVIEW_ICON = &"file_icon"
	const TYPE = &"file_type"
	const CUSTOM_ICON = &"file_custom_icon"
	
	class Preview:
		const PREVIEW = &"preview"
		const THUMBNAIL = &"thumbnail"

class GetDropData:
	static func files(selected_item_paths, from_node):
		return UTree.get_drop_data.files(selected_item_paths, from_node)

class CanDropData:
	static func files(at_position: Vector2, data: Variant, extensions:Array=[]) -> bool:
		return UTree.can_drop_data.files(at_position, data, extensions)

class DropData:
	static func move_dialog(data, target_dir, calling_node):
		var files = []
		if data.has("files"):
			files = data.get("files")
		elif data.has("file_and_dirs"):
			files = data.get("file_and_dirs")
		
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
		
		calling_node.get_window().gui_cancel_drag() #^r twice calling?
		FileSystemSingleton.move_dialogs(calling_node)
		
		var selected = FileSystemSingleton.ensure_items_selected(files)
		if not selected:
			return
		
		calling_node.get_window().grab_focus()
		
		FileSystemSingleton.move_dialogs(calling_node)
		FileSystemSingleton.show_file_move_dialog(target_dir)
