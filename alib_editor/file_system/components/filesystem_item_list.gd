extends ItemList

var filesystem_singleton:FileSystemSingleton

var file_type_icon_size:Vector2 = Vector2(16, 16)
var file_type_icon_margin:Vector2 = Vector2(4, 4)

var tree_root:=""
var folder_view_root:=""
var display_file_type_icon:=true

var display_as_list:=false

var _current_paths:= []
var _file_icons:= {}

signal right_clicked(self_node, selected_path, selected_path_array)
signal right_clicked_empty(self_node, selected_path)
signal double_clicked(selected_path)
signal select_tree_item(selected_path)

func _ready() -> void:
	filesystem_singleton = FileSystemSingleton.get_instance()
	
	file_type_icon_size = Vector2(16, 16) * EditorInterface.get_editor_scale()
	file_type_icon_margin = Vector2(4, 4) * EditorInterface.get_editor_scale()
	
	allow_rmb_select = true
	allow_reselect = true
	
	item_clicked.connect(_on_item_clicked)
	item_activated.connect(_on_double_clicked)
	empty_clicked.connect(_on_empty_clicked)
	_set_list_settings()

func set_display_as_list(toggled:bool):
	display_as_list = toggled
	_set_list_settings()
	_rebuild()

func _set_list_settings():
	if display_as_list:
		same_column_width = true
		wraparound_items = false
		max_text_lines = 1
		select_mode = ItemList.SELECT_MULTI
		max_columns = 1
		fixed_column_width = 0
		icon_mode = ItemList.ICON_MODE_LEFT
		fixed_icon_size = Vector2i(16,16)
	else:
		same_column_width = true
		wraparound_items = true
		max_text_lines = 2
		select_mode = ItemList.SELECT_MULTI
		max_columns = 0
		fixed_column_width = 96
		icon_mode = ItemList.ICON_MODE_TOP
		fixed_icon_size = Vector2i(64,64)


func _draw() -> void:
	if display_as_list:
		return
	if display_file_type_icon:
		var broken_file = EditorInterface.get_editor_theme().get_icon("FileBroken", "EditorIcons")
		var scroll_bar_offset = Vector2(get_h_scroll_bar().value, get_v_scroll_bar().value)
		for i in item_count:
			var path = get_item_metadata(i)
			if path.ends_with("/"):
				continue
			var rect = get_item_rect(i, false)
			var icon = _file_icons.get(i, broken_file)
			var display_rect = Rect2((rect.position - scroll_bar_offset) + file_type_icon_margin, file_type_icon_size)
			draw_texture_rect(icon, display_rect, false)
	
	
	var font = ThemeDB.fallback_font
	var count = item_count
	if folder_view_root != "":
		count -= 1
		count = max(count, 0)
	var text = "Items: %s" % count
	var rect = get_rect()
	var pos = rect.size
	var string_size = font.get_string_size(text)
	pos.x -= string_size.x
	pos -= Vector2(6,6)
	
	draw_string(font, pos, text,0,-1,14, Color(1,1,1,0.7))

func set_current_paths(new_paths:Array):
	_current_paths = new_paths
	_rebuild()

func _rebuild():
	clear_items()
	create_items()

func clear_items():
	clear()
	_file_icons.clear()

func create_items():
	
	var folder_thumb = EditorInterface.get_editor_theme().get_icon("FolderBigThumb", "EditorIcons")
	var file_thumb = EditorInterface.get_editor_theme().get_icon("FileBigThumb", "EditorIcons")
	if display_as_list:
		folder_thumb = filesystem_singleton.get_folder_icon()
	
	if folder_view_root != "" and folder_view_root != tree_root:
		add_icon_item(folder_thumb)
		set_item_text(0, "..")
		set_item_selectable(0, false)
		var icon_color = filesystem_singleton.get_icon_color(folder_view_root)
		if icon_color:
			set_item_icon_modulate(0, icon_color)
		set_item_metadata(0, folder_view_root)
	
	
	for path:String in _current_paths:
		var file_data = filesystem_singleton.get_file_data(path)
		var file_type_icon = file_data.get(FileSystemSingleton.FileData.TYPE_ICON)
		var item_icon:Texture2D
		if path.ends_with("/"):
			item_icon = folder_thumb
		else:
			var preview_data = filesystem_singleton.get_preview(path)
			if preview_data != null:
				item_icon = preview_data.get("preview")
			else:
				if display_as_list:
					item_icon = file_type_icon
				else:
					var file_icon = file_data.get(FileSystemSingleton.FileData.PREVIEW_ICON)
					var custom_icon = file_data.get(FileSystemSingleton.FileData.CUSTOM_ICON)
					if not custom_icon:
						item_icon = file_thumb
					else:
						item_icon = file_icon
		
		var idx = add_icon_item(item_icon)
		_file_icons[idx] = file_type_icon
		set_item_metadata(idx, path)
		set_item_text(idx, path.trim_suffix("/").get_file())
		var icon_color = filesystem_singleton.get_icon_color(path)
		if icon_color:
			set_item_icon_modulate(idx, icon_color)
		
		#print(file_data)


func get_selected_paths():
	var selected_items = get_selected_items()
	var paths = []
	for i:int in selected_items:
		paths.append(get_item_metadata(i))
	
	return paths

func get_item_path(idx:int):
	return get_item_metadata(idx)

func _on_empty_clicked(at_pos:Vector2, mouse_button_idx:int):
	
	if mouse_button_idx == 1 or mouse_button_idx == 2:
		deselect_all()
	if mouse_button_idx == 2:
		if folder_view_root != "":
			var path = get_item_path(0)
			right_clicked_empty.emit(self, path)
			

func _on_item_clicked(index:int, at_pos:Vector2, mouse_button_idx:int):
	if mouse_button_idx == 2:
		var item_at_pos = get_item_at_position(at_pos)
		if not item_at_pos in get_selected_items():
			select(item_at_pos)
		
		_on_right_clicked(item_at_pos)
	


func _on_right_clicked(selected_item:int):
	var path = get_item_path(selected_item)
	var path_array = get_selected_paths()
	right_clicked.emit(self, path, path_array)

func _on_double_clicked(selected_item:int):
	var path = get_item_path(selected_item)
	if not path.ends_with("/"):
		double_clicked.emit(path)
	else:
		if path == "res://":
			#select_tree_item.emit(path)
			return
		if path != folder_view_root:
			select_tree_item.emit(path)
		else:
			var base_dir = path.trim_suffix("/").get_base_dir()
			if not base_dir.ends_with("/"):
				base_dir += "/"
			select_tree_item.emit(base_dir)

func start_edit():
	var selected = get_selected_items()[0]
	var old_name = get_item_text(selected)
	
	var item_rect = get_item_rect(selected, false)
	
	var window_pos = Vector2(DisplayServer.window_get_position(get_window().get_window_id()))
	print(item_rect)
	item_rect.position += window_pos + get_global_rect().position
	item_rect.position.y +=  item_rect.size.y * 0.6
	item_rect.size.y *= 0.4
	
	
	var line = ALibRuntime.Dialog.LineSubmitHandler.new(self, item_rect)
	line.set_text(old_name, ALibRuntime.Dialog.LineSubmitHandler.SelectMode.BASENAME)
	var new_name = await line.line_submitted
	print("NEW ", new_name)
	
	if not filesystem_singleton.is_new_name_valid(old_name, new_name):
		return
	
	var old_path = get_selected_paths()[0]
	filesystem_singleton.rename_path(old_path, new_name)



func _get_drag_data(at_position):
	return FileSystemSingleton.GetDropData.files(get_selected_paths(), self)
