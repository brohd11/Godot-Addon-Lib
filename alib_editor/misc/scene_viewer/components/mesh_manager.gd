@tool
extends Node3D

const SCENE_EXTENSIONS = ["tscn", "scn", "glb", "gltf", "fbx"]

var decal_preview:Mesh

var _scene_cache:= {}
var current_scene:String=""

var show_only_active:=false

var label_height:float = 1
var label_size = 1
var label_current:=false
var show_labels:=true

var _current_mesh_index:=0

signal send_scene_stats(stats)
signal active_scene_set(scene, stats)

signal meshes_shown(scene_paths)

func _ready() -> void:
	decal_preview = PlaneMesh.new()



func load_scenes(scenes_to_load:PackedStringArray, search_scope):
	_clean_cache(scenes_to_load)
	_get_or_inst_scenes(scenes_to_load)
	_current_mesh_index = 0
	
	await get_tree().process_frame
	
	show_scene(scenes_to_load[0], scenes_to_load)
	
	await get_tree().process_frame
	self.meshes_shown.emit()

func clear_cache():
	current_scene = ""
	_clean_cache([])

func _clean_cache(current_paths:PackedStringArray):
	for path in _scene_cache.keys():
		#if path in current_paths:
			#continue
		var scene_data = _scene_cache.get(path)
		if scene_data == null:
			continue
		var ins = scene_data.get("ins")
		if is_instance_valid(ins):
			if ins.is_inside_tree():
				remove_child(ins)
			ins.queue_free()
		_scene_cache.erase(path)


func _get_or_inst_scenes(current_paths:PackedStringArray):
	for path:String in current_paths:
		if _scene_cache.has(path):
			continue
		var scn = null
		if path.get_extension() in SCENE_EXTENSIONS:
			var pck:PackedScene = ResourceLoader.load(path)
			scn = pck.instantiate()
		else:
			continue
		
		if scn == null:
			continue
		if scn is not Node3D:
			continue
		
		_scene_cache[path] = {
			"ins": scn
		}


func _remove_current_scenes_from_tree(scns_to_keep:=PackedStringArray()):
	var remove_all = scns_to_keep.is_empty()
	var children = get_children()
	for c in children:
		if not remove_all and c.scene_file_path in scns_to_keep:
			continue
		c.owner = null
		remove_child(c)

func refresh():
	if _scene_cache.has(current_scene):
		show_scene(current_scene)

func show_scene(scene_path:String, scenes_to_show:Array=_scene_cache.keys()):
	current_scene = scene_path
	_remove_current_scenes_from_tree()
	if show_only_active:
		scenes_to_show = [scene_path]
	_show_scenes(scene_path, scenes_to_show)

func _show_scenes(current_scene_path:String, scns_to_show:Array):
	#_remove_current_scenes_from_tree() # not sure about this
	
	var extra_space_mul = 1 # HelperInst.ABConfig.space_between_scenes
	var pos_offset = Vector3.ZERO
	var first_scn = true
	for path in scns_to_show:
		_process_scene(path)
		var scene_data = _scene_cache[path]
		var scn_aabb = scene_data.get("aabb")
		if scn_aabb == null:
			continue
		var aabb_adj_size = scn_aabb.size.x * extra_space_mul
		if first_scn:
			first_scn = false
		else:
			pos_offset += Vector3(aabb_adj_size * 2, 0, 0)
		
		scene_data["offset"] = pos_offset
	
	var current_scn_data = _scene_cache[current_scene_path]
	var current_scn_ins = current_scn_data.get("ins")
	var current_scn_pos = current_scn_data.get("offset")
	var adjusted_offset = Vector3.ZERO - current_scn_pos
	_set_label_settings(current_scene_path, true)
	
	add_child(current_scn_ins)
	current_scn_ins.position = Vector3.ZERO
	
	if current_scn_ins is Decal:
		active_scene_set.emit(current_scene_path, {})
	else:
		active_scene_set.emit(current_scene_path, get_current_scene_stats(current_scn_ins))
	
	for path in scns_to_show:
		if path == current_scene_path:
			continue
		_set_label_settings(path, false)
		var scene_data = _scene_cache[path]
		var ins = scene_data.get("ins")
		var offset = scene_data.get("offset")
		
		var new_position = offset + adjusted_offset
		add_child(ins)
		ins.position = new_position


