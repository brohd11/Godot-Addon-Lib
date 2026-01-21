@tool
extends VBoxContainer

#! import-p DataKeys,

const ATTEMPT_RENAME = true

const RightClickHandler = preload("res://addons/addon_lib/brohd/gui_click_handler/right_click_handler.gd")
const UFile = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_file.gd")

const FSClasses = preload("res://addons/addon_lib/brohd/alib_editor/file_system/util/fs_classes.gd")
const FileSystemTab = FSClasses.FileSystemTab
const FileSystemPathBar = FSClasses.FileSystemPathBar
const FileSystemTree = FSClasses.FileSystemTree
const FileSystemItemList = FSClasses.FileSystemItemList
const FileSystemPlaces = FSClasses.FileSystemPlaces
const FileSystemMiller = FSClasses.FileSystemMiller

const FSPopupHelper = FSClasses.FSPopupHelper
const FSPopupHandler = FSClasses.FSPopupHandler
const FSFilter = FSClasses.FSFilter
const FSUtil = FSClasses.FSUtil
const NonResHelper = FSClasses.NonResHelper

const FAVORITES_META = "FAVORITES"


enum BrowserState {
	BROWSE,
	SEARCH
}
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
enum SearchView{
	AUTO,
	ITEM_LIST,
}


var filesystem_singleton:FileSystemSingleton
var fs_popup_handler:FSPopupHandler
var right_click_handler:RightClickHandler
var non_res_helper:NonResHelper

var _modulated_icons:= {}

var current_path:String = "res://"
var current_dir:String = "res://"
var current_selected_paths:= PackedStringArray()
var _path_in_res:=true

var togglable_elements = []

var _toolbar_debounce_timer:Timer

var tool_bar_hbox:HBoxContainer

var path_bar:FileSystemPathBar
var search_label:Label
var tool_bar_spacer:Control

var search_hbox:HBoxContainer
var main_split_container:SplitContainer
var tree_vbox#:VBoxContainer #^ rename to split container
var tree: FileSystemTree
var places:FileSystemPlaces
var miller:FileSystemMiller

var _toggle_places_button:Button
var _toggle_path_button:Button
var _tree_button:Button
var _places_button:Button
var _miller_button:Button
var options_button:Button

var _search_select_path:bool=true

var _async_search:UFile.GetFilesAsync
var _search_tick = 1
var _async_is_searching:= false

var _current_search_view:SearchView=SearchView.AUTO
var _current_search_dir:= ""

var filters:= []
var _filters_toggled:=false
var _filter_debounce:= false
var _filter_timer:Timer

var _search_bar_spacer:Control
var file_type_filter:OptionButton
const _NO_FILTER_NAME = "Type"

var _filtered_paths:= PackedStringArray()
var _type_filtered_paths:= PackedStringArray()
var _last_prefix_filters:= PackedStringArray()
var _current_filter_mode:FSFilter.FilterMode = FSFilter.FilterMode.SUBSEQUENCE_SORT

var item_vbox:VBoxContainer
var item_list:FileSystemItemList

var _last_browser_state:=BrowserState.BROWSE
var _current_browser_state:= BrowserState.BROWSE

var _view_data = {}
var _current_view_mode:ViewMode = ViewMode.TREE
var _current_split_mode:SplitMode = SplitMode.NONE
var _recursive_view:bool = false

var plugin_tab_container
var _dock_data:= {}

signal new_plugin_tab(control)

func can_be_freed() -> bool:
	var tabs = plugin_tab_container.get_all_tab_controls()
	return not tabs.size() == 1
	
	#if not is_instance_valid(plugin_tab_container):
		#if tree.root_dir == "res://":
			#return false
		#return true
	#else:
		#var tabs = plugin_tab_container.get_all_tab_controls()
		#for tab:FileSystemTab in tabs:
			#if tab.tree.root_dir == "res://" and tab != self:
				#return true
		#return false

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
	
	_build_nodes()
	tool_bar_hbox.custom_minimum_size.y = path_bar.line_edit.size.y
	
	var root = _dock_data.get(DataKeys.ROOT, "res://")
	set_dir(root)
	var item_meta = _dock_data.get(DataKeys.TREE_ITEM_META, {})
	tree.tree_helper.data_dict = item_meta
	
	var place_data = _dock_data.get(DataKeys.PLACE_DATA, {})
	if place_data.is_empty():
		place_data = FileSystemPlaces.Data.get_default_data()
	
	places.build_item_list(place_data)
	
	#_set_current_path(self, root)
	
	_set_view_data() #^ must ensure root dir is set before calling
	visibility_changed.connect(_on_visibilty_changed, 1)
	
	_set_current_path(self, current_path)

func _exit_tree() -> void:
	filesystem_singleton.reset_dialogs(self)

func get_split_options() -> RightClickHandler.Options:
	var options = RightClickHandler.Options.new()
	var msg_text = "Show Tool Bar"
	var icon = EditorInterface.get_editor_theme().get_icon("GuiVisibilityVisible", "EditorIcons")
	var val = true
	if tool_bar_hbox.visible:
		msg_text = "Hide Tool Bar"
		icon = EditorInterface.get_editor_theme().get_icon("GuiVisibilityHidden", "EditorIcons")
		val = false
	options.add_option(msg_text, _toggle_element.bind(tool_bar_hbox, val), [icon])
	return options

