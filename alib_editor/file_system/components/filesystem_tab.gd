@tool
extends VBoxContainer

const RightClickHandler = preload("res://addons/addon_lib/brohd/gui_click_handler/right_click_handler.gd")

const FileSystemTab = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_tab.gd")
const FileSystemTree = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_tree.gd")
const FileSystemItemList = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_item_list.gd")

const FSPopupHelper = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/fs_popup_helper.gd")
const FSPopupHandler = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/fs_popup_id_handler.gd")

const _FS_ID_NEED_RESCAN = [4, 5]
const _FS_ID_NEED_HANDLE = [0, 21, 22, 10]

var filesystem_singleton:FileSystemSingleton

var fs_popup_handler:FSPopupHandler

var right_click_handler:RightClickHandler

var options_button:Button
var tree_split_container:SplitContainer
var tree_vbox:VBoxContainer
var tree: FileSystemTree

var item_vbox:VBoxContainer
var item_list:FileSystemItemList

enum ViewMode {
	TREE,
	PLACES,
	MILLER
}

enum SplitMode {
	NONE,
	VERTICAL,
	HORIZONTAL
}
var _current_split_mode:SplitMode = SplitMode.NONE
var _recursive_view:bool = false

var plugin_tab_container

var _dock_data:= {}

signal new_plugin_tab(control)

func can_be_freed() -> bool:
	if not is_instance_valid(plugin_tab_container):
		if tree.root_dir == "res://":
			return false
		return true
	else:
		var tabs = plugin_tab_container.get_all_tab_controls()
		for tab:FileSystemTab in tabs:
			if tab.tree.root_dir == "res://" and tab != self:
				return true
		return false

func get_tab_title():
	if tree.root_dir == "res://":
		return "FileSystem"
	else:
		return tree.root_dir.trim_suffix("/").get_file()

func set_dir(target_dir:String):
	tree.set_dir(target_dir)
	item_list.tree_root = target_dir

func _ready() -> void:
	filesystem_singleton = FileSystemSingleton.get_instance()
	filesystem_singleton.filesystem_changed.connect(_on_scan_files_complete, 1)
	visibility_changed.connect(_on_visibilty_changed)
	
	_build_nodes()
	_set_split_mode()
	
	var root = _dock_data.get("root", "res://")
	set_dir(root)
	var item_meta = _dock_data.get("item_meta", {})
	tree.tree_helper.data_dict = item_meta

func _build_nodes():
	if is_instance_valid(tree):
		return
	
	right_click_handler = RightClickHandler.new()
	add_child(right_click_handler)
	
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	
	var spacer = Control.new()
	add_child(spacer)
	
	var line_hbox = HBoxContainer.new()
	add_child(line_hbox)
	line_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var line_edit = LineEdit.new()
	line_edit.clear_button_enabled = true
	line_hbox.add_child(line_edit)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var line_edit_2  = LineEdit.new()
	line_edit_2.clear_button_enabled = true
	line_hbox.add_child(line_edit_2)
	line_edit_2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	options_button = Button.new()
	options_button.icon = EditorInterface.get_editor_theme().get_icon("TripleBar", "EditorIcons")
	options_button.pressed.connect(_on_options_button_pressed)
	options_button.theme_type_variation = &"MainScreenButton"
	options_button.focus_mode = Control.FOCUS_NONE
	line_hbox.add_child(options_button)
	
	#^ split
	tree_split_container = SplitContainer.new()
	add_child(tree_split_container)
	tree_split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	#^ tree side
	tree_vbox = VBoxContainer.new()
	tree_split_container.add_child(tree_vbox)
	tree_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	tree = FileSystemTree.new()
	tree.filters.append(line_edit)
	tree.filters.append(line_edit_2)
	tree_vbox.add_child(tree)
	tree.owner = self
	
	tree.tree_item_selected.connect(_on_tree_item_selected)
	
	#^ split side
	item_vbox = VBoxContainer.new()
	tree_split_container.add_child(item_vbox)
	item_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	item_list = FileSystemItemList.new()
	item_vbox.add_child(item_list)
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	
	
	fs_popup_handler = FSPopupHandler.new()
	fs_popup_handler.tree = tree
	fs_popup_handler.item_list = item_list
	
	fs_popup_handler.new_tab.connect(_on_rc_new_tab)
	
	tree.double_clicked.connect(_on_double_clicked)
	item_list.double_clicked.connect(_on_double_clicked)
	
	item_list.select_tree_item.connect(_on_item_list_select_tree_item)
	
	tree.right_clicked.connect(fs_popup_handler.right_clicked)
	item_list.right_clicked.connect(fs_popup_handler.right_clicked)
	item_list.right_clicked_empty.connect(fs_popup_handler.right_clicked_empty_item_list)


func set_dock_data(data:Dictionary):
	_build_nodes()
	_dock_data = data
	
	_current_split_mode = _dock_data.get("split_mode", 0)
	_recursive_view = _dock_data.get("recursive_view", false)
	item_list.set_display_as_list(_dock_data.get("display_list", false))
	tree.show_item_preview = _dock_data.get("preview_icons", false)
	

