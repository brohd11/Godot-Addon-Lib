
static var _token_regex: RegEx
#const pattern = "\"[^\"]*\"|'[^']*'|(\\[(?:[^\\[\\]]|(?1))*\\])|(\\{(?:[^{}]|(?2))*\\})|(\\((?:[^()]|(?3))*\\))|\\S+" # old version
const _TOKEN_PATTERN = "\".*?\"|'.*?'|#.*|[a-zA-Z_0-9]\\w*(?:\\.[a-zA-Z_0-9]\\w*)*|\n|[^\\w\\s]"

static func strip_symbols(text):
	var separators = " \t\n\r:,.()[]{}<>=+-*/!\"'@"
	#var separators = " \t\n\r:,.()[]{}<>=+-*/!@"
	var code_only_text = text.get_slice("#", 0)
	var clean_text = code_only_text
	for separator in separators:
		clean_text = clean_text.replace(separator, " ")
	var words = clean_text.split(" ", false)
	
	return words

static func tokenize_string(text: String, include_strings:=true, include_comments:=false, include_new_lines:=false) -> Dictionary:
	if _token_regex == null:
		_token_regex = RegEx.new()
		_token_regex.compile(_TOKEN_PATTERN)
	
	var tokens = PackedStringArray()
	if text.is_empty():
		return {"tokens":tokens}
	
	var matches = _token_regex.search_all(text)
	for _match in matches:
		var token = _match.get_string()
		
		if not include_strings and ((token.begins_with("\"") and token.ends_with("\"")) or (token.begins_with("'") and token.ends_with("'"))):
			continue
		if not include_comments and token.begins_with("#"):
			continue
		if not include_new_lines and token == "\n":
			continue
		
		tokens.push_back(token)
	
	return {
		"tokens": tokens,
	}