func set_dock_data(data:Dictionary):
	_build_nodes()
	_dock_data = data
	
	current_path = _dock_data.get(DataKeys.CURRENT_PATH, "res://")
	_current_view_mode = _dock_data.get(DataKeys.VIEW_MODE, ViewMode.TREE)
	_view_data = _dock_data.get(DataKeys.VIEW_DATA, {})
	
	_search_select_path = _dock_data.get(DataKeys.SEARCH_SELECT_PATH, true)
	
	_recursive_view = _dock_data.get(DataKeys.TREE_RECURSIVE_VIEW, false)
	tree.show_item_preview = _dock_data.get(DataKeys.TREE_PREVIEW_ICONS, false)


func get_dock_data() -> Dictionary:
	_get_view_data()
	var data = {}
	data[DataKeys.ROOT] = tree.root_dir
	
	var item_meta = {}
	for path in tree.tree_helper.data_dict.keys():
		var path_data = tree.tree_helper.data_dict.get(path)
		var collapsed = path_data.get(tree.tree_helper.Keys.METADATA_COLLAPSED)
		if collapsed:
			continue
		item_meta[path] = {tree.tree_helper.Keys.METADATA_COLLAPSED:false}
	
	data[DataKeys.TREE_ITEM_META] = item_meta
	#data[DataKeys.SPLIT_MODE] = _current_split_mode
	#data[DataKeys.ITEM_DISPLAY_LIST] = item_list.display_as_list
	data[DataKeys.TREE_RECURSIVE_VIEW] = _recursive_view
	data[DataKeys.TREE_PREVIEW_ICONS] = tree.show_item_preview
	
	data[DataKeys.SEARCH_SELECT_PATH] = _search_select_path
	
	data[DataKeys.CURRENT_PATH] = current_path
	data[DataKeys.VIEW_MODE] = _current_view_mode
	data[DataKeys.VIEW_DATA] = _view_data
	
	data[DataKeys.PLACE_DATA] = places.get_place_data()
	return data


func _on_scan_files_complete():
	if not visible:
		tree.file_array.clear()
		tree.set_inactive()
		return
	await tree.full_build()
	_set_current_path(self, current_path)

func _rebuild_tree():
	tree.full_build()

func _on_visibilty_changed():
	if visible:
		_set_active()
	else:
		_set_inactive()

func _set_active():
	tree.set_active()

func _set_inactive():
	tree.set_inactive()

func _on_filter_type_selected(idx:int):
	if idx == 0:
		_last_prefix_filters.clear()
	_start_filter_debounce()

func _on_filter_text_changed(new_text:String):
	_start_filter_debounce()

func _start_filter_debounce():
	_filter_timer.start(0.15)

func _set_filter_texts():
	if _is_filtering():
		_current_browser_state = BrowserState.SEARCH
	else:
		_current_browser_state = BrowserState.BROWSE
	
	if _async_is_searching:
		if _current_browser_state == BrowserState.BROWSE:
			_async_search.cancel()
		_filter_timer.start(0.2)
		return
	
	_set_browser_states()
	
	#^c SEARCH
	if _current_browser_state == BrowserState.SEARCH:
		if _last_browser_state != _current_browser_state:
			_current_search_dir = current_dir
			_get_view_data() #^ save current view data
			
		
		path_bar.hide()
		search_label.show()
		var display = _current_search_dir.trim_suffix("/").get_file()
		if FSUtil.is_root_folder(_current_search_dir):
			display = _current_search_dir
		search_label.text = 'Searching "%s"' % display
		search_label.tooltip_text = _current_search_dir
		
		if _current_search_view == SearchView.AUTO:
			_set_search_view_auto()
		elif _current_search_view == SearchView.ITEM_LIST:
			_set_search_view_item_list()
	
	elif _current_browser_state == BrowserState.BROWSE:
		_toggle_element_respect_meta(path_bar, true)
		#path_bar.show()
		search_label.hide()
		
		tree.set_filtered_paths([])
		tree.update_filter()
		item_list.set_filtered_paths([])
		
		miller.set_filtered_paths([])
		miller.clear_columns()
		miller.set_current_dir(current_dir, true, true)
		#miller.update_filter()
		
		if _last_browser_state != _current_browser_state:
			_async_search = null
			_current_search_dir = current_dir
			_set_view_data() #^ reset layout to current view data
			refresh_current_path()
			
	
	_last_browser_state = _current_browser_state

func _set_search_view_auto():
	if _current_view_mode == ViewMode.TREE and _current_split_mode == SplitMode.NONE:
		tree.set_filtered_paths(await _get_filtered_paths(false, false))
		tree.update_filter()
	
	elif _current_view_mode == ViewMode.PLACES:
		if miller.visible:
			miller.hide()
			item_list.show()
		item_list.set_filtered_paths(await _get_filtered_paths(false, true))
		item_list.update_filter()
	
	elif _current_view_mode == ViewMode.MILLER:
		miller.set_filtered_paths(await _get_filtered_paths(true, true))
		miller.update_filter()

func _set_search_view_item_list():
	if _current_split_mode == SplitMode.NONE:
		_set_split_mode(SplitMode.HORIZONTAL)
	if miller.visible:
		miller.hide()
	item_list.show()
	item_list.set_filtered_paths(await _get_filtered_paths(false, true))
	item_list.update_filter()


func _is_filtering():
	return not _get_filter_text_array().is_empty()

