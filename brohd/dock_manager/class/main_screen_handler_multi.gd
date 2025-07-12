@tool
extends Node

const MainScreen = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/main_screen.gd")

var editor_plugin:EditorPlugin
var plugin_control:Control
var plugin_button:Button
var main_screen_button:Button

static var plugin_buttons = []

func _init(_editor_plugin, _plugin_control) -> void:
	editor_plugin = _editor_plugin
	plugin_control = _plugin_control
	
	_connect_buttons()
	var main_bar = MainScreen.get_button_container()
	main_bar.child_entered_tree.connect(_child_entered_tree)
	for child in main_bar.get_children():
		if String(child.name) == editor_plugin._get_plugin_name():
			main_screen_button = child
			main_screen_button.hide()
			break


func clean_up():
	if is_instance_valid(main_screen_button):
		main_screen_button.text = editor_plugin._get_plugin_name()
	if is_instance_valid(plugin_button):
		plugin_button.queue_free()

func _child_entered_tree(c):
	_connect_buttons()

func _connect_buttons():
	var main_bar = MainScreen.get_button_container()
	for button:Button in main_bar.get_children():
		if not button.pressed.is_connected(_on_main_screen_bar_button_pressed):
			button.pressed.connect(_on_main_screen_bar_button_pressed.bind(button))

func _on_main_screen_bar_button_pressed(button:Button):
	if not is_instance_valid(plugin_button):
		return
	if button == main_screen_button and main_screen_button.button_pressed:
		return
	if not button in plugin_buttons:
		main_screen_button.hide()
		main_screen_button.text = editor_plugin._get_plugin_name()
		plugin_control.hide()
		plugin_button.show()
		plugin_button.text = String(plugin_control.name)
		return
	if button != plugin_button:
		plugin_button.show()
		#if plugin_control.get_parent() == EditorInterface.get_editor_main_screen(): #TODO test this to remove below hide
			#plugin_control.hide()
		plugin_control.hide()
		return
	var main_bar:HBoxContainer = MainScreen.get_button_container()
	var main_bar_children = main_bar.get_children()
	var idx = 0
	for c in main_bar_children:
		if c == plugin_button:
			break
		idx += 1
	
	main_bar.move_child(main_screen_button, idx)
	plugin_button.hide()
	plugin_control.show()
	main_screen_button.text = String(plugin_control.name)
	main_screen_button.icon = _get_control_icon(plugin_control)
	main_screen_button.show()
	EditorInterface.set_main_screen_editor.call_deferred(main_screen_button.text)

func add_main_screen_control(control):
	_add_main_screen_button(control)
	EditorInterface.get_editor_main_screen().add_child(control)
	control.hide()

func _add_main_screen_button(control):
	plugin_button = Button.new()
	plugin_button.name = control.name
	plugin_button.text = control.name
	plugin_button.icon = _get_control_icon(control)
	plugin_button.theme_type_variation = MainScreen.get_button_theme()
	var main_bar = MainScreen.get_button_container()
	main_bar.add_child(plugin_button)
	plugin_control = control
	
	plugin_buttons.append(plugin_button)
	_connect_buttons()

func remove_main_screen_control(control):
	_remove_main_screen_button(control)
	EditorInterface.get_editor_main_screen().remove_child(control)
	EditorInterface.set_main_screen_editor("Script")

func _remove_main_screen_button(control):
	var idx = plugin_buttons.find(plugin_button)
	plugin_buttons.remove_at(idx)
	
	plugin_button.queue_free()
	plugin_button = null
	if is_instance_valid(main_screen_button):
		main_screen_button.hide()
		main_screen_button.text = editor_plugin._get_plugin_name()

func _get_control_icon(control):
	if "icon" in control:
		return control.icon
	else:
		return EditorInterface.get_base_control().get_theme_icon("Node", &"EditorIcons")
	
