#! namespace ALibRuntime.Utils class UString

const INDENTIFIER_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
const NUMBERS = "0123456789"

static func get_member_access_front(text:String):
	var dot_idx = text.find(".")
	if dot_idx > -1:
		if text.find("(") > -1:
			var string_map = StringMap.new(text)
			var count = 0
			while count < text.length():
				if string_map.bracket_map.has(count):
					var next = string_map.bracket_map[count]
					if next > count:
						count = next
						continue
				var char = text[count]
				if char == ".":
					break
				count += 1
			dot_idx = count
		return text.substr(0, dot_idx)
	return text

static func get_member_access_back(text:String):
	var dot_idx = text.rfind(".")
	if dot_idx > -1:
		if text.find("(") > -1:
			var string_map = StringMap.new(text)
			var count = text.length() -1
			while count >= 0:
				if string_map.bracket_map.has(count):
					var next = string_map.bracket_map[count]
					if next < count:
						count = next
						continue
				var char = text[count]
				if char == ".":
					break
				count -= 1
			dot_idx = count
		return text.substr(dot_idx + 1)
	return text


static func get_string_indexes(text:String):
	var string_mask = PackedByteArray()
	string_mask.resize(text.length())
	
	var in_string = false
	var quote_char = ""
	var count = 0
	while count < text.length():
		var char = text[count]
		if char == '"' or char == "'":
			if not in_string:
				quote_char = char
				in_string = true
			else:
				if char == quote_char:
					in_string = false
					string_mask[count] = 1
		
		if in_string:
			string_mask[count] = 1
		count += 1
	
	return string_mask


static func string_safe_count(text:String, what:String, from:int=0, to:int=0, string_mask=null):
	if string_mask == null:
		string_mask = get_string_indexes(text)
	var count = 0
	var max_idx = to if to > 0 else text.length()
	var idx = -10
	idx = text.find(what, from)
	while idx != -1 and idx <= max_idx:
		if string_mask[idx] == 0:
			count += 1
		idx = text.find(what, idx + 1)
	return count

static func string_safe_find(text:String, find:String, start:=0, string_mask=null):
	if string_mask == null:
		string_mask = get_string_indexes(text)
	var idx = -10
	idx = text.find(find, start)
	while string_mask[idx] == 1 and not idx == -1:
		idx = text.find(find, idx + 1)
	return idx

static func string_safe_rfind(text:String, find:String, start:=-1, string_mask=null):
	if string_mask == null:
		string_mask = get_string_indexes(text)
	var idx = -10
	idx = text.rfind(find, start)
	while string_mask[idx] == 1 and not idx == -1:
		idx = text.rfind(find, idx - 1)
	return idx


static func get_word_at_index(text:String, idx:int):
	
	pass


static func test():
	var line = "string_safe_find(text:String, find:String, start:=0, reverse:=false, find:String string_indexes=null)"
	print(string_safe_find(line, "find:S", 31))
	print(string_safe_rfind(line, "find:S", 68))
	print(string_safe_count(line, "find:S"))
	pass


static func get_func_name_in_line(stripped_line_text:String) -> String:
	if not (stripped_line_text.begins_with("func ") or stripped_line_text.begins_with("static func ")):
		return ""
	#if stripped_line_text.find(":") == -1:
		#return ""
	var func_name = stripped_line_text.get_slice("func ", 1).get_slice("(", 0)
	return func_name

static func get_class_name_in_line(stripped_line_text:String) -> String:
	if not stripped_line_text.begins_with("class "): # "" <- parser
		return ""
	var _class = stripped_line_text.get_slice("class ", 1).get_slice(":", 0) # "" <- parser
	if _class.find("extends ") > -1: #  "" <- parser
		_class = _class.get_slice("extends ", 0) #  "" <- parser
	return _class.strip_edges()

### Strip edges and comment before passing
#static func get_var_name_in_line(stripped_line_text:String):
	#var var_idx = stripped_line_text.find("var ")
	#if var_idx > -1:
		#if var_idx == 0 or var_idx == 7: # start with or static
			#var var_dec = stripped_line_text.substr(var_idx + 4) # +4 to strip var
			#var _name = var_dec[0]
			#var idx = 1
			#while idx < var_dec.length():
				#var n = _name + var_dec[idx]
				#if n.is_valid_ascii_identifier():
					#_name = n
				#else:
					#break
				#idx += 1
			#return _name
	#return ""

static func get_var_name_and_type_hint_in_line(stripped_line_text:String): # for local vars
	var var_idx = stripped_line_text.find("var ")
	if not(var_idx == 0 or var_idx == 7): # start with or static
		return null
	
	var var_dec = stripped_line_text.substr(var_idx + 4)
	return _get_name_and_type_from_line(var_dec)

static func get_const_name_and_type_in_line(stripped_line_text:String):
	var const_idx = stripped_line_text.find("const ")
	if const_idx != 0:
		return null
	var preload_path = ""
	if stripped_line_text.find('preload("') > -1:
		preload_path = stripped_line_text.get_slice("preload(", 1) #""
		preload_path = preload_path.get_slice(")", 0)
		preload_path = preload_path.trim_prefix("'").trim_suffix("'").trim_prefix('"').trim_suffix('"')
		var const_name = stripped_line_text.get_slice("preload(", 0)
		const_name = const_name.substr(const_idx + 6)
		const_name = const_name.replace("=","").replace(":", "").strip_edges()
		return [const_name, preload_path]
	
	var const_dec = stripped_line_text.substr(const_idx + 6)
	var data = _get_name_and_type_from_line(const_dec)
	return data