func _get_filter_text_array():
	var filter_data = {}
	var filter_array = []
	var prefix_array = PackedStringArray()
	if file_type_filter.selected != 0:
		var category = file_type_filter.get_item_text(file_type_filter.selected)
		prefix_array.append(FSFilter.Prefix.CATEGORY + category)
	
	for f in filters:
		var text = f.text
		if text == "":
			continue
		var prefix_data = FSFilter.Prefix.get_prefix(text)
		if not prefix_data:
			if not FSFilter.Prefix.text_is_prefix(text):
				filter_array.append(text)
		else:
			prefix_array.append(text)
	
	if not filter_array.is_empty():
		filter_data["filter"] = filter_array
	if not prefix_array.is_empty():
		filter_data["prefix"] = prefix_array
	
	return filter_data


func _get_filtered_paths(include_dirs:=false, use_file_name:=true):
	print("GET FILTERED: ", current_dir)
	var paths:PackedStringArray
	if _current_search_dir == "res://":
		if include_dirs:
			paths = filesystem_singleton.file_and_dir_paths.duplicate()
		else:
			paths = filesystem_singleton.file_paths.duplicate()
	elif FSUtil.is_path_valid_res(_current_search_dir):
		paths = filesystem_singleton.get_files_in_dir(_current_search_dir, include_dirs)
	else:
		if is_instance_valid(_async_search):
			paths = _async_search.get_cached_files()
		else:
			_async_is_searching = true
			_async_search = UFile.GetFilesAsync.open(_current_search_dir, _search_async_callback)
			_async_search.set_settings(include_dirs)
			paths = await _async_search.get_files(50)
			_async_is_searching = false
			_reset_filter_icons()
			if _async_search.was_cancelled():
				return PackedStringArray()
		
	
	var idx = paths.find(_current_search_dir)
	if idx > -1:
		paths.remove_at(idx)
	
	var filter_text_array = _get_filter_text_array()
	var has_prefix_filter = filter_text_array.has("prefix")
	var string_filters = filter_text_array.get("filter", [])
	var prefix_filters = filter_text_array.get("prefix", [])
	
	var t = ALibRuntime.Utils.UProfile.TimeFunction.new("Search")
	
	if has_prefix_filter:
		if _last_prefix_filters != prefix_filters:
			_last_prefix_filters = prefix_filters
			_type_filtered_paths = FSFilter.filter_with_prefixes(paths, prefix_filters)
		paths = _type_filtered_paths
	
	
	if _current_filter_mode == FSFilter.FilterMode.EXACT:
		_filtered_paths = FSFilter.filter_exact_match(paths, string_filters, use_file_name)
	elif _current_filter_mode == FSFilter.FilterMode.EXACT_SORT:
		_filtered_paths = FSFilter.filter_exact_match_sorted(paths, string_filters, use_file_name)
	elif _current_filter_mode == FSFilter.FilterMode.SUBSEQUENCE:
		_filtered_paths = FSFilter.filter_subseq(paths, string_filters, use_file_name)
	elif _current_filter_mode == FSFilter.FilterMode.SUBSEQUENCE_SORT:
		_filtered_paths = FSFilter.filter_subseq_sorted(paths, string_filters, use_file_name)
	#_filtered_paths = FSFilter.filter_files(paths, _get_filter_text_array(), use_file_name)
	t.stop()
	(_filtered_paths.size())
	return _filtered_paths


func _search_async_callback():
	_search_tick += 1
	if _search_tick > 90:
		_search_tick = 1
	
	var _search_icon_num = _search_tick / 10
	_search_icon_num = clampi(_search_icon_num, 1, 8)
	var icon = EditorInterface.get_editor_theme().get_icon("Progress" + str(_search_icon_num), "EditorIcons")
	_set_filter_icons(icon, false)

func _reset_filter_icons():
	var icon = EditorInterface.get_editor_theme().get_icon("Search", "EditorIcons")
	_set_filter_icons(icon, true)

func _set_filter_icons(icon, clear_enabled:=true):
	for f:LineEdit in filters:
		f.clear_button_enabled = clear_enabled
		f.right_icon = icon


func _on_rc_new_tab(path:String):
	var new_instance = new()
	var data = get_dock_data()
	data[DataKeys.ROOT] = path
	new_instance.set_dock_data(data)
	new_plugin_tab.emit(new_instance)

func _on_add_to_places(path): #^r think obsolete
	return
	#places.add_place(path)

func _set_browser_states(browser_state:=_current_browser_state):
	tree.current_browser_state = browser_state
	item_list.current_browser_state = browser_state
	miller.current_browser_state = browser_state

func _set_path_in_res(path_in_res:=_path_in_res):
	item_list.path_in_res = path_in_res
	miller.path_in_res = path_in_res
	path_bar.path_in_res = path_in_res


func refresh_current_path():
	_set_current_path(self, current_path)

