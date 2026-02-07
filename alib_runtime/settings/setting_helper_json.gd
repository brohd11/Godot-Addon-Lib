#! namespace ALibRuntime.Settings class SettingHelperJson

extends "res://addons/addon_lib/brohd/alib_runtime/settings/components/settings_helper_file_base.gd"

const SettingsObjectJson = preload("res://addons/addon_lib/brohd/alib_runtime/settings/components/settings_object_json.gd")

var settings_object:SettingsObjectJson

var convert_str_to_var:=false

func set_file_path(path:String):
	settings_object = SettingsObjectJson.new(path)

func connect_trigger_signal(_signal:Signal):
	settings_object.connect_trigger_signal(_signal)

func _get_settings_object():
	return settings_object

func _set_setting(setting_name:String, settings_obj, value:Variant):
	if convert_str_to_var:
		value = var_to_str(value)
	settings_obj.set_setting(setting_name, value)

func _get_setting(setting_string:String, settings_obj):
	var setting = settings_obj.get_setting(setting_string)
	if convert_str_to_var and setting is String:
		return str_to_var(setting)
	return setting
