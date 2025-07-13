@tool
extends Window

@onready var cancel_button = %CancelButton

@onready var window_text_label = %WindowText
@onready var progress_bar = %ProgressBar

signal action_canceled

func _ready() -> void:
	pass
	#var theme_setter = ab_lib.Stat.ab_theme.new_theme_setter()
	#get_child(0).add_child(theme_setter)

func is_cancellable():
	cancel_button.show()

func set_text(new_text):
	window_text_label.text = new_text

func increment_bar(new_val):
	progress_bar.value += new_val

func _on_cancel_button_pressed() -> void:
	self.action_canceled.emit()
