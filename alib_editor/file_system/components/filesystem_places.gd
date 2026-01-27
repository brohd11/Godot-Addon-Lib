@tool
extends VBoxContainer

const MultiSplit = preload("res://addons/addon_lib/brohd/alib_runtime/ui/multi_split/multi_split.gd")

const PlaceList = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_place_list.gd")
const UFile = ALibRuntime.Utils.UFile

const Options = ALibRuntime.Popups.Options

const ADD_TO_PLACES_STRING = "Add to Places"
const _MIN_SIZE = Vector2(100,0)

var item_list_stylebox:StyleBoxFlat

signal path_selected(path:String)
signal right_clicked(index, place_list)
signal title_right_clicked(place_list)


var places:= {}

func _ready() -> void:
	custom_minimum_size = _MIN_SIZE
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func build_item_list(data:Dictionary):
	var pl_indexs = data.keys()
	pl_indexs.sort()
	for p_i in pl_indexs:
		var place_data = data[p_i]
		var title = place_data.get("title")
		var place_list = _new_place_list(title)
		place_list.split_offset = place_data.get("split_offset", 0)
		place_list.build_items(place_data.get("items",{}))

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
	place_list.item_list.add_theme_stylebox_override("panel", item_list_stylebox)
	place_list.path_selected.connect(_on_path_selected)
	place_list.right_clicked.connect(func(index, place_list):right_clicked.emit(index, place_list))
	place_list.title_right_clicked.connect(func(place_list):title_right_clicked.emit(place_list))
	place_list.move_lists.connect(_on_move_place_list)
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
	place_list.new_item(_name, path)

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
