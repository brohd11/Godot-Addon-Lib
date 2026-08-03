extends "res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/hl_base.gd"

## gdsh - the editor console's integrated shell language.
##
## Adapted from addons/editor_console/src/utils/misc/gdsh_hl.gd, which is a standalone
## [EditorSyntaxHighlighter]. Two things differ:
##
## - The source asked the CodeEdit delimiter parser ([code]is_in_string()[/code]) whether a
##   line began inside a string, which requires quotes to be registered as delimiters on that
##   specific [CodeEdit]. This uses the base class entry state cache instead, so it works on
##   any [TextEdit] and survives out of order line requests.
## - Colors come from the shared palette rather than the console's own color tables.
##
## Multiline: single and double quoted strings. Bit 0 of the state means the line begins inside
## a double quoted string, bit 1 inside a single quoted one.
##
## Unlike the other types this builds a per character color buffer and collapses it at the end.
## The grammar has a context stack - each [code]$( )[/code] pushes a frame so quotes inside a
## substitution are scoped separately from the surrounding string - which does not map onto
## in-order span emission.

const _STATE_DQ := 1
const _STATE_SQ := 2

const _EXPECT = &"expect"

const KEYWORDS := [
	"if", "elif", "else", "while", "for", "in",
	#"return", "break", "continue", # these are actually commands...
]

## Keywords whose *next* word is a command/condition, so `if return_test {` highlights
## return_test. `for`/`in`/`return` are deliberately excluded.
const CONDITION_KEYWORDS := ["if", "elif", "while", "else"]


func _init() -> void:
	multiline = true

func _tokenize(line:int, entry_state:int, map:Dictionary) -> int:
	var text := text_edit.get_line(line)
	var n := text.length()
	var colors:Array = []
	colors.resize(n)
	for k in n:
		colors[k] = palette.text

	# Context stack seeded from the incoming state. A line that begins inside a string is not
	# in command position, matching the source's `_EXPECT: not start_in_string`.
	var stack:Array = [{
		"dq": (entry_state & _STATE_DQ) != 0,
		"sq": (entry_state & _STATE_SQ) != 0,
		_EXPECT: entry_state == STATE_NORMAL,
	}]
	
	var i := 0
	var after_function := false
	
	while i < n:
		var f:Dictionary = stack[-1]
		var c := text[i]
	
		# ---- single-quoted: literal, no expansion ------------------------
		if f["sq"]:
			colors[i] = palette.string
			if c == "'":
				f["sq"] = false
				f[_EXPECT] = false
			i += 1
			continue
	
		# ---- double-quoted: $ expands, $( opens a sub-context ------------
		if f["dq"]:
			if c == "\\" and i + 1 < n:
				colors[i] = palette.string
				colors[i + 1] = palette.string
				i += 2
				continue
			if c == "$" and i + 1 < n and text[i + 1] == "(":
				colors[i] = palette.symbol
				colors[i + 1] = palette.bracket
				stack.append({"dq": false, "sq": false, _EXPECT: true})
				i += 2
				continue
			if c == "$":
				var adv := _color_variable(text, i, colors)
				if adv > 0:
					i += adv
					continue
			colors[i] = palette.string
			if c == "\"":
				f["dq"] = false
				f[_EXPECT] = false
			i += 1
			continue
		
		# ---- code context ------------------------------------------------
		if c == " " or c == "\t":
			i += 1
			continue
		
		if c == "#" and _is_comment_start(text, i):
			for k in range(i, n):
				colors[k] = palette.comment
			break
		
		if c == "\"":
			colors[i] = palette.string
			f["dq"] = true
			i += 1
			continue
		if c == "'":
			colors[i] = palette.string
			f["sq"] = true
			i += 1
			continue
		
		if c == "$" and i + 1 < n and text[i + 1] == "(":   # command substitution
			colors[i] = palette.symbol
			colors[i + 1] = palette.bracket
			stack.append({"dq": false, "sq": false, _EXPECT: true})
			i += 2
			continue
		if c == "$":
			var v := _color_variable(text, i, colors)
			if v > 0:
				i += v
				f[_EXPECT] = false
				continue
		
		# multi-char operators
		var two := text.substr(i, 2)
		if two == "&&" or two == "||" or two == ";;" or two == "==" \
				or two == "!=" or two == ">>" or two == "<<":
			colors[i] = palette.symbol
			colors[i + 1] = palette.symbol
			i += 2
			if two == "&&" or two == "||" or two == ";;":
				f[_EXPECT] = true
			continue
		
		# single-char operators
		if c == "|" or c == ";" or c == "&":
			colors[i] = palette.symbol
			i += 1
			f[_EXPECT] = true
			continue
		if c == "=" or c == "<" or c == ">" or c == "!":
			colors[i] = palette.symbol
			i += 1
			continue
		
		# closing a $( ) returns to the enclosing context (its dq may resume)
		if c == ")" and stack.size() > 1:
			colors[i] = palette.bracket
			stack.pop_back()
			i += 1
			continue
		
		# brackets
		if c == "[" or c == "]":
			colors[i] = palette.tag
			i += 1
			f[_EXPECT] = false
			continue
		
		if c == "{" or c == "(":
			colors[i] = palette.bracket
			i += 1
			f[_EXPECT] = true
			continue
		if c == "}" or c == ")":
			colors[i] = palette.bracket
			i += 1
			f[_EXPECT] = false
			continue

		# numbers
		if is_digit(c):
			var ns := i
			while i < n and (is_digit(text[i]) or text[i] == "."):
				i += 1
			for k in range(ns, i):
				colors[k] = palette.number
			continue

		# words: keyword / command / function / assignment / argument
		if is_identifier_start(c):
			var ws := i
			while i < n and is_identifier_char(text[i]):
				i += 1
			var word := text.substr(ws, i - ws)
			var col:Color = palette.text
			var next_expect := false

			if after_function:
				col = palette.function           # `function foo` style
				after_function = false
			elif word in KEYWORDS:
				col = palette.control_flow
				if word == "function":
					after_function = true
				elif word in CONDITION_KEYWORDS:
					next_expect = true           # `if cmd {`, `while cmd {`, ...
			elif f[_EXPECT]:
				if i < n and text[i] == "=" \
						and not (i + 1 < n and text[i + 1] == "="):
					col = palette.variable       # NAME=value assignment
				elif _is_function_def(text, i):
					col = palette.function       # name() { ... }
				else:
					col = palette.tag            # command position

			for k in range(ws, i):
				colors[k] = col
			f[_EXPECT] = next_expect
			continue

		i += 1                                    # anything else

	collapse(colors, map)

	# The frame actually in effect at end of line. An unclosed $( loses its depth, which is
	# malformed input either way.
	var top:Dictionary = stack[-1]
	var state := STATE_NORMAL
	if top["dq"]:
		state |= _STATE_DQ
	if top["sq"]:
		state |= _STATE_SQ
	return state


