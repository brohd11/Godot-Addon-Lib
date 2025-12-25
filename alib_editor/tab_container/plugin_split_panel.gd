extends Control

const RightClickHandler = preload("res://addons/addon_lib/brohd/gui_click_handler/right_click_handler.gd")
const ClickState = preload("res://addons/addon_lib/brohd/gui_click_handler/click_state.gd")

var right_click_handler:RightClickHandler

var tool_bar:HBoxContainer
var dock_button:Button
var vbox:VBoxContainer
var main_container
var dock_overlay:DockOverlay

enum SplitType { 
	HORIZONTAL_L,
	HORIZONTAL_R,
	VERTICAL_U,
	VERTICAL_D,
	}

enum DropZone {
	NIL,
	CENTER,
	LEFT,
	RIGHT,
	UP,
	DOWN
	}


func _ready():
	right_click_handler = RightClickHandler.new()
	add_child(right_click_handler)
	
	vbox = VBoxContainer.new()
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	#tool_bar = HBoxContainer.new()
	#vbox.add_child(tool_bar)
	
	#dock_button = Button.new()
	#tool_bar.add_child(dock_button)
	
	main_container = MarginContainer.new()
	vbox.add_child(main_container)
	main_container.name = "MainContainer"
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var button_detector = Control.new()
	add_child(button_detector)
	button_detector.custom_minimum_size = Vector2(24,24) * 1.5
	button_detector.set_anchors_preset(PRESET_TOP_LEFT)
	button_detector.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var buttons_bg = ColorRect.new()
	button_detector.add_child(buttons_bg)
	buttons_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	#buttons_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	buttons_bg.color = EditorInterface.get_editor_theme().get_color("base_color", "Editor")
	#buttons_bg.color.a = 0.7
	buttons_bg.hide()
	
	var margin = MarginContainer.new()
	buttons_bg.add_child(margin)
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	
	var buttons_h = HBoxContainer.new()
	buttons_h.mouse_filter = Control.MOUSE_FILTER_PASS
	buttons_h.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_child(buttons_h)
	
	dock_overlay = DockOverlay.new()
	add_child(dock_overlay)
	dock_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dock_overlay.hide()
	dock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_overlay.move_panel.connect(_move_panel_to_split)
	dock_overlay.swap_panels.connect(_swap_panels)
	
	
	dock_button = Button.new()
	buttons_h.add_child(dock_button)
	dock_button.mouse_filter = Control.MOUSE_FILTER_PASS
	dock_button.theme_type_variation = &"MainScreenButton"
	dock_button.focus_mode = Control.FOCUS_NONE
	dock_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	button_detector.mouse_entered.connect(func():buttons_bg.show())
	button_detector.mouse_exited.connect(func():buttons_bg.hide())
	
	margin.resized.connect(func(): buttons_bg.custom_minimum_size = margin.size)
	
	var panel = _new_movable_panel()
	main_container.add_child(panel)


func get_dock_data():
	return get_layout_data()

func set_dock_data(data):
	load_layout(data)


# Call this function when a user wants to split a specific panel
# target_panel: The actual Control node being split
func split_panel(target_panel: Control, direction: SplitType):
	var new_panel = _new_movable_panel()
	_new_split_panel(target_panel, new_panel, direction)

func _move_panel_to_split(dragging_panel: Control, target_panel: Control, direction:DropZone):
	detach_panel(dragging_panel, false)
	var split_type:SplitType
	match direction:
		DropZone.UP: split_type = SplitType.VERTICAL_U
		DropZone.DOWN: split_type = SplitType.VERTICAL_D
		DropZone.LEFT: split_type = SplitType.HORIZONTAL_L
		DropZone.RIGHT: split_type = SplitType.HORIZONTAL_R
	_new_split_panel(target_panel, dragging_panel, split_type)

func _new_split_panel(target_panel: Control, new_panel:Control, direction: SplitType):
	var parent = target_panel.get_parent()
	var new_split = SplitContainer.new()
	if direction == SplitType.VERTICAL_U or direction == SplitType.VERTICAL_D:
		new_split.vertical = true
	
	new_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if parent == main_container: # Special case: Splitting the absolute root
		main_container.remove_child(target_panel)
		main_container.add_child(new_split)
	else: # Standard case: Replacing a child in an existing split
		var index = target_panel.get_index()
		parent.remove_child(target_panel)
		parent.add_child(new_split)
		parent.move_child(new_split, index)
	
	if direction == SplitType.HORIZONTAL_R or direction == SplitType.VERTICAL_D:
		new_split.add_child(target_panel) 
		new_split.add_child(new_panel)
	else:
		new_split.add_child(new_panel)
		new_split.add_child(target_panel) 