## Path coming must be file or dir with trailing slash. If dir doesn't have slash, will treat as file.
func _set_current_path(who:Control, path:String):
	var dir = path
	if not dir.ends_with("/"):
		dir = UFile.get_dir(dir)
	
	if _current_browser_state == BrowserState.SEARCH:
		if not _search_select_path:
			if _current_view_mode == ViewMode.MILLER and who == miller:
				miller.set_current_dir_search(dir)
				print("EARLY EXIT")
			return
	
	current_path = path
	current_dir = dir
	
	miller.current_path = current_path
	
	_path_in_res = FSUtil.is_path_valid_res(current_path)
	
	_set_path_in_res()
	if _path_in_res:
		filesystem_singleton.select_items_in_fs(current_selected_paths)
		#^r this may need some more coordination
	
	if _current_browser_state == BrowserState.SEARCH:
		if _current_view_mode == ViewMode.TREE:
			pass
		elif _current_view_mode == ViewMode.PLACES:
			pass
		elif _current_view_mode == ViewMode.MILLER:
			miller.set_current_dir_search(current_dir)
		return
	
	#if who != tree and _path_in_res:
		#tree.select_paths([current_path], false, who == path_bar)
	
	if _current_split_mode != SplitMode.NONE: #^ need to sort out when and what fires these.
		item_list_set_current_dir()
	if current_path == FAVORITES_META:
		return
	
	path_bar.set_current_dir(current_path)
	
	if _current_view_mode == ViewMode.MILLER:
		var force_show = who == path_bar or who == places
		miller.set_current_dir(current_dir, false, force_show)
	
	print("SET CURRENT PATH")
	#if _current_browser_state == BrowserState.SEARCH:
		#_set_filter_texts()


func _on_path_bar_path_selected(path:String):
	_set_current_path(path_bar, path)

func _on_places_path_selected(path:String):
	_set_current_path(places, path)

func _on_miller_path_selected(path:String, selected_paths:Array):
	current_selected_paths = selected_paths
	_set_current_path(miller, path)

func _on_tree_item_selected(path:String, selected_paths:Array):
	current_selected_paths = selected_paths
	_set_current_path(tree, path)

func _on_item_list_item_selected(path:String, selected_paths:Array):
	current_selected_paths = selected_paths
	if _current_browser_state == BrowserState.SEARCH:
		_set_current_path(item_list, path)




func item_list_set_current_path():
	item_list.set_current_path(current_path, true, _recursive_view)

func item_list_set_current_dir(path:=current_dir):
	item_list.set_current_path(path, true, _recursive_view)

func _on_item_list_double_clicked(path):
	if not path.ends_with("/"):
		_on_double_clicked(path)
		return
	_set_current_path(item_list, path)

func _on_double_clicked(selected_path:String):
	current_selected_paths = [selected_path]
	if _path_in_res:
		var selected_in_fs = filesystem_singleton.ensure_items_selected([selected_path])
		if not selected_in_fs:
			return
		filesystem_singleton.activate_in_fs()
	else:
		NonResHelper.open_file(selected_path)

func _on_item_right_clicked(clicked_node:Node, selected_item_path:String, selected_paths:Array):
	current_selected_paths = selected_paths
	if _path_in_res:
		fs_popup_handler.right_clicked(clicked_node, selected_item_path, selected_paths)
	else:
		var options = non_res_helper.get_right_click_options(selected_item_path, selected_paths)
		right_click_handler.display_popup(options)
		

func _on_item_right_clicked_empty(clicked_node:Node, selected_item_path:String):
	current_selected_paths = [selected_item_path]
	if _path_in_res:
		fs_popup_handler.right_clicked_empty_item_list(clicked_node, selected_item_path)
	else:
		var options = non_res_helper.get_right_click_options(selected_item_path, [])
		right_click_handler.display_popup(options)


func _on_places_right_clicked(index:int, place_list:FileSystemPlaces.PlaceList):
	var item_title = place_list.get_item_title(index)
	var options = RightClickHandler.Options.new()
	options.add_option("Rename", place_list.rename_item.bind(index), ["Edit"])
	options.add_option("Remove", place_list.remove_item.bind(index), ["Close"])
	right_click_handler.display_popup(options)

func _on_places_title_right_clicked(place_list:FileSystemPlaces.PlaceList) -> void:
	var options = RightClickHandler.Options.new()
	options.add_option("New Category", places.add_place_list.bind(place_list), ["New"])
	options.add_option("Rename", place_list.rename_title, ["Edit"])
	if places.get_place_list_count() > 1:
		options.add_option("Remove", places.remove_place_list.bind(place_list), ["Close"])
	
	right_click_handler.display_popup(options)

func _on_path_bar_right_clicked(path:String):
	var options = places.get_add_to_places_options(path)
	right_click_handler.display_popup(options)


