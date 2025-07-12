@tool
extends Node

const UFile = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_file.gd")
const DockPopupHandler = preload("res://addons/addon_lib/brohd/dock_manager/dock_popup/dock_popup_handler.gd") #>remote
const Docks = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/docks.gd")
const _MainScreenHandlerClass = preload("res://addons/addon_lib/brohd/dock_manager/class/main_screen_handler.gd")
const _MainScreenHandlerMultiClass = preload("res://addons/addon_lib/brohd/dock_manager/class/main_screen_handler_multi.gd")
const PanelWindow = preload("res://addons/addon_lib/brohd/dock_manager/class/panel_window.gd")

var MainScreenHandler #>class_inst

var plugin:EditorPlugin
var plugin_control:Control
var dock_button:Button
var default_dock:int
var multi_gui:bool
var can_be_freed:bool

enum Slot{
	FLOATING,
	BOTTOM_PANEL,
	MAIN_SCREEN,
	DOCK_SLOT_LEFT_UL,
	DOCK_SLOT_LEFT_BL,
	DOCK_SLOT_LEFT_UR,
	DOCK_SLOT_LEFT_BR,
	DOCK_SLOT_RIGHT_UL,
	DOCK_SLOT_RIGHT_BL,
	DOCK_SLOT_RIGHT_UR,
	DOCK_SLOT_RIGHT_BR,
}
const _slot = {
	Slot.FLOATING: -3,
	Slot.BOTTOM_PANEL: -2,
	Slot.MAIN_SCREEN: -1,
	Slot.DOCK_SLOT_LEFT_UL: EditorPlugin.DockSlot.DOCK_SLOT_LEFT_UL,
	Slot.DOCK_SLOT_LEFT_BL: EditorPlugin.DockSlot.DOCK_SLOT_LEFT_BL,
	Slot.DOCK_SLOT_LEFT_UR: EditorPlugin.DockSlot.DOCK_SLOT_LEFT_UR,
	Slot.DOCK_SLOT_LEFT_BR: EditorPlugin.DockSlot.DOCK_SLOT_LEFT_BR,
	Slot.DOCK_SLOT_RIGHT_UL: EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_UL,
	Slot.DOCK_SLOT_RIGHT_BL: EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BL,
	Slot.DOCK_SLOT_RIGHT_UR: EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_UR,
	Slot.DOCK_SLOT_RIGHT_BR: EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BR,
}

signal free_requested(dock_manager)

static func hide_main_screen_button(_plugin):
	_MainScreenHandlerClass.hide_main_screen_button(_plugin)

func _init(_plugin:EditorPlugin, _plugin_control, _default_dock:Slot=Slot.BOTTOM_PANEL, _can_be_freed:=false, _multi_gui:=false) -> void:
	plugin = _plugin
	if _plugin_control is Control:
		plugin_control = _plugin_control
	elif _plugin_control is PackedScene:
		plugin_control = _plugin_control.instantiate()
	
	default_dock = _slot.get(_default_dock)
	multi_gui = _multi_gui
	can_be_freed = _can_be_freed
	#if can_be_freed:
		#free_requested.connect(_plugin._on_free_requested.bind())
	_init_async()

func _init_async():
	plugin.add_child(plugin_control)
	await plugin.get_tree().process_frame
	plugin.remove_child(plugin_control)
	
	if "dock_button" in plugin_control:
		dock_button = plugin_control.dock_button
		dock_button.icon = EditorInterface.get_base_control().get_theme_icon("MakeFloating", &"EditorIcons")
		dock_button.pressed.connect(_on_dock_button_pressed)
	else:
		print("Need dock button in scene to use Dock Manager.")
	if multi_gui:
		MainScreenHandler = _MainScreenHandlerMultiClass.new(plugin, plugin_control)
	else:
		plugin_control.name = plugin._get_plugin_name()
		MainScreenHandler = _MainScreenHandlerClass.new(plugin, plugin_control)
	plugin.add_child(MainScreenHandler)
	
	var layout_data = load_layout_data()
	var dock_target = layout_data.get("current_dock", default_dock)
	if dock_target == null:
		dock_target = default_dock
	if dock_target > -3:
		dock_instance(int(dock_target))
	else:
		undock_instance()

