
const PlainHighlighter = preload("res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/types/plain_highlighter.gd")
const LogHighlighter = preload("res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/types/log_highlighter.gd")
const MarkdownHighlighter = preload("res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/types/markdown_highlighter.gd")
const IniHighlighter = preload("res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/types/ini_highlighter.gd")
const JsonHighlighter = preload("res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/types/json_highlighter.gd")
const YamlHighlighter = preload("res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/types/yaml_highlighter.gd")
const TomlHighlighter = preload("res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/types/toml_highlighter.gd")
const XmlHighlighter = preload("res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/types/xml_highlighter.gd")
const GdshHighlighter = preload("res://addons/addon_lib/brohd/alib_runtime/misc/syntax_highlighters/text/types/gdsh_highlighter.gd")

## Godot's default text file extensions, plus the editor console's gdsh scripts.
const EXTENSION_MAP := {
	"txt": PlainHighlighter,
	"md": MarkdownHighlighter,
	"cfg": IniHighlighter,
	"ini": IniHighlighter,
	"log": LogHighlighter,
	"json": JsonHighlighter,
	"yml": YamlHighlighter,
	"yaml": YamlHighlighter,
	"toml": TomlHighlighter,
	"xml": XmlHighlighter,
	"gdsh": GdshHighlighter,
}

## A fresh highlighter instance for [param extension], or null when it is not handled.
## Accepts "json", ".json" or "res://path/to/file.json".
static func get_highlighter(extension:String):
	var script = EXTENSION_MAP.get(normalize(extension))
	if script == null:
		return null
	return script.new()

static func supports(extension:String) -> bool:
	return EXTENSION_MAP.has(normalize(extension))

static func get_supported_extensions() -> PackedStringArray:
	var extensions := PackedStringArray()
	for extension in EXTENSION_MAP:
		extensions.append(extension)
	return extensions


static func normalize(extension:String) -> String:
	if extension.contains("."):
		extension = extension.get_extension()
	return extension.to_lower()
