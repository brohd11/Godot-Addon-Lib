extends RefCounted
#! namespace ALibRuntime.Utils class UResource

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
