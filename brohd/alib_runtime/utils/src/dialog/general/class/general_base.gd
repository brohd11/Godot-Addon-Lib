extends "res://addons/addon_lib/brohd/alib_runtime/utils/src/dialog/handler_base.gd"

var scene

func _init(dialog_scn, _root_node=null) -> void:
	_set_root_node(_root_node)
	_create_dialog(dialog_scn)

func _create_dialog(dialog_scn:PackedScene):
	
	dialog = DialogWindow.new()
	dialog.always_on_top = true
	dialog.close_requested.connect(_on_canceled)
	
	scene = dialog_scn.instantiate()
	dialog.title = scene.dialog_name
	dialog.add_content(scene)
	
	dialog.confirm_button.pressed.connect(_on_confirmed)
	dialog.cancel_button.pressed.connect(_on_canceled)
	
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	dialog.size = scene.window_size
	
	root_node.add_child(dialog)
	if scene.has_method("is_dialog"):
		scene.is_dialog()
	
	dialog.show()


func _on_confirmed():
	var param = null
	if scene.has_method("on_confirm_pressed"):
		param = await scene.on_confirm_pressed()
	if param == null:
		return
	self.handled.emit(param)
	dialog.queue_free()
	
func _on_canceled():
	self.handled.emit(CANCEL_STRING)
	dialog.queue_free()


class DialogWindow extends Window:
	var confirm_button:Button
	var cancel_button:Button
	var _button_hbox:HBoxContainer
	var _background:ColorRect
	
	var _content:VBoxContainer
	func _init():
		var base_control = Control.new()
		add_child(base_control)
		base_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_set_size_flags(base_control)
		
		_background = ColorRect.new()
		base_control.add_child(_background)
		_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_set_size_flags(_background)
		set_background_color()
		
		var main_vbox = VBoxContainer.new()
		#bg.add_child(main_vbox)
		base_control.add_child(main_vbox)
		main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_set_size_flags(main_vbox)
		
		var top_spacer = Control.new()
		top_spacer.custom_minimum_size = Vector2i(0, 10)
		main_vbox.add_child(top_spacer)
		
		_content = VBoxContainer.new()
		main_vbox.add_child(_content)
		_set_size_flags(_content)
		
		_button_hbox = HBoxContainer.new()
		main_vbox.add_child(_button_hbox)
		_button_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_button_hbox.add_spacer(false)
		
		cancel_button = Button.new()
		_button_hbox.add_child(cancel_button)
		set_cancel_button_text("Cancel")
		
		_button_hbox.add_spacer(false)
		
		confirm_button = Button.new()
		_button_hbox.add_child(confirm_button)
		set_confirm_button_text("Confirm")
		
		_button_hbox.add_spacer(false)
		
		var bottom_spacer = Control.new()
		bottom_spacer.custom_minimum_size = Vector2i(0, 10)
		main_vbox.add_child(bottom_spacer)
	
	func set_confirm_button_text(text):
		confirm_button.text = text
	
	func set_cancel_button_text(text):
		cancel_button.text = text
	
	func set_background_color(color=null):
		if color == null:
			var ed_interface = Engine.get_singleton("EditorInterface")
			if not ed_interface:
				_background.hide()
				return
			var base_control = ed_interface.get_base_control()
			color = base_control.get_theme_color("base_color", &"Editor")
		_background.color = color
	
	func add_content(new_content):
		_content.add_child(new_content)
		_set_size_flags(new_content)
	
	func hide_button(idx:int):
		if idx >= _button_hbox.get_child_count():
			push_error("Genreal Dialog Handler - Hide button index out of range.")
			return
		var control = _button_hbox.get_child(idx)
		control.hide()
	
	func get_button(idx:int):
		if idx >= _button_hbox.get_child_count():
			push_error("Genreal Dialog Handler - Get button index out of range.")
			return
		return _button_hbox.get_child(idx)
	
	func _set_size_flags(control):
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
