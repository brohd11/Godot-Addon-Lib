class_name EditorPanelSingleton
extends Singleton.Base

# Use 'PE_STRIP_CAST_SCRIPT' to auto strip type casts with plugin exporter, if the class is not a global name
const PE_STRIP_CAST_SCRIPT = preload("res://addons/addon_lib/brohd/alib_editor/editor_panel/panel_singleton.gd")
static func get_singleton_name() -> String:
	return "EditorPanel"

static func get_instance() -> EditorPanelSingleton:
	return _get_instance(PE_STRIP_CAST_SCRIPT)

static func instance_valid() -> bool:
	return _instance_valid(PE_STRIP_CAST_SCRIPT)

static func call_on_ready(callable, print_err:bool=true):
	_call_on_ready(PE_STRIP_CAST_SCRIPT, callable, print_err)

static func register_panel(_name:String, path:String) -> void:
	register_panel_data(create_registry_data(_name, path))

static func create_registry_data(_name:String, path:String) -> Dictionary:
	return {
		"name": _name,
		"path": path
	}

static func register_panel_data(data:Dictionary) -> void:
	var instance = get_instance()
	var path = data.get("path")
	if instance._panel_data.has(path):
		print("Path already registered in EditorPanelSingleton Panels: %s" % path)
		return
	instance._panel_data[path] = data

static func unregister_panel(path:String):
	var instance = get_instance()
	if instance._panel_data.has(path):
		instance._panel_data.erase(path)
		return
	print("Path not registered in EditorPanelSingleton Panels: %s" % path)

static func get_registered_panels():
	var instance = get_instance()
	var data = instance._panel_data
	var formatted_data = {}
	for path in data.keys():
		var panel_data = data.get(path)
		var _name = panel_data.get("name")
		_name = _get_unique_name(_name, formatted_data.keys())
		formatted_data[_name] = {
			"path":path
		}
	
	return formatted_data

static func register_tab(_name:String, path:String) -> void:
	register_tab_data(create_registry_data(_name, path))

static func register_tab_data(data:Dictionary) -> void:
	var instance = get_instance()
	var path = data.get("path")
	if instance._tab_data.has(path):
		print("Path already registered in EditorPanelSingleton Tabs: %s" % path)
		return
	instance._tab_data[path] = data

static func unregister_tab(path:String):
	var instance = get_instance()
	if instance._tab_data.has(path):
		instance._tab_data.erase(path)
		return
	print("Path not registered in EditorPanelSingleton Tabs: %s" % path)

static func get_registered_tabs():
	var instance = get_instance()
	var data = instance._tab_data
	var formatted_data = {}
	for path in data.keys():
		var panel_data = data.get(path)
		var _name = panel_data.get("name")
		_name = _get_unique_name(_name, formatted_data.keys())
		formatted_data[_name] = {
			"path":path
		}
	
	return formatted_data

static func register_layout(_name:String, layout, icon=null) -> void:
	var instance = get_instance()
	if instance._layout_data.has(_name):
		print("Name already registered in EditorPanelSingleton Layouts: %s" % _name)
		return
	instance._layout_data[_name] = {
		"layout": layout,
		"icon":icon
	}

static func unregister_layout(_name:String):
	var instance = get_instance()
	if instance._layout_data.has(_name):
		instance._layout_data.erase(_name)
		return
	print("Name not registered in EditorPanelSingleton Layouts: %s" % _name)

static func get_registered_layouts():
	var instance = get_instance()
	return instance._layout_data

static func get_layout(_name:String):
	var instance = get_instance()
	if instance._layout_data.has(_name):
		return instance._layout_data.get(_name)
	else:
		print("Name not registered in EditorPanelSingleton Layouts: %s" % _name)

static func _get_unique_name(_name:String, current_names:Array):
	var count = 1
	var _new_name = _name
	while _new_name in current_names:
		_new_name = _name + "(%s)" % count
		count += 1
	return _new_name

static func register_split_panel_instance(split_panel):
	var instance = get_instance()
	instance._split_panel_instances.append(split_panel)

static func unregister_split_panel_instance(split_panel):
	var instance = get_instance()
	instance.clean_split_panel_instances()
	instance._split_panel_instances.erase(split_panel)

static func get_split_panel_instances():
	var instance = get_instance()
	instance.clean_split_panel_instances()
	return instance._split_panel_instances

func clean_split_panel_instances():
	var valid = []
	for ins in _split_panel_instances:
		if is_instance_valid(ins):
			valid.append(ins)
	_split_panel_instances = valid

var _layout_data:= {}
var _panel_data:= {}
var _tab_data:= {}
var _split_panel_instances:= []


func _ready() -> void:
	_register_panels.call_deferred()

func _register_panels():
	register_panel("Plugin Tabs", "res://addons/addon_lib/brohd/alib_editor/editor_panel/plugin_tab_container.tscn")

func _get_ready_bool() -> bool:
	return is_node_ready()
