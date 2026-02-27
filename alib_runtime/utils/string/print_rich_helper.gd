
var _string:String = ""

func clear():
	_string = ""
	return self

func append(text:Variant, color:Color=Color.TRANSPARENT):
	if text is not String:
		text = str(text)
	if color == Color.TRANSPARENT:
		_string += text
		return self
	var color_string = color.to_html()
	_string += "[color=%s]%s[/color]" % [color_string, text]
	return self

func get_string():
	return _string

func display(clear_string:=true):
	print_rich(_string)
	if clear_string:
		clear()
	return self
