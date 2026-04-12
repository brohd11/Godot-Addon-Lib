#! namespace ALibEditor.Singletons class ScriptListManager
extends SingletonBase
const SingletonBase = Singleton.Base

const TEXT_FILE_TYPES = ["gd", "json", "cfg", "txt", "ini", "md"]

const PE_STRIP_CAST_SCRIPT = preload("res://addons/addon_lib/brohd/alib_editor/misc/script_list/script_list_manager.gd")
static func get_singleton_name() -> String:
	return "ScriptListManager"

static func get_instance() -> PE_STRIP_CAST_SCRIPT:
	return _get_instance(PE_STRIP_CAST_SCRIPT)

static func instance_valid() -> bool:
	return _instance_valid(PE_STRIP_CAST_SCRIPT)

static func call_on_ready(callable, print_err:bool=true):
	_call_on_ready(PE_STRIP_CAST_SCRIPT, callable, print_err)

func _get_ready_bool() -> bool:
	return _initialized

var _initialized:=false

var editor_script_tab_container:TabContainer

var script_list:ItemList
var filter_line_edit:LineEdit
var item_cache:= {}

var current_script_editor:Node

var _last_script_signature:Array
var _update_debounce:bool = false
var _update_timer:Timer

var tool_color:Color

signal cache_updated

func _ready() -> void:
	EditorNodeRef.call_on_ready(_on_enr_ready)
	tool_color = EditorInterface.get_editor_theme().get_color(&"accent_color", &"Editor")
	tool_color.s = min(tool_color.s * 1.5, 1.0)

func _on_enr_ready():
	var side_bar = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.SCRIPT_EDITOR_SIDEBAR_V_SPLIT)
	filter_line_edit = side_bar.get_child(0).get_child(0)
	script_list = side_bar.get_child(0).get_child(1)
	
	editor_script_tab_container = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.SCRIPT_EDITOR_TAB_CONTAINER)
	editor_script_tab_container.tab_changed.connect(_on_editor_tab_changed)
	current_script_editor = editor_script_tab_container.get_current_tab_control()
	
	ScriptEditorRef.subscribe(ScriptEditorRef.Event.VALIDATE_SCRIPT, _on_script_editor_validate, 1)
	
	update_cache()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed, 1)
	
	_update_timer = Timer.new()
	add_child(_update_timer)
	_update_timer.wait_time = 1.0
	_update_timer.timeout.connect(_on_update_timer_timeout)
	_update_timer.start()
	
	_initialized = true

func _on_update_timer_timeout(): # quick check for differences
	var arr = _get_list_signature()
	if arr != _last_script_signature:
		update_cache()
	_last_script_signature = arr

func _get_list_signature() -> Array:
	var sig = []
	for i in range(script_list.item_count):
		# meta + text to catch reorders, renames
		var meta = script_list.get_item_metadata(i)
		var text = script_list.get_item_text(i)
		sig.append(str(meta) + "_" + text)
	return sig


func _on_editor_tab_changed(_arg):
	current_script_editor = editor_script_tab_container.get_current_tab_control()
	update_cache()

func _on_script_editor_validate():
	update_cache()

func _on_filesystem_changed():
	_update_debounce = false
	update_cache()


func update_cache():
	if _update_debounce:
		return
	
	_update_debounce = true
	var current_text = filter_line_edit.text
	if current_text != "":
		#await get_tree().process_frame
		#_update_debounce = false
		#return
		filter_line_edit.clear() # option is to return or clear. This should probably just be cleared so it is always accurate, say script editor opened when filtering
	
	item_cache = get_all_script_data()
	
	#if current_text != "":
		#filter_line_edit.text = current_text
		#filter_line_edit.text_changed.emit(current_text)
	
	cache_updated.emit()
	await get_tree().process_frame
	_update_timer.start()
	_update_debounce = false
	

# need to redo
func get_cached_item_data(tooltip:String):
	for script_idx in item_cache.keys():
		var data = item_cache[script_idx]
		if data.get(Keys.TOOLTIP) == tooltip:
			return data

func get_current_script_editor():
	return current_script_editor

func get_current_script_editor_index():
	return current_script_editor.get_index()

func get_current_item():
	var sel = -1
	var items = script_list.get_selected_items()
	if not items.is_empty():
		sel = items[0]
	return sel