# Call with dispose = true when clicking "Close"
# Call with dispose = false when starting a drag/move
func detach_panel(panel: Control, dispose: bool = true):
	var parent_container = panel.get_parent()
	if parent_container == main_container:
		if dispose:
			parent_container.remove_child(panel)
			panel.queue_free()
		else:
			parent_container.remove_child(panel)
		return
	
	var split = parent_container
	var grand_parent = split.get_parent()
	
	var sibling = null
	for child in split.get_children():
		if child != panel:
			sibling = child
			break
	
	if sibling:
		var split_index = split.get_index()
		sibling.reparent(grand_parent, false)
		grand_parent.move_child(sibling, split_index)
		sibling.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sibling.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if dispose: # CASE: CLOSING
		pass 
	else: # CASE: MOVING
		split.remove_child(panel)
	split.queue_free()

func _close_panel(target_panel):
	detach_panel(target_panel, true)
	if main_container.get_child_count() == 0:
		var panel = _new_movable_panel()
		main_container.add_child(panel)

func _toggle_panel(panel:Control):
	var split = panel.get_parent()
	if split is SplitContainer:
		split.vertical = not split.vertical

func _on_panel_right_clicked(panel:MoveablePanel):
	var options = RightClickHandler.Options.new()
	options.add_option("Split/Left", split_panel.bind(panel, SplitType.HORIZONTAL_L))
	options.add_option("Split/Right", split_panel.bind(panel, SplitType.HORIZONTAL_R))
	options.add_option("Split/Up", split_panel.bind(panel, SplitType.VERTICAL_U))
	options.add_option("Split/Down", split_panel.bind(panel, SplitType.VERTICAL_D))
	if panel.get_parent() is SplitContainer:
		options.add_option("Toggle Split", _toggle_panel.bind(panel))
	
	options.add_option("Close", _close_panel.bind(panel))
	#options.add_option("Print", print_tree_pretty)
	
	right_click_handler.display_popup(options)


func _on_drag_started(panel):
	dock_overlay.show()
	dock_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var panel_nodes = _get_panels()
	var panel_rects = {}
	for p:MoveablePanel in panel_nodes:
		panel_rects[p.get_global_rect()] = p
	
	dock_overlay.panel_rects = panel_rects
	
	while get_window().gui_is_dragging():
		await get_tree().process_frame
	
	dock_overlay.hide()
	dock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _swap_panels(panel_a: Control, panel_b: Control):
	var panel_a_parent = panel_a.get_parent()
	var panel_b_parent = panel_b.get_parent()
	
	var panel_a_idx = panel_a.get_index()
	var panel_b_idx = panel_b.get_index()
	
	panel_a_parent.remove_child(panel_a)
	panel_b_parent.remove_child(panel_b)
	
	panel_a_parent.add_child(panel_b)
	panel_b_parent.add_child(panel_a)
	
	panel_a_parent.move_child(panel_b, panel_a_idx)
	panel_b_parent.move_child(panel_a, panel_b_idx)


func get_layout_data():
	if main_container.get_child_count() == 0:
		return {}
	var root_node = main_container.get_child(0)
	var layout_data = _serialize_node(root_node)
	return layout_data

func _serialize_node(node: Control) -> Dictionary:
	var data = {}
	if node is SplitContainer:
		data["type"] = "split"
		data["direction"] = "vertical" if node.vertical else "horizontal"
		data["offset"] = node.split_offset
		
		var children_data = []
		for child in node.get_children(): # Recursively save children
			children_data.append(_serialize_node(child))
		
		data["children"] = children_data
		
	else: # movable panel
		data["type"] = "panel"
		if node.get_child_count() > 0:
			var control = node.get_control()
			data["content_path"] = _get_panel_path(control)
		else:
			data["content_path"] = "" # Empty panel
		
		if node.has_method("get_dock_data"):
			data["panel_dock_data"] = node.get_dock_data()
	
	return data

func load_layout(data:Dictionary):
	if data.is_empty():
		return
	_clear_current_layout()
	_deserialize_node(data, main_container)

func _clear_current_layout():
	for child in main_container.get_children():
		child.queue_free()

