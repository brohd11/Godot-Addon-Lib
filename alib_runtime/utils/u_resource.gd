extends RefCounted
#! namespace ALibRuntime.Utils class UResource

const UFile = preload("uid://gs632l1nhxaf") # u_file.gd

const Audio = preload("res://addons/addon_lib/brohd/alib_runtime/utils/resource/audio.gd")
const ImageSize = preload("res://addons/addon_lib/brohd/alib_runtime/utils/resource/image_size.gd")
const GDScriptFileAccess = preload("res://addons/addon_lib/brohd/alib_runtime/utils/resource/gdscript.gd")
const UPackedScene = preload("res://addons/addon_lib/brohd/alib_runtime/utils/resource/packed_scene.gd")

static func save_resource_to_path(res:Resource,path:String, name_overide:String="") -> void:
	if name_overide == "":
		res.resource_name = path.get_file().get_basename()
	else:
		res.resource_name = name_overide
	ResourceSaver.save(res, path)
	res.take_over_path(path)


static func edit_resource(path):
	if path == "" or path.get_extension() == "":
		return
	if not FileAccess.file_exists(path):
		printerr("u_resource - File doens't exist: %s" % path)
		return
	var editor_interface = Engine.get_singleton("EditorInterface")
	if not editor_interface:
		printerr("u_resource - Could not get EditorInterface.")
		return
	var path_ext = path.get_extension()
	#var text_files = ["cfg", "json", "txt"]
	#if path_ext in text_files:
		#print("Not possible to open by code. Open via FileSystem or ScriptViewer")
		#return
	if path_ext == "tscn" or path_ext == "scn":
		editor_interface.open_scene_from_path(path)
		return
	
	var res = ResourceLoader.load(path)
	editor_interface.edit_resource(res)



static func resize_texture(texture:Texture2D, new_size_x:int, new_size_y:int=-1):
	var img = texture.get_image()
	if new_size_y == -1:
		new_size_y = new_size_x
	img.resize(new_size_x, new_size_y)
	var img_tex = ImageTexture.create_from_image(img)
	return img_tex

static func get_modulated_icon(texture:Texture2D, color:=Color(1,1,1)) -> Texture2D:
	var img = texture.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8) # Convert to RGBA8 to ensure can modify pixels
	
	for y in img.get_height():
		for x in img.get_width():
			var pixel_color = img.get_pixel(x, y)
			if pixel_color.a > 0: # Check if pixel has any visibility
				img.set_pixel(x, y, Color(color.r, color.b, color.g, pixel_color.a)) # Set RGB to White, KEEP the original Alpha
	
	return ImageTexture.create_from_image(img)

static func create_rect_texture(color:Color=Color.WHITE, size_x:int=1, size_y:int=1):
	var img = Image.create_empty(size_x, size_y, false, Image.FORMAT_BPTC_RGBA)
	img.decompress()
	for x in range(size_x):
		for y in range(size_y):
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)

static func load_or_get_icon(name_or_path:String):
	if FileAccess.file_exists(name_or_path):
		return load(name_or_path)
	var editor_interface = Engine.get_singleton(&"EditorInterface")
	if is_instance_valid(editor_interface):
		var theme = editor_interface.get_editor_theme()
		if theme.has_icon(name_or_path, &"EditorIcons"):
			return theme.get_icon(name_or_path, &"EditorIcons")
	printerr("Could not find icon: %s" % name_or_path)


static func instance_scene_or_script(path:String):
	if not FileAccess.file_exists(path):
		print("Could not instance, file doesn't exist: %s" % path)
		return
	var res = load(path)
	if res is PackedScene:
		var ins = res.instantiate()
		return ins
	elif res is Script:
		var ins = res.new()
		return ins
	else:
		print("Could not instance file: %s, file is: %s" % [path, type_string(typeof(res))])

static func get_object_file_path(obj:Object) -> String:
	if obj is Node:
		if obj.scene_file_path != "":
			return obj.scene_file_path
	if obj is Resource:
		return obj.resource_path
	else:
		var script = obj.get_script()
		if script:
			return script.resource_path
	return ""



static func get_resource_script_class(path:String):
	if path.get_extension() == "tres":
		return _get_resource_script_class_file_access(path)
	var res = load(path) as Resource
	var script = res.get_script() as GDScript
	if script == null:
		return ""
	return script.get_global_name()

static func _get_resource_script_class_file_access(file_path: String) -> String:
	var result = ""
	var f = UFile.get_file_access(file_path)
	if f:
		var header = f.get_line()
		if "script_class=" in header:
			var start_index = header.find("script_class=") + 14 # Length of 'script_class="'
			var end_index = header.find('"', start_index)
			if end_index != -1:
				result = header.substr(start_index, end_index - start_index)
	return result

static func check_scene_root(file_path:String, valid_types:Array) -> bool:
	var root = get_scene_root_type(file_path)
	return root in valid_types
	

static func get_scene_root_type(file_path:String):
	var file = UFile.get_file_access(file_path)
	if file:
		while not file.eof_reached():
			var line = file.get_line()
			if not line.find("[node name=") > -1:
				continue
			if line.find("instance=") > -1:
				pass
			else:
				var first_pass_type = line.get_slice('type="', 1)
				var type = first_pass_type.get_slice('"', 0)
				return type
	return ""
