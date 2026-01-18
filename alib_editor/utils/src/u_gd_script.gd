#! namespace ALibEditor.Utils class UGDScript

const UString = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_string.gd")
const UClassDetail = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/u_class_detail.gd")


static func resolve_global_script(line:String, tokens=null):
	if tokens == null:
		tokens = UString.Token.tokenize_string(line)
	var replace = false
	for tok in tokens.tokens:
		var front = UString.get_member_access_front(tok)
		if UClassDetail.get_global_class_path(front) == "":
			continue
		var value_string = _get_resolved_access_path(tok)
		if value_string == "":
			continue
		var has_suffix = value_string.find(".gd.") > -1
		var new_string = 'preload("%s")'
		var replace_arr = [value_string]
		if has_suffix:
			new_string += ".%s"
			var script_path = value_string.get_slice(".gd.", 0) + ".gd"
			var script_suff = value_string.get_slice(".gd.", 1)
			replace_arr = [script_path, script_suff]
		
		var formatted = new_string % replace_arr
		line = line.replace(tok, formatted)
		replace = true
	
	return line


static func _get_resolved_access_path(member_access_path:String, script=null):
	if script == null:
		script = EditorInterface.get_script_editor().get_current_script()
	var value = UClassDetail.resolve_script_access_path(script, member_access_path)
	if value == null:
		return ""
	return value
