extends Control

@export var dialog_name = "Default"
@export var window_size = Vector2i(600,400)

func on_confirm_pressed():
	
	pass

func _get_button_at_index(idx):
	var dialog_window = get_window()
	return dialog_window.get_button(idx)

func _hide_button_at_index(idx):
	var dialog_window = get_window()
	dialog_window.hide_button(idx)

func _set_confirm_button_text(text):
	var dialog_window = get_window()
	dialog_window.set_confirm_button_text(text)

func _set_cancel_button_text(text):
	var dialog_window = get_window()
	dialog_window.set_cancel_button_text(text)