func _ready() -> void:
	plugin.add_child(self)

func clean_up():
	save_layout_data()
	_remove_control_from_parent()
	plugin_control.queue_free()
	MainScreenHandler.clean_up()
	MainScreenHandler.queue_free()
	
	queue_free()

func free_instance():
	clean_up()

func load_layout_data():
	if not FileAccess.file_exists(_get_layout_file_path()):
		var dir = _get_layout_file_path().get_base_dir()
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
			UFile.write_to_json({}, _get_layout_file_path())
		return {}
	var data = UFile.read_from_json(_get_layout_file_path())
	var scene_data = data.get(plugin_control.scene_file_path, {})
	return scene_data

func save_layout_data():
	if not is_instance_valid(plugin_control):
		return
	var current_dock = Docks.get_current_dock(plugin_control)
	if current_dock == -3:
		return
	var data = {}
	if FileAccess.file_exists(_get_layout_file_path()):
		data = UFile.read_from_json(_get_layout_file_path())
	var scene_data = {"current_dock": current_dock}
	data[plugin_control.scene_file_path] = scene_data
	UFile.write_to_json(data, _get_layout_file_path())

func _get_layout_file_path():
	#var script = self.get_script() as Script
	var script = plugin.get_script()
	var path = script.resource_path
	var dir = path.get_base_dir()
	var layout_path = dir.path_join(".dock_manager/layout.json")
	return layout_path

func _on_dock_button_pressed():
	var dock_popup_handler = DockPopupHandler.new(plugin_control)
	if can_be_freed:
		dock_popup_handler.can_be_freed()
	
	var handled = await dock_popup_handler.handled
	if handled is String:
		return
	
	var current_dock = Docks.get_current_dock(plugin_control)
	if current_dock == handled:
		return
	if handled == 20:
		free_instance.call_deferred()
		#free_requested.emit(self)
	elif handled == -3:
		undock_instance()
	else:
		dock_instance(handled)

func dock_instance(target_dock:int):
	var window = plugin_control.get_window()
	_remove_control_from_parent()
	if target_dock > -1:
		plugin.add_control_to_dock(target_dock, plugin_control)
	elif target_dock == -1:
		MainScreenHandler.add_main_screen_control(plugin_control)
	elif target_dock == -2:
		var name = plugin_control.name
		plugin.add_control_to_bottom_panel(plugin_control, name)
	
	if is_instance_valid(window):
		if window is PanelWindow:
			window.queue_free()

func undock_instance():
	_remove_control_from_parent()
	var window = PanelWindow.new(plugin_control)
	window.close_requested.connect(window_close_requested)
	#window.mouse_entered.connect(_on_window_mouse_entered.bind(window))
	#window.mouse_exited.connect(_on_window_mouse_exited)
	
	return window

func _remove_control_from_parent():
	var window = plugin_control.get_window()
	var current_dock = Docks.get_current_dock(plugin_control)
	var control_parent = plugin_control.get_parent()
	if is_instance_valid(control_parent):
		if current_dock > -1:
			plugin.remove_control_from_docks(plugin_control)
		elif current_dock == -1:
			MainScreenHandler.remove_main_screen_control(plugin_control)
		elif current_dock == -2:
			plugin.remove_control_from_bottom_panel(plugin_control)
		else:
			control_parent.remove_child(plugin_control)
	
	if is_instance_valid(window):
		if window is PanelWindow:
			window.queue_free()


func window_close_requested() -> void:
	var layout_data = load_layout_data()
	var current_dock = layout_data.get("current_dock", default_dock)
	dock_instance(current_dock)
func _on_window_mouse_entered(window):
	window.grab_focus()
func _on_window_mouse_exited():
	EditorInterface.get_base_control().get_window().grab_focus()
