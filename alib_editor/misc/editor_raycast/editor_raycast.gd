#! namespace ALibEditor.Singletons class EditorRaycast
extends Singleton.Base

## Implement in extended classes

# Use 'PE_STRIP_CAST_SCRIPT' to auto strip type casts with plugin exporter, if the class is not a global name

const PE_STRIP_CAST_SCRIPT = preload("res://addons/addon_lib/brohd/alib_editor/misc/editor_raycast/editor_raycast.gd")
static func get_singleton_name() -> String:
	return "EditorRaycast"

static func get_instance() -> PE_STRIP_CAST_SCRIPT:
	return _get_instance(PE_STRIP_CAST_SCRIPT)

static func instance_valid() -> bool:
	return _instance_valid(PE_STRIP_CAST_SCRIPT)

static func call_on_ready(callable, print_err:bool=true):
	_call_on_ready(PE_STRIP_CAST_SCRIPT, callable, print_err)

func _get_ready_bool() -> bool:
	return is_node_ready()

static func raycast_static(viewport_index:int=0):
	get_instance().raycast(viewport_index)

static func raycast_terrain3D_static(terrain_3D_node, viewport_index:int=0):
	get_instance().raycast_terrain3D(terrain_3D_node, viewport_index)

var _cache:= {}

func _init(_node:Node=null):
	_reset_cache()

func _process(_delta: float) -> void:
	await get_tree().process_frame
	_reset_cache()

func _reset_cache():
	_cache = {
		Keys.RAYCAST:{},
		Keys.RAYCAST_TERRAIN_3D:{},
	}

func raycast(viewport_index:int=0):
	var viewport_cache = _cache.get_or_add(viewport_index, {})
	var cached = viewport_cache.get(Keys.RAYCAST)
	if cached != null:
		return cached
	var editor_viewport = EditorInterface.get_editor_viewport_3d(viewport_index)
	var result = ALibRuntime.NodeUtils.NUViewport.Raycast.raycast(editor_viewport)
	_cache[viewport_index][Keys.RAYCAST] = result
	return result

func raycast_terrain3D(terrain_3D_node, viewport_index:int=0) -> Vector3:
	var viewport_cache = _cache.get_or_add(viewport_index, {})
	var cached = viewport_cache.get(Keys.RAYCAST_TERRAIN_3D)
	if cached != null:
		return cached
	var editor_viewport = EditorInterface.get_editor_viewport_3d(viewport_index)
	var result = ALibRuntime.NodeUtils.NUViewport.Raycast.raycast_terrain_3d(editor_viewport, terrain_3D_node)
	_cache[viewport_index][Keys.RAYCAST_TERRAIN_3D] = result
	return result

class Keys:
	const RAYCAST = &"RAYCAST"
	const RAYCAST_TERRAIN_3D = &"RAYCAST_TERRAIN_3D"
