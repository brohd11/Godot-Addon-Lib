#! namespace ALibEditor.Singletons class TagParser
extends Singleton.Base

const CacheHelper = preload("res://addons/addon_lib/brohd/alib_runtime/cache_helper/cache_helper.gd")
const EditorGDScriptParser = ALibEditor.Singletons.EditorGDScriptParser
const GDScriptParser = EditorGDScriptParser.GDScriptParser
const UString = ALibRuntime.Utils.UString

## Implement in extended classes

# Use 'PE_STRIP_CAST_SCRIPT' to auto strip type casts with plugin exporter, if the class is not a global name
const PE_STRIP_CAST_SCRIPT = preload("res://addons/addon_lib/brohd/alib_editor/misc/parser/tag_parser.gd")
static func get_singleton_name() -> String:
	return "EditorTagParser"

static func get_instance() -> PE_STRIP_CAST_SCRIPT:
	return _get_instance(PE_STRIP_CAST_SCRIPT)

static func instance_valid() -> bool:
	return _instance_valid(PE_STRIP_CAST_SCRIPT)

static func call_on_ready(callable:Callable, print_err:bool=true):
	_call_on_ready(PE_STRIP_CAST_SCRIPT, callable, print_err)

func _get_ready_bool() -> bool:
	return is_node_ready()

static func register_tag_parser(tag:StringName, parser:Object):
	var ins = get_instance()
	if ins.parsers.has(tag):
		printerr("Parser tag already registered::", tag)
	elif not parser.has_method("parse_tag"):
		printerr("Parser does not have 'parse_tag' method::", parser, "::Tag - ", tag)
	else:
		ins.parsers[tag] = parser

static func unregister_tag_parser(tag:StringName):
	var ins = get_instance()
	if not ins.parsers.has(tag):
		printerr("Tag was not registered::", tag)
	else:
		ins.parsers.erase(tag)



var parsers:Dictionary[StringName, Object] = {}

var meta_regex:RegEx
var member_regex:RegEx

var _cache = {}
var _hot_cache = {}

func _init(_node:Node=null):
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)

func _on_filesystem_changed():
	_hot_cache.clear()

func _on_editor_script_changed(script):
	pass


static func get_tag_parser(tag:StringName):
	var ins = get_instance()
	var parser = ins.parsers.get(tag)
	if parser == null:
		print("Parser not registered: ", tag)
	return parser

static func get_metadata_for_type(type_path:String, tag:StringName=&""):
	if not GDScriptParser.Utils.is_absolute_path(type_path):
		return
	
	var script_data = GDScriptParser.Utils.type_path_get_script_data(type_path)
	var script_path = script_data[0]
	var class_access = script_data[1]
	var member = GDScriptParser.Utils.type_path_get_member(type_path)
	
	var ins = get_instance()
	var script_meta = ins.get_script_metadata(script_path)
	if not script_meta:
		return
	var data_for_class = script_meta.get(class_access)
	if not data_for_class:
		return
	
	var data = {}
	var valid_tags = data_for_class.keys() if tag.is_empty() else [tag]
	for t in valid_tags:
		var tag_data = data_for_class.get(t)
		if not tag_data:
			continue
		var member_data = tag_data.get(member)
		if member_data:
			data[t] = member_data.duplicate()
	return data

static func get_tag_metadata(tag:StringName, path:String=""):
	var ins = get_instance()
	if path == "":
		path = ScriptEditorRef.get_current_script().resource_path
	var meta = ins.get_script_metadata(path)
	print("GETTING::", path, "::", meta)
	return meta.get(tag)

func get_script_metadata(path:String):
	var current_script = ScriptEditorRef.get_current_script()
	var is_current_script = path == current_script.resource_path
	if not is_current_script:
		var cached_data = CacheHelper.get_cached_data(path, _cache)
		if cached_data != null:
			#printerr("GETTING CACHED::", path)
			return cached_data
	
	var parser:GDScriptParser = EditorGDScriptParser.get_parser(path)
	var metadata = parse_script_metadata(parser)
	CacheHelper.store_data(path, metadata, _cache, [path])
	return metadata


