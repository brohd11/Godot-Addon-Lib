extends SplitContainer

const FileSystemPlaces = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_places.gd")
const PlaceList = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_place_list.gd")

var label:Label
var item_list:ItemList

var _title:String = "Places"
var _hovered_title:=false
#var _preview_state:=0

signal path_selected(path:String, _self)
signal right_clicked(index, _self)
signal title_right_clicked(_self)
signal move_lists(from, to)


func _init(title:String) -> void:
	_title = title

func _ready() -> void:
	vertical = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	add_child(vbox)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	label = Label.new()
	label.text = _title
	vbox.add_child(label)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.gui_input.connect(_on_title_gui_input)
	label.draw.connect(_title_draw)
	label.mouse_exited.connect(func():_hovered_title = false;label.queue_redraw())
	label.set_drag_forwarding(_title_get_drag_data, _title_can_drop_data, _title_drop_data)
	
	item_list = ItemList.new()
	vbox.add_child(item_list)
	item_list.allow_reselect = true
	item_list.allow_rmb_select = true
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.item_clicked.connect(_on_item_clicked)
	item_list.item_selected.connect(_on_item_selected)
	item_list.set_drag_forwarding(_item_list_get_drag_data, _item_list_can_drop_data, _item_list_drop_data)


func build_items(data:Dictionary):
	var indexes = data.keys()
	indexes.sort()
	for index in indexes:
		var item_data = data[index]
		new_item(item_data["name"], item_data["path"])


func _on_item_selected(index:int):
	var item_path = item_list.get_item_metadata(index)
	path_selected.emit(item_path, self)

func _on_item_clicked(index:int, at_pos:Vector2, button_idx:int):
	if button_idx == 2:
		right_clicked.emit(index, self)

func has_path(path:String):
	for i in range(item_list.item_count):
		if item_list.get_item_metadata(i) == path:
			return true
	return false

func new_item(text:String, path:String):
	item_list.add_item(text)
	var i = item_list.item_count - 1
	item_list.set_item_metadata(i, path)
	item_list.set_item_tooltip(i, path)

func get_item_path(index:int):
	return item_list.get_item_metadata(index)

func get_item_title(index:int):
	return item_list.get_item_text(index)

func set_item_title(index:int, new_name:String):
	item_list.set_item_text(index, new_name)

func rename_item(index:int):
	var item_rect = item_list.get_item_rect(index)
	item_rect.position += ALibRuntime.Utils.UWindow.get_control_absolute_position(item_list)
	var line_edit = ALibRuntime.Dialog.LineSubmitHandler.new(self, item_rect)
	var current_name = get_item_title(index)
	line_edit.set_text(current_name, ALibRuntime.Dialog.LineSubmitHandler.SelectMode.ALL)
	var text = await line_edit.line_submitted
	if text == current_name or text == "":
		return
	set_item_title(index, text)

func remove_item(index:int):
	item_list.remove_item(index)

func move_item(from:int, to:int):
	item_list.move_item(from, to)

func get_title():
	return _title

func set_title(new_name:String):
	label.text = new_name
	_title = new_name

func rename_title():
	var rect = label.get_rect()
	rect.position += ALibRuntime.Utils.UWindow.get_control_absolute_position(label)
	var line = ALibRuntime.Dialog.LineSubmitHandler.new(self, rect)
	var submit = await line.line_submitted
	if submit == "" or submit == get_title():
		return
	set_title(submit)

func get_place_data():
	var data = {}
	for i in range(item_list.item_count):
		var _name = item_list.get_item_text(i)
		var _path = item_list.get_item_metadata(i)
		data[i] = FileSystemPlaces.Data.get_place_dict(_name, _path)
	return data

func get_place_paths():
	var paths = []
	for i in range(item_list.item_count):
		var _path = item_list.get_item_metadata(i)
		paths.append(_path)
	return paths

func _item_list_get_drag_data(at_position: Vector2) -> Variant:
	var from_item = item_list.get_item_at_position(at_position)
	var data = {
		"from": self,
		"from_item": from_item,
	}
	_set_drag_preview(get_item_title(from_item))
	return data

func _item_list_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var from = data.get("from") as PlaceList
	if from and from is PlaceList:
		if data.has("from_item"):
			var from_item = data["from_item"]
			var from_path = from.get_item_path(from_item)
			var _name = from.get_item_title(from_item)
			if not has_path(from_path):
				return true
			elif from != self:
				pass #^ maybe do this later TODO
				#_set_drag_preview("List already has path.")
			
	return false

func _item_list_drop_data(at_position: Vector2, data: Variant) -> void:
	var from = data.get("from") as PlaceList
	var from_item = data.get("from_item")
	if from == self:
		var to_item = item_list.get_item_at_position(at_position)
		move_item(from_item, to_item)
	else:
		var _name = from.get_item_title(from_item)
		var _path = from.get_item_path(from_item)
		from.remove_item(from_item)
		new_item(_name, _path)
		var to_item = item_list.get_item_at_position(at_position, true)
		if to_item == -1:
			return
		await get_tree().process_frame
		
		move_item(item_list.item_count - 1, to_item)

func _on_title_gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == 2:
			title_right_clicked.emit(self)

func _title_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var can_drop = _check_can_drop(data, "title")
	if can_drop and data.get("from") != self:
		_hovered_title = true
		label.queue_redraw()
		return true
	return false

func _title_drop_data(at_position: Vector2, data: Variant) -> void:
	_hovered_title = false
	var from = data.get("from")
	move_lists.emit(from, self)

func _title_get_drag_data(at_position: Vector2) -> Variant:
	var data = {
		"from": self,
		"title":true
	}
	_set_drag_preview(get_title())
	return data

func _title_draw():
	if _hovered_title:
		var accent_color = ALibEditor.Utils.UEditorTheme.ThemeColor.get_theme_color(ALibEditor.Utils.UEditorTheme.ThemeColor.Type.ACCENT)
		label.draw_rect(label.get_rect(), accent_color, false)

func _set_drag_preview(text):
	var preview = Label.new()
	preview.text = text
	set_drag_preview(preview)

func _check_can_drop(data:Dictionary, key:String):
	var from = data.get("from")
	if from and from is PlaceList:
		if data.has(key):
			return true
	return false
