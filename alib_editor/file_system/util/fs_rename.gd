static func rename_path(old_path:String, new_file_name:String):
	if not new_file_name.is_valid_filename():
		return
	
	var selected = FileSystemSingleton.ensure_items_selected([old_path])
	if not selected:
		return
	
	var root = Engine.get_main_loop().root
	#var tree = ALibEditor.Nodes.FileSystem.get_tree() as Tree #^ rename callable, keeping for interest
	#var rename_callable = ALibRuntime.Utils.UNode.get_signal_callable(tree, "item_edited", "FileSystemDock::_rename_operation_confirm")
	var line = ALibEditor.Nodes.FileSystem.get_tree_line_edit() as LineEdit
	var line_editor_submit = ALibRuntime.Utils.UNode.get_signal_callable(line, "text_submitted", "Tree::_line_editor_submit")
	
	var edfs_dock = EditorInterface.get_file_system_dock()
	edfs_dock.top_level = true
	edfs_dock.show()
	
	#line.top_level = true #^ I think top level of dock and waiting one frame for draw is doing it
	
	await root.get_tree().process_frame
	
	var popup = ALibEditor.Nodes.FileSystem.get_popup() as PopupMenu
	popup.id_pressed.emit(10)
	line.text = new_file_name
	line.release_focus()
	line_editor_submit.call(new_file_name)
	
	#line.top_level = false
	edfs_dock.top_level = false
	edfs_dock.hide()


static func is_new_name_valid(original_file_name:String, new_file_name:String) -> bool:
	if new_file_name == "":
		return false
	if new_file_name == original_file_name:
		return false
	if not new_file_name.is_valid_filename():
		return false
	return true
