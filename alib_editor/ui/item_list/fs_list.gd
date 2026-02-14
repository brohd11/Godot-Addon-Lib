#! namespace ALibEditor.UIHelpers class FileSystemItemList
@tool
extends ItemList

var get_preview_callable

var _item_list_sel_flag:= false

signal right_clicked
signal left_clicked

func _ready() -> void:
	item_clicked.connect(_on_item_clicked)
	multi_selected.connect(_on_item_multi_select)
	item_selected.connect(_on_item_selected)

func _on_item_selected(idx:int):
	#print(idx)
	pass

func _on_item_clicked(idx, _pos, mouse_button):
	if mouse_button == 1:
		if select_mode == SELECT_SINGLE:
			left_clicked.emit()
	elif mouse_button == 2:
		if not idx in get_selected_items():
			select(idx)
		right_clicked.emit()


func _on_item_multi_select(_idx:int, _selected:bool):
	if _item_list_sel_flag:
		return
	_item_list_sel_flag = true
	await get_tree().process_frame
	left_clicked.emit()
	_item_list_sel_flag = false

func add_fs_item(asset_path="", icon=null):
	add_icon_item(icon, true)
	var idx = item_count - 1
	if icon == null:
		_queue_preview(asset_path, idx)
		icon = EditorInterface.get_editor_theme().get_icon("FileMediumThumb", "EditorIcons")
	set_item_text(idx, asset_path.get_file().get_basename())
	set_item_metadata(idx, asset_path)


func get_item_paths():
	var paths = []
	for i in range(item_count):
		paths.append(get_item_metadata(i))
	return paths

func get_selected_paths():
	var paths = []
	for i in get_selected_items():
		paths.append(get_item_metadata(i))
	return paths

func select_paths(paths:Array):
	deselect_all()
	for p in paths:
		var idx = get_item_index_from_path(p)
		if idx != -1:
			select(idx, false)

func get_item_index_from_path(path:String):
	for i in range(item_count):
		if get_item_metadata(i) == path:
			return i
	return -1

func _queue_preview(asset_path:String, item_index:int):
	var ed_interface = Engine.get_singleton("EditorInterface")
	if not is_instance_valid(ed_interface):
		return
	ed_interface.get_resource_previewer().queue_resource_preview(asset_path, self, &"_preview_generated", item_index)

func _preview_generated(path, preview, _thumbnail, item:int):
	if preview == null:
		if not path.ends_with(".tscn"):
			return
		if not get_preview_callable is Callable:
			return
		preview = get_preview_callable.call(path)
		if preview == null:
			return
	
	set_item_icon(item, preview)
