
static func scan_efs(dir:String,file_types:Array, include_dirs=false, ignore_dirs:Array=[], show_ignore=false) -> PackedStringArray:
	var fs = EditorInterface.get_resource_filesystem()
	var fs_dir = fs.get_filesystem_path(dir)
	if fs_dir == null:
		return _scan_efs(fs, dir, file_types, include_dirs, ignore_dirs)
	return []

static func _scan_efs(fs:EditorFileSystem, dir:String, file_types:Array, include_dirs=false, ignore_dirs:Array=[]) -> PackedStringArray:
	var files:= PackedStringArray()
	if include_dirs:
		files.append(dir)
	var fs_dir:EditorFileSystemDirectory = fs.get_filesystem_path(dir)
	for i in fs_dir.get_subdir_count():
		var sub_dir = fs_dir.get_subdir(i)
		var path = sub_dir.get_path()
		if path in ignore_dirs:
			continue
		var recur_files = _scan_efs(fs, path, file_types, include_dirs, ignore_dirs)
		files.append_array(recur_files)
		
	
	for i in fs_dir.get_file_count():
		var path = fs_dir.get_file_path(i)
		if file_types == []:
			files.append(path)
			continue
		if path.to_lower().get_extension() in file_types:
			files.append(path)
	
	return files
