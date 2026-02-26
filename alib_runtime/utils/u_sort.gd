#! namespace ALibRuntime.Utils class USort

static func sort_priority_dict(key_priority_dict:Dictionary) -> Dictionary:
	var keys = key_priority_dict.keys()
	# basic sort of priorities with ref to key
	keys.sort_custom(func(a, b): return key_priority_dict[a] < key_priority_dict[b])
	
	var result_dict: Dictionary = {}
	for i in range(keys.size()):
		var current_key = keys[i]
		result_dict[current_key] = i
	
	return result_dict
