extends RefCounted

const node = preload("res://addons/addon_lib/brohd/alib_runtime/utils/src/u_node.gd")

static func get_tree():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_TREE)

static func get_tree_line_edit():
	var tree = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_TREE)
	var nodes = tree.get_child(1, true).find_children("*", "LineEdit", true, false)
	return nodes[0]

static func populate_popup(calling_node:Control):
	var popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_POPUP)
	if calling_node.get_window() != popup.get_window():
		popup.reparent(calling_node.get_window().get_child(0))
	var tree = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_TREE)
	
	tree.item_mouse_selected.emit(Vector2.ZERO, 2)
	popup.hide()
	popup.reparent(EditorInterface.get_file_system_dock())


static func get_popup():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_POPUP)

static func get_create_popup():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_CREATE_POPUP)


static func scan_fs_dock(FileSystemItemDict, FileDataDict, preview_object=null):
	FileSystemItemDict.clear()
	FileDataDict.clear()
	var EditorResSys = EditorInterface.get_resource_filesystem()
	var fs_tree: Tree = get_tree()
	if not fs_tree:
		printerr("FileSystemDock Tree not found.")
		return
	var root: TreeItem = fs_tree.get_root()
	if not root:
		printerr("FileSystemDock Tree has no root item.")
		return
	
	_recursive_scan_tree_item(root, FileSystemItemDict, FileDataDict, EditorResSys, preview_object)

static func _recursive_scan_tree_item(item: TreeItem, FileSystemItemDict, FileDataDict, EditorResSys, preview_object=null):
	if item == null:
		return
	var file_path = item.get_metadata(0)
	if file_path != null:
		if file_path.ends_with("/") and not file_path == "res://":
			file_path = file_path.trim_suffix("/")
		FileSystemItemDict[file_path] = item
		
		var icon = item.get_icon(0)
		var file_type = EditorResSys.get_file_type(file_path)
		if file_type == "":
			file_type = "Folder"
		
		#print(file_type)
		var file_data = {
			"item_path": file_path,
			"File Icon": icon,
			"File Type": file_type,
			"File Custom Icon": false,
		}
		if preview_object != null:
			EditorInterface.get_resource_previewer().queue_resource_preview(file_path, preview_object, "_receive_previews", file_data)
		FileDataDict[file_path] = file_data
		
	
	var child: TreeItem = item.get_first_child()
	while child != null:
		_recursive_scan_tree_item(child, FileSystemItemDict, FileDataDict, EditorResSys, preview_object)
		child = child.get_next() # Move to the next sibling
