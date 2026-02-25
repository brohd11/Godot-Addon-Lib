
const FileSystemTab = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_tab.gd")
const FileSystemTree = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_tree.gd")
const FileSystemItemList = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_item_list.gd")
const FileSystemPlaces = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_places.gd")

const FSPopupHelper = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/fs_popup_helper.gd")

const PopupID = ALibEditor.Nodes.FileSystem.PopupID

const ITEM_LIST_EMPTY_HIDE = ["Rename..."]

var _fs_id_need_rescan = []
var _fs_id_need_handle_file = []
var _fs_id_need_handle_folder = []

const NEW_WINDOW = "New/Window"
const CREATE_NEW_TAB = "New/Tab"
const _NEW_SPLIT = "New/Split/"
const NEW_SPLIT_LEFT = _NEW_SPLIT + "Left"
const NEW_SPLIT_RIGHT = _NEW_SPLIT + "Right"
const NEW_SPLIT_UP = _NEW_SPLIT + "Up"
const NEW_SPLIT_DOWN = _NEW_SPLIT + "Down"
const ADD_TO_PLACES = "Add to Places"
const SET_ROOT = "Set Root"
const RESET_ROOT = "Reset Root"

signal new_tab(path)
signal add_to_places(path)

var filesystem_singleton:FileSystemSingleton

var current_browser_state:FileSystemTab.BrowserState=FileSystemTab.BrowserState.BROWSE

var filesystem_tab:FileSystemTab
var tree:FileSystemTree
var item_list:FileSystemItemList
var places:FileSystemPlaces

var _clicked_node:Node
var _selected_path:String

func _init() -> void:
	filesystem_singleton = FileSystemSingleton.get_instance()
	
	_fs_id_need_rescan = [PopupID.add_to_favorites(), PopupID.remove_from_favorites()]
	_fs_id_need_handle_folder = [PopupID.rename(), PopupID.expand_folder(), PopupID.expand_hierarchy(), PopupID.collapse_hierarchy()]
	_fs_id_need_handle_file = [PopupID.rename()]


func right_clicked_empty_item_list(clicked_node:Node, selected_item_path:String):
	var hide_names = FSPopupHelper.MenuItems.TO_HIDE_ITEM_LIST_EMPTY
	_right_click_menu(clicked_node, selected_item_path, [selected_item_path], hide_names)

func right_clicked(clicked_node:Node, selected_item_path:String, selected_paths:Array):
	var hide_names = []
	if clicked_node is FileSystemItemList:
		hide_names = FSPopupHelper.MenuItems.TO_HIDE_ITEM_LIST
	_right_click_menu(clicked_node, selected_item_path, selected_paths, hide_names)

func _right_click_menu(clicked_node:Node, selected_item_path:String, selected_paths:Array, names_to_hide:Array=[]):
	var items_selected = FileSystemSingleton.ensure_items_selected(selected_paths)
	if not items_selected:
		return
	
	_clicked_node = clicked_node
	_selected_path = selected_item_path
	FileSystemSingleton.populate_filesystem_popup(clicked_node)
	var selected_is_dir = _selected_path.ends_with("/")
	var items = {
		"pre":{},
		"post":{}
		}
	if _clicked_node is FileSystemTree:
		if _selected_path == _clicked_node.root_dir:
			items["pre"][RESET_ROOT] = {
				PopupWrapper.ItemParams.ICON:["Clear"]
			}
		elif _selected_path != "res://" and selected_is_dir:
			items["pre"][SET_ROOT] = {
				PopupWrapper.ItemParams.ICON:["NewRoot"]
			}
	if selected_is_dir and selected_paths.size() == 1:# and not tree_helper.is_item_in_favorites(selected_item):
		items["pre"][NEW_WINDOW] = {PopupWrapper.ItemParams.ICON:["New", "Window"]}
		items["pre"][CREATE_NEW_TAB] = {PopupWrapper.ItemParams.ICON:["New", ALibEditor.Singletons.EditorIcons.get_icon_white("TabContainer")]}
		var split_icon = ALibEditor.Singletons.EditorIcons.get_icon_white("SplitContainer", 1)
		for direction in [NEW_SPLIT_LEFT, NEW_SPLIT_RIGHT, NEW_SPLIT_UP, NEW_SPLIT_DOWN]:
			items["pre"][direction] = {PopupWrapper.ItemParams.ICON:["New", split_icon, null]}
		
		var places_options = places.get_add_to_places_options(_selected_path).get_options()
		for option in places_options.keys():
			items["pre"][option] = places_options[option]
			items["pre"][option].erase(PopupWrapper.ItemParams.CALLABLE)
	
	
	var window = clicked_node.get_window()
	var popup = PopupMenu.new()
	window.add_child(popup)
	popup.popup_hide.connect(_on_popup_hide.bind(popup), 1)
	FSPopupHelper.recreate_popup(popup, _on_wrapper_clicked, names_to_hide, items)
	popup.position = DisplayServer.mouse_get_position()
	popup.popup()