# need to redo
func get_item_by_tooltip(tooltip:String):
	var data = item_cache.get(tooltip)
	if data == null:
		return -1
	return data.get(Keys.ITEM_IDX, -1)


func get_current_item_data():
	var sel = get_current_item()
	if sel > -1:
		return get_item_data(sel)
	return {}

func get_item_data(idx:int):
	var text = script_list.get_item_text(idx)
	var tooltip = script_list.get_item_tooltip(idx)
	var icon = script_list.get_item_icon(idx)
	var icon_mod = script_list.get_item_icon_modulate(idx)
	var fg_color = script_list.get_item_custom_fg_color(idx)
	var script_idx = script_list.get_item_metadata(idx)
	return {
		Keys.ITEM_IDX: idx,
		#Keys.IDX: idx,
		Keys.NAME:text,
		Keys.TOOLTIP:tooltip,
		Keys.ICON: icon,
		Keys.ICON_MOD: icon_mod,
		Keys.FG_COLOR: fg_color,
		Keys.SCRIPT_IDX: script_idx,
		}


func is_item_tool(idx:int):
	return is_data_tool(get_item_data(idx))

func is_data_tool(data:Dictionary):
	return data.get(Keys.ICON_MOD) != Color.WHITE


func close_script_by_idx(idx:int):
	script_list.item_clicked.emit(idx, Vector2(), MOUSE_BUTTON_MIDDLE)

func right_click_by_idx(idx:int, position:Vector2):
	script_list.item_clicked.emit(idx, position, MOUSE_BUTTON_RIGHT)

func activate_item_by_idx(idx:int):
	script_list.item_selected.emit(idx)


func close_script_by_tooltip(tooltip:String):
	var idx = get_item_by_tooltip(tooltip)
	if idx == -1:
		printerr("COULD NOT GET SCRIPT::CLOSE::", tooltip)
		return
	script_list.item_clicked.emit(idx, Vector2(), MOUSE_BUTTON_MIDDLE)

func right_click_by_tooltip(tooltip:String, position:Vector2):
	var idx = get_item_by_tooltip(tooltip)
	if idx == -1:
		printerr("COULD NOT GET SCRIPT::RIGHT CLICK::", tooltip)
		return
	script_list.item_clicked.emit(idx, position, MOUSE_BUTTON_RIGHT)

func activate_item_by_tooltip(tooltip:String):
	var idx = get_item_by_tooltip(tooltip)
	if idx == -1:
		printerr("COULD NOT GET SCRIPT::ACTIVATE::", tooltip)
		return
	
	script_list.item_selected.emit(idx)

func get_all_script_data():
	var all_data = {}
	for i in range(script_list.item_count):
		var data = get_item_data(i)
		all_data[data.get(Keys.SCRIPT_IDX)] = data
	return all_data

func get_all_script_data_tooltip_key():
	var all_data = {}
	for i in range(script_list.item_count):
		var data = get_item_data(i)
		all_data[data.get(Keys.TOOLTIP)] = data
	return all_data

## Pass FileSystemSingleton instance. This allows ScriptTabs to be used without including the singleton.
func get_script_index_or_open(file_path:String, filesystem_singleton=null):
	var ext = file_path.get_extension()
	if not ext in TEXT_FILE_TYPES: return -1
	var script_list_data = get_cached_item_data(file_path)
	#print(file_path, "::DATA::", script_list_data)
	if script_list_data == null:
		if filesystem_singleton != null:
			if filesystem_singleton.instance_valid():
				filesystem_singleton.activate_path(file_path)
		elif ext == "gd":
			EditorInterface.edit_resource(load(file_path))
		return -1
	
	return script_list_data.get(Keys.SCRIPT_IDX)

func clear_script_list_filter():
	if is_instance_valid(filter_line_edit) and not filter_line_edit.text.is_empty():
		filter_line_edit.clear()

func script_list_filtering():
	return filter_line_edit.text != ""

class Keys:
	const ITEM_IDX = &"item_idx"
	const NAME = &"name"
	const TOOLTIP = &"tooltip"
	const ICON = &"icon"
	const ICON_MOD = &"icon_mod"
	#const IDX = &"idx"
	const SCRIPT_IDX = &"script_idx"
	const FG_COLOR = &"fg_color"
