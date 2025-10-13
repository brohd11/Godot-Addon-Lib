extends RefCounted
#! namespace ALibEditor.Utils class UClassDetail

const _MEMBER_ARGS = ["signal", "property", "method", "enum", "const"]
const _INVALID_DATA = "__INVALID_DATA__"

static func class_get_all_members(script:GDScript=null):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _recur_get_class_members(script)
	return members

static func class_get_all_signals(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _recur_get_class_members(script, ["signal"])
	return members

static func class_get_all_properties(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _recur_get_class_members(script, ["property"])
	return members

static func class_get_all_methods(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _recur_get_class_members(script, ["method"])
	return members

static func class_get_all_constants(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _recur_get_class_members(script, ["const"])
	return members

static func class_get_all_enums(script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _recur_get_class_members(script, ["enum"])
	return members


static func _recur_get_class_members(script:Script, desired_members:=_MEMBER_ARGS, get_class_data:=true):
	var members_dict = {}
	
	if get_class_data:
		var instance_type = script.get_instance_base_type()
		if instance_type == null:
			return []
		if "signal" in desired_members:
			var class_signals = ClassDB.class_get_signal_list(instance_type)
			for data in class_signals:
				var name = data.get("name")
				members_dict[name] = true
		if "property" in desired_members:
			var class_properties = ClassDB.class_get_property_list(instance_type)
			for data in class_properties:
				var name = data.get("name")
				members_dict[name] = true
		if "method" in desired_members:
			var class_methods = ClassDB.class_get_method_list(instance_type)
			for data in class_methods:
				var name = data.get("name")
				members_dict[name] = true
		if "enum" in desired_members:
			var class_enums = ClassDB.class_get_enum_list(instance_type)
			for i in class_enums:
				members_dict[i] = true
		if "const" in desired_members:
			var const_map = ClassDB.class_get_integer_constant_list(instance_type)
			for i in const_map:
				members_dict[i] = true
	
	var base_script = script.get_base_script()
	if base_script == null:
		var members_array = members_dict.keys()
		return members_array
	
	# get script members every script
	var script_members = _get_script_members(base_script, desired_members)
	for i in script_members:
		members_dict[i] = true
	
	# get class members only once
	var get_class_members = false
	var recurs_array = _recur_get_class_members(base_script, desired_members, get_class_members)
	for i in recurs_array:
		members_dict[i] = true
	
	var members_array = members_dict.keys()
	return members_array


static func script_get_all_members(script:Script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	return _get_script_members(script)

static func script_get_all_signals(script:Script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _get_script_members(script, ["signal"])
	return members

static func script_get_all_properties(script:Script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _get_script_members(script, ["property"])
	return members

static func script_get_all_methods(script:Script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _get_script_members(script, ["method"])
	return members

static func script_get_all_constants(script:Script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _get_script_members(script, ["const"])
	return members

static func script_get_all_enums(script:Script):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return []
	var members = _get_script_members(script, ["enum"])
	return members


static func _get_script_members(script:Script, desired_members:=_MEMBER_ARGS):
	var members_dict = {}
	if "signal" in desired_members:
		var script_members = script.get_script_signal_list()
		for data in script_members:
			var name = data.get("name")
			members_dict[name] = true
	if "method" in desired_members:
		var script_method_list = script.get_script_method_list()
		for data in script_method_list:
			var name = data.get("name")
			members_dict[name] = true
	if "property" in desired_members:
		var script_property_list = script.get_script_property_list()
		for data in script_property_list:
			var name = data.get("name")
			members_dict[name] = true
	if "const" in desired_members:
		var const_array = script.get_script_constant_map().keys()
		for name in const_array:
			members_dict[name] = true
	if "enum" in desired_members:
		var const_dict = script.get_script_constant_map()
		for name in const_dict.keys():
			var value = const_dict.get(name)
			if value is not Dictionary:
				continue
			var valid_dict = true
			var count = 0
			for i in value.values():
				if i is not int:
					valid_dict = false
					break
				if i != count:
					valid_dict = false
					break
				count += 1
			
			if valid_dict:
				members_dict[name] = true
	
	var members_array = members_dict.keys()
	
	return members_array


static func get_member_data(script, member_name:String, member_hint:String = ""):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return null
	
	var current_script = script as Script
	if member_name.find(".") > -1:
		var parts = member_name.split(".", false)
		for part in parts:
			#var const_dict = current_script.get_script_constant_map()
			#if not const_dict.has(part):
				#return
			var val = current_script.get(part)
			if val == null:
				var global_class_path = get_global_class_path(part)
				if global_class_path == "":
					return null # TODO ??
				val = load(global_class_path)
			
			#prints("in loop",part, val)
			if val is GDScript:
				current_script = val
			else:
				member_name = part
				break
	
	#prints("YEYEY", current_script, member_name)
	#print(current_script.get_script_method_list())
	return _get_member_data(current_script, member_name, member_hint)




static func _get_member_data(script, member_name:String, member_hint:String = ""):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	if script == null:
		return null
	
	var member_hints_array = _MEMBER_ARGS
	if member_hint in _MEMBER_ARGS:
		member_hints_array = [member_hint]
	
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
	if "signal" in member_hints_array:
		var script_members = script.get_script_signal_list()
		for data in script_members:
			var name = data.get("name")
			if name == member_name:
				return data
	if "method" in member_hints_array:
		var script_method_list = script.get_script_method_list()
		for data in script_method_list:
			var name = data.get("name")
			if name == member_name:
				return data
	if "property" in member_hints_array:
		var script_property_list = script.get_script_property_list()
		for data in script_property_list:
			var name = data.get("name")
			if name == member_name:
				return data
	if "const" in member_hints_array:
		var const_dict = script.get_script_constant_map()
		if const_dict.has(member_name):
			return const_dict.get(member_name)
	if "enum" in member_hints_array:
		var const_dict = script.get_script_constant_map()
		if const_dict.has(member_name):
			var value = const_dict.get(member_name)
			if value is Dictionary:
				return const_dict.get(member_name)
	
	return _INVALID_DATA


static func _get_member_data_class(script:Script, member_name:String, member_hints_array:Array):
	var instance_type = script.get_instance_base_type()
	if instance_type == null:
		return _INVALID_DATA
	
	if "signal" in member_hints_array:
		if ClassDB.class_has_signal(instance_type, member_name):
			var class_signals = ClassDB.class_get_signal_list(instance_type)
			for data in class_signals:
				var name = data.get("name")
				if name == member_name:
					return data
	if "property" in member_hints_array:
		var class_properties = ClassDB.class_get_property_list(instance_type)
		for data in class_properties:
			var name = data.get("name")
			if name == member_name:
				return data
	if "method" in member_hints_array:
		if ClassDB.class_has_method(instance_type, member_name):
			var class_methods = ClassDB.class_get_method_list(instance_type)
			for data in class_methods:
				var name = data.get("name")
				if name == member_name:
					return data
	if "enum" in member_hints_array:
		if ClassDB.class_has_enum(instance_type, member_name):
			return ClassDB.class_get_enum_constants(instance_type, member_name)
	if "const" in member_hints_array:
		if ClassDB.class_has_integer_constant(instance_type, member_name):
			return ClassDB.class_get_integer_constant(instance_type, member_name)
	
	return _INVALID_DATA

static func get_global_class_path(class_nm:String):
	var global_class_list = ProjectSettings.get_global_class_list()
	for dict in global_class_list:
		var name = dict.get("class")
		if name == class_nm:
			return dict.get("path", "")
	
	return ""
