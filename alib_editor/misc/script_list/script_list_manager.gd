#! namespace ALibEditor.Singletons class ScriptListManager
extends SingletonBase
const SingletonBase = Singleton.Base

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

signal cache_updated

func _ready() -> void:
	EditorNodeRef.call_on_ready(_on_enr_ready)

func _on_enr_ready():
	var side_bar = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.SCRIPT_EDITOR_SIDEBAR_V_SPLIT)
	filter_line_edit = side_bar.get_child(0).get_child(0)
	script_list = side_bar.get_child(0).get_child(1)
	
	editor_script_tab_container = EditorNodeRef.get_node_ref(EditorNodeRef.Nodes.SCRIPT_EDITOR_TAB_CONTAINER)
	editor_script_tab_container.tab_changed.connect(_on_editor_tab_changed)
	
	ScriptEditorRef.subscribe(ScriptEditorRef.Event.VALIDATE_SCRIPT, _on_script_editor_validate, 1)
	
	update_cache()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed, 1)
	_initialized = true

func _on_editor_tab_changed(_arg):
	current_script_editor = editor_script_tab_container.get_current_tab_control()
	update_cache()

func _on_script_editor_validate():
	update_cache()

func _on_filesystem_changed():
	update_cache()

func update_cache():
	var current_text = filter_line_edit.text
	if current_text != "":
		filter_line_edit.clear()
	
	item_cache = get_all_script_data()
	
	if current_text != "":
		filter_line_edit.text = current_text
		filter_line_edit.text_changed.emit(current_text)
	
	cache_updated.emit()

func get_cached_item_data(tooltip:String):
	return item_cache.get(tooltip)

func get_current_item():
	var sel = -1
	var items = script_list.get_selected_items()
	if not items.is_empty():
		sel = items[0]
	return sel

func get_item_by_tooltip(tooltip:String):
	var data = item_cache.get(tooltip)
	if data == null:
		return -1
	return data.get(Keys.IDX, -1)


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
		Keys.NAME:text,
		Keys.TOOLTIP:tooltip,
		Keys.ICON: icon,
		Keys.ICON_MOD: icon_mod,
		Keys.FG_COLOR: fg_color,
		Keys.IDX: script_idx
		}



func close_script_by_idx(idx:int):
	script_list.item_clicked.emit(idx, Vector2(), MOUSE_BUTTON_MIDDLE)

func right_click_by_idx(idx:int, position:Vector2):
	print("CLICKED RIGHT:: ", script_list, idx)
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
		var tooltip = script_list.get_item_tooltip(i)
		all_data[tooltip] = get_item_data(i)
	return all_data

func get_script_index_or_open(file_path:String):
	if not file_path.ends_with(".gd"): return -1
	var script_list_data = get_cached_item_data(file_path)
	if script_list_data == null:
		var script = load(file_path)
		EditorInterface.edit_script(script, 0)
		return -1
	
	return script_list_data.get(Keys.IDX)

class Keys:
	const NAME = &"name"
	const TOOLTIP = &"tooltip"
	const ICON = &"icon"
	const ICON_MOD = &"icon_mod"
	const IDX = &"idx"
	const FG_COLOR = &"fg_color"
