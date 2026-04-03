#! namespace ALibRuntime.Popups class Options
const PopupHelper = preload("res://addons/addon_lib/brohd/alib_runtime/popup_menu/popup_menu_path_helper.gd")
const Params = PopupHelper.ParamKeys

const SELF = preload("res://addons/addon_lib/brohd/alib_runtime/popup_menu/popup_options.gd")

var _dict:= {}

func is_empty():
	return _dict.is_empty()

func size():
	return _dict.size()

func get_options():
	return _dict

func add_option(menu_path:String, callable, icon_array=null, metadata:={}):
	var data = {}
	if callable != null:
		data[Params.CALLABLE] = callable
	if icon_array != null:
		data[Params.ICON] = icon_array
	if not metadata.is_empty():
		data[Params.METADATA] = metadata
	var count = 1
	var original_path = menu_path
	while _dict.has(menu_path):
		menu_path = "%s (%s)" % [original_path, count]
		count += 1
	_dict[menu_path] = data
	return _dict[menu_path]

func add_radio_option(menu_path:String, callable, is_checked:bool=false, icon_array=null):
	var data = add_option(menu_path, callable, icon_array)
	data[Params.RADIO] = true
	data[Params.RADIO_IS_CHECKED] = is_checked
	return data

## Add enum keys as radio option, passes enum as arg to the callable and compares to current value
## to set checked radio item
func add_enum_radio(menu_path:String, callable:Callable, _enum:Dictionary, current_val:int, icon_array=null):
	for key in _enum.keys():
		var val = _enum[key]
		add_radio_option(menu_path.path_join(key), callable.bind(val), current_val == val, icon_array)


func add_option_data(menu_path:String, icon_color=null, metadata:={}):
	if not _dict.has(menu_path):
		printerr("Trying to add data to non-existent option: %s" % menu_path)
		return
	var data = _dict[menu_path]
	if icon_color:
		data[Params.ICON_COLOR] = icon_color

func add_separator(text:="", path=""):
	Params.add_separator(_dict, text, path)

func merge(options:SELF, overwrite:=false):
	_dict.merge(options.get_options(), overwrite)