func parse_script_metadata(gdscript_parser: GDScriptParser) -> Dictionary:
	var metadata_cache = {}
	
	# Captures "arg_location" as 'tag' and "line:Keys context:SubSpace" as 'args'
	if not is_instance_valid(meta_regex):
		meta_regex = RegEx.new()
		#meta_regex.compile("^\\s*#!\\s*(?<tag>\\w+)(?:\\s+(?<args>.*))?$")
		meta_regex.compile("^\\s*#!\\s*(?<tag>\\w+)(?:\\s+(?<mod>[^;]+?))?(?:\\s*;\\s*(?<args>.*))?$") # new one allows for symbols directly after the tag

	# Captures the keyword (func/var/const/signal) as 'type' and the name as 'name'.
	# It safely ignores any @ annotations or 'static' keywords before it.
	if not is_instance_valid(member_regex):
		member_regex = RegEx.new()
		member_regex.compile("^\\s*(?:@[a-zA-Z0-9_]+(?:\\([^)]*\\))?\\s*)*(?:static\\s+)?(?<type>func|var|const|signal|class)\\s+(?<name>\\w+)")
	
	#if not gdscript_parser:
		#return {}
	var code_edit_parser = gdscript_parser.get_code_edit_parser()
	
	# pending_tags format: {"tag_name": "args string"}
	var pending_tags = {}
	#var source_code_lines = source_code.split("\n")
	
	for i in range(code_edit_parser.code_edit.get_line_count()):
		var line = code_edit_parser.get_line(i)
		# 1. Check for Meta Tags
		var meta_match = meta_regex.search(line)
		if meta_match:
			var tag = meta_match.get_string("tag")
			var modifiers = meta_match.get_string("mod")
			var args = meta_match.get_string("args").strip_edges()
			
			var has_semi = line.contains(";")
			if args.is_empty() and not has_semi:
				args = modifiers
				modifiers = ""
			
			# If a tag is used multiple times on the same member, append with a space
			if pending_tags.has(tag):
				pending_tags[tag]["args"] += " " + args
				pending_tags[tag]["mods"] += " " + modifiers
			else:
				pending_tags[tag] = {"args": args, "mods": modifiers}
			continue
			
		# 2. Check for Member Declarations (func, var, const, etc.)
		var member_match = member_regex.search(line)
		if member_match:
			if not pending_tags.is_empty():
				var class_access_path = gdscript_parser.get_class_at_line(i)
				var class_access_dict = metadata_cache.get_or_add(class_access_path, {})
				var member_name = member_match.get_string("name")
				
				
				# NOTE: You mentioned you have your own inner-class handling logic.
				# You would apply your "member_name" path logic here. 
				# e.g., if inside an inner class: member_name = "InnerClass." + member_name
				
				# Process each collected tag
				for tag in pending_tags.keys():
					if parsers.has(tag):
						var raw_tags = pending_tags[tag]
						var tag_parser = parsers.get(tag)
						var parsed_data = tag_parser.parse_tag(raw_tags)
						
						# Ensure the tag category exists in the root cache
						if not class_access_dict.has(tag):
							class_access_dict[tag] = {}
							
						# Store the data under the member name
						class_access_dict[tag][member_name] = parsed_data
					else:
						pass
						#push_warning("Script Metadata: No parser defined for tag: #! " + tag)
				
				# Clear pending tags for the next member
				pending_tags.clear()
			continue
			
		# 3. Code/Comment Reset Rule
		var stripped = line.strip_edges()
		if not stripped.begins_with("#") and not stripped.is_empty():
			# We hit standard code, so clear any floating tags that 
			# didn't attach to a recognized member to prevent misattribution.
			pending_tags.clear()

	return metadata_cache
