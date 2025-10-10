extends RefCounted
#! namespace ALibEditor.Utils class UEditorTheme

const BACKPORTED = 100

const ThemeSetter = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_theme/theme_setter.gd")

static func get_icon(icon_name:String, theme_type:String=&"EditorIcons"):
	var icon = EditorInterface.get_editor_theme().get_icon(icon_name, theme_type)
	return icon

static func get_icon_name(icon, theme_type:String=&"EditorIcons"):
	if BACKPORTED < 2:
		var path = new().get_script().resource_path
		printerr("Cannot get icon list in backported plugin version 4.%s. Calling file: %s" % [BACKPORTED, path])
		return ""
	var icon_list = EditorInterface.get_editor_theme().get_icon_list(theme_type)
	for icon_name in icon_list:
		if icon == get_icon(icon_name, theme_type):
			return icon_name

static func set_menu_button_to_editor_theme(menu_button:MenuButton):
	menu_button.flat = false
	var b = Button.new()
	menu_button.add_child(b)
	var overides = ["normal", "pressed"]
	for o in overides:
		menu_button.add_theme_stylebox_override(o, b.get_theme_stylebox(o))
	b.queue_free()

static func get_size_of_control_type(type):
	var ins = type.new()
	EditorInterface.get_base_control().add_child(ins)
	var new_size = ins.size
	ins.hide()
	ins.queue_free()
	return new_size

static func get_test():
	print(EditorInterface.get_editor_theme().get_stylebox_type_list())
	print(EditorInterface.get_editor_theme().get_constant_list("SplitContainer"))
	pass