func _on_options_button_pressed():
	var options = RightClickHandler.Options.new()
	
	var view_icon = EditorInterface.get_editor_theme().get_icon("TexturePreviewChannels", "EditorIcons")
	var vm = _current_view_mode
	var mp_tree = "View Mode/Tree"
	var mp_place = "View Mode/Places"
	var mp_miller = "View Mode/Columns"
	options.add_radio_option(mp_tree, _change_view_mode.bind(ViewMode.TREE), vm == ViewMode.TREE, [view_icon, _tree_icon()])
	options.add_radio_option(mp_place, _change_view_mode.bind(ViewMode.PLACES), vm == ViewMode.PLACES, [view_icon, _places_icon()])
	options.add_radio_option(mp_miller, _change_view_mode.bind(ViewMode.MILLER), vm == ViewMode.MILLER, [view_icon, _miller_icon()])
	
	var sv = _current_search_view
	options.add_radio_option("Search/View/Auto", _set_search_view.bind(SearchView.AUTO), sv == SearchView.AUTO, ["Search","ViewportZoom",view_icon])
	options.add_radio_option("Search/View/Item List", _set_search_view.bind(SearchView.ITEM_LIST), sv == SearchView.ITEM_LIST, ["Search","ViewportZoom",_places_icon()])
	options.add_option("Search/Set Path (%s)" % _search_select_path, func(): _search_select_path = not _search_select_path, ["Search", "Filesystem"])
	
	for _name in FSFilter.FilterMode.keys():
		var val = FSFilter.FilterMode[_name]
		var icons = ["Search", "FilenameFilter", null]
		options.add_radio_option("Search/Filter Mode/" + _name, func():_current_filter_mode = val, _current_filter_mode == val, icons)
	
	if _current_view_mode == ViewMode.TREE:
		options.add_option("Item List/Change Split Mode", _change_split_mode, [_places_icon(), _get_split_icon()])
		if _current_split_mode != SplitMode.NONE:
			options.add_option(_get_recursive_string(), _set_recursive_view, [_get_recursive_icon()])
		else:
			options.add_option("Tree/Preview Icons", _set_preview_icons, [_tree_icon(), "ImageTexture"])
	
	if _current_split_mode != SplitMode.NONE:
		var string = _get_display_as_list_string()
		options.add_option(string, _set_display_as_list, _get_display_as_list_icon())
		options.add_option_data(string, [Color(5,5,5), null])
	
	
	options.add_option("Element/Toggle Path Bar", _on_path_bar_button_pressed.bind(true), ["GuiVisibilityVisible","CopyNodePath"])
	
	if _current_view_mode == ViewMode.TREE:
		options.add_option("Element/Toggle Side Bar", func():places.visible = not places.visible, ["Favorites"])
	
	var element_options = _get_hidden_element_options()
	options.merge(element_options)
	
	var popup_pos = right_click_handler.get_centered_control_position(options_button)
	right_click_handler.display_popup(options, true, popup_pos)



func _change_split_mode():
	_current_split_mode += 1
	if _current_split_mode >= SplitMode.size():
		_current_split_mode = 0
	_set_split_mode()
	await _rebuild_tree()
	refresh_current_path()

func _set_split_mode(split_mode:SplitMode=_current_split_mode):
	tree.show_files = false
	if split_mode == SplitMode.NONE:
		item_vbox.hide()
		tree.show_files = true
	elif split_mode == SplitMode.HORIZONTAL:
		item_vbox.show()
		main_split_container.vertical = false
	elif split_mode == SplitMode.VERTICAL:
		item_vbox.show()
		main_split_container.vertical = true

func _get_split_icon():
	if _current_split_mode == SplitMode.NONE:
		return EditorInterface.get_editor_theme().get_icon("Panels1", "EditorIcons")
	elif _current_split_mode == SplitMode.HORIZONTAL:
		return EditorInterface.get_editor_theme().get_icon("Panels2", "EditorIcons")
	elif _current_split_mode == SplitMode.VERTICAL:
		return EditorInterface.get_editor_theme().get_icon("Panels2Alt", "EditorIcons")

func _change_view_mode(view_mode:ViewMode):
	_get_view_data()
	_current_view_mode = view_mode
	_set_view_data()
	await _rebuild_tree() #^ maybe conditional
	refresh_current_path()

func _get_view_data():
	var data = {
		DataKeys.SPLIT_OFFSET: main_split_container.split_offset,
		DataKeys.SPLIT_MODE:_current_split_mode,
		DataKeys.ITEM_DISPLAY_LIST: item_list.display_as_list
		}
	if _current_view_mode == ViewMode.TREE:
		_view_data[DataKeys.VIEW_DATA_TREE] = data
	elif _current_view_mode == ViewMode.PLACES:
		_view_data[DataKeys.VIEW_DATA_PLACES] = data
	elif _current_view_mode == ViewMode.MILLER:
		_view_data[DataKeys.VIEW_DATA_MILLER] = data


func _set_view_data():
	var data
	if _current_view_mode == ViewMode.TREE:
		data = _view_data.get(DataKeys.VIEW_DATA_TREE, {})
	elif _current_view_mode == ViewMode.PLACES:
		data = _view_data.get(DataKeys.VIEW_DATA_PLACES, {})
	elif _current_view_mode == ViewMode.MILLER:
		data = _view_data.get(DataKeys.VIEW_DATA_MILLER, {})
	
	main_split_container.split_offset = data.get(DataKeys.SPLIT_OFFSET, 0)
	_current_split_mode = data.get(DataKeys.SPLIT_MODE, SplitMode.NONE)
	if _current_view_mode != ViewMode.TREE:
		if _current_split_mode == SplitMode.NONE:
			_current_split_mode = SplitMode.HORIZONTAL
	
	item_list.set_display_as_list(data.get(DataKeys.ITEM_DISPLAY_LIST, false))
	
	_set_view_mode()
	_set_split_mode()

func _set_view_mode():
	if _current_view_mode == ViewMode.TREE:
		tree.show()
		if _current_split_mode != SplitMode.NONE:
			item_list.show()
		places.hide()
		miller.hide()
	elif _current_view_mode == ViewMode.PLACES:
		places.show()
		item_list.show()
		tree.hide()
		miller.hide()
	elif _current_view_mode == ViewMode.MILLER:
		places.show()
		miller.show()
		tree.hide()
		item_list.hide()
	
	item_list.current_view_mode = _current_view_mode

func _set_display_as_list():
	item_list.set_display_as_list(not item_list.display_as_list)

func _get_display_as_list_string():
	if item_list.display_as_list:
		return "Item List/Grid View"
	else:
		return "Item List/List View"

func _get_display_as_list_icon():
	var item_icon = EditorInterface.get_editor_theme().get_icon("ItemList", "EditorIcons")
	var list_icon = null
	if item_list.display_as_list:
		list_icon = EditorInterface.get_editor_theme().get_icon("FileThumbnail", "EditorIcons")
	else:
		list_icon = EditorInterface.get_editor_theme().get_icon("AnimationTrackList", "EditorIcons")
	return [item_icon, list_icon]

