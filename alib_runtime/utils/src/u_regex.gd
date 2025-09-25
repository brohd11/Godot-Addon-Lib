#! namespace ALib.Runtime class URegex

static func escape_regex_meta_characters(text: String) -> String:
	var output: PackedStringArray = []
	for char_str in text:
		match char_str:
			".", "+", "*", "?", "^", "$", "(", ")", "[", "]", "{", "}", "|", "\\":
				output.append("\\" + char_str)
			_:
				output.append(char_str)
	return "".join(output)


static func get_preload_path():
	var regex = RegEx.new() # match.get_string(2) -> path
	regex.compile('preload\\((["\'])(.+?)\\1\\)')
	return regex

static func get_const_name():
	var regex = RegEx.new()
	regex.compile("^\\s*const\\s+([a-zA-Z_][a-zA-Z0-9_]*)\\s*(:=|=)")
	return regex

static func get_strings(): # for use with string_safe_regex_sub, gets all strings
	var regex = RegEx.new()
	regex.compile("\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'")
	return regex


#static func string_safe_regex_sub(line: String, processor: Callable, string_regex:RegEx) -> String:
	#var code_part = line
	#var comment_part = ""
	#var comment_pos = line.find("#")
	#if comment_pos != -1:
		#code_part = line.substr(0, comment_pos)
		#comment_part = line.substr(comment_pos)
	#
	## 1. Find all string matches and store both their values and positions
	#var string_matches = string_regex.search_all(code_part)
	#var string_literals = []
	#for _match in string_matches:
		#string_literals.append(_match.get_string())
	#
	## 2. Replace strings with placeholders by POSITION, iterating BACKWARDS
	#var sanitized_code = code_part
	#for i in range(string_matches.size() - 1, -1, -1):
		#var _match = string_matches[i]
		#var placeholder = "__STRING_PLACEHOLDER_%d__" % i
		## Reconstruct the string using the match's start and end positions
		#sanitized_code = sanitized_code.left(_match.get_start()) + placeholder + sanitized_code.substr(_match.get_end())
	#
	## 3. Call the provided processor function on the sanitized code
	#var converted_code = processor.call(sanitized_code)
	#
	## 4. Restore strings (this part can remain the same)
	#var final_code = converted_code
	#for i in range(string_literals.size()):
		#var placeholder = "__STRING_PLACEHOLDER_%d__" % i
		#final_code = final_code.replace(placeholder, string_literals[i])
	#
	#return final_code + comment_part
#
#static func string_safe_regex_read(line: String, processor: Callable, string_regex:RegEx) -> void:
	#var code_part = line
	#var comment_part = ""
	#var comment_pos = line.find("#")
	#if comment_pos != -1:
		#code_part = line.substr(0, comment_pos)
		#comment_part = line.substr(comment_pos)
	#
	## 1. Find all string matches and store both their values and positions
	#var string_matches = string_regex.search_all(code_part)
	#var string_literals = []
	#for _match in string_matches:
		#string_literals.append(_match.get_string())
	#
	## 2. Replace strings with placeholders by POSITION, iterating BACKWARDS
	#var sanitized_code = code_part
	#for i in range(string_matches.size() - 1, -1, -1):
		#var _match = string_matches[i]
		#var placeholder = "__STRING_PLACEHOLDER_%d__" % i
		## Reconstruct the string using the match's start and end positions
		#sanitized_code = sanitized_code.left(_match.get_start()) + placeholder + sanitized_code.substr(_match.get_end())
	#
	#processor.call(sanitized_code)
	#return

static func _prepare_line_for_safe_regex(line: String, string_regex: RegEx) -> Dictionary:
	# 1. Find all string matches on the ENTIRE line first.
	var string_matches = string_regex.search_all(line)
	var string_literals = []
	for _match in string_matches:
		string_literals.append(_match.get_string())
	
	var line_with_placeholders = line
	for i in range(string_matches.size() - 1, -1, -1):
		var _match = string_matches[i]
		var placeholder = "__STRING_PLACEHOLDER_%d__" % i
		line_with_placeholders = line_with_placeholders.left(_match.get_start()) + placeholder + line_with_placeholders.substr(_match.get_end())
	
	# 3. NOW, safely find the comment marker in the placeholder line.
	var comment_pos = line_with_placeholders.find("#")
	
	var sanitized_code: String
	var comment_part: String
	
	if comment_pos != -1:
		# The sanitized code is the part of the placeholder line before the comment.
		sanitized_code = line_with_placeholders.substr(0, comment_pos)
		# The comment part is the part of the ORIGINAL line. This preserves
		# any strings that might have been inside the comment itself.
		comment_part = line_with_placeholders.substr(comment_pos)
	else:
		# No comment found
		sanitized_code = line_with_placeholders
		comment_part = ""
	
	# 4. Return all the processed parts.
	return {
		"sanitized_code": sanitized_code,
		"string_literals": string_literals,
		"comment_part": comment_part
	}


# Processes a line and RETURNS the modified string.
static func string_safe_regex_sub(line: String, processor: Callable, string_regex: RegEx) -> String:
	# Call our helper to do the heavy lifting of preparation
	var prepared = _prepare_line_for_safe_regex(line, string_regex)
	var sanitized_code = prepared.sanitized_code
	var string_literals = prepared.string_literals
	var comment_part = prepared.comment_part
	
	# Call the provided processor function on the sanitized code
	var converted_code = processor.call(sanitized_code)
	
	# Restore strings into the converted code
	var final_code = converted_code + comment_part
	for i in range(string_literals.size()):
		var placeholder = "__STRING_PLACEHOLDER_%d__" % i
		final_code = final_code.replace(placeholder, string_literals[i])
	
	return final_code


static func string_safe_regex_read(line: String, processor: Callable, string_regex: RegEx) -> void:
	var prepared = _prepare_line_for_safe_regex(line, string_regex)
	processor.call(prepared.sanitized_code)


const _TEST_STRINGS = [
	'var message = "hello world" # This is a standard comment.',
	'print("The winning ticket is #12345.")',
	"var tag = 'item_#4' # This part is the real comment.",
	'var value = 100 # Remember to add "final" to the report.',
	'update_record("Player #1", get_node("score_#2").text) # Update UI for both players.',
	'position.x += 10 # Move the character right.',
	'# This line is a comment with "quotes" and another # symbol.',
	'    var indented = "padded"    # Comment with spaces before it.',
	'player.health=0#This is a valid comment.',
	'if user_input == "": # Handle empty input from the user.',
	'var final_message = "All operations complete."',
	'"some_literal" hello "#" there # bucko. "YERRRP"',
	'const SINGLETON_MODULE = "Plugin Exporter/Singleton Module"'
]


static func _run_tests():
	var regex = get_strings()
	for test_string in _TEST_STRINGS:
		var line = string_safe_regex_sub(test_string, _test_call, regex)
		print(line == test_string)
		string_safe_regex_read(test_string, _test_call, regex)
	
static func _test_call(line):
	print(line)
	return line
	
