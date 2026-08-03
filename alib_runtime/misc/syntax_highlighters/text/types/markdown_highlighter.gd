extends "res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/hl_base.gd"

## md - headings, emphasis, code, links, lists and tables.
##
## Multiline: fenced code blocks, both [code]```[/code] and [code]~~~[/code]. Fence bodies are
## not highlighted as their info language, they take the code color as a whole.

const _STATE_FENCE_BACKTICK := 1
const _STATE_FENCE_TILDE := 2


func _init() -> void:
	multiline = true


func _tokenize(line:int, entry_state:int, map:Dictionary) -> int:
	var text := text_edit.get_line(line)
	var length := text.length()
	var start := indent_of(text)
	var rest := text.substr(start)

	if entry_state != STATE_NORMAL:
		var fence := "```" if entry_state == _STATE_FENCE_BACKTICK else "~~~"
		if rest.begins_with(fence):
			push(map, start, palette.symbol)
			return STATE_NORMAL
		if length > 0:
			push(map, 0, palette.code)
		return entry_state

	if start >= length:
		return STATE_NORMAL

	if rest.begins_with("```") or rest.begins_with("~~~"):
		var fence_char := text[start]
		var run := start
		while run < length and text[run] == fence_char:
			run += 1
		push(map, start, palette.symbol)
		push(map, run, palette.keyword)
		return _STATE_FENCE_BACKTICK if fence_char == "`" else _STATE_FENCE_TILDE

	var i := start

	# Blockquote markers, which nest: "> > quoted".
	while i < length and text[i] == ">":
		push(map, i, palette.symbol)
		push(map, i + 1, palette.text)
		i += 1
		while i < length and text[i] == " ":
			i += 1

	if i >= length:
		return STATE_NORMAL

	# ATX heading. The whole line takes the heading color, inline markup inside it is ignored.
	if text[i] == "#":
		var hashes := i
		while hashes < length and text[hashes] == "#":
			hashes += 1
		if hashes - i <= 6 and (hashes >= length or text[hashes] == " "):
			push(map, i, palette.heading)
			return STATE_NORMAL

	var trimmed := text.substr(i).strip_edges()
	if _is_repeated(trimmed, "="):
		push(map, i, palette.heading)
		return STATE_NORMAL
	if _is_repeated(trimmed, "-") or _is_repeated(trimmed, "*") or _is_repeated(trimmed, "_"):
		push(map, i, palette.symbol)
		return STATE_NORMAL

	# Unordered and ordered list markers.
	if "-*+".contains(text[i]) and i + 1 < length and text[i + 1] == " ":
		push(map, i, palette.symbol)
		push(map, i + 1, palette.text)
		i += 2
	elif is_digit(text[i]):
		var digits := i
		while digits < length and is_digit(text[digits]):
			digits += 1
		if digits < length and ".)".contains(text[digits]) \
			and digits + 1 < length and text[digits + 1] == " ":
			push(map, i, palette.symbol)
			push(map, digits + 1, palette.text)
			i = digits + 1

	_tokenize_inline(text, i, map)
	return STATE_NORMAL


func _tokenize_inline(text:String, from:int, map:Dictionary) -> void:
	var length := text.length()
	var i := from

	while i < length:
		var c := text[i]

		if c == "\\":
			i += 2
			continue

		if c == "`":
			var ticks := 0
			while i + ticks < length and text[i + ticks] == "`":
				ticks += 1
			push(map, i, palette.code)
			var code_close := text.find("`".repeat(ticks), i + ticks)
			if code_close == -1:
				return
			i = code_close + ticks
			push(map, i, palette.text)
			continue

		if c == "*" or c == "_":
			var marks := 0
			while i + marks < length and text[i + marks] == c:
				marks += 1
			var emphasis_close := text.find(c.repeat(marks), i + marks)
			if emphasis_close == -1:
				i += marks
				continue
			push(map, i, palette.keyword)
			i = emphasis_close + marks
			push(map, i, palette.text)
			continue

		# Links and images: [text](url) / ![alt](url).
		if c == "[" or (c == "!" and i + 1 < length and text[i + 1] == "["):
			var bracket := i if c == "[" else i + 1
			var bracket_close := text.find("]", bracket)
			if bracket_close != -1 and bracket_close + 1 < length and text[bracket_close + 1] == "(":
				var paren_close := text.find(")", bracket_close)
				if paren_close != -1:
					push(map, i, palette.symbol)
					push(map, bracket + 1, palette.text)
					push(map, bracket_close, palette.symbol)
					push(map, bracket_close + 2, palette.link)
					push(map, paren_close, palette.symbol)
					push(map, paren_close + 1, palette.text)
					i = paren_close + 1
					continue
			i += 1
			continue

		# Autolinks and raw html.
		if c == "<":
			var angle_close := text.find(">", i)
			if angle_close != -1:
				push(map, i, palette.link)
				push(map, angle_close + 1, palette.text)
				i = angle_close + 1
				continue

		if c == "|":
			push(map, i, palette.symbol)
			push(map, i + 1, palette.text)
			i += 1
			continue

		i += 1


## True when [param text] is three or more of [param c] and nothing else.
static func _is_repeated(text:String, c:String) -> bool:
	if text.length() < 3:
		return false
	for i in text.length():
		if text[i] != c:
			return false
	return true
