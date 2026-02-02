signal settings_changed

const PRINT_ERR = false

var _settings_dict:Dictionary
var _default_dict:Dictionary
var _no_default:=false
var _subscribed:Dictionary = {}

var _initialize_queued:bool = false

func _get_settings_object():
	return


## Pass the object and a dictionary [StringName property, StringName setting] add setting to the dictionary to provide default value
func _init(object:Object=null, settings_dict:Dictionary={}, default_dict:Dictionary={}) -> void:
	if object != null:
		subscribe_object(object)
	
	_settings_dict = settings_dict
	_default_dict = default_dict

func initialize():
	print("QUE ", _initialize_queued)
	if _no_default:
		printerr("Provide default settings in dictionary 'DEFAULTS'.")
		return
	if _initialize_queued:
		return
	_initialize_queued = true
	
	await Engine.get_main_loop().root.get_tree().process_frame
	var settings = _get_settings_object()
	_on_settings_changed(settings)
	if not settings.settings_changed.is_connected(_on_settings_changed):
		settings.settings_changed.connect(_on_settings_changed.bind(settings))
	
	_initialize_queued = false


func subscribe_object(object:Object):
	var script = object.get_script()
	var data = {Keys.NAME: str(object), Keys.SUBSCRIBED:{}}
	if script:
		data[Keys.PATH] = script.resource_path
	_subscribed[object] = data
	

func subscribe_property(object:Object, property_name:StringName, setting_path:StringName, default_value=null):
	subscribe(object, property_name, setting_path, default_value)

func subscribe(object:Object, property_name:StringName, setting_path:StringName, default_value=null):
	if not _default_dict.has(setting_path):
		if default_value == null:
			print("Setting has no default and none provided.")
			return
		else:
			_default_dict[setting_path] = default_value
	
	if not _subscribed.has(object):
		subscribe_object(object)
	var object_data = _subscribed.get(object)
	var subscribes = object_data.get(Keys.SUBSCRIBED)
	subscribes[property_name] = setting_path


func _on_settings_changed(settings):
	for object in _subscribed.keys():
		var data = _subscribed[object]
		if not is_instance_valid(object):
			if PRINT_ERR:
				var nm = data.get(Keys.NAME)
				var path = data.get(Keys.PATH, "")
				var text = "Cannot set setting on freed instance: %s" % nm
				if path != "":
					text += "\nPath: %s" % path
				printerr(text)
			_subscribed.erase(object)
			continue
		var subscribed = data.get(Keys.SUBSCRIBED, {})
		_process_dict(object, subscribed, settings)
		#_process_object(object, settings)
	
	settings_changed.emit()

func _process_object(object, settings):
	_process_dict(object, _settings_dict, settings)
	var obj_subscribes = _subscribed.get(object, {})
	_process_dict(object, obj_subscribes, settings)

func _process_dict(object:Object, dict:Dictionary, settings_obj):
	for property:StringName in dict.keys():
		var setting_string = dict.get(property)
		if not settings_obj.has_setting(setting_string):
			var default = _default_dict.get(setting_string)
			if default == null:
				default = object.get(property)
				if default == null:
					printerr("Attempted setting '%s' with no default provided." % [setting_string])
					continue
			settings_obj.set_setting(setting_string, default)
		
		if not property in object:
			printerr("Property not in object: %s -> %s" % [property, object])
		object.set(property, settings_obj.get_setting(setting_string))



class Keys:
	const NAME = &"NAME"
	const PATH = &"PATH"
	const SUBSCRIBED = &"SUBSCRIBED"
