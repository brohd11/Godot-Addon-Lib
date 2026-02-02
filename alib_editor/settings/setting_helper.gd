#! namespace ALibEditor.Settings class SettingHelperEditor

extends "res://addons/addon_lib/brohd/abstract/setting_helper_base.gd"

func _get_settings_object():
	return EditorInterface.get_editor_settings()