## Color a $variable starting at [param i]. Returns chars consumed, or 0 if `$` is not a
## variable here.
func _color_variable(text:String, i:int, colors:Array) -> int:
	var n := text.length()
	if i + 1 >= n:
		return 0
	var c2 := text[i + 1]

	if c2 == "{":                                   # ${ ... }
		var j := i + 2
		while j < n and text[j] != "}":
			j += 1
		if j < n:
			j += 1
		for k in range(i, j):
			colors[k] = palette.variable
		return j - i

	if c2 == "(":                                   # $( ... ) handled by caller
		return 0

	if is_identifier_start(c2):                     # $name
		var j := i + 1
		while j < n and is_identifier_char(text[j]):
			j += 1
		for k in range(i, j):
			colors[k] = palette.variable
		return j - i

	# special parameters: $? $@ $# $$ $! $* $- $0..$9
	if c2 in ["?", "@", "#", "$", "!", "*", "-",
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
		colors[i] = palette.variable
		colors[i + 1] = palette.variable
		return 2

	return 0


## True if what follows a word (skipping spaces) is "()".
func _is_function_def(text:String, after_word:int) -> bool:
	var n := text.length()
	var j := after_word
	while j < n and (text[j] == " " or text[j] == "\t"):
		j += 1
	if j >= n or text[j] != "(":
		return false
	j += 1
	while j < n and (text[j] == " " or text[j] == "\t"):
		j += 1
	return j < n and text[j] == ")"


## `#` only starts a comment at a token boundary (not mid-word like a#b).
func _is_comment_start(text:String, i:int) -> bool:
	if i == 0:
		return true
	var p := text[i - 1]
	return p == " " or p == "\t" or p == ";" or p == "|" \
			or p == "&" or p == "(" or p == "{"
