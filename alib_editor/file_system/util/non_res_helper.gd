
const FileSystemPlaces = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/filesystem_places.gd")

const RightClickHandler = preload("res://addons/addon_lib/brohd/gui_click_handler/right_click_handler.gd")
const Options = ALibRuntime.Popups.Options

var places:FileSystemPlaces

func get_right_click_options(path:String, selected_paths:Array) -> Options:
	var options = Options.new()
	
	if FileAccess.file_exists(path):
		options.add_option("Open File", open_file.bind(path), ["Load"])
		options.add_option("Open Dir", open_file.bind(path.get_base_dir()),["Load"])
	elif DirAccess.dir_exists_absolute(path):
		options.add_option("Open Dir", open_file.bind(path),["Load"])
		var places_options = places.get_add_to_places_options(path)
		options.merge(places_options)
	
	
	return options


static func open_file(path:String):
	var global = ProjectSettings.globalize_path(path)
	OS.shell_open(global)
