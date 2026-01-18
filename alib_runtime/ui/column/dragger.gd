extends Control

var dragging: bool = false
var target_column: Control
var mouse_in_dragger:= false

var grabber_icon:Texture2D

signal drag_ended

func _ready():
	mouse_default_cursor_shape = Control.CURSOR_HSPLIT
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	mouse_entered.connect(func(): mouse_in_dragger = true; queue_redraw())
	mouse_exited.connect(func(): mouse_in_dragger = false; queue_redraw())
	
	custom_minimum_size.x = 4
	
	var ed_interface = Engine.get_singleton(&"EditorInterface")
	if ed_interface:
		grabber_icon = ed_interface.get_editor_theme().get_icon("h_grabber", "SplitContainer")
		custom_minimum_size.x *= ed_interface.get_editor_scale()


func _draw():
	if mouse_in_dragger or dragging:
		if grabber_icon:
			var pos = size / 2
			draw_texture(grabber_icon, pos)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if not dragging:
				drag_ended.emit()
				queue_redraw()
	
	if dragging and event is InputEventMouseMotion:
		if target_column:
			var new_width = target_column.custom_minimum_size.x + event.relative.x
			new_width = max(200.0, new_width)
			target_column.custom_minimum_size.x = new_width
