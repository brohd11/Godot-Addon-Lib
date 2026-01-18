
static func is_path_valid_res(path:String) -> bool:
	if not path.begins_with("res://"):
		return false
	return FileSystemSingleton.is_path_valid(path)

static func is_root_folder(path:String):
	if path.ends_with("://") or path == "/":
		return true
	return false

static func paths_have_same_root(path:String, path_2:String):
	if path.begins_with("res://"):
		if path_2.begins_with("res://"):
			return true
		return false
	elif path.begins_with("user://"):
		if path_2.begins_with("user://"):
			return true
		return false
	elif path.begins_with("/"):
		if path_2.begins_with("/"):
			return true
		return false
