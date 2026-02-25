#! namespace ALibRuntime class Dialog



static func confirm(message_text:String, dialog_parent=null):
	var handler = Handlers.Confirmation.new(message_text, dialog_parent)
	return await handler.handled

static func acknowledge(message_text:String, dialog_parent=null):
	var handler = Handlers.Confirmation.new(message_text, dialog_parent)
	handler.is_acknowledge()
	return await handler.handled


class Handlers:
	const Confirmation = preload("uid://b4rwv7tgks0b5") # confirmation.gd
	const File = preload("uid://d1hn4ujniin7r") # file.gd
	const General = preload("uid://bnbqhxa04g4r5") # general_dialog.gd
	const LineSubmit = preload("uid://dmilkaqawd510") # line_submit.gd
