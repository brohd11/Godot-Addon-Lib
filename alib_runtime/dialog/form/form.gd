@tool
extends "res://addons/addon_lib/brohd/alib_runtime/utils/src/dialog/handler_base.gd"

# ! namespace ALibRuntime.Dialog

const Fields = preload("res://addons/addon_lib/brohd/alib_runtime/ui/fields/fields.gd")
enum FieldType {
	BOOL,
	LINE_EDIT,
	OPTION
}

enum TargetSection{
	HEADER,
	BODY,
	FOOTER,
}

var _form_build_data = {}
var constructed_data = {}
var _title:String=""
var default_size = Vector2(600, 400)


func _init(form_build_data:Dictionary, _root_node=null) -> void:
	_set_root_node(_root_node)
	_form_build_data = form_build_data

func set_title(title:String):
	_title = title

func add_bool(_name, icon=null, default:=false, target:TargetSection=TargetSection.BODY):
	_form_build_data[_name] = {
		Keys.TYPE:"bool",
		Keys.ICON:icon,
		Keys.DEFAULT: default,
		Keys.TARGET: target
	}



func show_dialog():
	dialog = DialogStructure.new()
	
	dialog.title = _form_build_data.get(Keys.TITLE, _title)
	dialog.size = _form_build_data.get(Keys.SIZE, default_size)
	
	for _name in _form_build_data.keys():
		var data = _form_build_data.get(_name)
		if data is not Dictionary:
			continue
		_add_field(_name, data)
	
	
	#dialog.reset_size.call_deferred()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	
	Engine.get_main_loop().root.add_child(dialog)
	#root_node.add_child(dialog)
	
	#dialog.popup()
	
	dialog.close_requested.connect(_on_canceled)
	dialog.cancel_button.pressed.connect(_on_canceled)
	dialog.confirm_button.pressed.connect(_on_confirmed)
	dialog.always_on_top = true
	
	#var _handle_var = await handled
	return await handled




func get_data():
	var data = {}
	for _name in constructed_data.keys():
		var control = constructed_data[_name]
		var build_data = _form_build_data.get(_name)
		if not build_data:
			continue
		var type = build_data.get(Keys.TYPE)
		var val
		if type == "bool":
			val = control.button_pressed
		elif type == "LineEdit":
			val = control.get_text()
		data[_name] = val
	
	return data

func _on_confirmed():
	self.handled.emit(get_data())
	dialog.queue_free()
	
func _on_canceled():
	self.handled.emit(CANCEL_STRING)
	dialog.queue_free()


func _add_field(_name, data):
	var type = data.get(Keys.TYPE)
	var icon = data.get(Keys.ICON)
	var control
	if type == "bool":
		control = Fields.get_bool(_name, icon)
	elif type == "LineEdit":
		var placeholder = data.get("placeholder", "")
		control = Fields.get_line_edit(_name, placeholder, icon)
	
	var target = data.get(Keys.TARGET, TargetSection.BODY)
	match target:
		TargetSection.HEADER: dialog.header.add_child(control)
		TargetSection.BODY: dialog.body.add_child(control)
		TargetSection.FOOTER: dialog.footer.add_child(control)
	
	constructed_data[_name] = control
	return control

class DialogStructure extends Window:
	
	var header:= VBoxContainer.new()
	var body:= VBoxContainer.new()
	var footer:= VBoxContainer.new()
	
	var cancel_button:= Button.new()
	var confirm_button:= Button.new()
	
	func _init() -> void:
		var bg = Panel.new()
		add_child(bg)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		var main_vbox := VBoxContainer.new()
		bg.add_child(main_vbox)
		main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		main_vbox.add_child(header)
		main_vbox.add_child(body)
		main_vbox.add_child(footer)
		
		var button_hbox = HBoxContainer.new()
		button_hbox.add_spacer(false)
		button_hbox.add_child(cancel_button)
		cancel_button.text = "Cancel"
		cancel_button.custom_minimum_size = Vector2(75, 0)
		button_hbox.add_spacer(false)
		button_hbox.add_child(confirm_button)
		confirm_button.text = "Confirm"
		confirm_button.custom_minimum_size = Vector2(75, 0)
		button_hbox.add_spacer(false)
		
		footer.add_child(button_hbox)
	
	
	func add_to_header(control:Control):
		header.add_child(control)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	func add_to_body(control:Control):
		body.add_child(control)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	func add_to_footer(control:Control):
		footer.add_child(control)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

class Keys:
	const TITLE = &"title"
	const SIZE = &"size"
	const NAME = &"name"
	const ICON = &"icon"
	const TYPE = &"type"
	const DEFAULT = &"default"
	const TARGET = &"target"