func _set_recursive_view():
	_recursive_view = not _recursive_view
	#item_list_set_current_path()
	refresh_current_path()

func _get_recursive_string():
	if _recursive_view:
		return "Item List/List Folder"
	return "Item List/List Deep"

func _get_recursive_icon():
	if _recursive_view:
		return EditorInterface.get_editor_theme().get_icon("Filesystem", "EditorIcons")
	return EditorInterface.get_editor_theme().get_icon("FileTree", "EditorIcons")

func _set_preview_icons():
	tree.show_item_preview = not tree.show_item_preview
	_rebuild_tree()

func _set_search_setting():
	pass

func _set_search_view(search_view:SearchView):
	_current_search_view = search_view
	if _current_browser_state == BrowserState.SEARCH:
		_set_filter_texts()


func check_toolbar_elements():
	_toolbar_debounce_timer.start(0.2)

func _on_toolbar_debounce_timeout() -> void:
	_check_toolbar_elements()

func _check_toolbar_elements():
	var elements = [path_bar, search_label]
	var _show_tool_bar = true
	for e in elements:
		if e.visible:
			_show_tool_bar = false
			break
	tool_bar_spacer.visible = _show_tool_bar
	
	var show_sep = false
	for control in tool_bar_hbox.get_children():
		if control is VSeparator:
			control.visible = show_sep
			show_sep = false
			continue
		if control.visible and control != tool_bar_spacer:
			show_sep = true #^ not sure about the seperators
			pass
	
	if search_hbox.visible:
		var _show_search = false
		for f in filters:
			if f.visible:
				_show_search = true
				break
		_search_bar_spacer.visible = not _show_search
		if file_type_filter.visible:
			_show_search = true
		search_hbox.visible = _show_search
	
	
	
	var show_buttons = true
	if size.x < 500 and (path_bar.visible or search_label.visible):
		show_buttons = false
	
	_toggle_element_respect_meta(_toggle_places_button, show_buttons)
	_toggle_element_respect_meta(_toggle_path_button, show_buttons)
	_toggle_element_respect_meta(_tree_button, show_buttons)
	_toggle_element_respect_meta(_places_button, show_buttons)
	_toggle_element_respect_meta(_miller_button, show_buttons)
	

func _on_navigate_up():
	if current_path == FAVORITES_META:
		return
	if FSUtil.is_root_folder(current_dir):
		return
	var dir = UFile.get_dir(current_dir)
	_set_current_path(self, dir)

func _on_path_bar_button_pressed(show_hide:=false):
	if show_hide:
		_toggle_element(path_bar, not path_bar.visible)
		#path_bar.visible = not path_bar.visible
	else:
		if not path_bar.visible:
			_toggle_element(path_bar, true)
		else:
			path_bar.toggle_view_mode()
	_check_toolbar_elements()

func _on_search_pressed():
	if search_hbox.visible:
		file_type_filter.select(0)
		_on_filter_type_selected(0)
		for f in filters:
			f.clear()
		search_hbox.visible = false
		return
	search_hbox.visible = true
	var has_visible = false
	for f in filters:
		if f.visible:
			has_visible = true
			break
	
	if not has_visible:
		var unhidden_filters = []
		for f in filters:
			var _hidden = _get_hidden_meta(f)
			if not _hidden:
				unhidden_filters.append(f)
		if unhidden_filters.is_empty() and not file_type_filter.visible:
			unhidden_filters = [filters[0]]
		for f in unhidden_filters:
			f.show()
			_set_hidden_meta(f, true)
	
	_check_toolbar_elements()

func _toggle_element_respect_meta(control:Control, toggled:bool):
	var meta = _get_hidden_meta(control)
	if toggled:
		if meta:
			return
		control.show()
	else:
		control.hide()

func _toggle_element(control:Control, toggled:bool):
	control.visible = toggled
	_set_hidden_meta(control, toggled)
	_check_toolbar_elements()

func _set_hidden_meta(control:Control, is_vis:bool):
	if is_vis:
		control.set_meta(&"hidden_element", null)
	else:
		control.set_meta(&"hidden_element", true)

func _get_hidden_meta(control:Control):
	return control.get_meta(&"hidden_element", false)

func _on_togglable_gui_input(event:InputEvent, control:Control):
	if event is InputEventMouseButton:
		if event.button_mask == 2:
			if control is LineEdit:
				var control_rect = control.get_rect()
				var icon_size
				if control.right_icon:
					icon_size = control.right_icon.get_size()
				else:
					icon_size = Vector2(16, control_rect.size.y)
				var icon_rect = control_rect
				icon_rect.position.x = icon_rect.size.x - icon_size.x
				icon_rect.size.x = icon_size.x
				if not icon_rect.has_point(event.position):
					return
			
			var icon = EditorInterface.get_editor_theme().get_icon("GuiVisibilityHidden", "EditorIcons")
			var options = RightClickHandler.Options.new()
			options.add_option("Hide", _toggle_element.bind(control, false),[icon])
			right_click_handler.display_popup(options)
			if control is LineEdit:
				control.context_menu_enabled = false
				await right_click_handler.popup_hidden
				control.context_menu_enabled = true

