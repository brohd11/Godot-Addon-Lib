#! namespace ALibEditor.Singletons class EditorGDScriptParser
extends SingletonRefCount
const SingletonRefCount = Singleton.RefCount
## Implement in extended classes

const GDScriptParser = ALibRuntime.Utils.UResource.UGDScript.Parser


# Use 'PE_STRIP_CAST_SCRIPT' to auto strip type casts with plugin exporter, if the class is not a global name
const PE_STRIP_CAST_SCRIPT = preload("res://addons/addon_lib/brohd/alib_editor/misc/parser/editor_parser.gd")

static func get_singleton_name() -> String:
	return "EditorGDScriptParser"

static func get_instance() -> PE_STRIP_CAST_SCRIPT:
	return _get_instance(PE_STRIP_CAST_SCRIPT)

static func instance_valid() -> bool:
	return _instance_valid(PE_STRIP_CAST_SCRIPT)

static func register_node(node:Node):
	return _register_node(PE_STRIP_CAST_SCRIPT, node)

static func unregister_node(node:Node):
	_unregister_node(PE_STRIP_CAST_SCRIPT, node)

static func call_on_ready(callable, print_err:bool=true):
	_call_on_ready(PE_STRIP_CAST_SCRIPT, callable, print_err)


const SCRIPT_CACHE_SIZE = 40

signal editor_script_changed(script)
signal parse_completed

var gdscript_parser:GDScriptParser

var _parse_queued:bool = false
var _parser_cache:Dictionary = {}


func _init(node):
	gdscript_parser = GDScriptParser.new()
	_set_parser_cache()



func _set_parser_cache():
	gdscript_parser.set_parser_cache(_parser_cache)
	gdscript_parser.set_parser_cache_size(SCRIPT_CACHE_SIZE)

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	ScriptEditorRef.subscribe(ScriptEditorRef.Event.VALIDATE_SCRIPT, _on_script_validate)
	ScriptEditorRef.subscribe(ScriptEditorRef.Event.EDITOR_SCRIPT_CHANGED, _on_editor_script_changed)
	_on_editor_script_changed(ScriptEditorRef.get_current_script())
	

func _on_text_changed():
	gdscript_parser.reset_caret_context()


func _on_script_validate():
	gdscript_parser.parse()
	parse_completed.emit()
	gdscript_parser.clean_parser_cache.call_deferred()

func _on_editor_script_changed(script):
	if is_instance_valid(script):
		await get_tree().process_frame
		var code_edit = ScriptEditorRef.get_current_code_edit()
		if is_instance_valid(code_edit):
			gdscript_parser.set_current_script(script)
			gdscript_parser.set_code_edit(code_edit)
			editor_script_changed.emit(script)
			_parse()

static func queue_parse(force:=false):
	get_instance()._parse(force)

func _parse(force:=false):
	if _parse_queued:
		return
	_parse_queued = true
	gdscript_parser.parse(force)
	parse_completed.emit()
	await get_tree().process_frame
	_parse_queued = false


static func get_parser(script_path:String="") -> GDScriptParser:
	var ins = get_instance()
	if script_path == "" or script_path == ins.gdscript_parser.get_script_path():
		return ins.gdscript_parser
	else:
		return ins.gdscript_parser.get_parser_for_path(script_path)

func get_caret_context() -> GDScriptParser.CaretContext:
	return gdscript_parser.get_caret_context()

static func clear_cache():
	var ins = get_instance()
	ins._parser_cache.clear()
	ins._set_parser_cache()

static func cache_size():
	return get_instance()._parser_cache.size()

#^ --- Singletone Methods

func _all_unregistered_callback():
	pass

func _get_ready_bool() -> bool:
	return is_node_ready()
