#! namespace ALibRuntime.Settings class SettingHelperJson

extends "res://addons/addon_lib/brohd/abstract/setting_helper_base.gd"

const SettingsObjectJson = preload("res://addons/addon_lib/brohd/alib_runtime/settings/components/settings_object_json.gd")

var settings_object:SettingsObjectJson



func set_file_path(path:String):
	settings_object = SettingsObjectJson.new(path)

func connect_trigger_signal(_signal:Signal):
	settings_object.connect_trigger_signal(_signal)

func _get_settings_object():
	return settings_object

func set_setting(setting_name:String, value:Variant):
	settings_object.set_setting(setting_name, value)