static func _get_name_and_type_from_line(declaration:String):
	var colon_idx = declaration.find(":")
	var has_colon = colon_idx > -1
	var eq_idx = declaration.find("=")
	var has_eq = eq_idx > -1
	
	var var_nm:String
	var type_hint:String = ""
	if has_colon and has_eq:
		var col_sub_idx = colon_idx + 1
		var_nm = declaration.substr(0, col_sub_idx - 1).strip_edges()
		type_hint = declaration.substr(col_sub_idx, eq_idx - col_sub_idx).strip_edges()
		if type_hint == "":
			type_hint = declaration.get_slice("=", 1).strip_edges()
	elif has_colon:
		var_nm = declaration.get_slice(":", 0).strip_edges()
		type_hint = declaration.get_slice(":", 1).strip_edges()
	elif has_eq:
		var_nm = declaration.get_slice("=", 0).strip_edges()
		type_hint = declaration.get_slice("=", 1).strip_edges()
	else:
		var_nm = declaration.strip_edges()
	
	return [var_nm, type_hint]





static func get_string_map(text:String, _mode:StringMap.Mode=StringMap.Mode.FULL, print_err:=false) -> StringMap:
	return StringMap.new(text, _mode, print_err)


class StringMap:
	const BRACKETS = { "(": ")", "[": "]", "{": "}" }
	enum Mode {
		FULL,
		STRING,
	}
	## Copy of text that was parsed.
	var string:String
	## A mask where 1 means "inside a string" and 0 means "outside".
	var string_mask: PackedByteArray
	## A dictionary mapping a quote's index to its matching partner's index.
	var quote_map: Dictionary
	## A dictionary mapping each bracket's index to the index of its matching partner.
	var bracket_map: Dictionary
	## A flag to indicate if any parsing errors (like mismatched brackets) occurred.
	var has_errors: bool = false
	## Select full scan or only string mask
	var mode:Mode
	##
	var comment_index:int = -1
	
	
	
	
	func _init(text:String, _mode:Mode=Mode.FULL, print_err:=false) -> void:
		string = text
		mode = _mode
		_parse(text)
		
	
	func _parse(text: String, print_err:=false):
		var t = ALibRuntime.Utils.UProfile.TimeFunction.new("Parse", ALibRuntime.Utils.UProfile.TimeFunction.TimeScale.USEC)
		var text_length = text.length()
		string_mask.resize(text_length)
		
		var bracket_values = BRACKETS.values()
		var bracket_stack = []
		var in_string = false
		var quote_char = ""
		var string_start_index = -1
		
		var i = -1 # for easy indexing
		while i + 1 < text_length:
			i += 1
			var char = text[i]
			if in_string:
				string_mask[i] = 1
				if char == "\\":
					if i + 1 < text_length:
						string_mask[i + 1] = 1
					i += 1
				elif char == quote_char:
					in_string = false
					quote_map[string_start_index] = i
					quote_map[i] = string_start_index
			else: # not in_string
				if char == '"' or char == "'":
					in_string = true
					quote_char = char
					string_start_index = i
					string_mask[i] = 1
				elif char == "#": # is this right?
					comment_index = i
					break
				elif mode == Mode.FULL:
					if char in BRACKETS:
						bracket_stack.push_back(i)
					elif char in bracket_values:# bracket closing
						if bracket_stack.is_empty():
							has_errors = true
							break
						var open_idx = bracket_stack.pop_back()
						if BRACKETS[text[open_idx]] == char:
							bracket_map[open_idx] = i
							bracket_map[i] = open_idx
						else:
							has_errors = true
							break
				
				
				
				#elif char in BRACKETS:
					#bracket_stack.push_back(i)
				#elif char in bracket_values:# bracket closing
					#if bracket_stack.is_empty():
						#has_errors = true
						#break
					#var open_idx = bracket_stack.pop_back()
					#if BRACKETS[text[open_idx]] == char:
						#bracket_map[open_idx] = i
						#bracket_map[i] = open_idx
					#else:
						#has_errors = true
						#break
		
		# after loop
		if in_string:
			if print_err:
				printerr("Unterminated string starting at index ", string_start_index)
			has_errors = true
		if not bracket_stack.is_empty():
			if print_err:
				printerr("Unclosed opening bracket at index ", bracket_stack.front())
			has_errors = true
		
		t.stop()



static func run_test():
	var code = r'var result = get_tree().get_first_node_in_group("players").call_deferred("set_inventory", {"name": "Potion [Healing]", "effects": ["Regen(5)", 10]}, Callable(self, "_on_set_complete")).get_meta("config_{}".format(["v1", "default"]), "Fallback string with an (unmatched bracket and a fake escape \\")'
	var parse_result = get_string_map(code, StringMap.Mode.FULL)
	print(parse_result.string)
	# Test 1: No errors should be reported.
	# The "unmatched bracket" is inside a string, so it's not a real error.
	assert(not parse_result.has_errors)
	print("Test 1 PASSED: No parsing errors reported.")
	
	# Test 2: Check if the parser correctly ignored brackets inside strings.
	var string_with_brackets_pos = code.find("Potion [Healing]") + 8 # Index of the '['
	assert(parse_result.string_mask[string_with_brackets_pos] == 1) # Must be in a string
	assert(not string_with_brackets_pos in parse_result.bracket_map) # Must NOT be in the bracket map
	print("Test 2 PASSED: Correctly identified brackets in strings as text.")
	
	# Test 3: Check a deeply nested bracket.
	# Let's find the closing ')' of the .format() call.
	var format_close_paren_pos = code.find('default"])') + 9
	var format_open_paren_pos = code.find('(["v1", ')
	assert(parse_result.bracket_map[format_close_paren_pos] == format_open_paren_pos)
	print("Test 3 PASSED: Correctly mapped a deeply nested bracket pair.")
