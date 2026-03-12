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


var gdscript_parser:GDScriptParser


func _init(node):
	gdscript_parser = GDScriptParser.new()
	

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	ScriptEditorRef.subscribe(ScriptEditorRef.Event.VALIDATE_SCRIPT, _on_script_validate)
	ScriptEditorRef.subscribe(ScriptEditorRef.Event.EDITOR_SCRIPT_CHANGED, _on_editor_script_changed)
	_on_editor_script_changed(ScriptEditorRef.get_current_script())

func _on_text_changed():
	gdscript_parser.reset_caret_context()


func _on_script_validate():
	gdscript_parser.parse()

func _on_editor_script_changed(script):
	if is_instance_valid(script):
		await get_tree().process_frame
		var code_edit = ScriptEditorRef.get_current_code_edit()
		if is_instance_valid(code_edit):
			gdscript_parser.set_current_script(script)
			gdscript_parser.set_code_edit(code_edit)


func get_parser() -> GDScriptParser:
	return gdscript_parser

func get_caret_context() -> GDScriptParser.CaretContext:
	return gdscript_parser.get_caret_context()


#^ --- Singletone Methods

func _all_unregistered_callback():
	pass

func _get_ready_bool() -> bool:
	return is_node_ready()
