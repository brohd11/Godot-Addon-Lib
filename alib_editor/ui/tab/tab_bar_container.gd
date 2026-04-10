extends VBoxContainer

const _TAB_CONTROL = &"_tab_control"

var _tab_panel:PanelContainer
var _tab_bar:TabBar
var _tab_bar_hbox:HBoxContainer
var _tab_vbox:VBoxContainer

var _current_tab_idx:int = 0

var _tab_meta:= {}

signal tab_changed(tab:int)

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	_tab_bar_hbox = HBoxContainer.new()
	add_child(_tab_bar_hbox)
	
	_tab_panel = PanelContainer.new()
	_tab_bar_hbox.add_child(_tab_panel)
	var ed_theme = EditorInterface.get_editor_theme()
	_tab_panel.add_theme_stylebox_override(&"panel", ed_theme.get_stylebox(&"tabbar_background", &"TabContainer"))
	
	_tab_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_bar = TabBar.new()
	_tab_panel.add_child(_tab_bar)
	#_tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	_tab_vbox = VBoxContainer.new()
	add_child(_tab_vbox)
	_tab_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_tab_bar.active_tab_rearranged.connect(_on_active_tab_rearranged)
	_tab_vbox.child_exiting_tree.connect(_on_child_exiting_tree)

func _on_active_tab_rearranged(idx_to:int):
	for i in range(_tab_bar.tab_count):
		var control = _get_tab_control_from_meta(i)
		_tab_vbox.move_child(control, i)
	set_current_tab(idx_to)


func get_tab_count():
	return _tab_bar.tab_count

func get_tab_bar():
	return _tab_bar

func get_tab_bar_hbox():
	return _tab_bar_hbox

func get_tab_parent():
	return _tab_vbox

func set_current_tab(tab:int):
	if tab != _tab_bar.current_tab:
		_tab_bar.current_tab = tab
	else:
		_on_tab_changed(tab)

func add_tab(control:Control, icon=null):
	_tab_vbox.add_child(control)
	_tab_bar.add_tab(control.name, icon)
	_tab_bar.set_tab_metadata(_tab_bar.tab_count - 1, {_TAB_CONTROL:control})
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_on_tab_changed(_tab_bar.tab_count - 1)

func remove_tab(tab:int, free_tab:=true):
	if free_tab:
		var control = get_tab_control(tab)
		control.queue_free()
	_tab_bar.remove_tab(tab)

func get_current_tab_control():
	return _tab_vbox.get_child(_tab_bar.current_tab)

func get_tab_control(tab:int):
	return _tab_vbox.get_child(tab)

func _on_tab_changed(tab:int):
	var current_tab = get_current_tab_control()
	for i in range(_tab_bar.tab_count):
		var control = get_tab_control(i)
		control.visible = control == current_tab
	tab_changed.emit(tab)

func _on_child_exiting_tree(node:Node):
	if node.is_queued_for_deletion():
		for i in range(_tab_bar.tab_count):
			var control = _get_tab_control_from_meta(i)
			if control == node:
				_tab_bar.remove_tab(i)
				break

func set_tab_meta_value(tab:int, key:String, value):
	var meta = _tab_bar.get_tab_metadata(tab)
	meta[key] = value
	_tab_bar.set_tab_metadata(tab, meta)

func get_tab_meta_value(tab:int, key:String):
	var meta = _tab_bar.get_tab_metadata(tab)
	return meta.get(key)

func _get_tab_control_from_meta(tab:int):
	var meta = _tab_bar.get_tab_metadata(tab)
	return meta.get(_TAB_CONTROL)
