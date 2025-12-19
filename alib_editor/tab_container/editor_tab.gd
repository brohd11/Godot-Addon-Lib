@tool
extends TabContainer

@export var tab_titles:PackedStringArray
@export var tab_icons:PackedStringArray

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	_on_editor_settings_changed()
	var ed_settings = EditorInterface.get_editor_settings()
	ed_settings.settings_changed.connect(_on_editor_settings_changed)

func _on_editor_settings_changed():
	var ed_settings = EditorInterface.get_editor_settings()
	var tab_style_setting = ed_settings.get_setting("interface/editor/dock_tab_style")
	
	for i in range(get_tab_count()):
		var title = tab_titles[i] if i < tab_titles.size() else null
		var icon_str = tab_icons[i] if i < tab_icons.size() else null
		var icon:Texture2D
		if icon_str:
			if FileAccess.file_exists(icon_str):
				icon = load(icon_str)
			else:
				icon = EditorInterface.get_editor_theme().get_icon(icon_str, "EditorIcons")
		var set_title:= false
		var set_icon:= false
		if tab_style_setting == 0: # Text
			set_title = true
		elif tab_style_setting == 1: # Icon
			if icon:
				set_icon = true
			else:
				set_title = true
		elif tab_style_setting == 2: # Both
			set_title = true
			set_icon = true
		
		if set_title:
			if title:
				set_tab_title(i, title)
			else:
				set_tab_title(i, get_tab_control(i).name)
		else:
			set_tab_title(i, "")
		if set_icon and icon:
			set_tab_icon(i, icon)
		else:
			set_tab_icon(i, null)
