class_name ScriptEditorRef
extends Singleton.Base
## Singleton for accessing script editor nodes and signals. Manages the signals for the current script editor.

const SCRIPT = preload("res://addons/addon_lib/brohd/alib_editor/script_editor_ref/script_editor_ref.gd")

static func get_singleton_name() -> String:
	return "ScriptEditorRef"

static func get_instance() -> ScriptEditorRef:
	return _get_instance(SCRIPT)

static func call_on_ready(callable:Callable):
	_call_on_ready(SCRIPT, callable)

enum Event{
	EDITOR_SCRIPT_CHANGED, # some com
	VALIDATE_SCRIPT,
	CODE_COMPLETION_REQUESTED,
	TEXT_CHANGED,
	
}

static func subscribe(event:Event, _callable:Callable):
	var instance = get_instance()
	var _signal
	if event == Event.EDITOR_SCRIPT_CHANGED:
		_signal = instance.editor_script_changed
	elif event == Event.VALIDATE_SCRIPT:
		_signal = instance.validate_script
	elif event == Event.CODE_COMPLETION_REQUESTED:
		_signal = instance.code_completion_requested
	elif event == Event.TEXT_CHANGED:
		_signal = instance.text_changed
	
	if _signal != null:
		_connect_signal(_signal, _callable)



static func get_current_script_text_editor():
	var instance = get_instance()
	if not is_instance_valid(instance._current_script_text_editor):
		instance._set_refs()
	return instance._current_script_text_editor

static func get_current_code_text_editor():
	var instance = get_instance()
	if not is_instance_valid(instance._current_code_text_editor):
		instance._set_refs()
	return instance._current_code_text_editor

static func get_current_code_edit():
	var instance = get_instance()
	if not is_instance_valid(instance._current_code_edit):
		instance._set_refs()
	return instance._current_code_edit

static func get_current_script():
	var instance = get_instance()
	if not is_instance_valid(instance._current_script):
		instance._set_refs()
	return instance._current_script

# instance vars

var _current_script_text_editor:ScriptEditorBase
var _current_code_text_editor
var _current_code_edit:CodeEdit
var _current_script

#ScriptEditor
signal editor_script_changed(script)

#ScriptEditorBase

# CodeTextEditor
signal validate_script

#CodeEdit
signal code_completion_requested
signal text_changed

func _ready() -> void:
	_set_refs()
	_connect_signal(EditorInterface.get_script_editor().editor_script_changed, _on_editor_script_changed)


func _on_editor_script_changed(script):
	if script == null:
		return
	_disconnect_signals()
	_set_refs()
	_connect_signals()
	
	editor_script_changed.emit(script)


func _connect_signals():
	
	# CodeTextEditor
	if is_instance_valid(_current_code_text_editor):
		_connect_signal(_current_code_text_editor.validate_script, _on_validate_script)
	
	# CodeEdit
	if is_instance_valid(_current_code_edit):
		_connect_signal(_current_code_edit.code_completion_requested, _on_code_completion_requested)
		_connect_signal(_current_code_edit.text_changed, _on_text_changed) # may want to limit this? Not sure how much string allocation is happening

func _disconnect_signals():
	
	# CodeTextEditor
	if is_instance_valid(_current_code_text_editor):
		_disconnect_signal(_current_code_text_editor.validate_script, _on_validate_script)
	
	# CodeEdit
	if is_instance_valid(_current_code_edit):
		_disconnect_signal(_current_code_edit.code_completion_requested, _on_code_completion_requested)
		_disconnect_signal(_current_code_edit.text_changed, _on_text_changed)

func _set_refs():
	_current_script_text_editor = EditorInterface.get_script_editor().get_current_editor()
	if _current_script_text_editor == null:
		return
	
	_current_code_text_editor = _get_code_text_editor(_current_script_text_editor)
	_current_code_edit = _current_script_text_editor.get_base_editor()
	
	_current_script = EditorInterface.get_script_editor().get_current_script()

 

#^ events

func _on_validate_script():
	validate_script.emit()

func _on_code_completion_requested():
	code_completion_requested.emit()

func _on_text_changed():
	text_changed.emit()


#^ utils

func _get_code_text_editor(script_text_editor:ScriptEditorBase):
	var vsplit:VSplitContainer
	for c in script_text_editor.get_children():
		if c is VSplitContainer:
			vsplit = c
			break
	if not vsplit:
		return
	for c in vsplit.get_children():
		if c.get_class() == "CodeTextEditor":
			return c


static func _connect_signal(_signal:Signal, callable:Callable):
	if callable == null:
		print(_signal)
		return
	if not _signal.is_connected(callable):
		_signal.connect(callable)

static func _disconnect_signal(_signal:Signal, callable:Callable):
	if callable == null:
		print(_signal)
		return
	if _signal.is_connected(callable):
		_signal.disconnect(callable)
