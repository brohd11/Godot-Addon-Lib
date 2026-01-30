extends VBoxContainer

const PluginButton = ALibEditor.UIHelpers.Buttons.PluginButton

const ControllerFreeView = preload("res://addons/addon_lib/brohd/alib_runtime/controller/mouse_camera/free_view.gd")

var toolbar:HBoxContainer

var sub_viewport_root:Control
var sub_viewport_container:SubViewportContainer
var sub_viewport:SubViewport

var mouse_detector:Control

var root_3d:Node3D
var world_env:WorldEnvironment
var directional_light:DirectionalLight3D
var controller:ControllerFreeView
var camera:Camera3D

var scene_target:Node3D



func _ready() -> void:
	_build_nodes()
	pass

func get_tab_title():
	return "Scene Viewer"

func _build_nodes():
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	toolbar = HBoxContainer.new()
	add_child(toolbar)
	
	var fov_slider:=HSlider.new()
	toolbar.add_child(fov_slider)
	fov_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fov_slider.min_value = 15
	fov_slider.max_value = 135
	fov_slider.custom_minimum_size.x = 100
	var fov_label:= Label.new()
	toolbar.add_child(fov_label)
	
	
	toolbar.add_spacer(false)
	
	var reset_button = PluginButton.new("Reload", null, "Reset camera").get_button()
	toolbar.add_child(reset_button)
	
	
	sub_viewport_root = Control.new()
	add_child(sub_viewport_root)
	sub_viewport_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	sub_viewport_container = SubViewportContainer.new()
	sub_viewport_root.add_child(sub_viewport_container)
	sub_viewport_container.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	sub_viewport_container.stretch = true
	
	
	sub_viewport = SubViewport.new()
	sub_viewport_container.add_child(sub_viewport)
	sub_viewport.own_world_3d = true
	
	mouse_detector = Control.new()
	sub_viewport_root.add_child(mouse_detector)
	mouse_detector.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_detector.set_drag_forwarding(func(a):return null, _on_sub_viewport_can_drop_data, _on_sub_viewport_drop_data)
	
	root_3d = Node3D.new()
	sub_viewport.add_child(root_3d)
	
	var env = Environment.new()
	var sky = Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	
	world_env = WorldEnvironment.new()
	root_3d.add_child(world_env)
	world_env.environment = env
	
	directional_light = DirectionalLight3D.new()
	root_3d.add_child(directional_light)
	directional_light.rotation = Vector3(0.3, 0.3, 0.3)
	
	controller = ControllerFreeView.new()
	root_3d.add_child(controller)
	
	
	
	camera = Camera3D.new()
	controller.add_child(camera)
	camera.position = Vector3(0, 1.6, 5)
	
	controller.camera = camera
	
	fov_slider.value = camera.fov
	fov_label.text="(%s deg)" % fov_slider.value
	
	scene_target = Node3D.new()
	root_3d.add_child(scene_target)
	
	
	reset_button.pressed.connect(controller.camera_reset)
	mouse_detector.gui_input.connect(controller.mouse_input)
	
	fov_slider.value_changed.connect(func(val):camera.fov = (fov_slider.max_value + fov_slider.min_value) - val;fov_label.text="(%s deg)" % val)



func _clear_scenes():
	for c in scene_target.get_children():
		scene_target.remove_child(c)
		c.queue_free()


func _on_sub_viewport_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data.get("type") == "files":
		var files = data.get("files")
		for f in files:
			if FileSystemSingleton.get_file_type_static(f) == "PackedScene":
				return true
	return false

func _on_sub_viewport_drop_data(at_position: Vector2, data: Variant) -> void:
	_clear_scenes()
	var files = data.get("files")
	for f in files:
		if FileSystemSingleton.get_file_type_static(f) == "PackedScene":
			var pck = load(f) as PackedScene
			var ins = pck.instantiate()
			scene_target.add_child(ins)
	pass

func _on_sub_viewport_get_drag_data(at_position: Vector2) -> Variant:
	return null
