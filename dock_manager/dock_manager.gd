@tool
class_name DockManager
extends Node

#! import-p Keys,
#! import-show-global DockManager,

const UFile = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_file.gd")
const UName = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_name.gd")
const DockPopupHandler = preload("res://addons/addon_lib/brohd/dock_manager/dock_popup/dock_popup_handler.gd")
const Docks = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/docks.gd")
const BottomPanel = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/bottom_panel.gd")
const MainScreen = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/main_screen.gd")
const MainScreenHandler = preload("res://addons/addon_lib/brohd/dock_manager/class/main_screen_handler.gd")
const MainScreenHandlerMulti = preload("res://addons/addon_lib/brohd/dock_manager/class/main_screen_handler_multi.gd")
const PanelWindow = preload("res://addons/addon_lib/brohd/dock_manager/class/panel_window.gd")

const WORKING_FILE_DIR = "user://addons/dock_manager"

const SET_DOCK_DATA = "set_dock_data"
const GET_DOCK_DATA = "get_dock_data"

var main_screen_handler
var external_main_screen_flag := false

var dock_tab_style:= 0

# init args
var plugin:EditorPlugin
var plugin_control:Control
var dock_button:Button
var default_dock:int
var last_dock:int
var can_be_freed:bool = false

var plugin_has_main:bool = false
var window_title:String = ""
var empty_panel:bool = false
var _default_window_size:= Vector2i(1200,800)
var save_layout:bool = true
var allow_scene_reload:bool = false
var _docked_name:String = ""


var dock_id:= -1
var dock_id_key:
	get:
		return str(dock_id)

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

signal dock_changed(dock_manager)
signal free_requested(dock_manager)


static func hide_main_screen_button(_plugin):
	MainScreenHandler.hide_main_screen_button(_plugin)

static func get_plugin_layout_data(_plugin:EditorPlugin):
	var working_dir = get_layout_file_dir(_plugin)
	if not DirAccess.dir_exists_absolute(working_dir):
		DirAccess.make_dir_recursive_absolute(working_dir)
	var working_file = working_dir.path_join("layout.json")
	if not FileAccess.file_exists(working_file):
		var default_data = {
			Keys.META:{Keys.NEXT_ID:0},
			Keys.DOCKS:{}
		}
		UFile.write_to_json(default_data, working_file)
	
	return UFile.read_from_json(working_file)

static func save_plugin_layout_data(_plugin:EditorPlugin, data:Dictionary):
	var working_dir = get_layout_file_dir(_plugin)
	if not DirAccess.dir_exists_absolute(working_dir):
		DirAccess.make_dir_recursive_absolute(working_dir)
	var working_file = working_dir.path_join("layout.json")
	UFile.write_to_json(data, working_file)

static func get_layout_file_path(_plugin:EditorPlugin):
	var layout_dir = get_layout_file_dir(_plugin)
	var layout_file = layout_dir.path_join("layout.json")
	return layout_file

static func get_layout_file_dir(_plugin:EditorPlugin):
	var script = _plugin.get_script()
	var path = script.resource_path
	var dir_name = path.get_base_dir().get_file()
	return WORKING_FILE_DIR.path_join(dir_name)


func _init(_plugin:EditorPlugin, _control, _dock:Slot=Slot.BOTTOM_PANEL, 
	_main_screen_handler=null, _add_to_tree:=true) -> void:
	plugin = _plugin
	if _control is Control:
		plugin_control = _control
	elif _control is PackedScene:
		plugin_control = _control.instantiate()
	
	if _plugin_has_main_screen(plugin):
		plugin_has_main = plugin._has_main_screen()
	else:
		plugin_has_main = false
	
	default_dock = _slot.get(_dock)
	if default_dock == -1 and not plugin_has_main:
		default_dock = -2 # if cant handle main, set to bottom panel
	last_dock = default_dock
	
	if _main_screen_handler != null:
		main_screen_handler = _main_screen_handler
		external_main_screen_flag = true
	
	_docked_name = get_docked_name()
	plugin_control.name = get_docked_name()
	
	_set_editor_settings()
	EditorInterface.get_editor_settings().settings_changed.connect(_set_editor_settings)
	
	if _add_to_tree:
		post_init()

func add_to_tree():
	await post_init()

