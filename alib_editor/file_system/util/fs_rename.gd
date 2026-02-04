

static func is_new_name_valid(original_file_name:String, new_file_name:String) -> bool:
	if new_file_name == "":
		return false
	if new_file_name == original_file_name:
		return false
	if not new_file_name.is_valid_filename():
		return false
	return true

static func show_item_in_dock(path, _activate_rename:=false):
	var edfs_dock = EditorInterface.get_file_system_dock()
	edfs_dock.show()
	edfs_dock.navigate_to_path(path)
	if _activate_rename:
		var selected = FileSystemSingleton.ensure_items_selected([path])
		if not selected:
			return
		await edfs_dock.get_tree().process_frame
		activate_rename()

static func activate_rename():
	var minor_version = ALibRuntime.Utils.UVersion.get_minor_version()
	var popup = ALibEditor.Nodes.FileSystem.get_popup() as PopupMenu
	popup.id_pressed.emit(10)
	if minor_version >= 6:
		var tree = ALibEditor.Nodes.FileSystem.get_tree()
		tree.edit_selected(true)

static func rename_path(old_path:String, new_file_name:String):
	#_rename_path_current(old_path, new_file_name)
	var minor = ALibRuntime.Utils.UVersion.get_minor_version()
	if minor <= 6:
		_rename_path_minimal(old_path, new_file_name)



static func _rename_path_minimal(old_path:String, new_file_name:String):
	if not new_file_name.is_valid_filename():
		return
	var selected = FileSystemSingleton.ensure_items_selected([old_path])
	if not selected:
		return
	
	activate_rename()
	var line = ALibEditor.Nodes.FileSystem.get_tree_line_edit() as LineEdit
	line.text = new_file_name
	await line.get_tree().process_frame
	line.text_submitted.emit(new_file_name)


static func _rename_path_current(old_path:String, new_file_name:String):
	if not new_file_name.is_valid_filename():
		return
	
	var selected = FileSystemSingleton.ensure_items_selected([old_path])
	if not selected:
		return
	
	var root = Engine.get_main_loop().root
	var line = ALibEditor.Nodes.FileSystem.get_tree_line_edit() as LineEdit
	
	var edfs_dock = EditorInterface.get_file_system_dock()
	edfs_dock.top_level = true
	edfs_dock.show()
	
	await root.get_tree().process_frame
	activate_rename()
	
	#var popup = ALibEditor.Nodes.FileSystem.get_popup() as PopupMenu
	#popup.id_pressed.emit(10)
	line.text = new_file_name
	line.text_submitted.emit(new_file_name)
	
	edfs_dock.top_level = false
	edfs_dock.hide()





#static func _rename_path4(old_path:String, new_file_name:String):
	#if not new_file_name.is_valid_filename():
		#return
	#
	#var selected = FileSystemSingleton.ensure_items_selected([old_path])
	#if not selected:
		#return
	#
	#var tree = ALibEditor.Nodes.FileSystem.get_tree() as Tree #^ rename callable, keeping for interest
	#var rename_callable = ALibRuntime.Utils.UNode.get_signal_callable(tree, "item_edited", "FileSystemDock::_rename_operation_confirm")
	#var line = ALibEditor.Nodes.FileSystem.get_tree_line_edit() as LineEdit
	#var line_editor_submit = ALibRuntime.Utils.UNode.get_signal_callable(line, "text_submitted", "Tree::_line_editor_submit")
	#
	#
	#var sel_item = tree.get_selected()
	#activate_rename()
	#line.text = new_file_name
	##sel_item.set_text(0, new_file_name)
	#await tree.get_tree().process_frame
	#line.text_submitted.emit(new_file_name)
