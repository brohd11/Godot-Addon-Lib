extends VBoxContainer

#! import-p Keys,

const PluginButton = ALibEditor.UIHelpers.Buttons.PluginButton

const MeshManager = preload("res://addons/addon_lib/brohd/alib_editor/misc/scene_viewer/components/mesh_manager.gd")
const NodeTree = preload("res://addons/addon_lib/brohd/alib_editor/misc/scene_viewer/components/node_tree.gd")
const ControllerFreeView = preload("res://addons/addon_lib/brohd/alib_runtime/controller/mouse_camera/free_view.gd")

var _dock_data:Dictionary = {}

var right_click_handler:ClickHandlers.RightClickHandler



var toolbar:HBoxContainer

var list_scene_button:Button
var hide_non_active_button:Button

var main_split_container:SplitContainer

var sub_viewport_root:Control
var sub_viewport_container:SubViewportContainer
var sub_viewport:SubViewport

var mouse_detector:Control
var stats_panel:StatsPanel

var root_3d:Node3D
var world_env:WorldEnvironment
var directional_light:DirectionalLight3D
var controller:ControllerFreeView
var camera:Camera3D

var mesh_manager:MeshManager

var node_tree:NodeTree

func _ready() -> void:
	_build_nodes()
	
	mesh_manager.show_only_active = _dock_data.get(Keys.SHOW_ONLY_ACTIVE, false)
	_set_non_active_button_icon(mesh_manager.show_only_active)
	main_split_container.split_offset = _dock_data.get(Keys.SPLIT_OFFSET, 0)
	node_tree.visible = _dock_data.get(Keys.NODE_TREE_VISIBLE, false)


func set_dock_data(data:Dictionary):
	_dock_data = data


func get_dock_data() -> Dictionary:
	var data = {}
	data[Keys.SHOW_ONLY_ACTIVE] = mesh_manager.show_only_active
	data[Keys.SPLIT_OFFSET] = main_split_container.split_offset
	data[Keys.NODE_TREE_VISIBLE] = node_tree.visible
	
	return data


func get_tab_title():
	return "Scene Viewer"

func _build_nodes():
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	right_click_handler = ClickHandlers.RightClickHandler.new()
	add_child(right_click_handler)
	
	
	
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
	
	var reset_button = PluginButton.new("Camera", null, "Reset camera").get_button()
	toolbar.add_child(reset_button)
	
	var prev_mesh_button = PluginButton.new("PagePrevious", null, "Make next scene active.").get_button()
	toolbar.add_child(prev_mesh_button)
	
	var next_mesh_button = PluginButton.new("PageNext", null, "Make next scene active.").get_button()
	toolbar.add_child(next_mesh_button)
	
	list_scene_button = PluginButton.new("PackedScene", null, "Make scene active.").get_button()
	toolbar.add_child(list_scene_button)
	
	hide_non_active_button = PluginButton.new("GuiVisibilityHidden", _on_hide_non_active_button_pressed, "Hide or show non active scenes.").get_button()
	toolbar.add_child(hide_non_active_button)
	
	var node_tree_button = PluginButton.new("FileTree", _on_node_tree_button_pressed, "Toggle scene tree.").get_button()
	toolbar.add_child(node_tree_button)
	
	var clear_button = PluginButton.new("Clear", _on_clear_pressed, "Clear loaded scenes").get_button()
	toolbar.add_child(clear_button)
	
	
	main_split_container = SplitContainer.new()
	main_split_container.vertical = false
	add_child(main_split_container)
	main_split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	sub_viewport_root = Control.new()
	main_split_container.add_child(sub_viewport_root)
	sub_viewport_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sub_viewport_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
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
	
	stats_panel = StatsPanel.new()
	mouse_detector.add_child(stats_panel)
	stats_panel.hide()
	
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
	
	
	mesh_manager = MeshManager.new()
	root_3d.add_child(mesh_manager)
	
	node_tree = NodeTree.new()
	main_split_container.add_child(node_tree)
	node_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	
	
	
	
	
	mesh_manager.active_scene_set.connect(_on_active_scene_set)
	
	node_tree.item_right_clicked.connect(_on_node_tree_right_clicked)
	
	next_mesh_button.pressed.connect(mesh_manager.show_next_mesh)
	prev_mesh_button.pressed.connect(mesh_manager.show_prev_mesh)
	list_scene_button.pressed.connect(_list_loaded_scenes)
	
	reset_button.pressed.connect(controller.camera_reset)
	mouse_detector.gui_input.connect(controller.mouse_input)
	
	fov_slider.value_changed.connect(func(val):camera.fov = (fov_slider.max_value + fov_slider.min_value) - val;fov_label.text="(%s deg)" % val)



