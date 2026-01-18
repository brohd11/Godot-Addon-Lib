
const SIMILARITY_TO_INT = true

static func filter_array(to_filter:PackedStringArray, filter_text_array:PackedStringArray,
					search_callables=default_callables()) -> PackedStringArray:
	
	var valid_path_dict = search_callables.match.call(to_filter, filter_text_array)
	if valid_path_dict is PackedStringArray:
		return valid_path_dict
	var valid_paths = PackedStringArray(search_callables.sort.call(valid_path_dict))
	return valid_paths

static func get_search_callable_dict(match_callable:Callable, sort_callable=null):
	if sort_callable == null:
		sort_callable = Sort.no_sort
	return {"match": match_callable, "sort": sort_callable}

static func default_callables(file_name:=false):
	return get_search_callable_dict(Match.subsequence_sorted.bind(file_name), Sort.similarity)

static func subsequence(to_filter:PackedStringArray, filter_text_array:PackedStringArray, file_name:=false):
	var callables = get_search_callable_dict(Match.subsequence.bind(file_name))
	return filter_array(to_filter, filter_text_array, callables)

static func subsequence_sorted(to_filter:PackedStringArray, filter_text_array:PackedStringArray, file_name:=false):
	var callables = get_search_callable_dict(Match.subsequence_sorted.bind(file_name), Sort.similarity)
	return filter_array(to_filter, filter_text_array, callables)

static func exact(to_filter:PackedStringArray, filter_text_array:PackedStringArray, file_name:=false):
	var callables = get_search_callable_dict(Match.exact.bind(file_name))
	return filter_array(to_filter, filter_text_array, callables)

static func exact_sorted(to_filter:PackedStringArray, filter_text_array:PackedStringArray, file_name:=false):
	var callables = get_search_callable_dict(Match.exact_sorted.bind(file_name), Sort.similarity)
	return filter_array(to_filter, filter_text_array, callables)



class Match:
	static func subsequence(to_filter:PackedStringArray, filter_text_array:PackedStringArray, file_name:=false):
		var valid_path_dict = {}
		for string in to_filter:
			var check_string = string.trim_suffix("/")
			if file_name:
				check_string = check_string.get_file()
			
			if Check.subsequence_n(check_string, filter_text_array):
				valid_path_dict[string] = true
		return valid_path_dict
	
	static func subsequence_sorted(to_filter:PackedStringArray, filter_text_array:PackedStringArray, file_name:=false):
		var valid_path_dict = {}
		for string in to_filter:
			var check_string = string.trim_suffix("/")
			if file_name:
				check_string = check_string.get_file()
			
			if Check.subsequence_n(check_string, filter_text_array):
				valid_path_dict[string] = Check.similarity(check_string, filter_text_array)
		return valid_path_dict
	
	static func exact(to_filter:PackedStringArray, filter_text_array:PackedStringArray, file_name:=false):
		var dict = {}
		for path in to_filter:
			var check_string = path.trim_suffix("/")
			if file_name:
				check_string = check_string.get_file()
			
			if Check.contains(check_string, filter_text_array):
				dict[path] = true
		return dict
	
	static func exact_sorted(to_filter:PackedStringArray, filter_text_array:PackedStringArray, file_name:=false):
		var dict = {}
		for path in to_filter:
			var check_string = path.trim_suffix("/")
			if file_name:
				check_string = check_string.get_file()
			
			if Check.contains(check_string, filter_text_array):
				dict[path] = Check.similarity(path, filter_text_array)
		return dict


class Sort:
	
	static func no_sort(valid_path_dict:Dictionary):
		return valid_path_dict.keys()
	
	static func similarity(valid_path_dict:Dictionary):
		var sort_callable = func(a:String, b:String):
			var a_sim = valid_path_dict[a]
			var b_sim = valid_path_dict[b]
			if a_sim > b_sim:
				return true
			if b_sim > a_sim:
				return false
			if a.length() != b.length():
				return a.length() < b.length()
			return a < b
		
		var valid_paths = valid_path_dict.keys()
		valid_paths.sort_custom(sort_callable)
		return valid_paths




class Check:
	
	static func contains(to_check:String, filter_text_array:PackedStringArray) -> bool:
		for string in filter_text_array:
			if not to_check.contains(string):
				return false
		return true
	
	static func contains_n(to_check:String, filter_text_array:PackedStringArray) -> bool:
		for string in filter_text_array:
			if not to_check.containsn(string):
				return false
		return true
	
	static func subsequence(to_check:String, filter_text_array:PackedStringArray) -> bool:
		for string in filter_text_array:
			if not string.is_subsequence_of(to_check):
				return false
		return true
	
	static func subsequence_n(to_check:String, filter_text_array:PackedStringArray) -> bool:
		for string in filter_text_array:
			if not string.is_subsequence_ofn(to_check):
				return false
		return true
	
	static func similarity(to_check:String, filter_text_array:PackedStringArray):
		var max_sim = 0
		for string in filter_text_array:
			max_sim = maxf(max_sim, string.similarity(to_check))
		if SIMILARITY_TO_INT:
			max_sim = int(max_sim * 1000)
		return max_sim


static func get_file_name(string:String, get_file:=true):
	if get_file:
		return string.trim_suffix("/").get_file()
	return string












static func check_filter(text:String, filter_text:String) -> bool:
	if filter_text == "":
		return true
	if text.find(filter_text) > -1:
		return true
	return false

static func check_filter_split(text:String, filter_text:String) -> bool:
	if filter_text == "":
		return true # true == don't hide
	var f_split := filter_text.split(" ", false)
	for s in f_split:
		if text.find(s) == -1:
			return false
	return true


static func check_subsequence(text:String, filter_text:String) -> bool:
	if filter_text.is_subsequence_ofn(text):
		return true
	return false