func get_dock_data() -> Dictionary:
	var data = {}
	data["root"] = tree.root_dir
	
	var item_meta = {}
	for path in tree.tree_helper.data_dict.keys():
		var path_data = tree.tree_helper.data_dict.get(path)
		var collapsed = path_data.get(tree.tree_helper.Keys.METADATA_COLLAPSED)
		if collapsed:
			continue
		item_meta[path] = {tree.tree_helper.Keys.METADATA_COLLAPSED:false}
	data["item_meta"] = item_meta
	data["split_mode"] = _current_split_mode
	data["display_list"] = item_list.display_as_list
	data["recursive_view"] = _recursive_view
	data["preview_icons"] = tree.show_item_preview
	return data


func _on_scan_files_complete():
	if not visible:
		tree.file_array.clear()
		tree.clear_items()
		return
	await tree.full_build()
	_item_list_select_path.call_deferred(tree.get_selected_paths())

func _rebuild_tree():
	tree.full_build()

func _on_visibilty_changed():
	if visible:
		tree.set_active()
	else:
		tree.set_inactive()
		prints("CLEARING TREE ", tree.root_dir)
		return


func _on_rc_new_tab(path):
	var new_instance = new()
	new_instance.set_dock_data({
		"root": path,
		"split_mode": _current_split_mode,
		"display_list": item_list.display_as_list
		})
	new_plugin_tab.emit(new_instance)

func _on_tree_item_selected(selected_paths:Array):
	_item_list_select_path(selected_paths)

func item_list_select_path():
	_item_list_select_path(tree.get_selected_paths())

func _item_list_select_path(selected_paths:Array):
	item_list.folder_view_root = ""
	if _current_split_mode != SplitMode.NONE:
		if selected_paths.is_empty():
			return
		var first_path = selected_paths[0]
		var paths
		if first_path == FileSystemTree.FAVORITES_META:
			paths = FileSystemSingleton.get_filesystem_favorites()
			paths.sort()
		else:
			if _recursive_view:
				paths = filesystem_singleton.get_files_in_dir(first_path)
			else:
				paths = FileSystemSingleton.get_dir_contents(first_path)
				item_list.folder_view_root = first_path
		
		item_list.set_current_paths(paths)

func _on_double_clicked(selected_path:String):
	var selected_in_fs = filesystem_singleton.ensure_items_selected([selected_path])
	if not selected_in_fs:
		return
	filesystem_singleton.activate_in_fs()

func _on_item_list_select_tree_item(path):
	tree.select_paths([path])


func _on_options_button_pressed():
	var options = RightClickHandler.Options.new()
	options.add_option("Change Split Mode", _change_split_mode, [_get_split_icon()])
	if _current_split_mode != SplitMode.NONE:
		options.add_option("Item View", _set_display_as_list, [_get_display_as_list_icon()])
		options.add_option("Recursive View", _set_recursive_view, [_get_recursive_icon()])
	else:
		options.add_option("Preview Icons", _set_preview_icons, [EditorInterface.get_editor_theme().get_icon("ImageTexture", "EditorIcons")])
	
	var popup_pos = right_click_handler.get_centered_control_position(options_button)
	right_click_handler.display_popup(options, true, popup_pos)



func _change_split_mode():
	_current_split_mode += 1
	if _current_split_mode >= SplitMode.size():
		_current_split_mode = 0
	_set_split_mode()

func _set_split_mode():
	tree.show_files = false
	if _current_split_mode == SplitMode.NONE:
		item_vbox.hide()
		tree.show_files = true
	elif _current_split_mode == SplitMode.HORIZONTAL:
		item_vbox.show()
		tree_split_container.vertical = false
	elif _current_split_mode == SplitMode.VERTICAL:
		item_vbox.show()
		tree_split_container.vertical = true
	
	await _rebuild_tree()
	if _current_split_mode != SplitMode.NONE:
		item_list_select_path()

func _get_split_icon():
	if _current_split_mode == SplitMode.NONE:
		return EditorInterface.get_editor_theme().get_icon("Panels1", "EditorIcons")
	elif _current_split_mode == SplitMode.HORIZONTAL:
		return EditorInterface.get_editor_theme().get_icon("Panels2", "EditorIcons")
	elif _current_split_mode == SplitMode.VERTICAL:
		return EditorInterface.get_editor_theme().get_icon("Panels2Alt", "EditorIcons")


func _set_display_as_list():
	item_list.set_display_as_list(not item_list.display_as_list)

func _get_display_as_list_icon():
	if item_list.display_as_list:
		return EditorInterface.get_editor_theme().get_icon("AnimationTrackList", "EditorIcons")
	else:
		return EditorInterface.get_editor_theme().get_icon("FileThumbnail", "EditorIcons")

func _set_recursive_view():
	_recursive_view = not _recursive_view
	item_list_select_path()

func _get_recursive_icon():
	if _recursive_view:
		return EditorInterface.get_editor_theme().get_icon("FileTree", "EditorIcons")
	return EditorInterface.get_editor_theme().get_icon("FileTree", "EditorIcons")

func _set_preview_icons():
	tree.show_item_preview = not tree.show_item_preview
	_rebuild_tree()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		filesystem_singleton.reset_dialogs()
