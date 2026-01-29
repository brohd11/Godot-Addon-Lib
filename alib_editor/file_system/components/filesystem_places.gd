@tool
extends VBoxContainer

const PlaceList = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_place_list.gd")

const CacheHelper = preload("res://addons/addon_lib/brohd/alib_runtime/cache_helper/cache_helper.gd")
const UFile = ALibRuntime.Utils.UFile
const Options = ALibRuntime.Popups.Options

const ADD_TO_PLACES_STRING = "Add to Places"
const _MIN_SIZE = Vector2(100,0)
const PROJECT_PLACES_FILE = "user://addons/filesystem_instances/places.json"

const PROJECT_PLACES_UPDATED_SIGNAL = &"FI_PROJECT_PLACES_UPDATED"

signal path_selected(path:String)
signal right_clicked(index, place_list)
signal title_right_clicked(place_list)

var active:bool=true

var _places_cache:={}
var _last_places_hash:int=-1

var places:= {}

func _ready() -> void:
	custom_minimum_size = _MIN_SIZE
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	EditorGlobalSignals.subscribe(PROJECT_PLACES_UPDATED_SIGNAL, refresh)
	_initial_build()

func on_filesystem_changed():
	refresh()

func set_active(active_state:bool):
	active = active_state
	if active:
		refresh()

func save_and_refresh():
	_save_project_data()
	EditorGlobalSignals.signal_emit(PROJECT_PLACES_UPDATED_SIGNAL)

func _initial_build():
	var data = _get_project_data()
	build_item_list(data, true)

func refresh():
	if not active:
		return
	var data = _get_project_data()
	var hash = data.hash()
	if hash != _last_places_hash:
		build_item_list(data)
	_last_places_hash = hash

func _save_project_data():
	var place_data = get_place_data()
	UFile.write_to_json(place_data, PROJECT_PLACES_FILE)
	var json_data = UFile.read_from_json(PROJECT_PLACES_FILE)
	CacheHelper.store_data("project_places", json_data, _places_cache, [PROJECT_PLACES_FILE])

func _get_project_data():
	var data = CacheHelper.get_cached_data("project_places", _places_cache)
	if data != null:
		return data
	
	if not FileAccess.file_exists(PROJECT_PLACES_FILE):
		_save_project_data()
	data = UFile.read_from_json(PROJECT_PLACES_FILE)
	CacheHelper.store_data("project_places", data, _places_cache, [PROJECT_PLACES_FILE])
	return data


func clear_item_lists():
	for id in places.keys():
		var list = places[id]
		list.get_parent().remove_child(list)
		list.queue_free()
		places.erase(id)

func build_item_list(data:Dictionary, set_split:=false):
	var pl_indexs = data.keys()
	pl_indexs.sort()
	for p_i in pl_indexs:
		var place_data = data[p_i]
		var title = place_data.get("title")
		var int_id = int(p_i)
		var place_list = places.get(int_id)
		if not is_instance_valid(place_list):
			place_list = _new_place_list(title, int_id)
		else:
			place_list.set_title(title)
			place_list.item_list.clear()
		
		place_list.build_items(place_data.get("items",{}))
	
	for id in places.keys():
		var str_id = str(id)
		if str_id in pl_indexs:
			continue
		var list = places[id]
		if is_instance_valid(list):
			list.get_parent().remove_child(list)
			list.queue_free()
		places.erase(id)
	
	if set_split:
		set_split_offsets.call_deferred()

func set_split_offsets():
	var total_chain_size = places.size() - 1
	for i in range(total_chain_size):
		var split = places[i]
		split.split_offset = 0
		var content_node = split.get_child(0)
		var next_level_node = split.get_child(1)
		var items_remaining_down_chain = total_chain_size - i
		content_node.size_flags_stretch_ratio = 1.0
		next_level_node.size_flags_stretch_ratio = float(items_remaining_down_chain)

func _new_place_list(title:String, idx=-1):
	var place_list = PlaceList.new(title)
	if idx == -1:
		idx = places.size()
	var parent = self
	if places.size() > 0:
		var ids = places.keys()
		ids.sort()
		parent = places[ids[ids.size() - 1]]
	parent.add_child(place_list)
	
	places[idx] = place_list
	
	place_list.places_instance = self
	place_list.path_selected.connect(_on_path_selected)
	place_list.right_clicked.connect(func(index, place_list):right_clicked.emit(index, place_list))
	place_list.title_right_clicked.connect(func(place_list):title_right_clicked.emit(place_list))
	place_list.move_lists.connect(_on_move_place_list)
	place_list.list_changed.connect(save_and_refresh)
	return place_list


