extends RefCounted
#! namespace ALibEditor.Utils class UClassDetail

enum IncludeInheritance{
	NONE,
	SCRIPTS_ONLY,
	ALL,
	
}

const _MEMBER_ARGS = ["signal", "property", "method", "enum", "const"]
const _INVALID_DATA = "__INVALID_DATA__"

static func class_get_all_members(script:GDScript=null):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _recur_get_class_members(script)
	return members

static func class_get_all_signals(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _recur_get_class_members(script, ["signal"])
	return members

static func class_get_all_properties(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _recur_get_class_members(script, ["property"])
	return members

static func class_get_all_methods(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _recur_get_class_members(script, ["method"])
	return members

static func class_get_all_constants(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _recur_get_class_members(script, ["const"])
	return members

static func class_get_all_enums(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _recur_get_class_members(script, ["enum"])
	return members


static func _recur_get_class_members(script:Script, desired_members:=_MEMBER_ARGS, get_class_data:=true):
	var members_dict = {}
	
	if get_class_data:
		var instance_type = script.get_instance_base_type()
		if instance_type == null:
			return {}
		if "signal" in desired_members:
			var class_signals = ClassDB.class_get_signal_list(instance_type)
			for data in class_signals:
				var name = data.get("name")
				members_dict[name] = data
		if "property" in desired_members:
			var class_properties = ClassDB.class_get_property_list(instance_type)
			for data in class_properties:
				var name = data.get("name")
				members_dict[name] = data
		if "method" in desired_members:
			var class_methods = ClassDB.class_get_method_list(instance_type)
			for data in class_methods:
				var name = data.get("name")
				members_dict[name] = data
		if "enum" in desired_members:
			var class_enums = ClassDB.class_get_enum_list(instance_type)
			for i in class_enums:
				members_dict[i] = ClassDB.class_get_enum_constants(instance_type, i)
		if "const" in desired_members:
			var const_map = ClassDB.class_get_integer_constant_list(instance_type)
			for i in const_map:
				members_dict[i] = ClassDB.class_get_integer_constant(instance_type, i)
	
	var base_script = script.get_base_script()
	if base_script == null:
		#var members_array = members_dict.keys()
		return members_dict
	
	# get script members every script
	var script_members = _get_script_members(base_script, desired_members)
	for i in script_members.keys():
		members_dict[i] = script_members[i]
	
	# get class members only once
	var get_class_members = false
	var recurs_dict = _recur_get_class_members(base_script, desired_members, get_class_members)
	for i in recurs_dict.keys():
		members_dict[i] = recurs_dict[i]
	
	return members_dict


static func script_get_all_members(script:Script, include_inheritance:=IncludeInheritance.NONE):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _get_script_members(script)
	if include_inheritance == IncludeInheritance.ALL:
		members.merge(_recur_get_class_members(script,_MEMBER_ARGS))
	elif include_inheritance == IncludeInheritance.SCRIPTS_ONLY:
		members.merge(_recur_get_class_members(script,_MEMBER_ARGS, false))
	
	return members

static func script_get_all_signals(script:Script, include_inheritance:=IncludeInheritance.NONE):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _get_script_members(script, ["signal"])
	if include_inheritance == IncludeInheritance.ALL:
		members.merge(_recur_get_class_members(script,["signal"]))
	elif include_inheritance == IncludeInheritance.SCRIPTS_ONLY:
		members.merge(_recur_get_class_members(script,["signal"], false))
	return members

static func script_get_all_properties(script:Script, include_inheritance:=IncludeInheritance.NONE):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _get_script_members(script, ["property"])
	if include_inheritance == IncludeInheritance.ALL:
		members.merge(_recur_get_class_members(script,["property"]))
	elif include_inheritance == IncludeInheritance.SCRIPTS_ONLY:
		members.merge(_recur_get_class_members(script,["property"], false))
	return members

static func script_get_all_methods(script:Script, include_inheritance:=IncludeInheritance.NONE):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _get_script_members(script, ["method"])
	if include_inheritance == IncludeInheritance.ALL:
		members.merge(_recur_get_class_members(script,["method"]))
	elif include_inheritance == IncludeInheritance.SCRIPTS_ONLY:
		members.merge(_recur_get_class_members(script,["method"], false))
	return members

static func script_get_all_constants(script:Script, include_inheritance:=IncludeInheritance.NONE):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _get_script_members(script, ["const"])
	if include_inheritance == IncludeInheritance.ALL:
		members.merge(_recur_get_class_members(script,["const"]))
	elif include_inheritance == IncludeInheritance.SCRIPTS_ONLY:
		members.merge(_recur_get_class_members(script,["const"], false))
	return members

static func script_get_all_enums(script:Script, include_inheritance:=IncludeInheritance.NONE):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return {}
	var members = _get_script_members(script, ["enum"])
	if include_inheritance == IncludeInheritance.ALL:
		members.merge(_recur_get_class_members(script,["enum"]))
	elif include_inheritance == IncludeInheritance.SCRIPTS_ONLY:
		members.merge(_recur_get_class_members(script,["enum"], false))
	return members


static func _get_script_members(script:Script, desired_members:=_MEMBER_ARGS):
	var members_dict = {}
	if "signal" in desired_members:
		var script_members = script.get_script_signal_list()
		for data in script_members:
			var name = data.get("name")
			members_dict[name] = data
	if "method" in desired_members:
		var script_method_list = script.get_script_method_list()
		for data in script_method_list:
			var name = data.get("name")
			members_dict[name] = data
	if "property" in desired_members:
		var script_property_list = script.get_script_property_list()
		for data in script_property_list:
			var name = data.get("name")
			members_dict[name] = data
	if "const" in desired_members:
		var const_dict = script.get_script_constant_map()
		for name in const_dict.keys():
			var value = const_dict.get(name)
			members_dict[name] = value
	if "enum" in desired_members:
		var const_dict = script.get_script_constant_map()
		for name in const_dict.keys():
			var value = const_dict.get(name)
			if value is not Dictionary:
				continue
			if _check_dict_is_enum(value):
				members_dict[name] = value
	
	return members_dict

static func _check_dict_is_enum(dict:Dictionary) -> bool:
	var count = 0
	for i in dict.values():
		if i is not int:
			return false
		if i != count:
			return false
		count += 1
	return true

static func get_member_info_by_path(script, member_name:String, member_hints_array:=_MEMBER_ARGS, print_err:=false):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return null
	
	if member_hints_array.find("const") == -1: # I think add this so you can search through classes
		member_hints_array.append("const")
	
	var current_script = script as Script
	var final_val
	var parts = [member_name]
	if member_name.find(".") > -1:
		parts = member_name.split(".", false)
	
	var parts_size = parts.size()
	for i in range(parts_size):
		var part = parts[i]
		var static_member = current_script.get(part)
		final_val = static_member
		if static_member is GDScript:
			current_script = static_member
			continue
		
		var member_info = get_member_info(current_script, part, member_hints_array)
		final_val = member_info
		if member_info == null:
			if i == 0:
				var global_class_path = get_global_class_path(part)
				if global_class_path == "":
					if print_err:
						printerr("Could not find member in script or global classes: %s" % part)
					return null
				current_script = load(global_class_path)
				final_val = current_script # set final val in case only looking up the global, for some reason
			else:
				if print_err:
					printerr("Member '%s' not found in: %s" % [part, member_name.get_slice(part, 0).trim_suffix(".")])
				return null
		
		elif member_info is GDScript:
			current_script = member_info
			continue
		else:
			if i == parts_size -1:
				break
			
			var _class_name = member_info.get("class_name", "")
			if _class_name != "":
				var class_path = ""
				if not _class_name.begins_with("res://"):
					class_path = get_global_class_path(_class_name)
					if class_path == "": # built in class, abort
						return null
				else:
					class_path = _class_name
				current_script = load(class_path)
				final_val = current_script
				continue
	
	return final_val


static func get_member_info(script, member_name:String, member_hints_array:=_MEMBER_ARGS):
	return _get_member_info(script, member_name, member_hints_array)


static func _get_member_info(script, member_name:String, member_hints_array:=_MEMBER_ARGS):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return null
	
	var class_check = _get_member_data_class(script, member_name, member_hints_array)
	if class_check is String and class_check != _INVALID_DATA:
		return class_check
	if class_check is not String:
		return class_check
	
	var current_script = script
	while current_script != null:
		var data = _get_member_data_script(current_script, member_name, member_hints_array)
		if data is String and data != _INVALID_DATA:
			return data
		if data is not String:
			return data
		
		current_script = current_script.get_base_script()
	
	return null


static func _get_member_data_script(script:Script, member_name:String, member_hints_array:Array):
	if "const" in member_hints_array:
		var const_dict = script.get_script_constant_map()
		if const_dict.has(member_name):
			return const_dict.get(member_name)
	if "property" in member_hints_array:
		var script_property_list = script.get_script_property_list()
		for data in script_property_list:
			var name = data.get("name")
			if name == member_name:
				return data
	if "enum" in member_hints_array:
		var const_dict = script.get_script_constant_map()
		if const_dict.has(member_name):
			var value = const_dict.get(member_name)
			if value is Dictionary:
				if _check_dict_is_enum(value):
					return const_dict.get(member_name)
	if "method" in member_hints_array:
		var script_method_list = script.get_script_method_list()
		for data in script_method_list:
			var name = data.get("name")
			if name == member_name:
				return data
	if "signal" in member_hints_array:
		var script_members = script.get_script_signal_list()
		for data in script_members:
			var name = data.get("name")
			if name == member_name:
				return data
	
	return _INVALID_DATA


static func _get_member_data_class(script:Script, member_name:String, member_hints_array:Array):
	var instance_type = script.get_instance_base_type()
	if instance_type == null:
		return _INVALID_DATA
	
	if "const" in member_hints_array:
		if ClassDB.class_has_integer_constant(instance_type, member_name):
			return ClassDB.class_get_integer_constant(instance_type, member_name)
	if "enum" in member_hints_array:
		if ClassDB.class_has_enum(instance_type, member_name):
			return ClassDB.class_get_enum_constants(instance_type, member_name)
	if "method" in member_hints_array:
		if ClassDB.class_has_method(instance_type, member_name):
			var class_methods = ClassDB.class_get_method_list(instance_type)
			for data in class_methods:
				var name = data.get("name")
				if name == member_name:
					return data
	if "property" in member_hints_array:
		var class_properties = ClassDB.class_get_property_list(instance_type)
		for data in class_properties:
			var name = data.get("name")
			if name == member_name:
				return data
	if "signal" in member_hints_array:
		if ClassDB.class_has_signal(instance_type, member_name):
			var class_signals = ClassDB.class_get_signal_list(instance_type)
			for data in class_signals:
				var name = data.get("name")
				if name == member_name:
					return data
	
	return _INVALID_DATA

## Returns dictionary of all classes [name, path]
static func get_all_global_class_paths():
	var class_dict = {}
	var global_class_list = ProjectSettings.get_global_class_list()
	for dict in global_class_list:
		var name = dict.get("class")
		var path = dict.get("path", "")
		class_dict[name] = path
	return class_dict

static func get_global_class_path(class_nm:String):
	var global_class_list = ProjectSettings.get_global_class_list()
	for dict in global_class_list:
		var name = dict.get("class")
		if name == class_nm:
			return dict.get("path", "")
	
	return ""

static func _script_get_member_by_value_recur(script, value:Variant, deep:=false, member_hints:=_MEMBER_ARGS, checked:={}):
	if checked.has(script):
		return null
	checked[script] = true
	var member = _script_get_member_by_value(script, value, member_hints)
	
	if not deep:
		return member
	if member != null:
		return member
	
	var constants = script_get_all_constants(script, IncludeInheritance.SCRIPTS_ONLY)
	var constants_keys = constants.keys()
	for c in constants_keys:
		var val = constants.get(c)
		if not val is GDScript:
			continue
		
		var next_member = _script_get_member_by_value_recur(val, value, deep, member_hints, checked)
		if next_member != null:
			return c + "." + next_member
	
	return null

static func script_get_member_by_value(script, value:Variant, deep:=false, member_hints:=_MEMBER_ARGS, breadth_first:=true):
	# For a non-deep search, just check the top-level script
	if not deep:
		return _script_get_member_by_value(script, value, member_hints)
	
	if breadth_first:
		return _script_get_member_by_value_breadth(script, value, member_hints)
	else:
		return _script_get_member_by_value_recur(script, value, deep, member_hints)


static func _script_get_member_by_value_breadth(start_script, value: Variant, member_hints:=_MEMBER_ARGS):
	var queue: Array = [{"script": start_script, "path": ""}]
	
	var checked: Dictionary = {start_script: true}
	while not queue.is_empty():
		var current_item = queue.pop_front()
		var current_script = current_item.script
		var current_path = current_item.path as String
		
		var member_name = _script_get_member_by_value(current_script, value, member_hints)
		
		if member_name != null:
			if current_path.is_empty():
				return member_name
			else:
				return current_path + "." + member_name
		
		var constants = script_get_all_constants(current_script, IncludeInheritance.ALL) # TEST, this was set to scripts only, may have some side effects
		for const_name in constants:
			var child_script = constants[const_name]
			if child_script is GDScript and not checked.has(child_script):
				checked[child_script] = true
				
				var next_path = const_name
				if not current_path.is_empty():
					next_path = current_path + "." + const_name
				
				queue.push_back({"script": child_script, "path": next_path})
	
	return null


static func _script_get_member_by_value(script, value:Variant, member_hints:=_MEMBER_ARGS):
	var value_type = typeof(value)
	for hint in member_hints:
		var members
		if hint == "const": members = script_get_all_constants(script, IncludeInheritance.ALL)
		elif hint == "enum": members = script_get_all_enums(script, IncludeInheritance.ALL)
		elif hint == "method": members = script_get_all_methods(script, IncludeInheritance.ALL)
		elif hint == "signal": members = script_get_all_signals(script, IncludeInheritance.ALL)
		elif hint == "property": members = script_get_all_properties(script, IncludeInheritance.ALL)
		if not members:
			continue
		var _check = _check_member_value(members, value, value_type)
		if _check != null:
			return _check
	return null

static func _check_member_value(members:Dictionary, value, value_type:int):
	for member in members.keys():
		var member_info = members.get(member)
		if value_type == typeof(member_info):
			#print("IS SAME: ", is_same(member_info, value))
			#print("COMPARE: ", member_info == value)
			if member_info == value:
			#if is_same(member_info, value):
				return member
	return null

## Return an array of paths including the path of script passed.
static func script_get_inherited_script_paths(script:GDScript) -> Array:
	var paths = []
	while script != null:
		paths.append(script.resource_path)
		script = script.get_base_script()
	return paths

static func script_get_inherited_scripts(script:GDScript) -> Array:
	var scripts = []
	while script != null:
		scripts.append(script)
		script = script.get_base_script()
	return scripts

static func script_get_preloads(script:GDScript, deep:=false, include_inner:=false):
	if deep:
		return _script_get_preloads_bfs(script, include_inner)
	
	var constants = script_get_all_constants(script, IncludeInheritance.SCRIPTS_ONLY)
	var preloads = {}
	for c in constants.keys():
		var val = constants.get(c)
		if not val is GDScript:
			continue
		if val.resource_path != "" or include_inner:
			preloads[c] = val
	
	return preloads

static func _script_get_preloads_bfs(script:GDScript, include_inner:=false):
	var preloads = {}
	var queue: Array = [{"script": script, "path": ""}]
	
	var checked = {script: true}
	while not queue.is_empty():
		var current_item = queue.pop_front()
		var current_script = current_item.script
		var current_path = current_item.path as String
		
		var constants = script_get_all_constants(current_script, IncludeInheritance.ALL)
		for const_name in constants:
			var child_script = constants[const_name]
			if child_script is GDScript and not checked.has(child_script):
				checked[child_script] = true
				
				var next_path = const_name
				if not current_path.is_empty():
					next_path = current_path + "." + const_name
				preloads[next_path] = child_script
				queue.push_back({"script": child_script, "path": next_path})
	
	
	return preloads
