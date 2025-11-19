extends Control

func _ready() -> void:
	self.hide()

func toggle() -> void:
	if visible:
		hide()
	else:
		show()
