#! namespace ALibRuntime.Settings class SettingHelperSingleton
extends Singleton.Base

## Implement in extended classes

# Use 'PE_STRIP_CAST_SCRIPT' to auto strip type casts with plugin exporter, if the class is not a global name
const PE_STRIP_CAST_SCRIPT = preload("res://addons/addon_lib/brohd/alib_runtime/settings/components/setting_helper_singleton.gd")

static func get_singleton_name() -> String:
	return "SettingHelperSingleton"

static func get_instance() -> PE_STRIP_CAST_SCRIPT:
	return _get_instance(PE_STRIP_CAST_SCRIPT)

static func instance_valid() -> bool:
	return _instance_valid(PE_STRIP_CAST_SCRIPT)

static func call_on_ready(callable, print_err:bool=true):
	_call_on_ready(PE_STRIP_CAST_SCRIPT, callable, print_err)

func _get_ready_bool() -> bool:
	return is_node_ready()


enum FileType{
	AUTO,
	JSON,
	CONFIG
}


static func get_file_helper(file_path:String, file_type:=FileType.AUTO):
	return get_instance().get_or_create_helper(file_path, file_type)

static func reset_file_helper(file_path:String):
	get_instance()._clear_helper(file_path)

var _settings_helpers:= {}

func get_or_create_helper(file_path:String, file_type:=FileType.AUTO):
	if _settings_helpers.has(file_path):
		return _settings_helpers[file_path]
	
	var ext = file_path.get_extension()
	var target_file_type = file_type
	if file_type == FileType.AUTO:
		match ext:
			"json": target_file_type = FileType.JSON
			"cfg": target_file_type = FileType.CONFIG
			_:printerr("Could not determine file type: %s" % file_path);return
	
	var helper
	if target_file_type == FileType.JSON:
		helper = ALibRuntime.Settings.SettingHelperJson.new()
	elif target_file_type == FileType.CONFIG:
		printerr("IMPLEMENT CONFIG HELPER")
		return
	
	helper.set_file_path(file_path)
	_settings_helpers[file_path] = helper
	return helper

func _clear_helper(file_path:String):
	_settings_helpers.erase(file_path)
