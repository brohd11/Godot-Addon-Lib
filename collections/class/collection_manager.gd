
const CollectionBase = preload("res://addons/addon_lib/brohd/collections/class/base/collection_base.gd")


var collections_dir = "user://addons/collections/"
var collections:= {}

signal collections_updated

func _update_collections():
	print("UPDATING")
	load_all_collections()
	collections_updated.emit()

func collection_valid(collection:CollectionBase):
	if not is_instance_valid(collection): return false
	return collections.has(collection.get_collection_name())

func get_collections():
	return collections.values()

func get_collection(collection_name:String):
	return collections.get(collection_name)

func refresh_collection(collection:CollectionBase):
	if not is_instance_valid(collection): return
	return collections.get(collection.get_collection_name())

func load_all_collections():
	for _name in collections.keys():
		var collection = collections[_name]
		var path = _get_collection_path(collection)
		if not FileAccess.file_exists(path):
			collections.erase(_name)
	
	DirAccess.make_dir_recursive_absolute(collections_dir)
	var files = DirAccess.get_files_at(collections_dir)
	for f in files:
		var path = collections_dir.path_join(f)
		var collection = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as CollectionBase
		collections[collection.get_collection_name()] = collection

func new_collection(_name:=""):
	var collection = CollectionBase.new()
	if _name != "":
		collection.set_collection_name(_name)
	if collection.get_collection_name() in collections.keys():
		print("Collection already exists: %s" % collection.get_collection_name())
		return
	collections[collection.get_collection_name()] = collection
	save_all_collections()
	return collection


func save_collection(collection, update:=true):
	if collection == null: return
	DirAccess.make_dir_recursive_absolute(collections_dir)
	ResourceSaver.save(collection, _get_collection_path(collection))
	if update:
		_update_collections()
	

func save_all_collections():
	for collection in collections.values():
		save_collection(collection, false)
	_update_collections()

func erase_collection(collection:CollectionBase):
	var collection_name = collection.get_collection_name()
	var conf = ALibRuntime.Dialog.ConfirmationDialogHandler.new("Delete collection: %s" % collection_name)
	var handled = await conf.handled
	if not handled:
		return
	DirAccess.remove_absolute(_get_collection_path(collection))
	collections.erase(collection_name)
	_update_collections()


func _get_collection_path(collection:CollectionBase):
	var save_name = collection.get_collection_name().replace("/", "_")
	return collections_dir.path_join(save_name) + ".tres"