func _on_path_selected(path:String, place_list:PlaceList):
	_deseelect_place_list_items(place_list)
	path_selected.emit(path)

func _deseelect_place_list_items(current_pl:PlaceList):
	for place_list:PlaceList in places.values():
		if place_list != current_pl:
			place_list.item_list.deselect_all()
			place_list.item_list.queue_redraw()


func add_place_item(path:String, place_list:PlaceList):
	var _name = path.trim_suffix("/").get_file()
	if UFile.path_is_root(path):
		_name = path
	if not path.ends_with("/"):
		path += "/"
	place_list.new_item(_name, path) # refresh handled in new_item

func get_place_data():
	var data = {}
	for p_i in places.keys():
		var place_list = places.get(p_i)
		data[p_i] = {
			"title": place_list.get_title(),
			"items": place_list.get_place_data(),
			"split_offset": place_list.split_offset
		}
	return data

func add_place_list(place_list:PlaceList):
	var line = ALibRuntime.Dialog.LineSubmitHandler.on_control(place_list.title_button, false)
	var text = await line.line_submitted
	if text == "":
		return
	_new_place_list(text)
	
	save_and_refresh()

func remove_place_list(place_list:PlaceList):
	if place_list.get_item_count() > 0:
		var conf = ALibRuntime.Dialog.ConfirmationDialogHandler.new("Delete non empty list?", self)
		var handled = await conf.handled
		if not handled:
			return
	var target_idx = -1
	for idx in places.keys():
		if places[idx] == place_list:
			target_idx = idx
			break
	if target_idx > -1:
		var parent = place_list.get_parent()
		var child_list = _get_list_child(place_list)
		if child_list:
			child_list.reparent(parent)
		parent.remove_child(place_list)
		place_list.queue_free()
		_reindex_lists()
	else:
		print("Could not remove list.")
	
	save_and_refresh()

func _on_move_place_list(from:PlaceList, to:PlaceList):
	var from_is_ancestor = from.is_ancestor_of(to)
	var from_split = from.split_offset
	var to_split = to.split_offset
	if from_is_ancestor:
		_move_place_list(from, to)
	else:
		_move_place_list(to, from)
	
	to.split_offset = from_split
	from.split_offset = to_split
	
	_reindex_lists()
	save_and_refresh()

func _move_place_list(ancestor:PlaceList, child:PlaceList):
	var child_par = child.get_parent()
	var anc_par = ancestor.get_parent()
	var child_child = _get_list_child(child)
	var anc_child = _get_list_child(ancestor)
	if child_par == ancestor:
		child.reparent(anc_par)
		ancestor.reparent(child)
		if child_child:
			child_child.reparent(ancestor)
		return
	
	child_par.remove_child(child)
	anc_par.remove_child(ancestor)
	
	anc_par.add_child(child)
	if anc_child:
		ancestor.remove_child(anc_child)
		child.add_child(anc_child)
	child_par.add_child(ancestor)
	if child_child:
		child.remove_child(child_child)
		ancestor.add_child(child_child)

func _reindex_lists():
	places.clear()
	var place_list = get_child(0)
	var count = 0
	while is_instance_valid(place_list):
		places[count] = place_list
		count += 1
		place_list = _get_list_child(place_list)
	

func _get_list_child(list:PlaceList):
	if list.get_child_count() > 1:
		return list.get_child(1)
	return null

func has_place_list_name(_name:String):
	for pl:PlaceList in places.values():
		if pl.get_title() == _name:
			return true
	return false

func get_place_list_count():
	return places.size()

func get_add_to_places_options(path:String):
	var options = Options.new()
	for i in places.keys():
		var place_list:PlaceList = places[i]
		if place_list.has_path(path):
			continue
		var menu_path = ADD_TO_PLACES_STRING.path_join(place_list.get_title())
		options.add_option(menu_path, add_place_item.bind(path, place_list), ["ControlAlignLeftWide", null], {"place_list": place_list})
	return options


class Data:
	static func get_default_data():
		var home = ALibRuntime.Utils.UOs.get_home_dir()
		var editor_paths = EditorInterface.get_editor_paths()
		
		var _places = {
		"title":"Places",
		"items":{
			0:get_place_dict("res://","res://"),
			}
		}
		var other = {
			"title": "Other",
			"items":{
				0:get_place_dict("user://","user://"),
				1:get_place_dict("home",home),
				2:get_place_dict("Project Settings", editor_paths.get_project_settings_dir()),
				3:get_place_dict("Editor Config", editor_paths.get_config_dir())
			},
		}
		var data = {
				0:_places,
				1: other,
			}
		return data

	static func get_place_dict(_name:String, path:String):
		return {"name":_name, "path":path}
