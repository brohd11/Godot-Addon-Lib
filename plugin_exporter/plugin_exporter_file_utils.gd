
const UFile = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_file.gd")
const UConfig = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_config.gd")
const USafeEditor = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_safe_editor.gd")

static func get_export_data(export_config_path):
	if not FileAccess.file_exists(export_config_path):
		print("Export file path does not exist.")
		return
	var export_file = FileAccess.open(export_config_path, FileAccess.READ)
	if export_file == null:
		printerr("Error opening export configuration file: " + export_config_path)
		return
	
	var config_string = export_file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(config_string)
	if parse_result != OK:
		printerr("Plugin Exporter - Error parsing JSON: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return
	return json.data

static func get_file_export_path(file_path:String, export_config_path:String, desired_export:int=-1):
	if not FileAccess.file_exists(file_path):
		printerr("Plugin Exporter - File doesn't exist: %s" % file_path)
		return
	
	var export_config_data = get_export_data(export_config_path)
	if export_config_data == null:
		return
	var exports = export_config_data.get(ExportFileKeys.exports, [])
	if exports.size() > 1 and desired_export == -1:
		USafeEditor.print_warn("Multiple exports, defaulting to first.")
	if desired_export == -1:
		desired_export = 0
	if desired_export > exports.size() - 1:
		printerr("Desired export index greater than exports in file.")
		return
	
	var export_root = get_export_root(export_config_path)
	
	var export_data = exports[desired_export]
	var export_folder = export_data.get(ExportFileKeys.export_folder)
	export_folder = replace_version(export_folder)
	var export_dir_path = export_root.path_join(export_folder)
	var other_transfers = export_data.get(ExportFileKeys.other_transfers, [])
	for transfer_data in other_transfers:
		var from = transfer_data.get(ExportFileKeys.from)
		if DirAccess.dir_exists_absolute(from):
			if not UFile.is_file_in_directory(file_path, from):
				continue
			var to_path = transfer_data.get(ExportFileKeys.to)
			var file_export_path = export_dir_path.path_join(to_path).path_join(file_path.get_file())
			return file_export_path
		else:
			if not file_path == from:
				continue
			var to_path = transfer_data.get(ExportFileKeys.to)
			var file_export_path = export_dir_path.path_join(to_path)
			return file_export_path
	
	var exclude = export_data.get(ExportFileKeys.exclude, {})
	var exclude_dirs = exclude.get(ExportFileKeys.directories, [])
	for dir in exclude_dirs:
		if UFile.is_file_in_directory(file_path, dir):
			USafeEditor.print_warn("File dir is excluded from export.")
			return
	var exclude_files = export_data.get(ExportFileKeys.files, [])
	for file in exclude_files:
		if file == file_path:
			USafeEditor.print_warn("File is excluded from export.")
			return
	var exclude_extensions = export_data.get(ExportFileKeys.file_extensions, [])
	for ext in exclude_extensions:
		if file_path.get_extension() == ext:
			USafeEditor.print_warn("File extension is excluded from export.")
			return
	
	var source = export_data.get(ExportFileKeys.source)
	if not UFile.is_file_in_directory(file_path, source):
		USafeEditor.print_warn("File not found in export source folder.")
		return
	
	var file_export_path = file_path.replace(source, export_dir_path)
	return file_export_path


static func get_version(folder):
	var addons_folder = "res://addons"
	var target_folder = addons_folder.path_join(folder)
	var plugin_cfg_path = target_folder.path_join("plugin.cfg")
	if not FileAccess.file_exists(plugin_cfg_path):
		plugin_cfg_path = target_folder.path_join("version.cfg")
	if not FileAccess.file_exists(plugin_cfg_path):
		USafeEditor.push_toast("Plugin or version file not present: " + plugin_cfg_path + ", Aborting.", 2)
		return
	var plugin_data = UConfig.load_config_data(plugin_cfg_path)
	if not plugin_data:
		USafeEditor.push_toast("Issue getting plugin data. Aborting.", 2)
		return 
	return plugin_data.get_value("plugin", "version", "No version")


static func replace_version(input_text: String) -> String:
	var output_text = ""
	var slice_count = input_text.get_slice_count("/")
	var regex = RegEx.new()
	var pattern = r"\{\{version=([^}]*)\}\}"
	regex.compile(pattern)
	for i in range(slice_count):
		var slice = input_text.get_slice("/", i)
		var edited_slice
		if slice.find("{{version=") > -1:
			var _match = regex.search(slice)
			var version_target = _match.get_string(1)
			var version = get_version(version_target)
			if version:
				version = "-" + version
				edited_slice = regex.sub(slice, version)
			else:
				edited_slice = regex.sub(slice, "{{version error}}")
				return ""
		elif slice.find("{{version}}") > -1:
			var version_target = slice.replace("{{version}}", "")
			var version = get_version(version_target)
			if version:
				version = "-" + version
				edited_slice = slice.replace("{{version}}", version)
			else:
				edited_slice = slice.replace("{{version}}", "{{version error}}")
				return ""
		else:
			edited_slice = slice
		if edited_slice != "":
			output_text += edited_slice + "/"
	
	return output_text


static func get_export_root(export_config_path):
	var export_data = get_export_data(export_config_path)
	if not export_data:
		return ""
	var _export_root = export_data.get(ExportFileKeys.export_root, "No root set.")
	var plugin_folder = export_data.get(ExportFileKeys.plugin_folder)
	if plugin_folder:
		_export_root = _export_root.path_join(plugin_folder)
	_export_root = replace_version(_export_root)
	if _export_root == "":
		return ""
	#if _export_root.ends_with("/"):
		#_export_root = _export_root.trim_suffix("/")
	if not _export_root.ends_with("/"):
		_export_root = _export_root + "/"
	
	var os_name = OS.get_name()
	if os_name == "Linux" or os_name == "macOS": # not sure about mac
		if not _export_root.begins_with("/"):
			_export_root = "/" + _export_root
	
	return _export_root


static func export_file(from, to, export_uid_file, export_import_file):
	var to_dir = to.get_base_dir()
	if not DirAccess.dir_exists_absolute(to_dir):
		DirAccess.make_dir_recursive_absolute(to_dir)
	DirAccess.copy_absolute(from, to)
	
	var from_uid = from + ".uid"
	var to_uid = to + ".uid"
	if FileAccess.file_exists(from_uid) and export_uid_file:
		DirAccess.copy_absolute(from_uid, to_uid)
	var from_import = from + ".import"
	var to_import = to + ".import"
	if FileAccess.file_exists(from_import) and export_uid_file:
		DirAccess.copy_absolute(from_import, to_import)

class ExportFileKeys:
	const export_root = "export_root"
	const plugin_folder = "plugin_folder"
	const pre_script = "pre_script"
	const post_script = "post_script"
	
	const exports = "exports"
	const source = "source"
	const export_folder = "export_folder"
	const exclude = "exclude"
	const directories = "directories"
	const file_extensions = "file_extensions"
	const files = "files"
	
	const other_transfers = "other_transfers"
	const from = "from"
	const to = "to"
	
	const options = "options"
	const include_import = "include_import"
	const include_uid = "include_uid"
	const overwrite = "overwrite"