func _on_wrapper_clicked(id:int, popup:PopupMenu, fs_popup:PopupMenu=null):
	if fs_popup == null:
		_handle_non_fs(id, popup)
		return
	
	#print(id)
	var queue_rescan = false
	var is_folder_popup = fs_popup.get_item_text(0) == "Default (Reset)"
	var is_create_popup = fs_popup == EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_CREATE_POPUP)
	FileSystemSingleton.move_dialogs(_clicked_node)
	if is_folder_popup:
		fs_popup.id_pressed.emit(id)
		filesystem_singleton.rebuild_files()
		return
	elif is_create_popup:
		pass
	else:
		var is_dir = _selected_path.ends_with("/")
		if id in _fs_id_need_rescan:
			queue_rescan = true
		if id == PopupID.rename():
			_clicked_node.start_edit()
			return
		if is_dir and id in _fs_id_need_handle_folder:
			if _clicked_node is FileSystemTree:
				if id == PopupID.expand_folder():
					_clicked_node.rc_expand_folder()
				if id == PopupID.expand_hierarchy():
					_clicked_node.rc_hierarchy(true)
				if id == PopupID.collapse_hierarchy():
					_clicked_node.rc_hierarchy(false)
					
			elif _clicked_node is FileSystemItemList:
				pass
			if queue_rescan:
				filesystem_singleton.rebuild_files()
			return
	
	if id < 5000:
		if fs_popup == EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.FILESYSTEM_BOTTOM_POPUP):
			fs_popup = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.FILESYSTEM_POPUP)
		if id == PopupID.reimport():
			await _reimport_pressed(fs_popup, popup)
		else:
			fs_popup.id_pressed.emit(id)
		
	else:
		_handle_non_fs(id, popup)
	
	if queue_rescan:
		filesystem_singleton.rebuild_files()

func _reimport_pressed(fs_popup, popup_wrapper):
	fs_popup.position = popup_wrapper.position
	fs_popup.show()
	await tree.get_tree().process_frame
	fs_popup.id_pressed.emit(PopupID.reimport())
	fs_popup.hide()


func _handle_non_fs(id, popup):
	var id_text = PopupWrapper.PopupHelper.parse_menu_path(id, popup)
	if id_text == CREATE_NEW_TAB:
		_rc_new_tab()
	elif id_text == NEW_WINDOW:
		var fs_data = filesystem_tab.get_dock_data()
		if filesystem_tab._current_view_mode == FileSystemTab.ViewMode.TREE:
			fs_data[FileSystemTab.DataKeys.ROOT] = _selected_path
		fs_data[FileSystemTab.DataKeys.CURRENT_PATH] = _selected_path
		EditorGlobalSignals.signal_emit(FileSystemTab.DataKeys.GLOBAL_NEW_WINDOW_SIGNAL, fs_data)
	elif id_text.begins_with(ADD_TO_PLACES):
		_add_to_places(PopupWrapper.PopupHelper.get_metadata(id, popup))
	elif id_text == SET_ROOT:
		tree.set_dir(_selected_path, true)
		item_list.tree_root = _selected_path
		filesystem_tab.refresh_current_path()
	elif id_text == RESET_ROOT:
		tree.set_dir("res://", true)
		item_list.tree_root = "res://"
		filesystem_tab.refresh_current_path()
	elif id_text.begins_with(_NEW_SPLIT):
		_new_split(id_text)


func _rc_new_tab():
	if _selected_path and _selected_path.ends_with("/"):
		new_tab.emit(_selected_path)

func _new_split(id_text:String):
	var fs_data = filesystem_tab.get_dock_data()
	if filesystem_tab._current_view_mode == FileSystemTab.ViewMode.TREE:
		fs_data[FileSystemTab.DataKeys.ROOT] = _selected_path
	fs_data[FileSystemTab.DataKeys.CURRENT_PATH] = _selected_path
	EditorGlobalSignals.signal_emitv(FileSystemTab.DataKeys.GLOBAL_NEW_SPLIT_SIGNAL, [filesystem_tab, id_text, fs_data])

func _add_to_places(meta:Dictionary):
	var place_list = meta.get("place_list")
	places.add_place_item(_selected_path, place_list)
	add_to_places.emit(_selected_path)

func _on_popup_hide(popup:PopupMenu):
	popup.queue_free()
	_reset.call_deferred()

func _reset():
	_clicked_node = null
	_selected_path = ""
