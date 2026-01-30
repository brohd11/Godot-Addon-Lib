#! namespace ALibEditor.UIHelpers class Buttons


static func new_button(icon="", callable=null, _name="", icon_color:=Color.TRANSPARENT, tooltip:=""):
	var button = Button.new()
	if _name != "":
		button.name = _name
	if callable != null:
		button.pressed.connect(callable)
	if icon is Texture2D:
		button.icon = icon
	elif icon != "":
		var icon_texture
		if icon_color:
			icon_texture = ALibEditor.Singletons.EditorIcons.get_icon(icon)
		else:
			icon_texture = EditorInterface.get_editor_theme().get_icon(icon, "EditorIcons")
		button.icon = icon_texture
	
	button.tooltip_text = tooltip
	button.theme_type_variation = &"FlatButton"
	button.focus_mode = Control.FOCUS_NONE
	return button


class PluginButton:
	var icon
	var callable
	var button_name:String = ""
	var icon_color:Color
	var tooltip:String = ""
	var theme_type_variation:= &"FlatButton"
	
	func _init(_icon="", _callable=null, _tooltip:=""):
		icon = _icon
		callable = _callable
		tooltip = _tooltip
	
	func get_button():
		var button = Button.new()
		if button_name != "":
			button.name = button_name
		if callable != null:
			button.pressed.connect(callable)
		if icon is Texture2D:
			button.icon = icon
		elif icon != "":
			var icon_texture
			if icon_color:
				icon_texture = ALibEditor.Singletons.EditorIcons.get_icon(icon)
			else:
				icon_texture = EditorInterface.get_editor_theme().get_icon(icon, "EditorIcons")
			button.icon = icon_texture
		
		button.tooltip_text = tooltip
		button.theme_type_variation = theme_type_variation
		button.focus_mode = Control.FOCUS_NONE
		return button