func _get_hidden_element_options():
	var options = RightClickHandler.Options.new()
	var element_icon = EditorInterface.get_editor_theme().get_icon("GuiVisibilityVisible", "EditorIcons")
	for element in togglable_elements:
		var meta = _get_hidden_meta(element)
		if not meta:
			continue
		var _class = element.get_class()
		var msg = "Element/Show %s (%s)" % [element.name, _class]
		var class_icon = EditorInterface.get_editor_theme().get_icon(_class, "EditorIcons")
		options.add_option(msg, _toggle_element.bind(element, true), [element_icon, class_icon])
	return options



func _build_nodes():
	if is_instance_valid(tree):
		return
	
	_toolbar_debounce_timer = Timer.new()
	add_child(_toolbar_debounce_timer)
	_toolbar_debounce_timer.timeout.connect(_on_toolbar_debounce_timeout)
	_toolbar_debounce_timer.one_shot = true
	
	_filter_timer = Timer.new()
	add_child(_filter_timer)
	_filter_timer.timeout.connect(_set_filter_texts)
	_filter_timer.one_shot = true
	
	right_click_handler = RightClickHandler.new()
	add_child(right_click_handler)
	
	non_res_helper = NonResHelper.new()
	
	
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	
	#var spacer = Control.new()
	#add_child(spacer)
	
	tool_bar_hbox = HBoxContainer.new()
	add_child(tool_bar_hbox)
	tool_bar_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tool_bar_hbox.resized.connect(check_toolbar_elements)
	
	var toggle_callable = func():places.visible = not places.visible
	_toggle_places_button = _new_button(true, "Favorites", toggle_callable, "Toggle Side Bar")
	tool_bar_hbox.add_child(_toggle_places_button) #^ not sure about this, dont want to toggle in other modes
	
	_toggle_path_button = _new_button(true,"CopyNodePath", _on_path_bar_button_pressed, "Path Toggle")
	tool_bar_hbox.add_child(_toggle_path_button)
	
	var navigate_up_button = _new_button(true, "MoveUp",_on_navigate_up, "Navigate Up")
	tool_bar_hbox.add_child(navigate_up_button)
	
	var sep_1 = VSeparator.new()
	tool_bar_hbox.add_child(sep_1)
	sep_1.hide()
	
	path_bar = FileSystemPathBar.new()
	tool_bar_hbox.add_child(path_bar)
	path_bar.name = "Path Bar"
	
	search_label = Label.new()
	tool_bar_hbox.add_child(search_label)
	search_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_label.clip_text = true
	search_label.mouse_filter = Control.MOUSE_FILTER_STOP
	#search_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	search_label.hide()
	
	tool_bar_spacer = Control.new()
	tool_bar_hbox.add_child(tool_bar_spacer)
	tool_bar_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#tool_bar_spacer.hide()
	
	search_hbox = HBoxContainer.new()
	add_child(search_hbox)
	search_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_hbox.hide()
	
	_search_bar_spacer = Control.new()
	search_hbox.add_child(_search_bar_spacer)
	_search_bar_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_bar_spacer.hide()
	
	var line_edit = LineEdit.new()
	line_edit.clear_button_enabled = true
	search_hbox.add_child(line_edit)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.name = "Filter 1"
	line_edit.right_icon = EditorInterface.get_base_control().get_theme_icon("Search", "EditorIcons")
	line_edit.placeholder_text = "Filter Files"
	line_edit.text_changed.connect(_on_filter_text_changed)
	
	var line_edit_2  = LineEdit.new()
	line_edit_2.clear_button_enabled = true
	search_hbox.add_child(line_edit_2)
	line_edit_2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit_2.name = "Filter 2"
	line_edit_2.right_icon = EditorInterface.get_base_control().get_theme_icon("Search", "EditorIcons")
	line_edit_2.placeholder_text = "Filter Files"
	line_edit_2.text_changed.connect(_on_filter_text_changed)
	
	filters = [line_edit, line_edit_2]
	for f:LineEdit in filters:
		f.visibility_changed.connect(func():if not f.visible:f.clear(), 1)
	
	file_type_filter = OptionButton.new()
	search_hbox.add_child(file_type_filter)
	file_type_filter.item_selected.connect(_on_filter_type_selected)
	file_type_filter.allow_reselect = true
	file_type_filter.focus_mode = Control.FOCUS_NONE
	file_type_filter.name = "File Type Filter"
	file_type_filter.add_icon_item(EditorInterface.get_editor_theme().get_icon("FilenameFilter", "EditorIcons"), _NO_FILTER_NAME)
	file_type_filter.add_icon_item(EditorInterface.get_editor_theme().get_icon("File", "EditorIcons"), "All")
	for _name in FSFilter.Types.get_categories():
		var icon = EditorInterface.get_editor_theme().get_icon(FSFilter.Types.get_icon(_name), "EditorIcons")
		file_type_filter.add_icon_item(icon, _name)
	
	
	var sep_2 = VSeparator.new()
	tool_bar_hbox.add_child(sep_2)
	sep_2.hide()
	

	
	_tree_button = _new_button(true, _tree_icon(), _change_view_mode.bind(ViewMode.TREE), "Tree View")
	tool_bar_hbox.add_child(_tree_button)
	
	_places_button = _new_button(true, _places_icon(), _change_view_mode.bind(ViewMode.PLACES), "Places View", true)
	tool_bar_hbox.add_child(_places_button)
	
	_miller_button = _new_button(true, _miller_icon(), _change_view_mode.bind(ViewMode.MILLER), "Column View", true)
	tool_bar_hbox.add_child(_miller_button)
	
	var search_button = _new_button(true,"Search", _on_search_pressed, "Search Toggle")
	tool_bar_hbox.add_child(search_button)
	
	options_button = _new_button(false, "TripleBar", _on_options_button_pressed,)
	tool_bar_hbox.add_child(options_button)
	
	#^ split
	main_split_container = SplitContainer.new()
	add_child(main_split_container)
	main_split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	#^ tree side
	tree_vbox = SplitContainer.new()
	tree_vbox.vertical = false
	main_split_container.add_child(tree_vbox)
	tree_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#tree_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	places = FileSystemPlaces.new()
	tree_vbox.add_child(places)
	
	tree = FileSystemTree.new()
	tree_vbox.add_child(tree)
	tree.owner = self
	
	#^ split side
	item_vbox = VBoxContainer.new()
	main_split_container.add_child(item_vbox)
	item_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	item_list = FileSystemItemList.new()
	item_vbox.add_child(item_list)
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	miller = FileSystemMiller.new()
	item_vbox.add_child(miller)
	
	
	fs_popup_handler = FSPopupHandler.new()
	fs_popup_handler.filesystem_tab = self
	fs_popup_handler.tree = tree
	fs_popup_handler.item_list = item_list
	fs_popup_handler.places = places
	
	
	fs_popup_handler.new_tab.connect(_on_rc_new_tab)
	fs_popup_handler.add_to_places.connect(_on_add_to_places)
	
	non_res_helper.places = places
	
	item_list.navigate_up.connect(_on_navigate_up)
	
	
	path_bar.path_selected.connect(_on_path_bar_path_selected)
	places.path_selected.connect(_on_places_path_selected)
	
	tree.left_clicked.connect(_on_tree_item_selected)
	item_list.left_clicked.connect(_on_item_list_item_selected)
	miller.left_clicked.connect(_on_miller_path_selected)
	
	tree.double_clicked.connect(_on_double_clicked)
	miller.double_clicked.connect(_on_double_clicked)
	item_list.double_clicked.connect(_on_item_list_double_clicked)
	
	path_bar.right_clicked.connect(_on_path_bar_right_clicked)
	places.right_clicked.connect(_on_places_right_clicked)
	tree.right_clicked.connect(_on_item_right_clicked)
	item_list.right_clicked.connect(_on_item_right_clicked)
	item_list.right_clicked_empty.connect(_on_item_right_clicked_empty)
	miller.right_clicked.connect(_on_item_right_clicked)
	
	
	places.title_right_clicked.connect(_on_places_title_right_clicked)
	
	togglable_elements.append_array([
		line_edit,
		line_edit_2,
		file_type_filter
	])
	line_edit.hide()
	_toggle_element(line_edit_2, false)
	for e in togglable_elements:
		e.gui_input.connect(_on_togglable_gui_input.bind(e))



