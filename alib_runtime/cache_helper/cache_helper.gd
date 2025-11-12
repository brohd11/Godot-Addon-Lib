## Args: Key, Value, CacheDict, FilePathArray=[]
static func store_data(key, value, data_cache:Dictionary, file_paths:=[]):
	var mod_data = {}
	for path in file_paths:
		mod_data[path] = FileAccess.get_modified_time(path)
	
	var data = {"value": value,
	"modified": mod_data}
	data_cache[key] = data

## Args: Keys, CacheDict
static func get_cached_data(key, data_cache:Dictionary):
	if not data_cache.has(key):
		return null
	var data = data_cache.get(key)
	var mod_data = data.get("modified", {})
	for path in mod_data.keys():
		if FileAccess.get_modified_time(path) != mod_data.get(path):
			data_cache.erase(key)
			return null
	return data.get("value")