func post_init():
	if plugin_has_main:
		if not is_instance_valid(main_screen_handler):
			main_screen_handler = MainScreenHandler.new(plugin, plugin_control)
			plugin.add_child(main_screen_handler)
	if is_instance_valid(main_screen_handler) and not plugin_has_main:
		printerr("Dock Manager has MainScreenHandler, but plugin doesn't handle main screen.")
	
	var dock_target
	var dock_index = -1
	var dock_data
	if save_layout:
		var layout_data = get_plugin_layout_data(plugin)
		if dock_id == -1:
			var meta = layout_data.get(Keys.META)
			dock_id = meta.get(Keys.NEXT_ID)
			
			save_plugin_layout_data(plugin, layout_data)
			save_layout_data.call_deferred()
		else:
			var docks = layout_data.get(Keys.DOCKS)
			var dock_layout_data = docks.get(dock_id_key)
			dock_target = dock_layout_data.get(Keys.CURRENT_DOCK)
			dock_index = dock_layout_data.get(Keys.CURRENT_DOCK_INDEX, -1)
			dock_data = dock_layout_data.get(Keys.DOCK_DATA, {})
	
	if dock_target != null:
		dock_target -= 3 #^ to offset saved enum back to working val
	else:
		dock_target = default_dock
	if dock_target > -3:
		dock_instance(int(dock_target))
		if dock_target >= 0 and dock_index > -1:
			var dock_control = get_current_dock_control() as TabContainer
			dock_control.move_child(plugin_control, dock_index)
	else:
		undock_instance()
	
	if save_layout:
		if plugin_control.has_method(SET_DOCK_DATA) and dock_data != null:
			plugin_control.call(SET_DOCK_DATA, dock_data)
	
	if window_title == "":
		window_title = get_docked_name()
	
	if "dock_button" in plugin_control:
		dock_button = plugin_control.dock_button
		dock_button.icon = EditorInterface.get_base_control().get_theme_icon("MakeFloating", &"EditorIcons")
		dock_button.pressed.connect(_on_dock_button_pressed)
		dock_button.show()
	else:
		print("Need dock button in scene to use Dock Manager.")
		plugin_control.queue_free()
		return
	
	if "dock_manager" in plugin_control:
		plugin_control.dock_manager = self
	
	_set_dock_tab_style.call_deferred() # need this even more delayed?


func _set_editor_settings():
	var ed_settings = EditorInterface.get_editor_settings()
	dock_tab_style = ed_settings.get_setting(EditorSet.DOCK_TAB_STYLE)
	
	await plugin.get_tree().create_timer(3).timeout
	_set_dock_tab_style()

func set_default_window_size(size:Vector2i):
	_default_window_size = size

func set_window_title(title:String):
	window_title = title

func _ready() -> void:
	plugin.add_child(self)

func get_plugin_control():
	return plugin_control

func show_in_editor():
	var current_dock = _get_current_dock()
	if current_dock > -1:
		var dock_control = get_current_dock_control()
		if dock_control is TabContainer:
			var i = dock_control.get_tab_idx_from_control(plugin_control)
			dock_control.current_tab = i
	elif current_dock == -2:
		BottomPanel.show_panel(_docked_name)
	

func clean_up():
	save_layout_data()
	_remove_control_from_parent()
	
	if not external_main_screen_flag and plugin_has_main:
		main_screen_handler.clean_up()
		main_screen_handler.queue_free()
	
	plugin_control.queue_free()
	queue_free()

func reload_control():
	save_layout_data() # saves before reloading
	
	var is_scene = plugin_control.scene_file_path != ""
	var control_path = get_scene_or_script(plugin_control)
	
	_remove_control_from_parent()
	plugin_control.queue_free()
	if main_screen_handler is MainScreenHandler:
		main_screen_handler.queue_free()
		main_screen_handler = null
	
	if is_scene:
		var packed:PackedScene = load(control_path)
		plugin_control = packed.instantiate()
	else:
		var script = load(control_path)
		plugin_control = script.new()
	
	await plugin.get_tree().process_frame
	add_to_tree()
	show_in_editor()

func free_instance():
	clean_up()
	_erase_dock_from_data()

func _erase_dock_from_data():
	var layout_data = get_plugin_layout_data(plugin)
	var docks = layout_data.get(Keys.DOCKS)
	docks.erase(dock_id_key)
	layout_data[Keys.META][Keys.NEXT_ID] = _get_next_dock_id(docks)
	
	save_plugin_layout_data(plugin, layout_data)


