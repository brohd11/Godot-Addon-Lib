extends Window

func _init(control, empty_panel:=true) -> void:
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	size = Vector2i(1200,800)
	EditorInterface.get_base_control().add_child(self)
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(panel)
	always_on_top = true
	
	if empty_panel:
		var panel_sb = StyleBoxEmpty.new()
		panel.add_theme_stylebox_override("panel", panel_sb)
	
	if is_instance_valid(control.get_parent()):
		control.reparent(panel)
	else:
		panel.add_child(control)
	
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	control.show()