func _new_button(hideable:=false, icon="", callable=null, _name="", icon_color:=false):
	var button = Button.new()
	if _name != "":
		button.name = _name
	if callable != null:
		button.pressed.connect(callable)
	if hideable:
		togglable_elements.append(button)
	if icon is Texture2D:
		button.icon = icon
	elif icon != "":
		button.icon = EditorInterface.get_editor_theme().get_icon(icon, "EditorIcons")
	button.theme_type_variation = &"MainScreenButton"
	button.focus_mode = Control.FOCUS_NONE
	if icon_color:
		var col = Color(5,5,5)
		button.add_theme_color_override("icon_disabled_color", col)
		button.add_theme_color_override("icon_hover_pressed_color", col)
		button.add_theme_color_override("icon_hover_color", col)
		button.add_theme_color_override("icon_pressed_color", col)
		button.add_theme_color_override("icon_focus_color", col)
		button.add_theme_color_override("icon_normal_color", col)
		
	return button

func _tree_icon():
	return "FileTree"
	return _get_modulated_icon("FileTree")
func _places_icon():
	return _get_modulated_icon("ItemList")
func _miller_icon():
	return _get_modulated_icon("HBoxContainer")


func _get_modulated_icon(text: String, brightness:=0.8) -> Texture2D:
	return ALibEditor.Singletons.EditorIcons.get_icon_white(text, brightness)

class DataKeys:
	const ROOT = &"ROOT"
	const CURRENT_PATH = &"CURRENT_PATH"
	const SPLIT_MODE = &"SPLIT_MODE"
	const SPLIT_OFFSET = &"SPLIT_OFFSET"
	
	const SEARCH_SELECT_PATH = &"SEARCH_SELECT_PATH"
	
	const TREE_ITEM_META = &"TREE_ITEM_META"
	const TREE_RECURSIVE_VIEW = &"TREE_RECURSIVE_VIEW"
	const TREE_PREVIEW_ICONS = &"TREE_PREVIEW_ICONS"
	
	const ITEM_DISPLAY_LIST = &"ITEM_DISPLAY_LIST"
	
	const PLACE_DATA = &"PLACE_DATA"
	
	const VIEW_MODE = &"VIEW_MODE"
	const VIEW_DATA = &"VIEW_DATA"
	const VIEW_DATA_TREE = &"VIEW_DATA_TREE"
	const VIEW_DATA_PLACES = &"VIEW_DATA_PLACES"
	const VIEW_DATA_MILLER = &"VIEW_DATA_MILLER"
	
	const GLOBAL_NEW_WINDOW_SIGNAL = &"GLOBAL_NEW_WINDOW_SIGNAL"
	pass