func _get_next_dock_id(docks:Dictionary):
	var count:= 0
	while docks.has(str(count)):
		count += 1
	return count

func save_layout_data():
	if not save_layout:
		return
	if not is_instance_valid(plugin_control):
		return
	var current_dock = _get_current_dock()
	var is_tab = current_dock >= 0
	current_dock += 3 #^ offset to get the enum val
	
	var layout_data = get_plugin_layout_data(plugin)
	var docks = layout_data.get(Keys.DOCKS)
	var scene_data = docks.get(dock_id_key, {})
	var file_path = get_scene_or_script(plugin_control)
	scene_data[Keys.SCENE_PATH] = file_path
	scene_data[Keys.CURRENT_DOCK] = current_dock
	if is_tab:
		var dock_control = get_current_dock_control() as TabContainer
		scene_data[Keys.CURRENT_DOCK_INDEX] = dock_control.get_tab_idx_from_control(plugin_control)
	if can_be_freed:
		scene_data[Keys.TYPE] = Keys.FREEABLE
	else:
		scene_data[Keys.TYPE] = Keys.PERSISTENT
	if allow_scene_reload:
		scene_data[Keys.ALLOW_RELOAD] = true
	
	if plugin_control.has_method(GET_DOCK_DATA):
		scene_data[Keys.DOCK_DATA] = plugin_control.call(GET_DOCK_DATA)
	
	docks[dock_id_key] = scene_data
	layout_data[Keys.DOCKS] = docks
	
	var meta = layout_data.get(Keys.META)
	meta[Keys.NEXT_ID] = _get_next_dock_id(docks)
	
	save_plugin_layout_data(plugin, layout_data)


func _on_dock_button_pressed():
	var dock_popup_handler = DockPopupHandler.new(plugin_control)
	if can_be_freed:
		dock_popup_handler.can_be_freed()
	if not plugin_has_main:
		dock_popup_handler.disable_main_screen()
	if allow_scene_reload:
		dock_popup_handler.allow_reload()
	
	var handled = await dock_popup_handler.handled
	if handled is String:
		return
	
	var current_dock
	if plugin_control.get_parent() is PanelWrapper:
		current_dock = _slot.get(Slot.MAIN_SCREEN)
	else:
		current_dock = Docks.get_current_dock(plugin_control)
	if current_dock == handled:
		return
	
	if handled == 20:
		free_requested.emit(self)
		free_instance.call_deferred()
	elif handled == 30:
		reload_control()
		return
		
	
	elif handled == _slot.get(Slot.FLOATING):
		undock_instance()
	else:
		dock_instance(handled)
	
	save_layout_data()

func dock_instance(target_dock:int):
	if target_dock == -3:
		if default_dock > -3:
			target_dock = default_dock
		else:
			target_dock = -2
	if target_dock == -1 and not plugin_has_main:
		target_dock = default_dock
	
	var window = plugin_control.get_window()
	_remove_control_from_parent()
	if target_dock > -1:
		plugin.add_control_to_dock(target_dock, plugin_control)
		_set_dock_tab_style()
	elif target_dock == -1:
		var panel_wrapper = PanelWrapper.new(plugin_control, empty_panel)
		panel_wrapper.name = get_docked_name()
		main_screen_handler.add_main_screen_control(panel_wrapper)
	elif target_dock == -2:
		plugin.add_control_to_bottom_panel(plugin_control, get_docked_name())
	
	if is_instance_valid(window):
		if window is PanelWindow:
			window.queue_free()
	
	dock_changed.emit(self)


func undock_instance():
	_remove_control_from_parent()
	var window = PanelWindow.new(plugin_control, empty_panel, _default_window_size)
	window.title = window_title
	window.close_requested.connect(window_close_requested)
	#window.mouse_entered.connect(_on_window_mouse_entered.bind(window))
	#window.mouse_exited.connect(_on_window_mouse_exited)
	
	dock_changed.emit(self)
	return window

func _remove_control_from_parent():
	var window = plugin_control.get_window()
	var current_dock = _get_current_dock()
	if current_dock != null:
		last_dock = current_dock
	var control_parent = plugin_control.get_parent()
	if is_instance_valid(control_parent):
		if current_dock > -1:
			plugin.remove_control_from_docks(plugin_control)
		elif current_dock == -1:
			var panel_wrapper = plugin_control.get_parent()
			main_screen_handler.remove_main_screen_control(panel_wrapper)
			panel_wrapper.remove_child(plugin_control)
			panel_wrapper.queue_free()
		elif current_dock == -2:
			plugin.remove_control_from_bottom_panel(plugin_control)
			BottomPanel.show_first_panel()
		else:
			control_parent.remove_child(plugin_control)
	
	if is_instance_valid(window):
		if window is PanelWindow:
			window.queue_free()