func _deserialize_node(data: Dictionary, parent: Control):
	if data["type"] == "split":
		var split = SplitContainer.new()
		if data["direction"] == "vertical":
			split.vertical = true
		
		split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		split.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		parent.add_child(split)
		split.split_offset = data.get("offset", 0)
		
		for child_data in data["children"]:
			_deserialize_node(child_data, split)
		
	elif data["type"] == "panel":
		var p = _new_movable_panel()
		parent.add_child(p)
		var panel_dock_data = data.get("plugin_dock_data")
		var path = data.get("content_path", "")
		if path != "":
			var scene = _get_panel_instance(path)
			if scene:
				p.add_control(scene)
				if panel_dock_data and scene.has_method("set_dock_data"):
					scene.set_dock_data(panel_dock_data)
			else:
				print("Could not find scene: ", path)
				# Maybe load an error label or empty picker here


func _new_movable_panel():
	var panel = MoveablePanel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.picker_right_clicked.connect(_on_picker_right_clicked)
	panel.drag_started.connect(_on_drag_started)
	panel.right_clicked.connect(_on_panel_right_clicked)
	panel.swap_panels.connect(_swap_panels)
	panel.move_panel.connect(_move_panel_to_split)
	return panel

func _get_panels():
	var nodes = []
	for c in main_container.get_children():
		nodes.append_array(_get_panel_recur(c))
	return nodes

func _get_panel_recur(node: Control) -> Array:
	var nodes = []
	if node is SplitContainer:
		for child in node.get_children():
			nodes.append_array(_get_panel_recur(child))
	elif node is MoveablePanel:
		nodes.append(node)
	return nodes

func _get_panel_instance(path:String):
	var loaded = load(path)
	if loaded is PackedScene:
		return loaded.instantiate()
	elif loaded is GDScript:
		return loaded.new()

func _get_panel_path(node:Node) -> String:
	if node.scene_file_path != "":
		return node.scene_file_path
	var script = node.get_script()
	if script:
		return script.resource_path
	return ""

func _on_picker_right_clicked(panel:MoveablePanel):
	var options = RightClickHandler.Options.new()
	options.add_option("Print", print_tree_pretty)
	
	right_click_handler.display_popup(options)

class MoveablePanel extends Control:
	
	signal picker_right_clicked(panel)
	signal drag_started(panel)
	signal right_clicked(panel)
	signal swap_panels(from_panel, to_panel)
	signal move_panel(from_panel, to_panel, zone)
	
	var _drag_section:ColorRect
	var _vbox:VBoxContainer
	var _scene_picker
	
	func _ready():
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		_vbox = VBoxContainer.new()
		add_child(_vbox)
		_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		
		_scene_picker = Control.new()
		_vbox.add_child(_scene_picker)
		_scene_picker.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var _scene_picker_button = Button.new()
		_scene_picker.add_child(_scene_picker_button)
		_scene_picker_button.text = "Pick Scene/File"
		_scene_picker_button.custom_minimum_size = Vector2(75, 35)
		_scene_picker_button.set_anchors_and_offsets_preset(PRESET_CENTER,Control.PRESET_MODE_KEEP_SIZE)
		#_scene_picker_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		#_scene_picker_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		_scene_picker_button.pressed.connect(_on_picker_pressed)
		_scene_picker_button.gui_input.connect(_on_picker_gui_input)
		
		
		_drag_section = ColorRect.new()
		add_child(_drag_section)
		_drag_section.custom_minimum_size = Vector2(20,20)
		_drag_section.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
		_drag_section.color = Color.WHITE
		_drag_section.color.a = 0
		_drag_section.mouse_entered.connect(func():_drag_section.color.a = 0.3)
		_drag_section.mouse_exited.connect(func():_drag_section.color.a = 0)
		_drag_section.set_drag_forwarding(_get_drag_data, func(p,d):return false, func(p,d):return)
		_drag_section.gui_input.connect(_on_gui_input)
		
		### ADD CONTENT
		#var bg = ColorRect.new()
		#bg.color = Color(randf_range(0,0.7),randf_range(0,0.7),randf_range(0,0.7))
		#add_control(bg)
	
	func get_control():
		return _vbox.get_child(0)
	
	func _on_picker_pressed():
		var dialog = EditorFileDialogHandler.File.new()
		var handled = await dialog.handled
		if handled == dialog.CANCEL_STRING:
			return
		
		var path = handled
		var loaded = load(path)
		var scene
		if loaded is PackedScene:
			scene = loaded.instantiate()
		elif loaded is GDScript:
			scene = loaded.new()
		if not scene:
			print("Could not get scene: %s" % path)
			return
		
		add_control(scene)
	
	
	func add_control(control:Control):
		if is_instance_valid(_scene_picker):
			_vbox.remove_child(_scene_picker)
			_scene_picker.queue_free()
		if _vbox.get_child_count() > 0:
			print("Panel already has control, can not save more than one.")
		_vbox.add_child(control)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	func _on_gui_input(event: InputEvent) -> void:
		var state = ClickState.get_click_state(event) as ClickState.State
		if state == ClickState.State.RMB_RELEASED:
			right_clicked.emit(self)
	
	func _on_picker_gui_input(event: InputEvent) -> void:
		var state = ClickState.get_click_state(event) as ClickState.State
		if state == ClickState.State.RMB_RELEASED:
			picker_right_clicked.emit(self)
	
	func _get_drag_data(_at_position):
		var preview = Label.new()
		preview.text = "Moving " + name
		set_drag_preview(preview)
		drag_started.emit(self)
		return { "type": "plugin_panel_control", "node": self }


