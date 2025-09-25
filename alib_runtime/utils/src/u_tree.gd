extends RefCounted
#! namespace ALib.Runtime class UTree

static func get_all_children_items(tree_item:TreeItem) -> Array[TreeItem]:
	return _get_all_children_items(tree_item)
static func get_all_visible_children_items(tree_item:TreeItem) -> Array[TreeItem]:
	return _get_all_children_items(tree_item, true)
static func _get_all_children_items(tree_item:TreeItem, limit_to_visible:=false) -> Array[TreeItem]:
	var items:Array[TreeItem] = []
	if not tree_item:
		return items
	if tree_item.get_child_count() > 0:
		var children:Array[TreeItem] = tree_item.get_children()
		for c in children:
			if limit_to_visible:
				if c.visible:
					items.append(c)
					items.append_array(_get_all_children_items(c, limit_to_visible))
			else:
				items.append(c)
				items.append_array(_get_all_children_items(c, limit_to_visible))
	
	return items


static func check_filter(text:String, filter_text:String) -> bool:
	if filter_text == "":
		return true # true == don't hide
	text = text.to_lower()
	if text.find(filter_text) > -1:
		return true
	return false

static func check_filter_split(text:String, filter_text:String) -> bool:
	if filter_text == "":
		return true # true == don't hide
	text = text.to_lower()
	var f_split := filter_text.split(" ", false)
	for s in f_split:
		if text.find(s) == -1:
			return false
	return true

static func uncollapse_items(items:Array, item_collapsed_callable:Callable):
	for item in items:
		var parent = item.get_parent()
		while parent:
			parent.collapsed = false
			item_collapsed_callable.call(parent)
			parent = parent.get_parent()

static func get_click_data_standard(selected_items):
	var right_click_data = []
	for i:TreeItem in selected_items:
		right_click_data.append(i)
		var child_items = get_all_visible_children_items(i)
		right_click_data.append_array(child_items)
	
	var item_data_array = []
	for item in right_click_data:
		var data = item.get_metadata(0)
		if not data:
			continue
		item_data_array.append(data)
	
	return item_data_array

static func find_item_by_meta(start_item: TreeItem, meta_value) -> TreeItem:
	var metadata = start_item.get_metadata(0)
	if metadata == meta_value:
		return start_item
	
	for child in start_item.get_children():
		var found_item = find_item_by_meta(child, meta_value)
		if found_item:
			return found_item
	
	return null

class get_drop_data:
	static func files(selected_item_paths, from_node):
		var data_type = "files"
		var selected_paths = []
		for path in selected_item_paths:
			if DirAccess.dir_exists_absolute(path):
				data_type = "files_and_dirs"
				if not path.ends_with("/"):
					path = path + "/"
				selected_paths.append(path)
			else:
				selected_paths.append(path)
		var data = {"type": data_type, "files": selected_paths, "from": from_node}
		
		return data

class can_drop_data:
	static func files(at_position: Vector2, data: Variant, extensions:Array=[]) -> bool:
		var type = data.get("type")
		if type == "files" or type == "files_and_dirs":
			if extensions == []:
				return true
			var files = data.get(type)
			for f in files:
				var ext = f.get_extension()
				if ext in extensions:
					return true
		return false