func _get_current_dock():
	if plugin_control.get_parent() is PanelWrapper:
		return _slot.get(Slot.MAIN_SCREEN)
	else:
		return Docks.get_current_dock(plugin_control)

func get_current_dock_control():
	return Docks.get_current_dock_control(plugin_control)

func window_close_requested() -> void:
	dock_instance(last_dock)
func _on_window_mouse_entered(window):
	window.grab_focus()
func _on_window_mouse_exited():
	EditorInterface.get_base_control().get_window().grab_focus()

func on_plugin_make_visible(visible:bool):
	main_screen_handler.on_plugin_make_visible(visible)

static func clean_dock_manager_array(instances:Array):
	InstanceManager._clean_dock_manager_array(instances)


func _get_plugin_icon():
	if not external_main_screen_flag:
		if plugin.has_method("_get_plugin_icon"):
			return plugin._get_plugin_icon()
	if "icon" in plugin_control:
		return plugin_control.get("icon")
	elif "plugin_icon" in plugin_control:
		return plugin_control.get("plugin_icon")
	return null

func _set_dock_tab_style():
	var dock = get_current_dock_control()
	if dock is not TabContainer:
		return
	var idx = dock.get_tab_idx_from_control(plugin_control)
	var plugin_name = get_docked_name()
	var icon = _get_plugin_icon()
	if dock_tab_style == 0 or icon == null: #^ text
		dock.set_tab_title(idx, plugin_name)
		dock.set_tab_icon(idx, null)
	elif dock_tab_style == 1: #^ icon
		dock.set_tab_title(idx, "")
		dock.set_tab_icon(idx, icon)
	elif dock_tab_style == 2: #^ text and icon
		dock.set_tab_title(idx, plugin_name)
		dock.set_tab_icon(idx, icon)


static func get_scene_or_script(control):
	if control is PackedScene:
		return control.resource_path
	elif control is Control:
		if control.scene_file_path != "":
			return control.scene_file_path
		var script = control.get_script()
		var script_path = script.resource_path
		if script_path == "":
			print("No scene or script path for control: %s" % control)
		return script_path
	else:
		print("DockManager - get_scene_or_script: Unhandled object")

static func _plugin_has_main_screen(_plugin:EditorPlugin):
	return _plugin.has_method("_has_main_screen")

class PanelWrapper extends PanelContainer:
	var _empty_pan := false
	func _init(control, _empty_panel:= false) -> void:
		add_child(control)
		_empty_pan = _empty_panel
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		
	func _ready() -> void:
		var panel_sb
		if _empty_pan:
			panel_sb = StyleBoxEmpty.new()
		else:
			panel_sb = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			panel_sb.content_margin_left = 4
			panel_sb.content_margin_right = 4
		
		add_theme_stylebox_override("panel", panel_sb)

