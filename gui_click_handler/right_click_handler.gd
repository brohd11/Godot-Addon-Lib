@tool
extends Node

#! import-p PopupHelper,

const PopupHelper = preload("res://addons/addon_lib/brohd/alib_runtime/popup_menu/popup_menu_path_helper.gd")
const MouseHelper = PopupHelper.MouseHelper

var popup:PopupMenu
var mouse_helper:MouseHelper

var hide_popup_with_timer:bool = false

var _custom_id_pressed_callable:Callable

var _click_debounce_timer:float = 0
var _click_debounce_time: float = 0.3

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	popup = PopupHelper.new()
	popup.wrap_controls = true
	popup.submenu_popup_delay = 0
	_set_popup_parent()
	mouse_helper = MouseHelper.new(popup, _on_mouse_helper_timeout)
	
	popup.popup_hide.connect(_on_popup_hide)


func set_custom_id_pressed_callable(callable):
	_custom_id_pressed_callable = callable


func display_popup(items_dict:Dictionary):
	popup.clear(true)
	
	PopupHelper.parse_dict_static(items_dict, popup, _popup_id_pressed, mouse_helper)
	popup.reset_size()
	_move_popup()


func _move_popup():
	_set_popup_parent()
	popup.position = DisplayServer.mouse_get_position() - _get_popup_offset()
	popup.show()


func _popup_id_pressed(id:int, _popup:PopupMenu):
	if _custom_id_pressed_callable.is_valid():
		_custom_id_pressed_callable.call(id, _popup)
		return
	
	var metadata = PopupHelper.parse_metadata(id, _popup)
	var callable = metadata.get(Params.CALLABLE)
	if callable is Callable:
		callable.call()


func _on_mouse_helper_timeout():
	if hide_popup_with_timer:
		_hide_popup()

func _hide_popup():
	popup.hide()
	_remove_popup_from_tree()


func _on_popup_hide():
	_hide_popup()


func _get_popup_offset():
	var item_count = popup.item_count
	var size_y = popup.size.y
	var size_per_item = size_y / item_count
	return Vector2i(15, size_per_item * 0.5)

func _set_popup_parent():
	var target_parent = get_window().get_child(0)
	if popup.get_parent() == null:
		target_parent.add_child(popup)
	elif popup.get_window() != get_window():
		popup.reparent(target_parent)

func _remove_popup_from_tree():
	popup.get_parent().remove_child(popup)


func _process(delta: float) -> void:
	if _click_debounce_timer != 0:
		_click_debounce_timer -= delta
		_click_debounce_timer = clampf(_click_debounce_timer,0,1)


func get_double_click():
	if _click_debounce_timer == 0:
		_click_debounce_timer = _click_debounce_time
		return false
	return true


class Params extends PopupHelper.ParamKeys:
	const CALLABLE = &"callable"
