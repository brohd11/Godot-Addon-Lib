@tool
extends ItemList

var get_preview_callable

func add_fs_item(asset_path="", icon=null):
	add_icon_item(icon, true)
	var idx = item_count - 1
	if icon == null:
		_queue_preview(asset_path, idx)
		icon = EditorInterface.get_editor_theme().get_icon("FileMediumThumb", "EditorIcons")
	set_item_text(idx, asset_path.get_file().get_basename())
	set_item_metadata(idx, asset_path)


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