class InstanceManager:
	var instances:Array[DockManager] = []
	var _msh#:MainScreenHandlerMulti
	var _plugin:EditorPlugin
	var _single_instance:bool
	
	func _init(_plug:EditorPlugin, _load_freeable_docks:=true, single_instance:=false) -> void:
		_plugin = _plug
		_single_instance = single_instance
		if DockManager._plugin_has_main_screen(_plugin):
			_msh = MainScreenHandlerMulti.new(_plugin)
			DockManager.hide_main_screen_button(_plugin)
		
		if _load_freeable_docks:
			load_freeable_docks.call_deferred()
	
	func load_freeable_docks():
		var layout_data = DockManager.get_plugin_layout_data(_plugin)
		var docks = layout_data.get(Keys.DOCKS, {})
		var current_ids = get_current_dock_ids()
		for id in docks.keys():
			var id_int = int(id)
			if id_int in current_ids:
				continue
			var data = docks.get(id, {})
			var type = data.get(Keys.TYPE, "nil")
			if type != Keys.FREEABLE:
				continue
			var current_dock = data.get(Keys.CURRENT_DOCK)
			var path = data.get(Keys.SCENE_PATH)
			if not FileAccess.file_exists(path):
				printerr("Dock Manager - Scene doesn't exist: %s, %s" % [path, DockManager.get_layout_file_path(_plugin)])
				continue
			var scn = load(path)
			if scn is GDScript:
				scn = scn.new()
			var ins = DockManager.new(_plugin, scn, current_dock, _msh, false)
			ins.can_be_freed = true
			var allow_reload = data.get(Keys.ALLOW_RELOAD, false)
			if allow_reload:
				ins.allow_scene_reload = true
			ins.dock_id = id_int
			ins.add_to_tree()
			instances.append(ins)
			current_ids.append(id_int)
	
	func new_persistent_dock_manager(scene, slot:Slot, _add_to_tree:=true):
		return _new_dock_manager(scene, slot, false, _add_to_tree)
	func new_freeable_dock_manager(scene, slot:Slot, _add_to_tree:=true):
		return _new_dock_manager(scene, slot, true, _add_to_tree)
	
	func _new_dock_manager(scene, slot:Slot, _can_be_freed:=false, _add_to_tree:=true):
		var scene_path = DockManager.get_scene_or_script(scene)
		
		if _single_instance:
			for ins in instances:
				if not is_instance_valid(ins):
					continue
				var ins_path = DockManager.get_scene_or_script(ins.plugin_control)
				if ins_path == scene_path:
					print("Scene already instanced: ", scene_path)
					return
		
		var ins = DockManager.new(_plugin,scene, slot, _msh, false)
		ins.can_be_freed = _can_be_freed
		var id = _get_dock_data(scene, _can_be_freed)
		if id > -1:
			ins.dock_id = id
		if _add_to_tree:
			ins.add_to_tree()
		
		clean_dock_manager_array()
		instances.append(ins)
		return ins
	
	func get_current_dock_ids():
		var _ids = []
		for i in instances:
			if is_instance_valid(i):
				_ids.append(i.dock_id)
		return _ids
	
	func _get_dock_data(scene, _can_be_freed:bool):
		var target_type = Keys.FREEABLE if _can_be_freed else Keys.PERSISTENT
		var layout_data = DockManager.get_plugin_layout_data(_plugin)
		var docks = layout_data.get(Keys.DOCKS, {})
		var current_ids = get_current_dock_ids()
		var scene_path = ""
		if scene is PackedScene:
			scene_path = scene.resource_path
		elif scene is Control:
			scene_path = DockManager.get_scene_or_script(scene)
		
		for id in docks.keys():
			var id_int = int(id)
			if id_int in current_ids:
				continue
			var data = docks.get(id, {})
			var type = data.get(Keys.TYPE, "nil")
			if type != target_type:
				continue
			var path = data.get(Keys.SCENE_PATH)
			if path == scene_path:
				return id_int
		return -1
	
	func on_plugin_make_visible(visible:bool):
		if is_instance_valid(_msh):
			_msh.on_plugin_make_visible(visible)
	
	func save_layout_data():
		for i in instances:
			if is_instance_valid(i):
				i.save_layout_data()
	
	func clean_dock_manager_array():
		_clean_dock_manager_array(instances)
	
	static func _clean_dock_manager_array(instances:Array):
		var invalid_positions = []
		for i in range(instances.size()):
			if is_instance_valid(instances[i]):
				continue
			invalid_positions.append(i)
	
		invalid_positions.reverse()
		for i in invalid_positions:
			instances.remove_at(i)
	
	func clean_up():
		for ins in instances:
			if is_instance_valid(ins):
				ins.clean_up()

func get_docked_name():
	if _docked_name != "":
		return _docked_name
	if not external_main_screen_flag:
		if plugin.has_method("_get_plugin_name"):
			return plugin._get_plugin_name()
	var _name = plugin_control.name
	return _name

class EditorSet:
	const DOCK_TAB_STYLE = &"interface/editor/dock_tab_style"

class Keys:
	const DOCKS = "docks"
	const TYPE = "type"
	const FREEABLE = "freeable"
	const PERSISTENT = "persistent"
	const ALLOW_RELOAD = "allow_reload"
	const SCENE_PATH = "scene_path"
	const CURRENT_DOCK = "current_dock"
	const CURRENT_DOCK_INDEX = "current_dock_index"
	const DOCK_DATA = "dock_data"
	
	const META = "meta"
	const NEXT_ID = "next_id"
