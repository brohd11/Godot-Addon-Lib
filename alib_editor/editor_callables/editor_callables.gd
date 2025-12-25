
const UNode = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_node.gd")

static var callables_dict:= {}

static var _key_cache:= {}

static func call_registered(access_name:String, args:=[]):
	var callable = callables_dict.get(access_name)
	if callable != null:
		if args.is_empty():
			callable.call()
		else:
			callable.callv(args)

static func build():
	_get_callables()

static func _get_callables():
	callables_dict = {}
	_key_cache = {}
	var classes = [
		FileSystem
	]
	
	var working_dicts = {}
	for c in classes:
		var class_dict = c._callables
		for class_signal_pair in class_dict.keys():
			var class_nm = class_signal_pair.get_slice("-", 0)
			var sig_nm = class_signal_pair.get_slice("-", 1)
			if not working_dicts.has(class_nm):
				working_dicts[class_nm] = {}
			if not working_dicts[class_nm].has(sig_nm):
				working_dicts[class_nm][sig_nm] = {}
			
			var data = class_dict[class_signal_pair]
			for nm in data.keys():
				working_dicts[class_nm][sig_nm][nm] = data[nm]
	
	
	var root = Engine.get_main_loop().root
	var all_nodes = UNode.recursive_get_nodes(root)
	for node in all_nodes:
		if node is Button:
			_check_working_dict("Button", node, working_dicts)
		elif node is PopupMenu:
			_check_working_dict("PopupMenu", node, working_dicts)
		elif node is Tree:
			_check_working_dict("Tree", node, working_dicts)
	

static func _check_working_dict(_class_nm:String, node:Object, working_dict:Dictionary):
	var dict = working_dict.get(_class_nm)
	if dict:
		_check_dict(node, dict)

static func _check_dict(node:Object, dict:Dictionary):
	var dict_keys = _key_cache.get(dict, dict.keys())
	for signal_name in dict_keys:
		var sig_dict = dict[signal_name]
		var sig_keys = _key_cache.get(sig_dict, sig_dict.keys())
		for access_name in sig_keys:
			if callables_dict.has(access_name):
				continue
			var callable_name = sig_dict[access_name]
			var callable = get_object_callable_by_name(node, signal_name, callable_name)
			if callable != null:
				callables_dict[access_name] = callable


static func get_object_callable_by_name(object:Object, signal_name:StringName, callable_name:StringName):
	if object.has_signal(signal_name):
		var signal_list = object.get_signal_connection_list(signal_name)
		for data in signal_list:
			var callable = data.get("callable") as Callable
			if not callable.is_standard():
				if str(callable) == "Delegate::Invoke":
					continue
			if callable.get_method() == callable_name:
				return callable

class FileSystem:
	const _callables = {
		"Button-pressed": {
			change_split_mode: "FileSystemDock::_change_split_mode",
		},
		"PopupMenu-id_pressed":{
			tree_rmb_option: "FileSystemDock::_tree_rmb_option"
		},
		"Tree-item_activated":{
			tree_activate_file: "FileSystemDock::_tree_activate_file"
		}
	}
	
	
	const change_split_mode = "FileSystem-_change_split_mode"
	const tree_rmb_option = "FileSystem-_tree_rmb_option"
	const tree_activate_file = "FileSystem-_tree_activate_file"


static func test():
	_get_callables()
	call_registered(FileSystem.tree_activate_file)
