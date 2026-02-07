
signal settings_changed

var _file_path:String
var _last_modified_time:int = -1

var _settings:= {}

var _save_to_file_on_change:=true

func _populate_dict():
	return

func _ensure_file_exists():
	return

func _save_to_file():
	return

func connect_trigger_signal(_signal:Signal):
	_signal.connect(check_file)

func _init(file_path:String) -> void:
	_file_path = file_path
	_ensure_file_exists()
	_populate_dict()

func check_file():
	var modified_time = FileAccess.get_modified_time(_file_path)
	if modified_time == _last_modified_time:
		return
	_last_modified_time = modified_time
	_populate_dict()
	settings_changed.emit()



func has_setting(setting_name:String):
	return _settings.has(setting_name)

func get_setting(setting_name:String):
	return _settings.get(setting_name)

func set_setting(setting_name:String, value:Variant):
	_settings[setting_name] = value
	_update_file()


func _update_file():
	if _save_to_file_on_change:
		_save_to_file()
		_last_modified_time = FileAccess.get_modified_time(_file_path)
		_populate_dict()
	settings_changed.emit()
	
