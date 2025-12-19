var _object:Object
var _settings_dict:Dictionary
var _default_dict:Dictionary
var _no_default:=false
var _subscribed:Dictionary = {}

func _get_settings_object():
	return

## Pass the object and a dictionary [StringName property, StringName setting] add setting to the dictionary to provide default value
func _init(object:Object, settings_dict:Dictionary={}, default_dict:Dictionary={}) -> void:
	_object = object
	_settings_dict = settings_dict
	_default_dict = default_dict

func initialize():
	if _no_default:
		printerr("Provide default settings in dictionary 'DEFAULTS'.")
		return
	
	var settings = _get_settings_object()
	_on_editor_settings_changed(settings)
	settings.settings_changed.connect(_on_editor_settings_changed.bind(settings))

func subscribe(property_name:StringName, setting_path:StringName, default_value=null):
	if not _default_dict.has(setting_path):
		if default_value == null:
			print("Setting has no default and none provided.")
			return
		else:
			_default_dict[setting_path] = default_value
	_subscribed[property_name] = setting_path

func _on_editor_settings_changed(settings):
	_process_dict(_settings_dict, settings)
	_process_dict(_subscribed, settings)

func _process_dict(dict:Dictionary, settings_obj):
	for property:StringName in dict.keys():
		var setting_string = dict.get(property)
		if not settings_obj.has_setting(setting_string):
			var default = _default_dict.get(setting_string)
			if default == null:
				default = _object.get(property)
				if default == null:
					printerr("Attempted setting '%s' with no default provided." % [setting_string])
					continue
			settings_obj.set_setting(setting_string, default)
		
		if not property in _object:
			printerr("Property not in object: %s -> %s" % [property, _object])
		_object.set(property, settings_obj.get_setting(setting_string))
