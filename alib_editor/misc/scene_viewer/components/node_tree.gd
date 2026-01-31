@tool
extends Tree


var scene_info = {}
var tree_items = {}

var current_scene_path:String = ""
var current_scene_instance:Node

signal item_right_clicked(path:String)

func _ready() -> void:
	FileSystemSingleton.get_instance().filesystem_changed.connect(_on_scan_files_complete)
	clear_tree()
	allow_rmb_select = true
	item_mouse_selected.connect(_on_item_mouse_selected)
	button_clicked.connect(_on_button_clicked)

func _on_item_mouse_selected(mouse_pos:Vector2, mouse_button_index:int):
	if mouse_button_index == 2:
		var selected = get_item_at_position(mouse_pos)
		var meta = selected.get_metadata(0)
		if meta != "":
			item_right_clicked.emit(meta)

func _on_button_clicked(item:TreeItem, col:int, id:int, mouse_button_index:int):
	var path = item.get_metadata(0)
	FileSystemSingleton.activate_path(path)

func clear_tree(msg:="No scene loaded", clear_current_scene:=false):
	clear()
	scene_info.clear()
	tree_items.clear()
	var item = create_item()
	item.set_text(0, msg)
	if clear_current_scene:
		current_scene_path = ""
		current_scene_instance = null

func refresh():
	build_tree()

func _on_scan_files_complete():
	build_tree()

func send_scene_instance(scene_instance:Node):
	current_scene_instance = scene_instance
	current_scene_path = scene_instance.scene_file_path
	build_tree()

func send_scene_path(preview_scene_path):
	current_scene_instance = null
	current_scene_path = preview_scene_path
	build_tree()

func build_tree():
	if not visible:
		clear_tree()
		return
	clear()
	scene_info.clear()
	tree_items.clear()
	var ins_scene
	if current_scene_instance == null:
		if current_scene_path == "":
			clear_tree()
			return
		var pck:PackedScene = ResourceLoader.load(current_scene_path)
		if not pck:
			clear_tree("Could not load path: %s" % current_scene_path)
			return
		ins_scene = pck.instantiate()
	else:
		ins_scene = current_scene_instance
	
	_read_scene(ins_scene, ins_scene)
	
	for node in scene_info:
		var node_data = scene_info.get(node)
		var node_name = node_data.get("name")
		var node_parent = node_data.get("parent")
		var node_class = node_data.get("node_class")
		var item:TreeItem
		if not node_parent in tree_items.keys():
			item = create_item()
			tree_items[node] = item
		else:
			var parent = tree_items.get(node_parent)
			item = create_item(parent)
			tree_items[node] = item
		
		_set_node_item_params(item, node)
		if node is MeshInstance3D:
			var mesh = node.mesh
			var mesh_item = create_item(item)
			_set_resource_item_params(mesh_item, mesh)
			
			var surface_count = mesh.get_surface_count()
			for i in range(surface_count):
				var mat:Material = mesh.surface_get_material(i)
				
				if not mat:
					continue
				
				var mat_item = create_item(mesh_item)
				_set_resource_item_params(mat_item, mat)
	
	if current_scene_instance == null:
		ins_scene.queue_free()

func _set_node_item_params(item:TreeItem, node:Node):
	item.set_text(0, node.name)
	item.set_icon(0, _get_class_icon(node))
	item.set_metadata(0, node.scene_file_path)
	if node.scene_file_path != "":
		item.add_button(0, EditorInterface.get_editor_theme().get_icon("Load", "EditorIcons"))

func _set_resource_item_params(item:TreeItem, resource:Resource):
	item.set_text(0, _get_resource_name(resource))
	item.set_icon(0, _get_class_icon(resource))
	item.set_metadata(0, resource.resource_path)
	if resource.resource_path != "":
		item.add_button(0, EditorInterface.get_editor_theme().get_icon("Load", "EditorIcons"))

func _get_resource_name(resource:Resource):
	var res_name = resource.resource_name
	if res_name == "":
		res_name = "No resource name."
	return res_name

func _read_scene(node:Node, root_node:Node):
	if node != root_node and node.owner != root_node:
		return
	var parent = node.get_parent()
	var node_name = node.name
	var node_class = node.get_class()
	scene_info[node] = {
		"parent": parent,
		"name": node_name,
		"node_class": node_class,
	}
	var node_children = node.get_children()
	for n in node_children:
		_read_scene(n, root_node)


func _get_class_icon(node:Object):
	var node_class:String = node.get_class()
	var editor_base_control:Control = EditorInterface.get_base_control()
	var icon:Texture2D = editor_base_control.get_theme_icon(node_class, &"EditorIcons")
	if icon:
		return icon
	else:
		icon = EditorInterface.get_editor_theme().get_icon(node_class, &"EditorIcons")
		if not icon:
			icon = EditorInterface.get_editor_theme().get_icon("MissingNode",  &"EditorIcons")
		
		return icon