func _process_scene(path):
	var scene_data = _scene_cache[path]
	if scene_data.get("scene_processed", false) == true:
		return
	
	var ins = scene_data.get("ins")
	var scn_aabb:AABB

	var has_mesh = is_instance_valid(ALibRuntime.Utils.UNode.find_first_node_of_type(ins, MeshInstance3D))
	if has_mesh:
		scn_aabb = ALibRuntime.Utils.UResource.UPackedScene.get_scene_aabb(ins)
		scene_data["aabb"] = scn_aabb
	
	elif ins is Decal:
		var new_mesh = MeshInstance3D.new()
		var decal_prev_mesh = decal_preview.duplicate()
		new_mesh.mesh = decal_prev_mesh
		
		scn_aabb.size = Vector3(ins.size.x, ins.size.y, ins.size.z)
		new_mesh.mesh.size = Vector2(ins.size.x, ins.size.z)
		scene_data["aabb"] = scn_aabb
		ins.add_child(new_mesh)
	
	var label = Label3D.new()
	ins.add_child(label)
	label.text = ins.name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	#label.fixed_size = true
	#label.pixel_size = 0.1
	if scn_aabb:
		label.position = Vector3(0 ,scn_aabb.size.y * label_height, 0)
	else:
		label.position = Vector3(0,1,0)
	
	scene_data["scene_processed"] = true


func _set_label_settings(path:String, is_current:=false):
	var scene_data = _scene_cache[path]
	
	var ins = scene_data.get("ins")
	var scn_label = ALibRuntime.Utils.UNode.find_first_node_of_type(ins, Label3D)
	if scn_label is Label3D:
		if not show_labels:
			scn_label.hide()
		else:
			scn_label.show()
		if is_current:
			scn_label.modulate = Color(0.4,0.8,0.2)
		else:
			scn_label.modulate = Color.WHITE
		
		var aabb = scene_data["aabb"]
		if aabb:
			scn_label.position = Vector3(0, aabb.size.y * label_height + 0.25, 0)
			#if HelperInst.ABConfig.label_adaptive_size:
				#current_scn_label.pixel_size = 0.005 * aabb.x * label_size
			#else:
			scn_label.pixel_size = 0.005 * label_size
			scn_label.pixel_size = clampf(scn_label.pixel_size, 0.001, 0.1)

func get_active_scene_instance():
	return _scene_cache[current_scene].get("ins")

func get_loaded_paths():
	return _scene_cache.keys()

func show_next_mesh():
	if _scene_cache.is_empty():
		return
	_current_mesh_index += 1
	if _current_mesh_index >= _scene_cache.size():
		_current_mesh_index = 0
	var paths = _scene_cache.keys()
	show_scene(paths[_current_mesh_index], paths)

func show_prev_mesh():
	if _scene_cache.is_empty():
		return
	_current_mesh_index -= 1
	if _current_mesh_index < 0 :
		_current_mesh_index = _scene_cache.size() - 1
	var paths = _scene_cache.keys()
	show_scene(paths[_current_mesh_index], paths)


func _get_mesh_nodes(scn_ins):
	return ALibRuntime.Utils.UNode.get_all_nodes_of_type(scn_ins, MeshInstance3D)

func get_current_scene_stats(scene:Node3D):
	var m = ALibRuntime.Utils.UNode.find_first_node_of_type(scene, MeshInstance3D)
	if not m:
		return {}
	var mesh:MeshInstance3D = m
	var mesh_surf_count = mesh.mesh.get_surface_count()
	var m_tool = MeshDataTool.new()
	#print("mtool ",mesh)
	var face_count = 0
	var vert_count = 0
	var edge_count = 0
	for ms in mesh_surf_count:
		var err = m_tool.create_from_surface(mesh.mesh,ms)
		#print("errr ",err)
		if not err == OK:
			continue
		face_count += m_tool.get_face_count()
		vert_count += m_tool.get_vertex_count()
		edge_count += m_tool.get_edge_count()
	
	var scn_stats ={
		"face_count": face_count,
		"vert_count": vert_count,
		"edge_count": edge_count,
	}
	return scn_stats
