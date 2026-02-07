extends "res://addons/addon_lib/brohd/abstract/setting_helper_base.gd"

func set_save_to_file_on_change(state:bool):
	_get_settings_object()._save_to_file_on_change = state

func save_to_file():
	_get_settings_object()._save_to_file()

func set_setting(setting_string, val):
	var obj =  _get_settings_object()
	_set_setting(setting_string, obj, val)
	if not obj._save_to_file_on_change:
		settings_changed.emit()

func get_all_settings():
	var data = {}
	for _name in _get_settings_object()._settings.keys():
		data[_name] = get_setting(_name)
	return data
