@tool
extends VBoxContainer

const FileSystemTab = preload("res://addons/addon_lib/brohd/alib_editor/file_system/tree/filesystem_tab.gd")
const FileSystemTree = preload("res://addons/addon_lib/brohd/alib_editor/file_system/tree/filesystem_tree.gd")

var tree: FileSystemTree

var plugin_tab_container

var _dock_data:= {}

signal new_plugin_tab(control)

func can_be_freed() -> bool:
	if not is_instance_valid(plugin_tab_container):
		if tree.root_dir == "res://":
			return false
		return true
	else:
		var tabs = plugin_tab_container.get_all_tab_controls()
		for tab:FileSystemTab in tabs:
			if tab.tree.root_dir == "res://" and tab != self:
				return true
		return false

func get_tab_title():
	if tree.root_dir == "res://":
		return "FileSystem"
	else:
		return tree.root_dir.trim_suffix("/").get_file()

func set_dir(target_dir:String):
	tree.set_dir(target_dir)

func _ready() -> void:
	_build_nodes()
	
	var root = _dock_data.get("root", "res://")
	set_dir(root)
	var item_meta = _dock_data.get("item_meta", {})
	tree.tree_helper.data_dict = item_meta
	tree.new_tab.connect(_on_rc_new_tab)

func _build_nodes():
	if is_instance_valid(tree):
		return
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var spacer = Control.new()
	add_child(spacer)
	
	var line_edit = LineEdit.new()
	line_edit.clear_button_enabled = true
	add_child(line_edit)
	
	tree = FileSystemTree.new()
	tree.filters.append(line_edit)
	add_child(tree)
	tree.owner = self

func set_dock_data(data:Dictionary):
	_build_nodes()
	_dock_data = data

func get_dock_data() -> Dictionary:
	var data = {}
	data["root"] = tree.root_dir
	data["item_meta"] = tree.tree_helper.data_dict
	return data

func _on_rc_new_tab(path):
	var new_instance = new()
	new_instance.set_dock_data({"root": path})
	new_plugin_tab.emit(new_instance)