class DockOverlay extends Control:
	
	const EDGE_MARGIN = 0.25 # Top 25% creates a split, Center 50% swaps
	
	signal swap_panels(from_panel, to_panel)
	signal move_panel(from_panel, to_panel, zone)
	
	var panel_rects = {}
	var draw_data:= {}
	
	func _draw() -> void:
		if draw_data.is_empty():
			return
		var color = Color.WHITE
		var rect = draw_data.rect as Rect2
		var zone = draw_data.zone as DropZone
		if zone == DropZone.CENTER:
			draw_rect(rect, color, false)
		else:
			match zone:
				DropZone.LEFT: draw_line(rect.position, rect.position + Vector2(0, rect.size.y), color)
				DropZone.RIGHT: draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, color)
				DropZone.UP: draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), color)
				DropZone.DOWN: draw_line(rect.position + Vector2(0, rect.size.y), rect.position + rect.size, color)
	
	func _can_drop_data(at_position, data):
		queue_redraw()
		draw_data.clear()
		var source_panel = data["node"]
		var to_panel = _get_panel_at_position(at_position)
		if to_panel == source_panel:
			return false
		var zone = _calculate_drop_zone(at_position)
		if zone == DropZone.NIL:
			return false
		var rect = _get_rect_at_position(at_position)
		if rect == null:
			return false
		draw_data = {
			"position": at_position,
			"panel": to_panel,
			"zone":zone,
			"rect": rect
		}
		return data is Dictionary and data.get("type") == "plugin_panel_control"

	func _drop_data(at_position, data):
		var source_panel = data["node"]
		var to_panel = _get_panel_at_position(at_position)
		if to_panel == source_panel:
			return
		var zone = _calculate_drop_zone(at_position)
		if zone == DropZone.NIL:
			return
		#prints(source_panel, to_panel, DropZone.keys()[zone])
		if zone == DropZone.CENTER:
			swap_panels.emit(source_panel, to_panel)
		else:
			move_panel.emit(source_panel, to_panel, zone)
	
	func _calculate_drop_zone(at_position: Vector2) -> DropZone:
		var rect = _get_rect_at_position(at_position)
		if rect == null:
			return DropZone.NIL
		var s = rect.size
		var localized_pos = at_position - rect.position
		if localized_pos.y < s.y * EDGE_MARGIN:
			return DropZone.UP
		if localized_pos.y > s.y * (1.0 - EDGE_MARGIN):
			return DropZone.DOWN
		if localized_pos.x < s.x * EDGE_MARGIN:
			return DropZone.LEFT
		if localized_pos.x > s.x * (1.0 - EDGE_MARGIN):
			return DropZone.RIGHT
		return DropZone.CENTER
	
	func _get_rect_at_position(at_position:Vector2):
		for rect:Rect2 in panel_rects.keys():
			var adj_rect = _get_adjusted_rect(rect)
			if adj_rect.has_point(at_position):
				return adj_rect
	
	func _get_panel_at_position(at_position:Vector2):
		for rect:Rect2 in panel_rects.keys():
			var adj_rect = _get_adjusted_rect(rect)
			if adj_rect.has_point(at_position):
				return panel_rects[rect]
	
	func _get_adjusted_rect(rect:Rect2):
		rect.position -= global_position
		return rect