func _on_active_scene_set(scene_path, data):
	stats_panel.set_text(data)
	node_tree.send_scene_instance(mesh_manager.get_active_scene_instance())

func _on_node_tree_button_pressed():
	node_tree.visible = not node_tree.visible
	if node_tree.visible:
		node_tree.refresh()

func _on_node_tree_right_clicked(path:String):
	var options = ALibRuntime.Popups.Options.new()
	var fs_singleton = FileSystemSingleton.get_instance()
	var file_type = fs_singleton.get_file_type(path)
	if ClassDB.is_parent_class("Resource", file_type):
		options.add_option("Edit", FileSystemSingleton.get_instance().activate_path.bind(path), ["Edit"])
	else:
		options.add_option("Open", FileSystemSingleton.get_instance().activate_path.bind(path), ["Load"])
	
	options.add_option("Show in FileSystem", FileSystemSingleton.get_instance().navigate_to_path.bind(path, self), ["Filesystem"])
	
	right_click_handler.display_popup(options)


func _on_clear_pressed():
	mesh_manager.clear_cache()
	node_tree.clear_tree("Scene cleared", true)



func _list_loaded_scenes():
	var options = ALibRuntime.Popups.Options.new()
	var loaded_scenes = mesh_manager.get_loaded_paths()
	if loaded_scenes.is_empty():
		options.add_option("No scenes loaded.", null)
	else:
		for path in loaded_scenes:
			options.add_option(path.get_file(), mesh_manager.show_scene.bind(path))
	
	
	var pos = right_click_handler.get_centered_control_position(list_scene_button)
	right_click_handler.display_popup(options, true, pos)

func _on_hide_non_active_button_pressed():
	mesh_manager.show_only_active = not mesh_manager.show_only_active
	_set_non_active_button_icon(mesh_manager.show_only_active)
	mesh_manager.refresh()

func _set_non_active_button_icon(show_only_active:bool):
	if show_only_active:
		hide_non_active_button.icon = EditorInterface.get_editor_theme().get_icon("GuiVisibilityHidden", "EditorIcons")
	else:
		hide_non_active_button.icon = EditorInterface.get_editor_theme().get_icon("GuiVisibilityVisible", "EditorIcons")


func _on_sub_viewport_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data.get("type") == "files":
		var files = data.get("files")
		for f in files:
			if FileSystemSingleton.get_file_type_static(f) == "PackedScene":
				return true
	return false

func _on_sub_viewport_drop_data(at_position: Vector2, data: Variant) -> void:
	stats_panel.set_text({})
	var files = data.get("files")
	mesh_manager.load_scenes(files, files[0])

func _on_sub_viewport_get_drag_data(at_position: Vector2) -> Variant:
	return null


class StatsPanel extends VBoxContainer:
	var _face_label:Label
	var _vert_label:Label
	var _edge_label:Label
	
	func _ready() -> void:
		var vbox = VBoxContainer.new()
		add_child(vbox)
		vbox.add_theme_constant_override("separation", 0)
		var max_size = ThemeDB.fallback_font.get_string_size("Faces:")
		var empty = StyleBoxEmpty.new()
		var data = {"_face_label":"Faces:", "_vert_label":"Verts:", "_edge_label":"Edges:"}
		for _var_name in data.keys():
			var hbox = HBoxContainer.new()
			
			vbox.add_child(hbox)
			hbox.add_theme_constant_override("separation", 0)
			var text_label = Label.new()
			hbox.add_child(text_label)
			text_label.text = data[_var_name]
			text_label.custom_minimum_size.x = max_size.x + 5
			text_label.add_theme_stylebox_override("normal", empty)
			var num_label = Label.new()
			set(_var_name, num_label)
			hbox.add_child(num_label)
			num_label.add_theme_stylebox_override("normal", empty)
			num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT,Control.PRESET_MODE_KEEP_SIZE, 4)
		
	func set_text(data:Dictionary):
		visible = not data.is_empty()
		if data.is_empty():
			return
		_face_label.text = str(data.face_count)
		_vert_label.text = str(data.vert_count)
		_edge_label.text = str(data.edge_count)


class Keys:
	
	const SHOW_ONLY_ACTIVE = &"SHOW_ONLY_ACTIVE"
	const SPLIT_OFFSET = &"SPLIT_OFFSET"
	const NODE_TREE_VISIBLE = &"NODE_TREE_VISIBLE"
