
const FileSystemTree = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_tree.gd")
const FileSystemItemList = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_item_list.gd")
const FileSystemPlaces = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_places.gd")

const FSPopupHelper = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/fs_popup_helper.gd")

const ITEM_LIST_EMPTY_HIDE = ["Rename..."]

const _FS_ID_NEED_RESCAN = [4, 5]
const _FS_ID_NEED_HANDLE = [0, 21, 22, 10]

const CREATE_NEW_TAB = "New Tab"
const ADD_TO_PLACES = "Add to Places"
const SET_ROOT = "Set Root"
const RESET_ROOT = "Reset Root"

signal new_tab(path)
signal add_to_places(path)

var filesystem_singleton:FileSystemSingleton

var tree:FileSystemTree
var item_list:FileSystemItemList
var places:FileSystemPlaces

var _clicked_node:Node
var _selected_path:String

func _init() -> void:
	filesystem_singleton = FileSystemSingleton.get_instance()

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
	filesystem_singleton.populate_filesystem_popup(clicked_node)
	var selected_is_dir = _selected_path.ends_with("/")
	var items = {
		"pre":{},
		"post":{}
		}
	if _clicked_node is FileSystemTree:
		if _selected_path == _clicked_node.root_dir:
			items["pre"]["Reset Root"] = {
				PopupWrapper.ItemParams.ICON:["Clear"]
			}
		elif _selected_path != "res://" and selected_is_dir:
			items["pre"]["Set Root"] = {
				PopupWrapper.ItemParams.ICON:["NewRoot"]
			}
	if selected_is_dir and selected_paths.size() == 1:# and not tree_helper.is_item_in_favorites(selected_item):
		items["pre"][CREATE_NEW_TAB] = {
				PopupWrapper.ItemParams.ICON:["New"]
			}
		var places_options = places.get_add_to_places_options(_selected_path).get_options()
		for option in places_options.keys():
			items["pre"][option] = places_options[option]
			items["pre"][option].erase(PopupWrapper.ItemParams.CALLABLE)
	
	var window = clicked_node.get_window()
	var popup = PopupMenu.new()
	window.add_child(popup)
	popup.popup_hide.connect(_on_popup_hide.bind(popup))
	FSPopupHelper.recreate_popup(popup, _on_wrapper_clicked, names_to_hide, items)
	popup.position = DisplayServer.mouse_get_position()
	popup.popup()


func _on_wrapper_clicked(id:int, popup:PopupMenu, fs_popup:PopupMenu=null):
	if fs_popup == null:
		_handle_non_fs(id, popup)
		return
	
	var queue_rescan = false
	var is_folder_popup = fs_popup.get_item_text(0) == "Default (Reset)"
	var is_create_popup = fs_popup == EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_CREATE_POPUP)
	filesystem_singleton.move_dialogs(_clicked_node)
	if is_folder_popup:
		fs_popup.id_pressed.emit(id)
		filesystem_singleton.rebuild_files()
		return
	elif is_create_popup:
		pass
	else:
		if id in _FS_ID_NEED_RESCAN:
			queue_rescan = true
		if id in _FS_ID_NEED_HANDLE:
			if _clicked_node is FileSystemTree:
				if id == 0: # Expand Folder
					_clicked_node.rc_expand_folder()
				if id == 21: # Expand Hierarchy
					_clicked_node.rc_hierarchy(true)
				elif id == 22: # Collapse Hierarchy
					_clicked_node.rc_hierarchy(false)
				elif id == 10:
					_clicked_node.start_edit()
			elif _clicked_node is FileSystemItemList:
				if id == 10:
					_clicked_node.start_edit()
			if queue_rescan:
				filesystem_singleton.rebuild_files()
			return
	
	if id < 5000:
		if fs_popup == EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.FILESYSTEM_BOTTOM_POPUP):
			fs_popup = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.FILESYSTEM_POPUP)
		fs_popup.id_pressed.emit(id)
	else:
		_handle_non_fs(id, popup)
	
	if queue_rescan:
		filesystem_singleton.rebuild_files()


func _handle_non_fs(id, popup):
	var id_text = PopupWrapper.PopupHelper.parse_menu_path(id, popup)
	if id_text == CREATE_NEW_TAB:
		_rc_new_tab()
	elif id_text.begins_with(ADD_TO_PLACES):
		_add_to_places(PopupWrapper.PopupHelper.get_metadata(id, popup))
	elif id_text == SET_ROOT:
		tree.set_dir(_selected_path, true)
	elif id_text == RESET_ROOT:
		tree.set_dir("res://", true)


func _rc_new_tab():
	if _selected_path and _selected_path.ends_with("/"):
		new_tab.emit(_selected_path)

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
